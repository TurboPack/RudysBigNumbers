unit ThreadedCharacterQueue;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.SyncObjs;

type
  TCharacterQueue = class
  private
    FQueue: TQueue<Char>;
    FLock: TCriticalSection;
    FNotEmptyEvent: TEvent;
    FNotFullEvent: TEvent;
    FThreshold: Integer;
  public
    constructor Create(AThreshold: Integer);
    destructor Destroy; override;

    // Add a batch of characters to the queue
    // Will block if queue is at or above threshold
    procedure EnqueueBatch(const ABatch: string);

    // Get next character from queue
    // Will block if queue is empty
    function DequeueChar(out AChar: Char): Boolean;

    // Non-blocking check of queue size
    function Count: Integer;
  end;

implementation

constructor TCharacterQueue.Create(AThreshold: Integer);
begin
  inherited Create;
  FQueue := TQueue<Char>.Create;
  FLock := TCriticalSection.Create;
  FNotEmptyEvent := TEvent.Create(nil, True, False, '');  // Manual reset
  FNotFullEvent := TEvent.Create(nil, True, True, '');    // Initially signaled
  FThreshold := AThreshold;
end;

destructor TCharacterQueue.Destroy;
begin
  FNotFullEvent.Free;
  FNotEmptyEvent.Free;
  FLock.Free;
  FQueue.Free;
  inherited;
end;

procedure TCharacterQueue.EnqueueBatch(const ABatch: string);
var
  C: Char;
begin
  // Wait until queue is below threshold
  while True do
  begin
    FLock.Acquire;
    try
      if FQueue.Count < FThreshold then
        Break;
    finally
      FLock.Release;
    end;

    // Wait for queue to have space
    FNotFullEvent.WaitFor;
  end;

  // Add characters to queue
  FLock.Acquire;
  try
    for C in ABatch do
    begin
      FQueue.Enqueue(C);
    end;

    // Signal that queue is not empty
    FNotEmptyEvent.SetEvent;

    // If we're at or above threshold, reset the not full event
    if FQueue.Count >= FThreshold then
      FNotFullEvent.ResetEvent;
  finally
    FLock.Release;
  end;
end;

function TCharacterQueue.DequeueChar(out AChar: Char): Boolean;
begin
  Result := False;

  // Wait until queue has items
  while True do
  begin
    FLock.Acquire;
    try
      if FQueue.Count > 0 then
        Break;
    finally
      FLock.Release;
    end;

    // Wait for queue to have items
    FNotEmptyEvent.WaitFor;
  end;

  // Get character from queue
  FLock.Acquire;
  try
    AChar := FQueue.Dequeue;
    Result := True;

    // If queue is now empty, reset the not empty event
    if FQueue.Count = 0 then
      FNotEmptyEvent.ResetEvent;

    // If queue was at threshold and now is below, signal not full event
    if FQueue.Count = FThreshold - 1 then
      FNotFullEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

function TCharacterQueue.Count: Integer;
begin
  FLock.Acquire;
  try
    Result := FQueue.Count;
  finally
    FLock.Release;
  end;
end;

end.
