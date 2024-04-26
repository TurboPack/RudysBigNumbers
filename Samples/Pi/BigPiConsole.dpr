{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
program BigPiConsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Diagnostics,
  Math,
  Hash,
  Velthuis.BigDecimals,
  Velthuis.BigIntegers,
  BigPi in 'BigPi.pas';

function TimeChudnovskyPi(digits: UInt64): Int64;
begin
  var sw := TStopwatch.StartNew;
  var pi := Chudnovsky(digits);
  sw.Stop;
  writeln(Format('%6d'#9'%d',[digits,sw.ElapsedTicks]));
  Result := sw.ElapsedTicks;
end;

function TimeBBPPi(digits: UInt64): Int64;
begin
  var sw := TStopwatch.StartNew;
  var pi := BBPpi(digits);
  sw.Stop;
  writeln(Format('%6d'#9'%d',[digits,sw.ElapsedTicks]));
  Result := sw.ElapsedTicks;
end;

procedure HashPi(digits: UInt64);
begin
  var pi := BBPpi(digits).ToString.Insert(1,'.');
  Assert(Length(pi) = Succ(digits),
    Format('Expected %d digits but found %d digits',[succ(digits),Length(pi)]));
  var hash := THashMD5.GetHashString(pi);
  Writeln(Format('%d,%s', [digits, hash]));
end;

procedure GenBBBPPiHashTable;
begin
  for var i := 1 to 9 do HashPi(i * 100);
  for var i := 1 to 10 do HashPi(i * 1000);
end;

function CheckDigits(const Digits1, Digits2: string): UInt64;
begin
  Assert(Length(Digits1) = Length(Digits2),
    'Calls to Check Digits should include two strings with the same length.');
  
	for var idx := 1 to Length(Digits1) do
    if Digits1[idx] <> Digits2[idx] then 
		  Exit(idx);
  
	Result := 0;
end;

procedure CompareDigits(digits: UInt64);
begin
  Write('Digits    : ', digits);
  var BBP := BBPpi(digits).ToString.Insert(1,'.');
  var chud := Chudnovsky(digits).ToString;
  var firstError := CheckDigits(BBP,Chud);
  if firstError = 0 then
    Writeln(' = Match')
  else
  begin
    Writeln(Format(' = *** MISMATCH at %d ***',[firstError]));
    Writeln('BBP Pi    : ',BBP[FirstError]);
    Writeln('Chudnovsky: ', Chud[FirstError]);
  end;
end;

procedure GenValueTable;
begin
  for var i := 1 to 9 do CompareDigits(i * 100);
  for var i := 1 to 10 do CompareDigits(i * 1000);
end;

var firstChunk: Boolean = True;
procedure WritelnCallBack(Chunk: TDigits);
begin
  var digits: String;
  if firstChunk then
  begin
    digits := DigitsToString(Chunk).Insert(1,'.');
    firstChunk := False;
  end
  else
    digits := DigitsToString(Chunk);

  // slow down the output for demonstration purposes
  for var i := Low(digits) to High(digits) do
  begin
    Write(digits[i]);
    Sleep(100);
  end;
end;

const Places = 10000;
begin
  ReportMemoryLeaksOnShutdown := True;
  try

    //BBPpi(Places, WritelnCallBack);
    Writeln(BBPpi(80).ToString.Insert(1,'.'));
    Writeln(Chudnovsky(80).ToString);
    Writeln;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Write('Press [Enter]');
  Readln;
end.
