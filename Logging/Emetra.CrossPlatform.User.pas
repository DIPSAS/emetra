unit Emetra.CrossPlatform.User;

interface

uses
{$IFDEF Android}
  Androidapi.JNI.Os, // TJBuild
  Androidapi.JNI.Javatypes,
  Androidapi.Helpers, // StringToJString
{$ENDIF}
  System.SysUtils;

function GetUserName: string;
function GetComputerName: string;
function GetSerialNumber: string;

implementation

{$IFDEF MSWINDOWS}

uses
  System.Win.Registry, WinAPI.Windows;

function GetWindowsSerialNumber: string;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly( '\SOFTWARE\Microsoft\Windows NT\CurrentVersion' ) then
      Result := Reg.ReadString( 'BuildLabEx' );
  finally
    FreeAndNil( Reg );
  end;
end;

{$ENDIF}

function GetUserName: string;
begin
  Result := GetEnvironmentVariable( 'USERNAME' );
end;

function GetComputerName: string;
begin
{$IFDEF Android}
  Result := JStringToString( TJBuild.JavaClass.HOST );
{$ENDIF}
{$IFDEF MSWINDOWS}
  Result := GetEnvironmentVariable( 'COMPUTERNAME' );
{$ENDIF}
end;

function GetSerialNumber: string;
begin
{$IFDEF MSWINDOWS}
  Result := GetWindowsSerialNumber;
{$ENDIF}
{$IFDEF Android}
  Result := JStringToString( TJBuild.JavaClass.SERIAL );
{$ENDIF}
end;

end.
