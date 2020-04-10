unit Emetra.Azure.TablePublisher;

interface

uses
  FireDAC.Comp.Client,
  Emetra.Azure.Table.API,
  Emetra.Database.Simple,
  Emetra.Database.ConnectionString,
  System.Classes,
  System.SysUtils,
  Generics.Collections;

type
  ESQLConnectionFailed = class( Exception );
  ETableConnectionFailed = class( Exception );
  ETableRetrievalFailed = class( Exception );

  TBlazorDashPublisher = class
  strict private
    fDb: TSimpleDatabase;
    fStorage: TSimpleAzureTableAPI;
    fTableNames: TList<string>;
    fTable: TFDMemTable;
    fEncoding: TUTF8Encoding;
    fRowsTotal: integer;
  private
    procedure Feedback( const s: string; const ALineFeed: boolean = true );
    procedure Connect;
    procedure Disconnect;
  public
    constructor Create( ATable: TFDMemTable; ADb: TSimpleDatabase; AStorage: TSimpleAzureTableAPI );
    procedure BeforeDestruction; override;
    procedure PublishAllDatasets( const AMinTimestamp: TDateTime );
    property RowsTotal: integer read fRowsTotal;
  end;

implementation

uses
  Emetra.Azure.Table.Column,
  System.StrUtils,
  System.IOUtils;

constructor TBlazorDashPublisher.Create( ATable: TFDMemTable; ADb: TSimpleDatabase; AStorage: TSimpleAzureTableAPI );
begin
  inherited Create;
  fTable := ATable;
  fDb := ADb;
  fStorage := AStorage;
  fTableNames := TList<string>.Create;
  fEncoding := TUTF8Encoding.Create;
end;

procedure TBlazorDashPublisher.Feedback( const s: string; const ALineFeed: boolean );
begin
{$IFDEF Console}
  write( s );
  if ALineFeed then
    WriteLn;
{$ENDIF}
end;

procedure TBlazorDashPublisher.BeforeDestruction;
begin
  fEncoding.Free;
  fTableNames.Free;
  inherited;
end;

procedure TBlazorDashPublisher.Connect;
begin
  Feedback( 'Retrieving connection strings from registry.' );
  fDb.ConnectionString := GetAzureConnectionString( 'Software\Emetra\Dashboard' );
  try
    Feedback( 'Retrieving list of tables from Azure table service ... ', false );
    fStorage.GetTableNames( fTableNames );
    Feedback( 'Success' );
  except
    on E: Exception do
    begin
      Feedback( E.Message );
      raise ETableConnectionFailed.Create( E.Message )
    end;
  end;
  try
    Feedback( 'Connecting to database ... ', false );
    fDb.Connect;
    Feedback( 'Success' );
    Feedback( DupeString( '-', 64 ) );
  except
    on E: Exception do
    begin
      Feedback( E.Message );
      raise ESQLConnectionFailed.Create( E.Message );
    end;
  end;
end;

procedure TBlazorDashPublisher.Disconnect;
begin
  fTableNames.Clear;
  fDb.Disconnect;
end;

procedure TBlazorDashPublisher.PublishAllDatasets( const AMinTimestamp: TDateTime );
var tableName: string; dataFile: TStringList; fileName: string;
begin
  Connect;
  try
    for tableName in fTableNames do
    begin
      Feedback( Format( '%-32s: Query', [tableName] ), false );
      fileName := TPath.GetTempPath + tableName + '.json';
      if not fStorage.TryRetrieveDataset( fTable, TAzureColumnMapper.Create, tableName, EmptyStr, AMinTimestamp ) then
        raise ETableRetrievalFailed.Create( 'Failed to retrieve data from Azure Tables.' );
      Feedback( ' Save', false );
      fTable.SaveToFile( fileName );
      inc( fRowsTotal, fTable.RecordCount );
      Feedback( 'd ', false );
      dataFile := TStringList.Create;
      try
        Feedback( 'Load ', false );
        dataFile.LoadFromFile( fileName, fEncoding );
        Feedback( 'Post ', false );
        fDb.ExecuteCommand( 'EXEC AzureTable.AddTableData :TableName, :TableJsonData', [tableName, dataFile.Text] );
        Feedback( 'Success!' );
      finally
        dataFile.Free;
      end;
    end;
    Feedback( DupeString( '-', 64 ) );
    Feedback( Format( 'Posted %d records to BlazorDash', [fRowsTotal] ) );
    fDb.ExecuteCommand( 'EXEC Jobs.RunAll' );
  finally
    Disconnect;
  end;
end;

end.
