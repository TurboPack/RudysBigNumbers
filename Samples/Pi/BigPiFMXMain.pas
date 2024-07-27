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
  FMX.Objects, System.Skia, FMX.Skia;

type
  TBigPiGui = class(TForm)
    Label1: TLabel;
    piMemo: TMemo;
    delayTrackBar: TTrackBar;
    ScaledLayout1: TScaledLayout;
    delayLabel: TLabel;
    labelCount: TLabel;
    Label2: TLabel;
    Layout1: TLayout;
    Layout2: TLayout;
    captionLabel: TLabel;
    StyleBook1: TStyleBook;
    labelDigit: TLabel;
    procedure FormShow(Sender: TObject);
    procedure UpdateUI(digit: char; count: Integer);
    function GetDelay: Double;
    procedure delayTrackBarChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    var background: TThread;
    var lastCount: UInt64;
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

procedure TBigPiGui.FormCreate(Sender: TObject);
begin
  lastCount := 0;
end;

procedure TBigPiGui.FormShow(Sender: TObject);
begin
  captionLabel.Text := Caption;
  captionLabel.Visible := True;
  background := TBackgroundPi.Create(True);
  TBackgroundPi(background).OnUIUpdate := UpdateUI;
  TBackgroundPi(background).OnGetDelay := GetDelay;
  background.FreeOnTerminate := False;
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
  if not assigned(Application.MainForm) then exit;

  Assert(count = lastcount+1,
    Format('Digits out of order. Exepcting digit # %d but received # %d.',[lastcount+1, count]));
  lastCount := count;

  labelCount.Text := Format('%.0n', [count + 0.0]);
  labelDigit.Text := digit;
  piMemo.GoToTextEnd;
  piMemo.InsertAfter(piMemo.CaretPosition, digit, [TInsertOption.MoveCaret]);
  piMemo.Repaint;
end;

end.
