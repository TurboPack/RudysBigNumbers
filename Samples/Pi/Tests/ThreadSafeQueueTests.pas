unit ThreadSafeQueueTests;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, DUnitX.TestFramework, ThreadSafeQueue;

type
  [TestFixture]
  TQueueTests = class
  private
    FQueue: TThreadSafeQueue;
    const Max = 100;
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
  FQueue.Enqueue(42);
  Assert.IsFalse(FQueue.IsEmpty);
  Assert.AreEqual(42, FQueue.Peek);
end;

procedure TQueueTests.TestFill;
begin
  for var i := 0 to Pred(FQueue.Capacity) do
    Assert.IsTrue(FQueue.Enqueue(i),
      Format('Failed to add #%d before Capacity full.',[i]));
  Assert.IsFalse(FQueue.Enqueue(MaxInt), 'Added beyond Capacity');
  Assert.AreEqual(FQueue.Capacity, FQueue.Count, 'Count should be at Capacity.')
end;

procedure TQueueTests.TestDequeue;
begin
  FQueue.Enqueue(42);
  Assert.AreEqual(42, FQueue.Dequeue.Value);
  Assert.IsTrue(FQueue.IsEmpty);
end;

procedure TQueueTests.TestPeek;
begin
  FQueue.Enqueue(42);
  Assert.AreEqual(42, FQueue.Peek);
  Assert.IsFalse(FQueue.IsEmpty);
end;

procedure TQueueTests.TestIsEmpty;
begin
  Assert.IsTrue(FQueue.IsEmpty);
  FQueue.Enqueue(42);
  Assert.IsFalse(FQueue.IsEmpty);
  FQueue.Dequeue;
  Assert.IsTrue(FQueue.IsEmpty);
end;

procedure TQueueTests.TestOrder;
var
  Task1, Task2: ITask;
begin
  Task1 := TTask.Create(procedure
    begin
      for var I := 1 to Max do
        FQueue.Enqueue(I*2);
    end);

  Task2 := TTask.Create(procedure
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
        Assert.AreEqual(Integer(I), Integer(Value.Index),
          'Read in wrong order.');
      end;
    end);

  Task1.Start;
  Task2.Start;

  TTask.WaitForAll([Task1, Task2]);
  Assert.IsTrue(FQueue.IsEmpty,'Queue was not empty when done.');
end;

procedure TQueueTests.TestConcurrentOperations;
var
  Task1, Task2: ITask;
begin
  Task1 := TTask.Create(procedure
    begin
      for var I := 1 to Max do
        FQueue.Enqueue(I*2);
    end);

  Task2 := TTask.Create(procedure
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
        Assert.AreEqual(Integer(I*2),
          Value.Value, 'Wrong value read');
      end;
    end);

  Task1.Start;
  Task2.Start;

  TTask.WaitForAll([Task1, Task2]);
  Assert.IsTrue(FQueue.IsEmpty,'Queue was not empty when done.');
end;

end.
