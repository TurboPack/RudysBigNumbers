{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

 Licensed under BSD 2-Clause License
 Copyright © 2025 by Jim McKeeth

================================================}
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

    /// <summary>
    /// Adds a batch of characters to the queue.
    /// </summary>
    /// <param name="ABatch">The batch of characters to add to the queue.</param>
    /// <remarks>
    /// This method will block if the queue is at or above the threshold.
    /// </remarks>
    procedure EnqueueBatch(const ABatch: string);

    /// <summary>
    /// Retrieves the next character from the queue.
    /// </summary>
    /// <returns>The character retrieved from the queue.</returns>
    /// <remarks>
    /// This method will block if the queue is empty.
    /// </remarks>
    function DequeueChar: Char;

    /// <summary>
    /// Gets the current size of the queue without blocking.
    /// </summary>
    /// <returns>Returns the number of characters currently in the queue.</returns>
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

function TCharacterQueue.DequeueChar: Char;
begin
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
    Result := FQueue.Dequeue;

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
