{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
program BigPiFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  BigPiFMXMain in 'BigPiFMXMain.pas' {BigPiGui},
  BigPi in 'BigPi.pas',
  ThreadedCharacterQueue in 'ThreadedCharacterQueue.pas';

{$R *.res}

begin
  GlobalUseSkia := True;
  Application.Initialize;
  Application.CreateForm(TBigPiGui, BigPiGui);
  Application.Run;
end.
