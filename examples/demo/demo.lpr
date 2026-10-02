program demo;

{ NeoClassicIcons demo - shows every icon with its name and constant.
  SPDX-License-Identifier: MIT }

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  NeoClassicTheme, // optional classic GTK2 look; must come before Interfaces
  Interfaces,
  Forms, mainform;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Title := 'NeoClassicIcons Demo';
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
