{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
unit BackgroundPi;

interface

uses
  System.SysUtils, System.Types, System.Classes;

type
  TUIUpdate = procedure(digit: char; count: Integer) of object;
  TGetDelay = function: Double of object;
  TBackgroundPi = Class(TThread)
  private
    FFirstChunk: Boolean;
    FDigitCount: NativeUInt;
    FUIUpdate: TUIUpdate;
    FGetDelay: TGetDelay;
  public
    procedure Execute; override;
    property OnUIUpdate: TUIUpdate read FUIUpdate write FUIUpdate;
    property OnGetDelay: TGetDelay read FGetDelay write FGetDelay;
  end;

implementation

uses
  BigPi;

procedure TBackgroundPi.Execute;
begin
  FFirstChunk := True;
  FDigitCount := 0;
  BBPpi(MaxInt-1, procedure(chunk: TDigits) begin
    if TThread.CheckTerminated then Abort;
    if not Assigned(FUIUpdate) then
      raise ENotImplemented.Create('Must assign an OnUIUpdate handler');

    var Digits := DigitsToString(Chunk);
    if FFirstChunk then
    begin
      Digits := Digits.Insert(1,'.');
      FFirstChunk := False;
    end;

    for var idx := low(Digits) to High(Digits) do
    begin
      if TThread.CheckTerminated then Abort;
      Inc(FDigitCount);

      TThread.Queue(nil,
        procedure begin
          FUIUpdate(Digits[idx], FDigitCount);
        end);

      var Delay: Double := 1;
      if Assigned(FGetDelay) then
      begin
        Delay := FGetDelay;
        if Delay < 1 then
          Delay := 1;
      end;

      sleep(Round(Delay * 10));
    end;


  end);

end;



end.
