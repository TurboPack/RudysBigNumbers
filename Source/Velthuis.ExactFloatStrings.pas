{---------------------------------------------------------------------------}
{                                                                           }
{ File:       Velthuis.ExactFloatStrings.pas                                }
{ Function:   Routines to generate strings that contain the exact values    }
{             of Singles, Doubles or Extendeds.                             }
{ Language:   Delphi version XE3 or later                                   }
{ Author:     Rudy Velthuis                                                 }
{ Copyright:  (c) 2015, Rudy Velthuis                                       }
{ Notes:      Requires the Velthuis.BigIntegers unit                        }
{             Requires record helpers for intrinsic types                   }
{                                                                           }
{ License:    BSD 2-Clause License - See LICENSE.md                         }
{                                                                           }
{ Latest:     https://github.com/TurboPack/RudysBigNumbers/                 }
{---------------------------------------------------------------------------}

unit Velthuis.ExactFloatStrings;

interface

{$IF CompilerVersion >= 24.0}
  {$LEGACYIFEND ON}
{$IFEND}

{$IF SizeOf(Extended) > SizeOf(Double)}
  {$DEFINE HASEXTENDED}
{$IFEND}

uses
  System.SysUtils;

{$IFDEF HASEXTENDED}
function ExactString(const F: Extended): string; overload;
{$ENDIF}
function ExactString(const F: Double): string; overload;
function ExactString(const F: Single): string; overload;

implementation

uses
  Velthuis.BigIntegers,
  Velthuis.FloatUtils,
  System.Math;

// BigIntegers are required to either multiply the mantissa by powers of 5 or by powers of 2 and to
// generate a string from the resulting BigInteger.
// Record helpers for intrinsics are used to get info out of the floating point types, e.g. IsNan, Mantissa, etc.

{$IFDEF HASEXTENDED}
function ExactString(const F: Extended): string;
var
  Mantissa: UInt64;
  Exponent: Integer;
  Sign: Boolean;
  BigInt: BigInteger;
  DecimalPoint: Integer;
  Len: Integer;
begin
  if System.Math.IsNan(F) then
    Exit('NaN')
  else if IsNegativeInfinity(F) then
    Exit('NegInfinity')
  else if IsPositiveInfinity(F) then
    Exit('Infinity');

  Mantissa := GetSignificand(F);
  if Mantissa = 0 then
    Exit('0');

  Exponent := GetExponent(F) - 63;
  Sign := System.Math.Sign(F) < 0;

  while not Odd(Mantissa) do
  begin
    Mantissa := Mantissa shr 1;
    Inc(Exponent);
  end;

  BigInt := Mantissa;

  DecimalPoint := 0;
  if Exponent < 0 then
  begin
    // BigInt must repeatedly be divided by 2.
    // This isn't done directly: On each iteration, BigInt is multiplied by 5 and then the decimal point is moved one
    // position to the left, which is equivalent to dividing by 10. This is done in one fell swoop, using Pow().
    BigInt := BigInt * BigInteger.Pow(5, -Exponent);
    DecimalPoint := -Exponent;
  end
  else
    // BigInt must repeatedly be multipied by 2. This is done in one go, by shifting the BigInteger left by Exponent.
    BigInt := BigInt shl Exponent;

  Result := BigInt.ToString;
  Len := Length(Result);

  // Now we insert zeroes and the decimal point into the plain big integer value to get a nice output.

  if DecimalPoint = 0 then
    Result := Result                                             // e.g. 123.0
  else if DecimalPoint >= Len then
    Result := '0.' + StringOfChar('0', DecimalPoint - Len) + Result       // e.g. 0.00123
  else
    Result := Copy(Result, 1, Len - DecimalPoint) + '.' + Copy(Result, Len - DecimalPoint + 1, Len); // e.g. 12.3

  if Sign then
    Result := '-' + Result;
end;
{$ENDIF}

function ExactString(const F: Double): string;
var
  Mantissa: UInt64;
  Exponent: Integer;
  Sign: Boolean;
  BigInt: BigInteger;
  DecimalPoint: Integer;
  Len: Integer;
begin
  if System.Math.IsNan(F) then
    Exit('NaN')
  else if IsNegativeInfinity(F) then
    Exit('NegInfinity')
  else if IsPositiveInfinity(F) then
    Exit('Infinity');

  Mantissa := GetSignificand(F);
  if Mantissa = 0 then
    Exit('0');

  Exponent := GetExponent(F) - 52;
  Sign := System.Math.Sign(F) < 0;
  if IsDenormal(F) then
    Mantissa := Mantissa and (UInt64(-1) shr 12);

  while not Odd(Mantissa) do
  begin
    Mantissa := Mantissa shr 1;
    Inc(Exponent);
  end;

  BigInt := Mantissa;

  DecimalPoint := 0;
  if Exponent < 0 then
  begin
    // BigInt must be repeatedly divided by 2.
    // This isn't done directly: On each iteration, BigInt is multiplied by 5 and then the decimal point is moved one
    // position to the left, which is equivalent to dividing by 10. This is done in one fell swoop, using Pow().
    BigInt := BigInt * BigInteger.Pow(5, -Exponent);
    DecimalPoint := -Exponent;
  end
  else
    // BigInt must repeatedly be multipied by 2. This is done in one go, by shifting the BigInteger left.
    BigInt := BigInt shl Exponent;

  Result := BigInt.ToString;
  Len := Length(Result);

  // Now we insert zeroes and the decimal point into the plain big integer value to get a nice output.

  if DecimalPoint = 0 then
    Result := Result                                             // e.g. 123.0
  else if DecimalPoint >= Len then
    Result := '0.' + StringOfChar('0', DecimalPoint - Len) + Result     // e.g. 0.00123
  else
    Result := Copy(Result, 1, Len - DecimalPoint) + '.' + Copy(Result, Len - DecimalPoint + 1, Len); // e.g. 12.3

  if Sign then
    Result := '-' + Result;
end;

function ExactString(const F: Single): string;
var
  Mantissa: UInt32;
  Exponent: Integer;
  Sign: Boolean;
  BigInt: BigInteger;
  DecimalPoint: Integer;
  Len: Integer;
begin
  if System.Math.IsNan(F) then
    Exit('NaN')
  else if IsNegativeInfinity(F) then
    Exit('NegInfinity')
  else if IsPositiveInfinity(F) then
    Exit('Infinity');

  Mantissa := GetSignificand(F);
  if Mantissa = 0 then
    Exit('0');

  Exponent := GetExponent(F) - 23;
  Sign := System.Math.Sign(F) < 0;
  if IsDenormal(F) then
    Mantissa := Mantissa and $7FFFFF;

  while not Odd(Mantissa) do
  begin
    Mantissa := Mantissa shr 1;
    Inc(Exponent);
  end;

  BigInt := Mantissa;

  DecimalPoint := 0;
  if Exponent < 0 then
  begin
    // BigInt must be repeatedly divided by 2.
    // This isn't done directly: On each iteration, BigInt is multiplied by 5 and then the decimal point is moved one
    // position to the left, which is equivalent to dividing by 10. This is done in one fell swoop, using Pow().
    BigInt := BigInt * BigInteger.Pow(5, -Exponent);
    DecimalPoint := -Exponent;
  end
  else
    // BigInt must repeatedly be multipied by 2. This is done in one go, by shifting the BigInteger left.
    BigInt := BigInt shl Exponent;

  Result := BigInt.ToString;
  Len := Length(Result);

  // Now we insert zeroes and the decimal point into the plain big integer value to get a nice output.

  if DecimalPoint = 0 then
    Result := Result                                             // e.g. 123.0
  else if DecimalPoint >= Len then
    Result := '0.' + StringOfChar('0', DecimalPoint - Len) + Result       // e.g. 0.00123
  else
    Result := Copy(Result, 1, Len - DecimalPoint) + '.' + Copy(Result, Len - DecimalPoint + 1, Len); // e.g. 12.3

  if Sign then
    Result := '-' + Result;

end;

end.
