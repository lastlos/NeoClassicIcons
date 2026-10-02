{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit neoclassicicons;

{$warn 5023 off : no warning about unused units}
interface

uses
  NeoClassicImageList, NeoClassicIconNames, NeoClassicTheme, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('NeoClassicImageList', @NeoClassicImageList.Register);
end;

initialization
  RegisterPackage('neoclassicicons', @Register);
end.
