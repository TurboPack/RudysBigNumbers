{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
unit BigPiHashTestCaseProvider;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DUnitX.Types,
  DUnitX.InternalDataProvider,
  DUnitX.TestDataProvider,
  DUnitX.TestFramework;

type
  TPiHash = record
    Digits: UInt64;
    Hash: String;
  end;

  TPiHashProvider = Class(TTestDataProvider)
  private
    fHashes: TList<TPiHash>;
  public
    constructor Create; override;
    //Get the amount of cases we are creating
    function GetCaseCount(const methodName: string): Integer; override;
    //Get the name of the cases, depending on the Test-Function
    function GetCaseName(const methodName: string; const caseNumber: Integer): string; override;
    //Get the Params for calling the Test-Function;Be aware of the order !
    function GetCaseParams(const methodName: string; const caseNumber: Integer): TValuearray; override;
    //Cleanup the instance
    Destructor Destroy; override;
  end;

implementation

{ TPiHashProvider }

uses
  System.Classes, IOUtils, BigPiTestsCommon;

constructor TPiHashProvider.Create;
begin
  inherited;
  fHashes := TList<TPiHash>.Create;
  var hashes := TStringList.Create;
  try
    hashes.NameValueSeparator := ',';
    hashes.LoadFromFile(TPath.Combine(TestDataFolder,'pi-hashes.txt'));
    for var i := 0 to Pred(hashes.Count) do
    begin
      var hash: TPiHash;
      hash.Digits := hashes.Names[i].ToInt64;
      hash.Hash := hashes.ValueFromIndex[i];
      fHashes.Add(hash);
    end;
  finally
    hashes.Free;
  end;
end;

destructor TPiHashProvider.Destroy;
begin
  fHashes.Free;
  inherited;
end;

function TPiHashProvider.GetCaseCount(const methodName: string): Integer;
begin
  Result := fHashes.Count;
end;

function TPiHashProvider.GetCaseName(const methodName: string;
  const caseNumber: Integer): string;
begin
  Result := Format('Calculate %d digits', [fHashes[caseNumber].Digits]);
end;

function TPiHashProvider.GetCaseParams(const methodName: string;
  const caseNumber: Integer): TValuearray;
begin
  SetLength(Result,2);
	
  Result[0] := fHashes[caseNumber].Digits;
  Result[1] := fHashes[caseNumber].Hash;
end;

initialization
  TestDataProviderManager.RegisterProvider('PiHashProvider',TPiHashProvider);

end.
