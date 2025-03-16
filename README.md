# Rudy's Big Numbers 

<a href="https://github.com/TurboPack/RudysBigNumbers/"><img src="https://user-images.githubusercontent.com/821930/230476405-ebf33117-139a-4895-8d00-70e30186e3fa.jpg" align="Right" alt="Logo for Rudy's Big Numbers Library"></a>[Rudy Velthuis](http://rvelthuis.de) is the orignal author of this library. He unfortunately passed away a while back. In an effort to keep this valuable library alive we've done the following:

* Pulled changes from [all the other branches](https://github.com/TurboPack/RudysBigNumbers/network) into this repository
* Created [Wiki articles](https://github.com/TurboPack/RudysBigNumbers/wiki) based on his original documentation (with some updates)
* Opened up for [issues](https://github.com/TurboPack/RudysBigNumbers/issues) 
* Fixed some other issues and updated for Delphi 11.3

***Pull requests welcome.*** If you want to help maintain this library, please let us know.

----

## BigInteger, BigDecimal and BigRational for Delphi and C++Builder

These are implementations of the multi-precision `BigInteger`, `BigDecimal` and `BigRational` types, built from scratch by Rudy Velthuis and now maintained by [TurboPack](https://github.com/TurboPack).

![RudysBigNumbers - Wide Banner](https://github.com/user-attachments/assets/b7655ef4-93b4-4b54-aedc-13b994db0b4f)

## BigInteger

<img src="https://github.com/user-attachments/assets/07d88eae-9c86-4d54-aa6b-bbd4e129dd72" alt="Rudy Velthuis' BigIntegers Logo" width="250" align="right">

`BigInteger` is a multi-precision integer. Its size is only limited by available memory.

`BigInteger` is built for ease of use, speed and reliability. It is written in plain Object Pascal and x86-32/x86-64 assembler, but every assembler function has a so called "pure Pascal" equivalent as well. It is modelled after the `BigInteger` type in .NET, but is far more optimized than that and provides an interface that is more in line with Delphi. It uses higher level algorithms like *Burnikel-Ziegler*, *Karatsuba*, *Toom-Cook*, etc. to make things fast even for very large integers. It offers overloaded operators and all the usual functions. More information can be found on the [BigIntegers unit wiki page](https://github.com/TurboPack/RudysBigNumbers/wiki/BigIntegers).

Simple usage:

```Delphi
var
  A, B, C, D: BigInteger;
begin
  A := 3141592653589793238462643383279;
  B := 1414213562373095 shl 10;
  C := 2718281828459045235360287471352;
  D := A + B * C;
  Writeln(D.ToString);
```

## BigDecimal

<img src="https://github.com/user-attachments/assets/0efa7aff-50c1-4c5b-a7c0-3f45907cbfe0" alt="Rudy Velthuis' BigDecimals Logo" width="250" align="right">

`BigDecimal` is a multi-precision decimal floating point type. It can have an almost unlimited precision.

`BigDecimal` is equally built for ease of use and reliability. It builds on top of BigInteger: the internal representation is a BigInteger for the significant digits, and a scale to indicate the decimals. It also offers overloaded operators and all the usual functions. This is modelled after the `BigDecimal` type in Java, but the interface is more in line with Delphi. More information about this type can be found on the [BigDecimals unit wiki page](https://github.com/TurboPack/RudysBigNumbers/wiki/BigDecimals).

Simple usage:

```Delphi
var
  A, B, C: BigDecimal;
begin
  A := '1.3456e-17';        // exact
  B := 1234.197;            // floating point approximation
  C := A + B * '3.0';
  Writeln(string(C));
```

## BigRational <img src="https://github.com/user-attachments/assets/e320934f-88c6-4f2b-a6fb-2528cf436ab5" alt="Rudy Velthuis' BigRationals Logo" width="175" align="right">

A type that holds a number as fraction (ratio) of two `BigIntegers`, a numerator and a denominator, i.e. `1/7` or `100/3`. 
This type is very good at simple arithmetic (`+`, `-`, `*`, `/`), since it doesn't lose precision or need any rounding. Still a work in progress...

## C++Builder

The newest version of BigIntegers has additional overloaded operators and additional constructors that are compatible
with C++Builder. So now you simply include:

```C++
    #include "Velthuis.BigIntegers.hpp"
```
and then you can do things like:
```C++
    BigInteger a = 17;
    BigInteger b = "123";
    BigInteger c = a + b;
```
## Directory structure

```text
RudysBigNumbers
   Source                      --- Sources for units and for bases.inc
   Tests
      BigDecimals /...         --- Sources for DUnit tests for BigDecimals
      BigIntegers /...         --- Sources for DUnit tests for BigIntegers
      BigRationals /...        --- Sources for DUnit tests for BigRationals
   Visualizers                 --- Sources for IDE debug visualizer DLL and packages for BigInteger and BigDecimal  
   Samples                     --- A Few samples of Big Math including Pi and Euler's number
```

The [data generators](https://github.com/TurboPack/RudysBigNumbers-DataGenerators/) are now in their own repository.
