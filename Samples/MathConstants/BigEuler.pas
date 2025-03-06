{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
unit BigEuler;

interface

uses
  System.SysUtils,
  System.Math,
  Velthuis.BigIntegers,
  Velthuis.BigDecimals;

function Euler(const Digits: Integer): BigDecimal;

implementation

function Euler(const Digits: Integer): BigDecimal;
begin
  Result := 1;
  var InternalPrecision := MaxInt;
  if Digits <= MaxInt - 2 then
    InternalPrecision := Digits + 2;

  Result.DefaultPrecision :=InternalPrecision;
  var lastFactorial := BigInteger.One;
  var lastResult := BigDecimal.Zero;
  var iteration: UInt64 := 1;
  while true do
  begin
    lastResult := Result;
    lastFactorial := lastFactorial * iteration;
    Result := (Result + BigDecimal.One / lastFactorial).RoundToPrecision(InternalPrecision);
    
		if lastResult = Result then 
			Break;
    
		Inc(Iteration);
  end;
  //Writeln(Format('%d digits took %d iterations',[Digits, iteration]));
  Result.DefaultRoundingMode := rmFloor;
  Result := Result.RoundToPrecision(Digits);
end;

end.
