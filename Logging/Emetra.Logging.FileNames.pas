unit Emetra.Logging.FileNames;

interface

type
  TLogFileNaming = class
  public
    class function GetStdFileName( const AExtension: string ): string;
    class function GetSubfolder( const ASubfolderName: string ): string;
    class function GetExeName: string;
  end;

implementation

uses
  Emetra.Win.User,
  System.SysUtils;

{$REGION 'TLogFileNaming'}

class function TLogFileNaming.GetSubfolder( const ASubfolderName: string ): string;
begin
  Result := IncludeTrailingPathDelimiter( ExtractFilePath( ParamStr( 0 ) ) + ASubfolderName );
end;

class function TLogFileNaming.GetStdFileName( const AExtension: string ): string;
begin
  Result := GetSubfolder( 'LOGS' ) + GetExeName + '-' + GetWindowsUserName + AExtension;
end;

class function TLogFileNaming.GetExeName: string;
begin
  Result := ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '' );
end;

{$ENDREGION}

end.
