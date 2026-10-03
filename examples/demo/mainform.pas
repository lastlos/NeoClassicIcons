unit mainform;

{ NeoClassicIcons demo - SPDX-License-Identifier: MIT }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Menus, Clipbrd, NeoClassicImageList, NeoClassicIconNames;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    cbView: TComboBox;
    edFilter: TEdit;
    ilLarge: TNeoClassicImageList;
    ilSmall: TNeoClassicImageList;
    lblFilter: TLabel;
    lblView: TLabel;
    lvIcons: TListView;
    miCopyConst: TMenuItem;
    miCopyName: TMenuItem;
    miEdit: TMenuItem;
    miExit: TMenuItem;
    miFile: TMenuItem;
    miHelp: TMenuItem;
    miAbout: TMenuItem;
    miSep1: TMenuItem;
    mnuMain: TMainMenu;
    pnlTop: TPanel;
    sbStatus: TStatusBar;
    tbMain: TToolBar;
    tbNew: TToolButton;
    tbOpen: TToolButton;
    tbSave: TToolButton;
    tbSep1: TToolButton;
    tbCopy: TToolButton;
    tbFind: TToolButton;
    tbSep2: TToolButton;
    tbAbout: TToolButton;
    tbExit: TToolButton;
    procedure cbViewChange(Sender: TObject);
    procedure edFilterChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lvIconsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure miAboutClick(Sender: TObject);
    procedure miCopyConstClick(Sender: TObject);
    procedure miCopyNameClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure tbFindClick(Sender: TObject);
  private
    procedure FillList;
    function SelectedIndex: Integer;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ 'document_save' -> 'nciDocumentSave' }
function ConstName(const AName: string): string;
var
  Part: string;
begin
  Result := 'nci';
  for Part in AName.Split(['_']) do
    if Part <> '' then
      Result := Result + UpperCase(Part[1]) + Copy(Part, 2, MaxInt);
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // ImageIndex values are the generated constants - readable and stable.
  tbNew.ImageIndex := nciDocumentNew;
  tbOpen.ImageIndex := nciDocumentOpen;
  tbSave.ImageIndex := nciDocumentSave;
  tbCopy.ImageIndex := nciEditCopy;
  tbFind.ImageIndex := nciEditFind;
  tbAbout.ImageIndex := nciInfo;
  tbExit.ImageIndex := nciExit;
  miCopyName.ImageIndex := nciEditCopy;
  miCopyConst.ImageIndex := nciDocumentText;
  miExit.ImageIndex := nciExit;
  miAbout.ImageIndex := nciInfo;
  FillList;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  // GTK2 keeps the icon view scrolled to the last added item; start at the top.
  if lvIcons.Items.Count > 0 then
  begin
    lvIcons.Selected := lvIcons.Items[0];
    lvIcons.Items[0].MakeVisible(False);
  end;
end;

procedure TfrmMain.FillList;
var
  I: Integer;
  Filter: string;
  Item: TListItem;
begin
  Filter := LowerCase(Trim(edFilter.Text));
  lvIcons.Items.BeginUpdate;
  try
    lvIcons.Items.Clear;
    for I := 0 to NeoClassicIconCount - 1 do
    begin
      if (Filter <> '') and (Pos(Filter, NeoClassicIconList[I]) = 0)
         and (Pos(Filter, LowerCase(NeoClassicIconTitles[I])) = 0) then
        Continue;
      Item := lvIcons.Items.Add;
      Item.Caption := NeoClassicIconList[I];
      Item.ImageIndex := I;
      Item.SubItems.Add(ConstName(NeoClassicIconList[I]));
      Item.SubItems.Add(IntToStr(I));
      Item.SubItems.Add(NeoClassicIconTitles[I]);
    end;
  finally
    lvIcons.Items.EndUpdate;
  end;
  sbStatus.Panels[0].Text := Format('%d / %d icons', [lvIcons.Items.Count, NeoClassicIconCount]);
end;

function TfrmMain.SelectedIndex: Integer;
begin
  if lvIcons.Selected = nil then
    Result := -1
  else
    Result := lvIcons.Selected.ImageIndex;
end;

procedure TfrmMain.lvIconsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  I: Integer;
begin
  I := SelectedIndex;
  if I < 0 then
    sbStatus.Panels[1].Text := ''
  else
    sbStatus.Panels[1].Text := Format('%s = %d  -  ''%s''  -  %s',
      [ConstName(NeoClassicIconList[I]), I, NeoClassicIconList[I], NeoClassicIconTitles[I]]);
end;

procedure TfrmMain.cbViewChange(Sender: TObject);
begin
  case cbView.ItemIndex of
    0: lvIcons.ViewStyle := vsIcon;
    1: lvIcons.ViewStyle := vsReport;
    2: lvIcons.ViewStyle := vsList;
  end;
end;

procedure TfrmMain.edFilterChange(Sender: TObject);
begin
  FillList;
end;

procedure TfrmMain.tbFindClick(Sender: TObject);
begin
  edFilter.SetFocus;
  edFilter.SelectAll;
end;

procedure TfrmMain.miCopyNameClick(Sender: TObject);
begin
  if SelectedIndex >= 0 then
    Clipboard.AsText := NeoClassicIconList[SelectedIndex];
end;

procedure TfrmMain.miCopyConstClick(Sender: TObject);
begin
  if SelectedIndex >= 0 then
    Clipboard.AsText := ConstName(NeoClassicIconList[SelectedIndex]);
end;

procedure TfrmMain.miAboutClick(Sender: TObject);
begin
  MessageDlg('NeoClassicIcons',
    Format('%d classic 16x16 pixel-art icons for Lazarus.' + LineEnding +
           'MIT License - github.com/lastlos/NeoClassicIcons', [NeoClassicIconCount]),
    mtInformation, [mbOK], 0);
end;

procedure TfrmMain.miExitClick(Sender: TObject);
begin
  Close;
end;

end.
