{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
unit BigPiChudnovskyTests;

interface

uses
  System.SysUtils,
  BigPiHashTestCaseProvider,
  DUnitX.TestFramework;

type
  [TestFixture]
  ChudnovskyPiTest = class
  public
    [Test(True)]
    [TestCaseProvider(TPiHashProvider)]
    procedure HashCheck(const Digits : Integer;const Hash : String);
    [Test]
    procedure Check1000Digits();
  end;

implementation

uses IOUtils, BigPi, Hash, BigPiTestsCommon;

{ ChudnovskyPiTest }

procedure ChudnovskyPiTest.Check1000Digits;
begin
  var calcPi := Chudnovsky(1000).ToString;
  var readPi := TFile.ReadAllText(TPath.Combine(TestDataFolder,'pi-100k.txt'));
  for var idx := 1 to Length(calcPi) do
     Assert.AreEqual(readPi[idx], calcPi[idx], Format('Incorrect digit # %d with Chudnovsky: %s.',[idx, calcPi]));
end;

procedure ChudnovskyPiTest.HashCheck(const Digits: Integer;  const Hash: String);
begin
  if digits > 5000 then 
	  Exit;

  var pi := Chudnovsky(Digits).ToString;
	
  Assert.AreEqual(Succ(Digits), Length(pi));
  
	var calcHash := THashMD5.GetHashString(pi);
  
	Assert.AreEqual(hash, calcHash, Format('Incorrect hash for %d digits with Chudnovsky. ',[digits]))
end;

initialization
  TDUnitX.RegisterTestFixture(ChudnovskyPiTest);

end.
