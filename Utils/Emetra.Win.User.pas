unit Emetra.Win.User;

interface

function GetWindowsUserName: string; { Returns the user currently logged in to OS }
function GetWindowsComputerName: string; { Returns the computer this application runs on }
function GetWindowsDomainName: string;
function GetTempDir: string;

implementation

uses
  System.SysUtils, WinAPI.Windows;

{$REGION 'WindowsNames'}

function GetWindowsUserName: string;
const
  cnMaxLen = 254;
var

{$IFDEF DotNet}

  sUserName: stringbuilder;

{$ELSE}

  sUserName: array [0 .. cnMaxLen] of char;

{$ENDIF}

  dwUserNameLen: dword;
begin
  dwUserNameLen := cnMaxLen - 1;
  GetUserName(sUserName, dwUserNameLen);

{$IFDEF DotNet}

  Result := sUserName.ToString;

{$ELSE}

  Result := strPas(sUserName);

{$ENDIF}

end;

function GetWindowsComputerName: string;
const
  cnMaxLen = 254;
var

{$IFDEF DotNet}

  sUserName: stringbuilder;

{$ELSE}

  sUserName: array [0 .. cnMaxLen] of char;

{$ENDIF}

  dwUserNameLen: dword;
begin
  dwUserNameLen := cnMaxLen - 1;
  GetComputerName(sUserName, dwUserNameLen);

{$IFDEF DotNet}

  Result := sUserName.ToString;

{$ELSE}

  Result := strPas(sUserName);

{$ENDIF}

end;

function GetTempDir: string;
var

{$IFDEF DotNet}

  pCurrTempDir: stringbuilder;

{$ELSE}

  pCurrTempDir: array [0 .. 255] of char;

{$ENDIF}

begin
  WinAPI.Windows.GetEnvironmentVariable('TEMP', pCurrTempDir, 255);

{$IFDEF DotNet}

  Result := IncludeTrailingPathDelimiter(pCurrTempDir.ToString);

{$ELSE}

  Result := IncludeTrailingPathDelimiter(strPas(pCurrTempDir));

{$ENDIF}

end;

function GetWindowsDomainName: string;
var
  pUserDomain: array [0 .. 255] of char;
begin
  WinAPI.Windows.GetEnvironmentVariable('USERDOMAIN', pUserDomain, 255);
  Result := strPas(pUserDomain);
end;

{$ENDREGION}
end.
