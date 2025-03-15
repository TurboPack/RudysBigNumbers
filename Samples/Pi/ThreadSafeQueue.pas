unit ThreadSafeQueue;

interface

uses
  System.Classes, System.SyncObjs, System.Generics.Collections, System.SysUtils;

type
  /// <summary>
  /// Record to store the integer value and its index.
  /// </summary>
  TQueueItem = record
    Value: Char;
    Index: Int64;
  end;

  /// <summary>
  /// Lock-free queue implementation.
  /// </summary>
  TThreadSafeQueue = class
  private
    // const
    //   SPIN_COUNT = 4000;
    //   YIELD_COUNT = 10;
    //   WAIT_TIME = 50;
    //   BATCH_SIZE = 16; // Adjust based on usage patterns
  private
    // Group rarely modified items
    FItems: array of TQueueItem;     // Dynamic array pointer
    FCapacity: Integer;              // Fixed after creation
    FThresholdEvent: TEvent;         // For threshold signaling
    FFullEvent: TEvent;              // For full queue signaling
    FThreshold: Integer;             // Changed infrequently

    // Frequently accessed atomic variables with padding
    FCachePad1: array[0..63] of Byte; // Ensure new cache line
    FHead: Integer;
    FCachePad2: array[0..63] of Byte; // Ensure new cache line
    FTail: Integer;
    FCachePad3: array[0..63] of Byte; // Ensure new cache line
    FNextIndex: Int64;
    FCachePad4: array[0..63] of Byte; // Ensure new cache line

    FSpinCount: Integer; 
    FYieldCount: Integer;
    FWaitTime: Integer;
    FBatchSize: Integer;
    /// <summary>
    /// Helper method to check if the queue is empty. 
    /// </summary>
    function GetIsEmpty: Boolean;
    /// <summary>
    /// Helper method to get the current capacity of the queue.
    /// </summary>
    function GetCapacity: Integer;
  public
    /// <summary>
    /// Constructor to create a thread-safe queue.
    /// </summary>
    /// <param name="AThreshold">The threshold for signaling.</param>
    /// <param name="AInitialCapacity">The initial capacity of the queue.</param>
    /// <param name="ASpinCount">Number of spins before yielding.</param>
    /// <param name="AYieldCount">Number of yields before waiting.</param>
    /// <param name="AWaitTime">Wait time in milliseconds.</param>
    /// <param name="ABatchSize">Batch size for dequeue operations.</param>
    constructor Create(AThreshold, AMaxCapacity: Integer; 
      ASpinCount: Integer = 4000; 
      AYieldCount: Integer = 10;
      AWaitTime: Integer = 50;
      ABatchSize: Integer = 16);
    /// <summary>
    /// Destructor to clean up resources.
    /// </summary>
    destructor Destroy; override;

    /// <summary> 
    /// Peek at the front item of the queue without removing it.
    /// Thread safe but may throw exception if queue changes during peek.
    /// </summary>
    /// <exception cref="Exception">Thrown if queue is empty or changes during peek.</exception>
    function Peek: Char;

    /// <summary>
    /// Add an item to the queue (producer thread).
    /// </summary>
    /// <param name="AValue">The value to add to the queue.</param>
    /// <returns>True if the item was added successfully, False if the queue is full.</returns>
    function Enqueue(AValue: Char): Boolean;

    /// <summary>
    /// Try to get an item from the queue (consumer thread).
    /// </summary>
    /// <param name="AItem">The item retrieved from the queue.</param>
    /// <returns>True if an item was retrieved successfully, False if the queue is empty.</returns>
    function TryDequeue(out AItem: TQueueItem): Boolean;

    /// <summary>
    /// Get and remove the front Record (value and index) of the queue (consumer thread).
    /// Fails if the queue is empty.
    /// </summary>
    function Dequeue: TQueueItem;

    /// <summary>
    /// Get and remove the front value of the queue (consumer thread).
    /// Fails if the queue is empty.
    /// </summary>
    function DequeueValue: Char;

    /// <summary>
    /// Get the current queue count.
    /// </summary>
    /// <returns>The number of items in the queue.</returns>
    function Count: Integer;

    /// <summary>
    /// Wait until the queue drops below the threshold (producer thread).
    /// </summary>
    procedure WaitUntilBelowThreshold;

    /// <summary>
    /// Signal that an item has been removed (consumer thread).
    /// </summary>
    procedure SignalItemRemoved;

    /// <summary>
    /// Property to get/set the threshold.
    /// </summary>
    property Threshold: Integer read FThreshold write FThreshold;

    /// <summary>
    /// Property to check if the queue is empty.  
    /// </summary>
    property IsEmpty: Boolean read GetIsEmpty;

    /// <summary>
    /// Property to get the current capacity of the queue.
    /// </summary>
    property Capacity: Integer read GetCapacity;

    /// <summary>
    /// Waits for and removes an item from the queue (consumer thread).
    /// </summary>
    /// <param name="ATimeout">Optional timeout in milliseconds. Default is INFINITE.</param>
    /// <returns>The dequeued item record.</returns>
    /// <exception cref="ETimeoutException">Thrown if timeout expires before item available.</exception>
    function DequeueWait(ATimeout: Cardinal = INFINITE): TQueueItem;

    /// <summary>
    /// Waits for and removes an item from the queue (consumer thread).
    /// </summary>
    /// <param name="ATimeout">Optional timeout in milliseconds. Default is INFINITE.</param>
    /// <returns>The dequeued item value.</returns>
    /// <exception cref="ETimeoutException">Thrown if timeout expires before item available.</exception>
    function DequeueWaitValue(ATimeout: Cardinal = INFINITE): char;

    function TryDequeueBatch(var Items: array of TQueueItem): Integer;
  end;

implementation

uses
  System.Math;

{ TThreadSafeQueue }

constructor TThreadSafeQueue.Create(AThreshold, AMaxCapacity: Integer; 
  ASpinCount: Integer = 4000; 
  AYieldCount: Integer = 10;
  AWaitTime: Integer = 50;
  ABatchSize: Integer = 16);
begin
  inherited Create;

  Assert(AThreshold < AMaxCapacity, 'Threshold must be less than MaxCapacity.');

  // Prevent H2219 Private symbol declared but never used
  FillChar(FCachePad1, Length(FCachePad1), 0);
  FillChar(FCachePad2, Length(FCachePad2), 0);
  FillChar(FCachePad3, Length(FCachePad3), 0);
  FillChar(FCachePad4, Length(FCachePad4), 0);

  FSpinCount := ASpinCount;
  FYieldCount := AYieldCount;
  FWaitTime := AWaitTime;
  FBatchSize := ABatchSize;

  try
    // Initialize with power of 2 capacity for efficient modulo operations
    FCapacity := 1 shl Trunc(Log2(AMaxCapacity - 1) + 1);

    SetLength(FItems, FCapacity);

    FHead := 0;
    FTail := 0;
    FThreshold := AThreshold;

    // Manual reset = False, Initial state = False (non-signaled)
    FThresholdEvent := TEvent.Create(nil, False, False, '');
    FFullEvent := TEvent.Create(nil, False, True, '');  // Start signaled since queue is empty

    AtomicExchange(FNextIndex, 0);
  except
    on E: Exception do
    begin
      raise Exception.CreateFmt('Error initializing TThreadSafeQueue: %s', [E.Message]);
    end;
  end;
end;

function TThreadSafeQueue.Dequeue: TQueueItem;
var
  item: TQueueItem;
begin
  if TryDequeue(item) then
    Result := Item
  else
    raise Exception.Create('Queue empty, unable to dequeue.');
end;

function TThreadSafeQueue.DequeueValue: Char;
begin
  Result := Dequeue.Value;
end;

destructor TThreadSafeQueue.Destroy;
begin
  try
    FThresholdEvent.Free;
    FFullEvent.Free;
  finally
    inherited;
  end;
end;

function TThreadSafeQueue.Enqueue(AValue: Char): Boolean;
var
  Tail, NextTail, Head: Integer;
  Item: TQueueItem;
begin
  Item.Value := AValue;
  Item.Index := System.AtomicIncrement(FNextIndex);

  while True do
  begin
    Tail := System.AtomicCmpExchange(FTail, FTail, FTail);
    NextTail := (Tail + 1) and (FCapacity - 1);
    Head := System.AtomicCmpExchange(FHead, FHead, FHead);

    if NextTail = Head then
    begin
      FFullEvent.ResetEvent;  // Signal queue is full
      Exit(False);
    end;

    if System.AtomicCmpExchange(FTail, NextTail, Tail) = Tail then
    begin
      FItems[Tail] := Item;
      System.MemoryBarrier;
      // Signal waiting consumers
      FThresholdEvent.SetEvent;
      Exit(True);
    end;

    TThread.Yield;
  end;
end;

/// <summary> 
/// Peek at the front item of the queue without removing it.
/// Thread safe but may throw exception if queue changes during peek.
/// </summary>
/// <exception cref="Exception">Thrown if queue is empty or changes during peek.</exception>
function TThreadSafeQueue.Peek: Char;
var
  Head, Tail: Integer;
  Item: TQueueItem;
begin
  Head := System.AtomicCmpExchange(FHead, FHead, FHead);
  Tail := System.AtomicCmpExchange(FTail, FTail, FTail);
  
  if Head = Tail then
    raise Exception.Create('Queue is empty');
    
  Item := FItems[Head];
  System.MemoryBarrier; // Ensure we read consistent data
  
  if Head <> System.AtomicCmpExchange(FHead, FHead, FHead) then
    raise Exception.Create('Queue changed during peek');
    
  Result := Item.Value;
end;

function TThreadSafeQueue.TryDequeue(out AItem: TQueueItem): Boolean;
var
  Head, NextHead, Tail, SpinCount: Integer;
  LocalItem: TQueueItem;
begin
    SpinCount := 0;

  while True do
  begin
    // Get consistent snapshot of head and tail with memory barriers
    Head := System.AtomicCmpExchange(FHead, FHead, FHead);
    System.MemoryBarrier; // Ensure head read is ordered
        // Ensure head read is ordered
    Tail := System.AtomicCmpExchange(FTail, FTail, FTail);
    System.MemoryBarrier; // Ensure tail read is ordered

    if Head = Tail then
      Exit(False);

    System.MemoryBarrier;
    
    // Read item before attempting head update to ensure visibility
    LocalItem := FItems[Head];

    System.MemoryBarrier;
    NextHead := (Head + 1) and (FCapacity - 1);

    // Try to update head - if successful, we've claimed the item
    if System.AtomicCmpExchange(FHead, NextHead, Head) = Head then
    begin
      System.MemoryBarrier; // Ensure all reads are complete
      AItem := LocalItem;   // Safe to copy now
      Result := True;
      
      if Count < FThreshold then
        FThresholdEvent.SetEvent;
      FFullEvent.SetEvent;  // Signal queue is not full
      Break;
    end;

    // Contention - apply backoff strategy
    Inc(SpinCount);
    if SpinCount >= FSpinCount then
    begin
      SpinCount := 0;
      TThread.Yield;
    end;
  end;
end;

function TThreadSafeQueue.Count: Integer;
var
  Head, Tail: Integer;
begin
  // Atomic reads using CmpExchange
  Head := System.AtomicCmpExchange(FHead, FHead, FHead);
  Tail := System.AtomicCmpExchange(FTail, FTail, FTail);
  
  // Efficient wrap-around calculation for power-of-2 sized array
  Result := (Tail - Head) and (FCapacity - 1);
end;

procedure TThreadSafeQueue.WaitUntilBelowThreshold;
begin
  try
    // Fast path: check if already below threshold
    if Count < FThreshold then
      Exit;

    // Wait for the event to be signaled
    FThresholdEvent.WaitFor;
  except
    on E: Exception do
    begin
      raise Exception.CreateFmt('Error waiting until below threshold: %s', [E.Message]);
    end;
  end;
end;

procedure TThreadSafeQueue.SignalItemRemoved;
begin
  try
    if Count < FThreshold then
      FThresholdEvent.SetEvent;
    FFullEvent.SetEvent;
  except
    on E: Exception do
    begin
      raise Exception.CreateFmt('Error signaling item removed: %s', [E.Message]);
    end;
  end;
end;

function TThreadSafeQueue.GetCapacity: Integer;
begin
  Result := FCapacity -1;
end;

function TThreadSafeQueue.GetIsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TThreadSafeQueue.DequeueWait(ATimeout: Cardinal = INFINITE): TQueueItem;
var
  Item: TQueueItem;
  SpinCount: Integer;
  StartTime: Cardinal;
begin
  SpinCount := 0;
  StartTime := TThread.GetTickCount;
  
  while True do
  begin
    // Try immediate dequeue
    if TryDequeue(Item) then
    begin
      Result := Item;
      Exit;
    end;

    // Check timeout
    if (ATimeout <> INFINITE) and 
       (TThread.GetTickCount - StartTime > ATimeout) then
      raise Exception.Create('Dequeue timeout expired');

    // Backoff strategy
    Inc(SpinCount);
    if SpinCount >= FSpinCount then
    begin
      SpinCount := 0;
      // Signal we're waiting and wait for new items
      System.MemoryBarrier;
      FThresholdEvent.WaitFor(50); // Short wait interval
    end;
  end;
end;

function TThreadSafeQueue.DequeueWaitValue(ATimeout: Cardinal): char;
begin
  Result := DequeueWait(ATimeout).Value;
end;

function TThreadSafeQueue.TryDequeueBatch(var Items: array of TQueueItem): Integer;
var
  Head, NextHead, Tail, SpinCount, Count: Integer;
begin
  SpinCount := 0;
  Count := 0;
  
  while Count < Length(Items) do
  begin
    Head := System.AtomicCmpExchange(FHead, FHead, FHead);
    Tail := System.AtomicCmpExchange(FTail, FTail, FTail);
    NextHead := (Head + 1) and (FCapacity - 1);

    if Head = Tail then
      Break;

    Items[Count] := FItems[Head];

    if System.AtomicCmpExchange(FHead, NextHead, Head) = Head then
    begin
      Inc(Count);
      if Count < FThreshold then
        FThresholdEvent.SetEvent;
      FFullEvent.SetEvent;  // Signal queue is not full
    end;

    Inc(SpinCount);
    if SpinCount >= FSpinCount then
    begin
      SpinCount := 0;
      TThread.Yield;
    end;
  end;

  Result := Count;
end;

end.
