{---------------------------------------------------------------------------}
{                                                                           }
{ File:       Velthuis.StrConsts.pas                                        }
{ Function:   Constants for error messages for BigNumbers.                  }
{ Language:   Delphi version XE3 or later                                   }
{ Author:     Rudy Velthuis                                                 }
{ Copyright:  (c) 2016 Rudy Velthuis                                        }
{                                                                           }
{ License:    BSD 2-Clause License - See LICENSE.md                         }
{                                                                           }
{ Latest:     https://github.com/TurboPack/RudysBigNumbers/                 }
{                                                                           }
{---------------------------------------------------------------------------}

unit Velthuis.StrConsts;

interface

resourcestring
  SErrorParsingFmt         = '''%s'' is not a valid %s value';
  SDivisionByZero          = 'Division by zero';
  SOverflow                = 'Resulting value too big to represent';
  SOverflowFmt             = '%s: Resulting value too big to represent';
  SInvalidOperation        = 'Invalid operation';
  SConversionFailedFmt     = '%s value too large for conversion to %s';
  SInvalidArgumentFloatFmt = '%s parameter may not be NaN or +/- Infinity';
  SInvalidArgumentBase     = 'Base parameter must be in the range 2..36';
  SInvalidArgumentFmt      = 'Invalid argument: %s';
  SOverflowInteger  = 'Value %g cannot be converted to an integer ratio';
  SNegativeRadicand        = '%s: Negative radicand not allowed';
  SNoInverse               = 'No modular inverse possible';
  SNegativeExponent        = 'Negative exponent %s not allowed';
  SUnderflow               = 'Resulting value too small to represent';
  SRounding                = 'Rounding necessary';
  SExponent                = 'Exponent to IntPower outside the allowed range';
  SZeroDenominator         = 'BigRational denominator cannot be zero';

implementation

end.

