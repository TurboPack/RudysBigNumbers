unit TestBigIntegersIssues;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Math,
  Velthuis.BigIntegers,
  Velthuis.RandomNumbers,
  System.IOUtils;

{$IF BigInteger.Immutable}
{$DEFINE IMMUTABLE}
{$IFEND}

{$IF RTLVersion >= 29.0}
{$DEFINE HASINVARIANT}
{$IFEND}


type
  // Test methods for BigInteger records.
  TTestBigIntegerIssues = class(TTestCase)
  public
    procedure Error(const Msg: string);
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // https://github.com/rvelthuis/DelphiBigNumbers/issues/17
    procedure TestParseHugeBase12;
  end;

implementation
{$IFDEF MSWINDOWS}
uses
  Winapi.Windows;
{$ENDIF}

procedure TTestBigIntegerIssues.Error(const Msg: string);
begin
{$IFDEF MSWINDOWS}
  OutputDebugString(PChar(Msg));
{$ELSE}
  {$IFDEF CONSOLE}
    Writeln(ErrOutput, Msg);
  {$ENDIF}
{$ENDIF}
end;

procedure TTestBigIntegerIssues.SetUp;
begin
{$IF HASINVARIANT}
  Status(Format('Compiler version: %0.1f', [System.CompilerVersion], TFormatSettings.Invariant));
{$ELSE}
  Status(Format('Compiler version: %0.1f', [System.CompilerVersion]));
{$ENDIF}
{$IFDEF WIN64}
  Status('Win64');
{$ENDIF}
{$IFDEF WIN32}
  Status('Win32');
{$ENDIF}
  if Velthuis.BigIntegers.PurePascal then
    Status('PUREPASCAL')
  else
  begin
    if BigInteger.StallAvoided then
      Status('Asssembler: partial flag stall code used')
    else
      Status('Assembler: plain code');
  end;
{$IFDEF TESTPARTIALFLAGCODE}
  BigInteger.AvoidPartialFlagsStall(True);
{$ENDIF}
end;

procedure TTestBigIntegerIssues.TearDown;
begin
end;

procedure TTestBigIntegerIssues.TestParseHugeBase12;
var
  N,M : BigInteger;
  NS, MS: string;
  R : IRandom;
  NumBits: Integer;
begin
  R := TDelphiRandom.Create(-332888001);
  NumBits := Random(100)*1000;
  N := BigInteger.Create(NumBits, R);
  BigInteger.Base := 12;
  NS := N.ToString();
  BigInteger.TryParse(NS, M);
  MS := M.ToString();
  CheckEquals(NS, MS, 'Parsed value differs from the original!');
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TTestBigIntegerIssues.Suite);
end.
