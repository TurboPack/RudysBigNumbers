unit ThreadSafeQueue;

interface

uses
  System.Classes, System.SyncObjs, System.Generics.Collections, System.SysUtils;

type
  /// <summary>
  /// Record to store the integer value and its index.
  /// </summary>
  TQueueItem = record
    Value: Integer;
    Index: Int64;
  end;

  /// <summary>
  /// Lock-free queue implementation.
  /// </summary>
  TThreadSafeQueue = class
  private
    const
      SPIN_COUNT = 4000;
  private
    FCachePad1: array[0..63] of Byte;
    // Internal queue storage
    FItems: array of TQueueItem;
    FCapacity: Integer;
    FCachePad2: array[0..63] of Byte;

    // Head and tail indices (using atomic operations)
    FHead: Integer;
    FCachePad3: array[0..63] of Byte;
    FTail: Integer;
    FCachePad4: array[0..63] of Byte;

    // Event for threshold signaling
    FEvent: TEvent;
    FThreshold: Integer;

    // Next index counter (using atomic operations)
    FNextIndex: Int64;

    /// <summary>
    /// Helper method to check if the queue is empty. 
    /// </summary>
    function GetIsEmpty: Boolean;

    /// <summary>
    /// Helper method to increment index with wrap-around.
    /// </summary>
    /// <param name="AIndex">The index to increment.</param>
    /// <returns>The incremented index.</returns>
    function IncrementIndex(const AIndex: Integer): Integer; inline;
    function GetCapacity: Integer;
  public
    /// <summary>
    /// Constructor to create a thread-safe queue.
    /// </summary>
    /// <param name="AThreshold">The threshold for signaling.</param>
    /// <param name="AInitialCapacity">The initial capacity of the queue.</param>
    constructor Create(AThreshold, AMaxCapacity: Integer);
    destructor Destroy; override;

    function Peek: Integer;

    /// <summary>
    /// Add an item to the queue (producer thread).
    /// </summary>
    /// <param name="AValue">The value to add to the queue.</param>
    /// <returns>True if the item was added successfully, False if the queue is full.</returns>
    function Enqueue(AValue: Integer): Boolean;

    /// <summary>
    /// Try to get an item from the queue (consumer thread).
    /// </summary>
    /// <param name="AItem">The item retrieved from the queue.</param>
    /// <returns>True if an item was retrieved successfully, False if the queue is empty.</returns>
    function TryDequeue(out AItem: TQueueItem): Boolean;

    function Dequeue: TQueueItem;


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


    property Capacity: Integer read GetCapacity;
  end;

implementation

{ TThreadSafeQueue }

constructor TThreadSafeQueue.Create(AThreshold, AMaxCapacity: Integer);
begin
  inherited Create;
  try
    // Initialize with power of 2 capacity for efficient modulo operations
    FCapacity := 2;
    while FCapacity < AMaxCapacity do
      FCapacity := FCapacity * 2;

    SetLength(FItems, FCapacity);

    FHead := 0;
    FTail := 0;
    FThreshold := AThreshold;

    // Manual reset = False, Initial state = False (non-signaled)
    FEvent := TEvent.Create(nil, False, False, '');

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

destructor TThreadSafeQueue.Destroy;
begin
  FEvent.Free;
  inherited;
end;

function TThreadSafeQueue.IncrementIndex(const AIndex: Integer): Integer;
begin
  // Efficient modulo for power-of-2 sized arrays
  Result := (AIndex + 1) and (FCapacity - 1);
end;

function TThreadSafeQueue.Enqueue(AValue: Integer): Boolean;
var
  Tail, NextTail, Head, SpinCount: Integer;
  Item: TQueueItem;
begin
  Result := False;
  SpinCount := 0;
  
  Item.Value := AValue;
  Item.Index := System.AtomicIncrement(FNextIndex);

  while True do
  begin
    // Atomic reads using CmpExchange
    Tail := System.AtomicCmpExchange(FTail, FTail, FTail);
    NextTail := (Tail + 1) and (FCapacity - 1);
    Head := System.AtomicCmpExchange(FHead, FHead, FHead);

    if NextTail = Head then
      Exit(False);

    if System.AtomicCmpExchange(FTail, NextTail, Tail) = Tail then
    begin
      FItems[Tail] := Item;
      Break;
    end;

    // Simple spin wait
    Inc(SpinCount);
    if SpinCount >= SPIN_COUNT then
    begin
      SpinCount := 0;
      TThread.Yield;
    end;
  end;

  Result := True;
end;

function TThreadSafeQueue.Peek: Integer;
var
  Head: Integer; 
begin
  if IsEmpty then
    raise Exception.Create('Queue is empty');

  Head := System.AtomicCmpExchange(FHead, FHead, FHead);
  Result := FItems[Head].Value;
end;

function TThreadSafeQueue.TryDequeue(out AItem: TQueueItem): Boolean;
var
  Head, NextHead, Tail, SpinCount: Integer;
begin
  Result := False;
  SpinCount := 0;
  
  while True do
  begin
    Head := System.AtomicCmpExchange(FHead, FHead, FHead);
    Tail := System.AtomicCmpExchange(FTail, FTail, FTail);
    NextHead := (Head + 1) and (FCapacity - 1);

    if Head = Tail then
      Exit(False);

    AItem := FItems[Head];

    if System.AtomicCmpExchange(FHead, NextHead, Head) = Head then
    begin
      Result := True;
      if Count < FThreshold then
        FEvent.SetEvent;
      Break;
    end;

    Inc(SpinCount);
    if SpinCount >= SPIN_COUNT then
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
    FEvent.WaitFor;
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
      FEvent.SetEvent;
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

end.
