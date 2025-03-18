{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
unit BackgroundPi;

interface

uses
  System.SysUtils, System.Types, System.Classes, BigPi, ThreadedCharacterQueue;

type
  TBackgroundPi = Class(TThread)
  private
    FFirstChunk: Boolean;
    FDigitCount: NativeUInt;
  protected

  public
    procedure Execute; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

implementation

procedure TBackgroundPi.AfterConstruction;
begin
  inherited;

end;

procedure TBackgroundPi.BeforeDestruction;
begin
  inherited;

end;

procedure TBackgroundPi.Execute;
begin
  FFirstChunk := True;
  FDigitCount := 0;
  BBPpi(MaxInt-1, procedure(chunk: TDigits) begin
    if TThread.CheckTerminated then 
      Exit;

    var Digits := DigitsToString(Chunk);
    if FFirstChunk then
    begin
      Digits := Digits.Insert(1, '.');
      FFirstChunk := False;
    end;

    FUIUpdater.WaitUntilBelowThreshold;
    for var idx := Low(Digits) to High(Digits) do
    begin
      if TThread.CheckTerminated then 
        Abort;
        
      Inc(FDigitCount);

      FUIUpdater.Enqueue(Digits[idx]);
    end;
  end);

end;

procedure TBackgroundPi.Init(AUIUpdater: TUIUpdate; AGetDelay: TGetDelay);
begin
  FUIUpdater.OnUIUpdate := AUIUpdater;
  FUIUpdater.OnGetDelay := AGetDelay;
  FUIUpdater.Start;
end;

end.
