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
    piMemo: TMemo;
    delayTrackBar: TTrackBar;
    labelDigit: TLabel;
    ScaledLayout1: TScaledLayout;
    delayLabel: TLabel;
    labelCount: TLabel;
    Label2: TLabel;
    Layout1: TLayout;
    Layout2: TLayout;
    captionLabel: TLabel;
    StyleBook1: TStyleBook;
    procedure FormShow(Sender: TObject);
    procedure UpdateUI(digit: char; count: Integer);
    function GetDelay: Double;
    procedure delayTrackBarChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    var background: TThread;
  public
    { Public declarations }
  end;

var
  BigPiGui: TBigPiGui;

implementation

{$R *.fmx}

uses
  BackgroundPi, FMX.Text;

procedure TBigPiGui.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  background.Terminate;
end;

procedure TBigPiGui.FormShow(Sender: TObject);
begin
  captionLabel.Text := Caption;
  captionLabel.Visible := True;
  background := TBackgroundPi.Create(True);
  TBackgroundPi(background).OnUIUpdate := UpdateUI;
  TBackgroundPi(background).OnGetDelay := GetDelay;
  background.FreeOnTerminate := True;
  background.Start;
end;

function TBigPiGui.GetDelay: Double;
begin
  Result := 1;
  if Application.Terminated then Exit;
  Result := delayTrackBar.Value;
end;

procedure TBigPiGui.delayTrackBarChange(Sender: TObject);
begin
  if delayTrackBar.Value < delayTrackBar.Max/2 then
    delayLabel.Align := TAlignLayout.Right
  else
    delayLabel.Align := TAlignLayout.Left;
end;

procedure TBigPiGui.UpdateUI(digit: char; count: Integer);
begin
  if Application.Terminated then exit;

  labelCount.Text := Format('%.0n', [count + 0.0]);
  labelDigit.Text := digit;
  piMemo.GoToTextEnd;
  piMemo.InsertAfter(piMemo.CaretPosition, digit, [TInsertOption.MoveCaret]);
end;

end.
