unit NeoClassicImageList;

{ NeoClassicIcons - classic 16x16 pixel-art icons for Lazarus.
  https://github.com/OpenLast/NeoClassicIcons
  SPDX-License-Identifier: MIT

  TNeoClassicImageList is a TImageList that fills itself with all NeoClassic
  icons from linked resources. The images are NOT streamed into the .lfm, so
  forms stay small and always get the icon set of the package version they
  are compiled with. Use the nciXxx constants from NeoClassicIconNames as
  ImageIndex values.

  For HiDPI, each icon is registered with 16, 24 and 32 px resolutions
  (24 px is scaled down from the 32 px pixel-doubled image), so Scaled
  toolbars, menus and buttons pick a sharp size automatically. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, ImgList, NeoClassicIconNames;

type

  { TNeoClassicImageList }

  TNeoClassicImageList = class(TImageList)
  private
    FReloading: Boolean;
    function GetIconHeight: Integer;
    function GetIconWidth: Integer;
    procedure SetIconHeight(AValue: Integer);
    procedure SetIconWidth(AValue: Integer);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    // Image data comes from resources; never read it from or write it to the .lfm.
    procedure ReadData(AStream: TStream); override;
    procedure WriteData(AStream: TStream); override;
    procedure ReadAdvData(AStream: TStream); override;
    procedure WriteAdvData(AStream: TStream); override;
    { Clears the list and loads every NeoClassic icon again. }
    procedure ReloadIcons;
    { Image index of an icon by its name, e.g. 'document_save'; -1 if unknown. }
    function IndexOfName(const AName: string): Integer;
  published
    // Changing the size clears an image list; these setters refill it.
    property Width: Integer read GetIconWidth write SetIconWidth default 16;
    property Height: Integer read GetIconHeight write SetIconHeight default 16;
  end;

{ Fills any image list with all NeoClassic icons, appended in nciXxx order
  (call it on an empty list if you want the nciXxx constants to match).
  Resolutions 16, 24 and 32 px plus the list's own Width are registered. }
procedure NeoClassicLoadIcons(AImageList: TCustomImageList);

{ Loads one icon as PNG: ASize is 16 or 32. Caller frees the result. }
function NeoClassicCreateIcon(const AName: string; ASize: Integer = 16): TPortableNetworkGraphic;

procedure Register;

implementation

{$R neoclassicicons_images.res}

function NeoClassicCreateIcon(const AName: string; ASize: Integer): TPortableNetworkGraphic;
var
  ResName: string;
begin
  ResName := 'NCI_' + UpperCase(AName);
  if ASize > 16 then
    ResName := ResName + '_200';
  Result := TPortableNetworkGraphic.Create;
  try
    Result.LoadFromResourceName(HInstance, ResName);
  except
    Result.Free;
    raise;
  end;
end;

procedure NeoClassicLoadIcons(AImageList: TCustomImageList);
var
  I: Integer;
  Small, Large: TPortableNetworkGraphic;
  Sizes: array[0..1] of TCustomBitmap; // typed: AddMultipleResolutions is overloaded
begin
  AImageList.BeginUpdate;
  try
    AImageList.RegisterResolutions([16, 24, 32, AImageList.Width]);
    for I := 0 to NeoClassicIconCount - 1 do
    begin
      Small := NeoClassicCreateIcon(NeoClassicIconList[I], 16);
      try
        Large := NeoClassicCreateIcon(NeoClassicIconList[I], 32);
        try
          Sizes[0] := Small;
          Sizes[1] := Large;
          AImageList.AddMultipleResolutions(Sizes);
        finally
          Large.Free;
        end;
      finally
        Small.Free;
      end;
    end;
  finally
    AImageList.EndUpdate;
  end;
end;

{ TNeoClassicImageList }

constructor TNeoClassicImageList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ReloadIcons;
end;

procedure TNeoClassicImageList.ReloadIcons;
begin
  if FReloading then Exit;
  FReloading := True;
  try
    Clear;
    NeoClassicLoadIcons(Self);
  finally
    FReloading := False;
  end;
end;

function TNeoClassicImageList.IndexOfName(const AName: string): Integer;
begin
  Result := NeoClassicIconIndex(AName);
end;

procedure TNeoClassicImageList.ReadData(AStream: TStream);
begin
  // ignore: older .lfm files may contain image data, icons come from resources
end;

procedure TNeoClassicImageList.WriteData(AStream: TStream);
begin
  // nothing: keep the .lfm free of image data
end;

procedure TNeoClassicImageList.ReadAdvData(AStream: TStream);
begin
end;

procedure TNeoClassicImageList.WriteAdvData(AStream: TStream);
begin
end;

function TNeoClassicImageList.GetIconWidth: Integer;
begin
  Result := inherited Width;
end;

function TNeoClassicImageList.GetIconHeight: Integer;
begin
  Result := inherited Height;
end;

procedure TNeoClassicImageList.SetIconWidth(AValue: Integer);
begin
  if AValue = inherited Width then Exit;
  inherited Width := AValue;
  if not (csLoading in ComponentState) then
    ReloadIcons;
end;

procedure TNeoClassicImageList.SetIconHeight(AValue: Integer);
begin
  if AValue = inherited Height then Exit;
  inherited Height := AValue;
  if not (csLoading in ComponentState) then
    ReloadIcons;
end;

procedure TNeoClassicImageList.Loaded;
begin
  inherited Loaded;
  // Width/Height from the .lfm are applied now; load at the final size.
  ReloadIcons;
end;

procedure Register;
begin
  RegisterComponents('NeoClassic', [TNeoClassicImageList]);
end;

end.
