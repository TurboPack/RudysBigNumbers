{==========================================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

 Calculates Bernoulli numbers
 https://en.wikipedia.org/wiki/Bernoulli_number

 Bernoulli function code from
 https://rosettacode.org/wiki/Bernoulli_numbers#Delphi
 Under the CC BY-SA 4.0 license

==========================================================}

program BigBernoulli;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Velthuis.BigIntegers,
  Velthuis.BigDecimals,
  // Experimental
  Velthuis.BigRationals;

function Bernoulli(n: UInt64): BigRational;
begin
  var a: TArray<BigRational>;
  SetLength(a, n + 1);
  for var m := 0 to High(a) do
  begin
    a[m] := BigRational.Create(1, m + 1);
    for var j := m downto 1 do
    begin
      a[j - 1] := (a[j - 1] - a[j]) * j;
    end;
  end;
  Result := a[0];
end;

function FormatBernoulli(n: UInt64; bb: BigRational): string;
begin
  Result := Format('B(%2d) = %45s/%s', [n, bb.Numerator.ToString, bb.Denominator.ToString]);
end;

function PrintBernoulli(n: UInt64; bb: BigRational): string;
begin
  Result :=FormatBernoulli(n,bb);
  Writeln(Result);
end;

begin
  try
    var check: TStringList := nil;
    var lines := TStringList.Create;
    try
      lines.Add(PrintBernoulli(0, Bernoulli(0)));
      lines.Add(PrintBernoulli(1, Bernoulli(1)));
      for var n := 1 to 30 do
        lines.Add(PrintBernoulli(n*2, Bernoulli(n*2)));

      var BernoulliCheck := '..\..\BernoulliCheck.txt';
      if TFile.Exists(BernoulliCheck) then
      begin
        check := TStringList.Create;
        check.LoadFromFile(BernoulliCheck);
        var checkCount := check.Count;
        var currentCount := lines.Count;
        Assert(checkCount = currentCount, Format('Expected %d results but received %d results.',[checkCount, currentCount]));
        for var n := 0 to pred(check.Count) do
          Assert(check[n] = lines[n],'Error on the line: ' + lines[n]);
      end;
    finally
      lines.Free;
      check.Free
    end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  readln;
end.
