{===============================================

 Included with Rudy's Big Numbers Library
 https://github.com/TurboPack/RudysBigNumbers/

================================================}
unit BigPiFMXMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.EditBox, FMX.SpinBox, FMX.Layouts,
  FMX.Objects;

type
  TBigPiGui = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    bbpMemo: TMemo;
    chudnovskyMemo: TMemo;
    Layout1: TLayout;
    Label3: TLabel;
    digitsEdit: TSpinBox;
    Button1: TButton;
    Z: TLayout;
    Path1: TPath;
    ScaledLayout1: TScaledLayout;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BigPiGui: TBigPiGui;

implementation

{$R *.fmx}

uses BigPi;

procedure TBigPiGui.Button1Click(Sender: TObject);
begin
  bbpMemo.Text := DigitsToString(BBPpi(Trunc(digitsEdit.Value)));
  chudnovskyMemo.Text := Chudnovsky(Trunc(digitsEdit.Value)).ToString;
end;

end.
