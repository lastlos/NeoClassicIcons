program imagelisttest;

{ Automated checks for TNeoClassicImageList. Needs a display (use xvfb-run in CI).
  Exit code 0 = all checks passed. SPDX-License-Identifier: MIT }

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Interfaces, Classes, SysUtils, Forms, Graphics, ImgList,
  NeoClassicImageList, NeoClassicIconNames;

var
  Failures: Integer = 0;

procedure Check(Cond: Boolean; const What: string);
begin
  if Cond then
    WriteLn('ok    ', What)
  else
  begin
    WriteLn('FAIL  ', What);
    Inc(Failures);
  end;
end;

function ResourcePngWidth(const ResName: string): Integer;
var
  Png: TPortableNetworkGraphic;
begin
  Png := TPortableNetworkGraphic.Create;
  try
    try
      Png.LoadFromResourceName(HInstance, ResName);
      Result := Png.Width;
    except
      Result := -1;
    end;
  finally
    Png.Free;
  end;
end;

function HasResolution(IL: TCustomImageList; W: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to IL.ResolutionCount - 1 do
    if IL.ResolutionByIndex[I].Width = W then
      Exit(True);
  Result := False;
end;

{ Compares image Index of resolution W with the PNG that tools/build.py wrote. }
function SameAsFile(IL: TCustomImageList; Index, W: Integer; const FileName: string): Boolean;
var
  Bmp: TBitmap;
  Png: TPortableNetworkGraphic;
  X, Y: Integer;
begin
  Result := False;
  Bmp := TBitmap.Create;
  Png := TPortableNetworkGraphic.Create;
  try
    IL.ResolutionForPPI[W, 96, 1].Resolution.GetBitmap(Index, Bmp);
    Png.LoadFromFile(FileName);
    if (Bmp.Width <> Png.Width) or (Bmp.Height <> Png.Height) then Exit;
    for Y := 0 to Png.Height - 1 do
      for X := 0 to Png.Width - 1 do
        if Png.Canvas.Pixels[X, Y] <> Bmp.Canvas.Pixels[X, Y] then
          if Png.Canvas.Pixels[X, Y] <> clNone then // ignore fully transparent pixels
            Exit;
    Result := True;
  finally
    Png.Free;
    Bmp.Free;
  end;
end;

var
  IL: TNeoClassicImageList;
  MS: TMemoryStream;
  Root, Name: string;
  I: Integer;
begin
  Application.Initialize;
  Root := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..' + PathDelim);
  IL := TNeoClassicImageList.Create(nil);
  try
    Check(IL.Count = NeoClassicIconCount, Format('Count = %d', [IL.Count]));
    Check((IL.Width = 16) and (IL.Height = 16), 'default size 16x16');
    Check(HasResolution(IL, 16) and HasResolution(IL, 24) and HasResolution(IL, 32),
      'resolutions 16, 24 and 32 registered');
    Check(IL.IndexOfName('document_save') = nciDocumentSave, 'IndexOfName(document_save) = nciDocumentSave');
    Check(IL.IndexOfName('DOCUMENT_SAVE') = nciDocumentSave, 'IndexOfName is case-insensitive');
    Check(IL.IndexOfName('no_such_icon') = -1, 'IndexOfName(unknown) = -1');

    for I := 0 to NeoClassicIconCount - 1 do
    begin
      Name := NeoClassicIconList[I];
      if not SameAsFile(IL, I, 16, Root + 'icons/16/' + Name + '.png') then
        Check(False, '16 px pixels of ' + Name);
      if not SameAsFile(IL, I, 32, Root + 'icons/32/' + Name + '.png') then
        Check(False, '32 px pixels of ' + Name);
    end;
    Check(not SameAsFile(IL, nciDocument, 16, Root + 'icons/16/add.png'),
      'pixel comparison detects a different icon (sanity check)');
    Check(Failures = 0, Format('16/32 px pixels of all %d icons match icons/16 and icons/32', [NeoClassicIconCount]));

    IL.Width := 32;
    IL.Height := 32;
    Check(IL.Count = NeoClassicIconCount, 'refilled after Width/Height := 32');
    Check(SameAsFile(IL, nciDocumentSave, 32, Root + 'icons/32/document_save.png'),
      '32x32 list shows the 32 px artwork');

    Check((ResourcePngWidth('TNEOCLASSICIMAGELIST') = 24) and
          (ResourcePngWidth('TNEOCLASSICIMAGELIST_150') = 36) and
          (ResourcePngWidth('TNEOCLASSICIMAGELIST_200') = 48),
      'IDE palette icon resources 24/36/48 px present');

    MS := TMemoryStream.Create;
    try
      MS.WriteComponent(IL);
      Check(MS.Size < 512, Format('streamed size %d bytes (no image data in .lfm)', [MS.Size]));
    finally
      MS.Free;
    end;
  finally
    IL.Free;
  end;

  if Failures = 0 then
    WriteLn('ALL CHECKS PASSED')
  else
    WriteLn(Failures, ' CHECK(S) FAILED');
  ExitCode := Ord(Failures > 0);
end.
