unit U_Random_2;

interface
uses Velthuis.RandomNumbers, Velthuis.BigIntegers;

type

  TRandomBase2 = class(TRandomBase, IRandom)
  protected
    function  Next(Bits: Integer): UInt32; virtual; abstract;
  public
    procedure NextBytes(var Bytes: array of Byte);
  end;


  TRandom2 = class(TRandomBase2, IRandom)
  private
    FSeed: Int64;
  protected
    function  Next(Bits: Integer): UInt32; override;
  public
    constructor Create(Seed: Int64 = 0);
  end;


  TDelphiRandom2 = class(TRandomBase2, IRandom)
  protected
    function Next(Bits: Integer): UInt32; override;
  public
    constructor Create(Seed: Int64); overload;
  end;


  BigInteger2 = record
    BigInt : BigInteger;
    constructor Create(NumBits: Integer; const Random: IRandom);
  end;


implementation
uses
  System.SysUtils, Velthuis.Numerics;

{ BigInteger2 }

constructor BigInteger2.Create(NumBits: Integer; const Random: IRandom);
var
  Bytes: TArray<Byte>;
  Bits: Byte;
begin
  SetLength(Bytes, (NumBits + 7) shr 3 + 1);
  Random.NextBytes(Bytes);

  // One byte too many was allocated, to get a top byte of 0, i.e. always positive.
  Bytes[High(Bytes)] := 0;

  // Set bits above required bit length to 0.
  Bits := NumBits and $07;
  if Bits = 0 then
    Bits := 8;
  Bytes[High(Bytes) - 1] := Bytes[High(Bytes) - 1] and ($FF shr (8 - Bits));
  BigInt := BigInteger.Create(Bytes);
//Compact;
//  Assert(BitLength <= Numbits, Format('BitLength (%d) >= NumBits (%d): %s', [BitLength, NumBits, Self.ToString(2)]));
end;


{ TDelphiRandom2 }

constructor TDelphiRandom2.Create(Seed: Int64);
begin
  System.RandSeed := Integer(Seed);
end;

function TDelphiRandom2.Next(Bits: Integer): UInt32;
begin
  var a := UInt32(System.RandSeed);
  Result := a shr (32 - Bits);

  //Result := UInt32(System.RandSeed) shr (32 - Bits);
  System.Random;
end;


{ TRandom2 }

const
  CMultiplier = Int64(6364136223846793005);
  CIncrement  = Int64(1442695040888963407);
  CSeedSize   = 64 div 8;

constructor TRandom2.Create(Seed: Int64);
begin
  FSeed := Seed;
end;

function TRandom2.Next(Bits: Integer): UInt32;
begin
{$IFOPT R+}
{$DEFINE HasRangeChecks}
{$ENDIF}
{$IFOPT Q+}
{$DEFINE HasOverflowChecks}
{$ENDIF}

{$RANGECHECKS OFF}
{$OVERFLOWCHECKS OFF}

  FSeed := (FSeed * CMultiplier + CIncrement);
  Result := UInt32(FSeed shr (64 - Bits)); // Use the highest bits; Lower bits have lower period.

{$IFDEF HasRangeChecks}
{$RANGECHECKS ON}
{$ENDIF}
{$IFDEF HasOverflowChecks}
{$OVERFLOWCHECKS ON}
{$ENDIF}
end;


{ TRandomBase2 }

procedure TRandomBase2.NextBytes(var Bytes: array of Byte);
var
  Head, Tail: Integer;
  N,  I: Integer;
//Rnd :  Int32;
  Rnd : UInt32;
begin
  Head := Length(Bytes) div SizeOf(Int32);
  Tail := Length(Bytes) mod SizeOf(Int32);
  N := 0;

  for I := 1 to Head do
  begin
    Rnd := Next(32);
    Bytes[N] := Byte(Rnd);
    Bytes[N + 1] := Byte(Rnd shr 8);
    Bytes[N + 2] := Byte(Rnd shr 16);
    Bytes[N + 3] := Byte(Rnd shr 24);
    Inc(N, 4);
  end;

  Rnd := Next(32);

  for I := 1 to Tail do
  begin
    Bytes[N] := Byte(Rnd);
    Rnd := Rnd shr 8;
    Inc(N);
  end;
end;



end.
