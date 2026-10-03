unit NeoClassicTheme;

{ NeoClassicIcons - optional Windows 2000 / Delphi 7 look for GTK2 applications.
  https://github.com/lastlos/NeoClassicIcons
  SPDX-License-Identifier: MIT

  Add this unit to your .lpr uses clause BEFORE "Interfaces":

    uses
      {$IFDEF UNIX} cthreads, {$ENDIF}
      NeoClassicTheme,   // must come before Interfaces
      Interfaces, Forms, ...

  On GTK2 it points GTK2_RC_FILES to a classic style (gray #D4D0C8 face,
  navy selection, bevelled widgets) before the widgetset starts, so only
  this application is affected - not the desktop theme. The style is adapted
  from the "Redmond" theme of gtk2-engines; if the redmond95 engine is not
  installed GTK falls back to its default engine and the colours still apply.
  On other widgetsets (Win32, Qt, Cocoa) the unit does nothing, and it is
  also a no-op inside the Lazarus IDE when the package is installed.

  Opt out at run time with the environment variable NEOCLASSIC_THEME=0. }

{$mode objfpc}{$H+}

interface

implementation

{$IF DEFINED(UNIX) AND DEFINED(LCLGTK2)}
uses
  SysUtils, InterfaceBase;

function setenv(Name, Value: PChar; Overwrite: LongInt): LongInt; cdecl; external 'c';

const
  CLASSIC_GTKRC =
    'gtk-icon-sizes = "gtk-menu=16,16:gtk-small-toolbar=16,16:gtk-large-toolbar=16,16:gtk-button=16,16"' + LineEnding +
    'gtk-toolbar-style = GTK_TOOLBAR_BOTH_HORIZ' + LineEnding +
    'gtk-button-images = 1' + LineEnding +
    'gtk-menu-images = 1' + LineEnding +
    'style "nc-default" {' + LineEnding +
    '  font_name = "Liberation Sans 9"' + LineEnding +
    '  GtkWidget::interior_focus = 2' + LineEnding +
    '  GtkButton::default_border = { 1, 1, 1, 1 }' + LineEnding +
    '  GtkButton::default_outside_border = { 0, 0, 0, 0 }' + LineEnding +
    '  GtkButton::child_displacement_x = 1' + LineEnding +
    '  GtkButton::child_displacement_y = 1' + LineEnding +
    '  GtkComboBox::appears-as-list = 1' + LineEnding +
    '  GtkMenu::horizontal-padding = 1' + LineEnding +
    '  GtkMenu::vertical-padding = 1' + LineEnding +
    '  GtkScrolledWindow::scrollbar-spacing = 0' + LineEnding +
    '  GtkScrolledWindow::scrollbars-within-bevel = 1' + LineEnding +
    '  GtkRange::trough_border = 0' + LineEnding +
    '  GtkRange::slider_width = 16' + LineEnding +
    '  GtkRange::stepper_size = 16' + LineEnding +
    '  GtkRange::stepper_spacing = 0' + LineEnding +
    '  fg[NORMAL]        = "#000000"' + LineEnding +
    '  fg[ACTIVE]        = "#000000"' + LineEnding +
    '  fg[PRELIGHT]      = "#000000"' + LineEnding +
    '  fg[INSENSITIVE]   = "#808080"' + LineEnding +
    '  fg[SELECTED]      = "#FFFFFF"' + LineEnding +
    '  bg[NORMAL]        = "#D4D0C8"' + LineEnding +
    '  bg[ACTIVE]        = "#D4D0C8"' + LineEnding +
    '  bg[PRELIGHT]      = "#D4D0C8"' + LineEnding +
    '  bg[INSENSITIVE]   = "#D4D0C8"' + LineEnding +
    '  bg[SELECTED]      = "#0A246A"' + LineEnding +
    '  GtkStatusbar::shadow-type = GTK_SHADOW_IN' + LineEnding +
    '  base[NORMAL]      = "#FFFFFF"' + LineEnding +
    '  base[ACTIVE]      = "#0A246A"' + LineEnding +
    '  base[PRELIGHT]    = "#0A246A"' + LineEnding +
    '  base[SELECTED]    = "#0A246A"' + LineEnding +
    '  base[INSENSITIVE] = "#D4D0C8"' + LineEnding +
    '  text[NORMAL]      = "#000000"' + LineEnding +
    '  text[ACTIVE]      = "#FFFFFF"' + LineEnding +
    '  text[PRELIGHT]    = "#FFFFFF"' + LineEnding +
    '  text[SELECTED]    = "#FFFFFF"' + LineEnding +
    '  text[INSENSITIVE] = "#808080"' + LineEnding +
    '  engine "redmond95" {}' + LineEnding +
    '}' + LineEnding +
    'class "GtkWidget" style "nc-default"' + LineEnding +
    'widget_class "*" style "nc-default"' + LineEnding +
    'style "nc-menu" {' + LineEnding +
    '  bg[PRELIGHT] = "#0A246A"' + LineEnding +
    '  fg[PRELIGHT] = "#FFFFFF"' + LineEnding +
    '}' + LineEnding +
    'widget_class "*MenuItem*" style "nc-menu"' + LineEnding +
    'style "nc-menubar" {' + LineEnding +
    '  bg[PRELIGHT] = "#D4D0C8"' + LineEnding +
    '  fg[PRELIGHT] = "#000000"' + LineEnding +
    '}' + LineEnding +
    'widget_class "*MenuBar.*MenuItem*" style "nc-menubar"' + LineEnding +
    'style "nc-tooltip" {' + LineEnding +
    '  bg[NORMAL] = "#FFFFE1"' + LineEnding +
    '  fg[NORMAL] = "#000000"' + LineEnding +
    '}' + LineEnding +
    'widget "gtk-tooltip*" style "nc-tooltip"' + LineEnding;

procedure ApplyClassicTheme;
var
  FileName: string;
  F: TextFile;
begin
  if GetEnvironmentVariable('NEOCLASSIC_THEME') = '0' then Exit;
  // GTK reads GTK2_RC_FILES only at start-up. If the widgetset already exists
  // (unit listed after Interfaces, or running inside the Lazarus IDE where
  // installed packages initialise late) do nothing at all.
  if WidgetSet <> nil then Exit;
  // Fixed per-user name: rewritten on every start, never piles up in the temp dir.
  FileName := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'neoclassic-' + GetEnvironmentVariable('USER') + '.gtkrc';
  try
    AssignFile(F, FileName);
    Rewrite(F);
    Write(F, CLASSIC_GTKRC);
    CloseFile(F);
  except
    Exit; // cannot write the style: keep the system theme
  end;
  setenv('GTK2_RC_FILES', PChar(FileName), 1);
end;

initialization
  ApplyClassicTheme;
{$ENDIF}

end.
