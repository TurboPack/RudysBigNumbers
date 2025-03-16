{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
unit BBPpiTests;

interface

uses
  System.SysUtils,
  BigPiHashTestCaseProvider,
  DUnitX.TestFramework;

type
  [TestFixture]
  BBPpiTest = class
  public
    [Test(True)]
    [TestCaseProvider(TPiHashProvider)]
    procedure HashCheck(const Digits : Integer;const Hash : String);
    [Test]
    procedure Check1000Digits();
    [Test]
    procedure CompareCallbackToResult;
  end;

implementation

uses
  IOUtils, BigPi,Hash, BigPiTestsCommon;

{ BBPpiTest }

procedure BBPpiTest.Check1000Digits;
begin
  var calcPi := BBPpi(1000).ToString.Insert(1,'.');
  var readPi := TFile.ReadAllText(TPath.Combine(TestDataFolder,'pi-100k.txt'));
  for var idx := 1 to Length(calcPi) do
     Assert.AreEqual(readPi[idx], calcPi[idx], Format('Incorrect digit # %d with BBPpi: %s',[idx, calcPi]));
end;

procedure BBPpiTest.CompareCallbackToResult;
begin
  var CallBackString := '';
  var CallBackStringBuilder: TChunkCallBack := procedure(Chunk: TDigits)
  begin
    CallBackString := CallBackString + DigitsToString(Chunk);
  end;

  var calcPi := BBPpi(100, CallBackStringBuilder).ToString;
  Assert.AreEqual(calcPi, CallBackString);
end;

procedure BBPpiTest.HashCheck(const Digits: Integer; const Hash: String);
begin
  if digits > 10000 then 
	  Exit;

  var pi := BBPpi(Digits).ToString.Insert(1,'.');
  // one more digit for the decimal point
  var expectedLength := Succ(Digits);
  var actualLength := Length(pi);
	
  Assert.AreEqual(expectedLength, actualLength,
    Format('For %d digits, was expecting one more for the decimal, '+
     'but received %d.',[digits, actualLength]));
		 
  var calcHash := THashMD5.GetHashString(pi);
	
  Assert.AreEqual(hash, calcHash,
    Format('Incorrect hash for %d digits with BBPpi. ',[digits]))
end;

end.
