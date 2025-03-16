{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

 Licensed under BSD 2-Clause License
 Copyright © 2025 by Jim McKeeth

================================================}
unit BigPi;

interface

uses
  SysUtils, Math, Velthuis.BigDecimals, Velthuis.BigIntegers;

/// <summary>
/// A type representing an array of digits (bytes).
/// </summary>
type TDigits = Array of Byte;
//const MaxUnit64 = 18_446_744_073_709_551_615;
const CallBackChunkSize = 64;
/// <summary>
/// A callback type for receiving chunks of computed digits.
/// </summary>
type TChunkCallBack = reference to Procedure(Chunk: TDigits);

/// <summary>
/// Computes the value of Pi to a specified number of decimal places using the Bailey-Borwein-Plouffe (BBP) formula. 
/// Which is an integer based spigot algorithm that allows for the extraction of individual digits of Pi.
/// </summary>
/// <param name="Places">The number of decimal places to compute.</param>
/// <param name="CallBack">An optional callback function that will be called with chunks of computed digits.</param>
/// <returns>A BigInteger representing the computed value of Pi.</returns>  
function BBPpi(Places: UInt64; CallBack: TChunkCallBack = nil): BigInteger;
/// <summary>
/// Computes the value of Pi to a specified number of decimal places using the Chudnovsky (floating point based) algorithm.
/// </summary>
/// <param name="Places">The number of decimal places to compute.</param>
/// <returns>A BigDecimal representing the computed value of Pi.</returns>
function Chudnovsky(Places: Integer): BigDecimal;
/// <summary>
/// Converts an array of digits (bytes) to a string representation.
/// </summary>
/// <param name="digits">An array of digits (bytes).</param>
function DigitsToString(digits: TDigits): String;

implementation

function BBPpi(Places: UInt64; CallBack: TChunkCallback = nil): BigInteger;
// Bailey-Borwein-Plouffe algorithm to calculate Pi
// https://en.wikipedia.org/wiki/Bailey%E2%80%93Borwein%E2%80%93Plouffe_formula
begin
  Result := 0;

  var idx: NativeInt := 0;
  var q := BigInteger.One;
  var r := BigInteger.Zero;
  var t := BigInteger.One;
  var k := BigInteger.One;
  var n := BigInteger.Create(3);
  var l := BigInteger.Create(3);

  var buffer: TDigits;
  SetLength(buffer, CallbackChunkSize);
  var bufferIdx: Integer := 0;

  while true do
  begin
    if 4*q+r-t < n*t then
    begin
      Result := Result * 10 + n.AsInt64; // It is just a byte
      //result[idx] :=
      inc(idx);

      if Assigned(Callback) then
      begin
        buffer[bufferIdx] := n.AsInt64;
        inc(bufferIdx);
        // Check if buffer is full, then call callback and reset bufferIdx
        if bufferIdx = CallbackChunkSize then
        begin
          Callback(buffer); // Call the callback with the buffer
          bufferIdx := 0; // Reset buffer index
        end;
      end;

      if idx >= places then break;
      var newR := 10 * (r - n * t);
      n := (10 * (3 * q + r)) div t - 10 * n;
      q := q * 10;
      r := newR;
    end
    else
    begin
      var newR := (2 * q + r) * l;
      var newN := (q * (7 * k)+2+(r * l)) div (t * l);
      q := q * k;
      t := t * l;
      l := l + 2;
      k := k + 1;
      n := newN;
      r := newR;
    end;
  end;

  // Handle remaining buffer
  if (bufferIdx > 0) and Assigned(CallBack) then
  begin
    SetLength(buffer, bufferIdx); // Resize buffer to actual used size before callback
    CallBack(buffer);
  end;
end;

function Chudnovsky(Places: Integer):BigDecimal;
// Chudnovsky algorithm to caluclate Pi
// https://en.wikipedia.org/wiki/Chudnovsky_algorithm
begin
  // Use +6 internally for calculations
  var internalPrecision := MaxInt;
  if Places <= MaxInt - 6 then
    internalPrecision := Places + 6;

  var lastSum: BigDecimal;
  var t := BigDecimal.Create(3);
  var sum := BigDecimal.Create(3);
  sum.DefaultPrecision := internalPrecision;
  sum.DefaultRoundingMode := rmFloor;
  var n := BigInteger.One;
  var d := BigInteger.Zero;
  var na: UInt64 := 0;
  var da: UInt64 := 24;
  while sum <> lastSum do
  begin
    lastSum := sum;
    n := n + na;
    na := na + 8;
    d := d + da;
    da := da + 32;
    t := ((t * n)/d);
    sum := (sum + t).RoundToPrecision(internalPrecision);
  end;
  Result := sum.RoundToPrecision(Places);
end;

function DigitsToString(digits: TDigits): String;
begin
  SetLength(Result, Length(digits));
  for var idx := Low(digits) to High(digits) do
    Result[idx + 1] := Char(digits[idx] + Ord('0'));
end;

end.
