{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
program BigMathConstants;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Math,
  System.IOUtils,
  Velthuis.BigIntegers,
  Velthuis.BigDecimals,
  BigEuler in 'BigEuler.pas';

function CheckDigits(const Digits1, Digits2: string): UInt64;
begin
  for var idx := 1 to Length(Digits1) do
    if Digits1[idx] <> Digits2[idx] then 
			Exit(idx);
			
  Result := 0;
end;

const Precision = 200;

begin
  try
    Writeln(Format('Precision: %d',[Precision]));
    Writeln('√2, Square root of 2, Pythagoras constant:');
    Writeln(BigDecimal.Sqrt(2,Precision).ToString);
    Writeln('√3, Square root of 3, Theodorus'' constant:');
    Writeln(BigDecimal.Sqrt(3,Precision).ToString);
    Writeln('√5, Square root of 5:');
    var sqrt5 := BigDecimal.Sqrt(5,Precision);
    Writeln(sqrt5.ToString);
    Writeln('φ, Phi, Golden ratio, (1 + √5)/2:');
    var phi := BigDecimal.Divide((1 + Sqrt5), 2, Precision);
    Writeln(phi.ToString);
    Writeln('Common logarithm of 2:');
    Writeln(BigInteger.Log(2,10).ToString);
    Writeln('Natural logarithm of 2:');
    Writeln(BigInteger.Ln(2).ToString);
    Writeln('------');
    var EulerDigits := 500;
    Writeln(Format('Euler''s Number to %d digits',[EulerDigits]));
    var CalcEuler := Euler(EulerDigits);
    Writeln(CalcEuler.ToString);
    var CheckEuler := TFile.ReadAllText('..\..\..\Samples\MathConstants\Euler10k.txt');
    var firstError := CheckDigits(calcEuler.ToString, CheckEuler);
    if FirstError <> 0 then
      Writeln(Format('First Euler Error at digit # %d. Expected %s and got %s',
        [FirstError, CheckEuler[FirstError], calcEuler.ToString[FirstError]]));
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('Press [Enter] to close.');
  Readln;
end.
