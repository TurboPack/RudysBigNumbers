program BigIntegerDevelopmentTests2;
{

  Delphi DUnit Test Project

  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

// FastMM4 can slow down testing a lot.
{$DEFINE USEFASTMM4}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

{$WARN UNIT_EXPERIMENTAL OFF}
{$WARN CONSTRUCTING_ABSTRACT OFF}

uses
  {$IFDEF USEFASTMM4}
  {$ENDIF }
  DUnitTestRunner,
  Velthuis.RandomNumbers in '..\..\Source\Velthuis.RandomNumbers.pas',
  Velthuis.BigIntegers in '..\..\Source\Velthuis.BigIntegers.pas',
  TestVelthuisBigIntRandom in 'TestVelthuisBigIntRandom.pas',
  U_Random_2 in 'U_Random_2.pas';

{$R *.RES}

begin
{$IFDEF USEFASTMM4}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  DoDebug := False;
  DUnitTestRunner.RunRegisteredTests;
end.

