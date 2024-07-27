{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
unit BackgroundPi;

interface

uses
  System.SysUtils, System.Types, System.Classes, BigPi;

type
  TUIUpdate = procedure(digit: char; count: Integer) of object;
  TGetDelay = function: Double of object;
  TBackgroundPi = Class(TThread)
  private
    FFirstChunk: Boolean;
    FDigitCount: NativeUInt;
    FUIUpdate: TUIUpdate;
    FGetDelay: TGetDelay;
    FNextChunk: TDigits;
    procedure QueueUpdate(digit: Char; count: UInt64);
    procedure QueueUpdates(digits: string);

  protected
    procedure DoTerminate; override;
  public
    procedure Execute; override;
    property OnUIUpdate: TUIUpdate read FUIUpdate write FUIUpdate;
    property OnGetDelay: TGetDelay read FGetDelay write FGetDelay;
  end;

implementation

procedure TBackgroundPi.QueueUpdate(digit: Char; count: UInt64);
begin
  TThread.Queue(nil,
    procedure begin
      FUIUpdate(digit, count);

      var Delay := 1;
      if Assigned(FGetDelay) then
      begin
        Delay := Round(FGetDelay);
        if Delay < 1 then
          Delay := 1;
      end;

      Sleep(Round(Delay));

    end);
end;

procedure TBackgroundPi.QueueUpdates(digits: string);
begin
  for var idx := low(Digits) to High(Digits) do
  begin
    if TThread.CheckTerminated then Exit;
    Inc(FDigitCount);

    var digit := Digits[idx];

    QueueUpdate(digit, FDigitCount);
  end;
end;

procedure TBackgroundPi.DoTerminate;
begin
  inherited;

end;

procedure TBackgroundPi.Execute;
begin
  FFirstChunk := True;
  FDigitCount := 0;
  BBPpi(MaxInt-1, procedure(chunk: TDigits) begin
    if TThread.CheckTerminated then Exit;
    if not Assigned(FUIUpdate) then
      raise
        ENotImplemented.Create(
          'Must assign an OnUIUpdate handler for TBackgroundPi.');

    var Digits := DigitsToString(Chunk);
    if FFirstChunk then
    begin
      Digits := Digits.Insert(1,'.');
      FFirstChunk := False;
    end;

    QueueUpdates(digits);
  end);

end;



end.
