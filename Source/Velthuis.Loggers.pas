{---------------------------------------------------------------------------}
{                                                                           }
{ File:       Velthuis.Loggers.pas                                          }
{ Function:   Very simple logger type                                       }
{ Language:   Delphi version XE3 or later                                   }
{ Author:     Rudy Velthuis                                                 }
{ Copyright:  (c) 2016 Rudy Velthuis                                        }
{                                                                           }
{ License:    BSD 2-Clause License - See LICENSE.md                         }
{                                                                           }
{ Latest:     https://github.com/TurboPack/RudysBigNumbers/                 }
{---------------------------------------------------------------------------}

unit Velthuis.Loggers;

interface

uses
  System.Classes;

type
  ILogger = interface
    ['{B6821CA6-64F8-48B0-89D0-A9A3E6304D82}']
    procedure Log(const Msg: string); overload;
    procedure Log(const Format: string; Args: array of const); overload;
  end;

  TLogger = class(TInterfacedObject, ILogger)
  private
    FStream: TStream;
    FWriter: TStreamWriter;
  public
    constructor Create(S: TStream); overload;
    constructor Create(const LogFileName: string); overload;
    destructor Destroy; override;
    procedure Log(const Msg: string); overload;
    procedure Log(const Format: string; Args: array of const); overload;
  end;

var
  Logger: TLogger = nil;

implementation

uses
  System.SysUtils;

{ TLogger }

constructor TLogger.Create(S: TStream);
begin
  FStream := S;
  FWriter := TStreamWriter.Create(S);
end;

constructor TLogger.Create(const LogFileName: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(LogFileName, fmCreate);
  Create(F);
end;

destructor TLogger.Destroy;
begin
  FWriter.Free;
  FStream.Free;

  //TODO: inherited destructor missing
end;

procedure TLogger.Log(const Msg: string);
begin
  FWriter.WriteLine(Msg);
end;

procedure TLogger.Log(const Format: string; Args: array of const);
begin
  FWriter.WriteLine(System.SysUtils.Format(Format, Args));
end;

end.
