unit Emetra.Logging.Target.TextFile;

interface

uses
  Emetra.Logging.Target.Interfaces,
  Emetra.Logging.LogItem.Interfaces,
  System.SyncObjs, System.Classes;

type
  TLogWriter = class( TInterfacedObject, ILogItemTarget )
  strict private
    fWriteErrors: integer;
    fFileStream: TFileStream;
    fCriticalSection: TCriticalSection;
    procedure CreateLogFile( const AFileName: string );
  private
    procedure WriteToFile( const AItem: IBasicLogItem );
    procedure Send( ALogItem: IBasicLogItem );
    { Property accessors }
    function URI: string;
  public
    constructor Create( const AFileName: string ); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
  WinAPI.Windows,
{$ENDIF}
  System.IOUtils, System.SysUtils;

const
  MAX_ERRORS = 256;
  UTF8BOM: array [0 .. 2] of byte = ( $EF, $BB, $BF );

constructor TLogWriter.Create( const AFileName: string );
begin
  inherited Create;
  fCriticalSection := TCriticalSection.Create;
  CreateLogFile( AFileName );
end;

destructor TLogWriter.Destroy;
begin
  if Assigned( fFileStream ) then
    FreeAndNil( fFileStream );
  fCriticalSection.Free;
  inherited;
end;

procedure TLogWriter.WriteToFile( const AItem: IBasicLogItem );
var
  plainTextData: RawByteString;
begin
  plainTextData := UTF8Encode( AItem.PlainText + #13#10 );
  try
    fFileStream.WriteBuffer( plainTextData[1], Length( plainTextData ) );
    {$IFDEF MSWINDOWS}
    FlushFileBuffers( fFileStream.Handle );
    {$ENDIF}
  except on Exception do
    inc( fWriteErrors );
  end;
end;

procedure TLogWriter.Send( ALogItem: IBasicLogItem );
begin
  if Assigned( fFileStream ) and ( fWriteErrors < MAX_ERRORS ) then
    WriteToFile( ALogItem );
end;

procedure TLogWriter.CreateLogFile( const AFileName: string );
const
  MAX_FILE = 64;
var
  tmpFileName: string;
  successfulCreate: boolean;
  fileNo: integer;
begin
  fCriticalSection.Enter;
  try
    tmpFileName := AFileName;
    fileNo := 0;
    successfulCreate := false;
    repeat
      try
        fFileStream := TFileStream.Create( tmpFileName, fmCreate or fmShareDenyWrite );
        successfulCreate := true;
      except
        on E: Exception do
          fFileStream := nil;
      end;
      inc( fileNo );
      tmpFileName := ChangeFileExt( AFileName, Format( '.%.2d.LOG', [fileNo] ) );
    until successfulCreate or ( fileNo >= MAX_FILE );
    if successfulCreate then
      fFileStream.WriteBuffer( UTF8BOM[0], 3 );
  finally
    fCriticalSection.Leave;
  end;
end;

function TLogWriter.URI: string;
begin
  if Assigned( fFileStream ) then
    Result := 'file://' + fFileStream.FileName
  else
    Result := EmptyStr;
end;

end.
