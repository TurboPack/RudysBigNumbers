unit ThreadSafeQueueTests;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, DUnitX.TestFramework, ThreadSafeQueue;

type
  [TestFixture]
  TQueueTests = class
  private
    FQueue: TThreadSafeQueue;
    const Max = 48;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test] procedure TestEnqueue;
    [Test] procedure TestDequeue;
    [Test] procedure TestPeek;
    [Test] procedure TestIsEmpty;
    [Test] procedure TestConcurrentOperations;
    [Test] procedure TestOrder;
    [Test] procedure TestFill;
    [Test] procedure TestSlowFill;

  end;

implementation

uses
  System.Threading;

{ TThreadSafeQueueTests }

procedure TQueueTests.Setup;
begin
  FQueue := TThreadSafeQueue.Create(10, Max);
end;

procedure TQueueTests.TearDown;
begin
  FQueue.Free;
end;

procedure TQueueTests.TestEnqueue;
begin
  FQueue.Enqueue('4');
  Assert.IsFalse(FQueue.IsEmpty);
  Assert.AreEqual('4', FQueue.Peek);
end;

procedure TQueueTests.TestFill;
begin
  for var i := 0 to Pred(FQueue.Capacity) do
    Assert.IsTrue(FQueue.Enqueue(chr(i)),
      Format('Failed to add #%d before Capacity full.',[i]));
  Assert.IsFalse(FQueue.Enqueue(#27), 'Added beyond Capacity');
  Assert.AreEqual(FQueue.Capacity, FQueue.Count, 'Count should be at Capacity.')
end;

procedure TQueueTests.TestDequeue;
begin
  FQueue.Enqueue('4');
  Assert.AreEqual('4', FQueue.Dequeue.Value);
  Assert.IsTrue(FQueue.IsEmpty);
end;

procedure TQueueTests.TestPeek;
begin
  FQueue.Enqueue('4');
  Assert.AreEqual('4', FQueue.Peek);
  Assert.IsFalse(FQueue.IsEmpty);
end;


procedure TQueueTests.TestOrder;
var WriteTask, ReadTask: ITask;
begin
  WriteTask := TTask.Create(procedure
    begin
      for var I := 1 to Max*2 do
      begin
        FQueue.WaitUntilBelowThreshold;
        FQueue.Enqueue(Chr(I));
      end;
    end);

  ReadTask := TTask.Create(procedure
    var
      Value: TQueueItem;
    begin
      for var I := 1 to Max*2 do
      begin
        Value := FQueue.DequeueWait;
        Assert.AreEqual(Integer(I), Integer(Value.Index),
          'Read in wrong order.');
      end;
    end);

  WriteTask.Start;
  ReadTask.Start;

  TTask.WaitForAll([WriteTask, ReadTask]);
  Assert.IsTrue(FQueue.IsEmpty,'Queue was not empty when done.');
end;

procedure TQueueTests.TestSlowFill;
var
  WriteTask, ReadTask: ITask;
begin
  WriteTask := TTask.Create(procedure begin
      for var I := 1 to Max do begin
        sleep(10);
        FQueue.Enqueue(Chr(I));
      end;
    end);

  ReadTask := TTask.Create(procedure
    var Value: TQueueItem;
    begin
      for var I := 1 to Max do
      begin
        Value := FQueue.DequeueWait();
        Assert.AreEqual(Integer(I), Integer(Value.Index),
          'Read in wrong order.');
      end;
    end);

  ReadTask.Start;
  Sleep(10);
  WriteTask.Start;

  TTask.WaitForAll([WriteTask, ReadTask]);
  Assert.IsTrue(FQueue.IsEmpty,'Queue was not empty when done.');
end;

procedure TQueueTests.TestIsEmpty;
begin
  Assert.IsTrue(FQueue.IsEmpty);
  FQueue.Enqueue('4');
  Assert.IsFalse(FQueue.IsEmpty);
  FQueue.Dequeue;
  Assert.IsTrue(FQueue.IsEmpty);
end;


procedure TQueueTests.TestConcurrentOperations;
var
  WriteTask, ReadTask: ITask;
begin
  WriteTask := TTask.Create(procedure
    begin
      for var I := 1 to Max do
        FQueue.Enqueue(chr(I));
    end);

  ReadTask := TTask.Create(procedure
    var
      Value: TQueueItem;
    begin
      for var I := 1 to Max do
      begin
        while FQueue.IsEmpty do
        begin
          Sleep(1);
        end;
        Value := FQueue.Dequeue;
        Assert.AreEqual(chr(I),
          Value.Value, 'Wrong value read');
      end;
    end);

  WriteTask.Start;
  ReadTask.Start;

  TTask.WaitForAll([WriteTask, ReadTask]);
  Assert.IsTrue(FQueue.IsEmpty,'Queue was not empty when done.');
end;

end.
