unit Emetra.Azure.Table.API;

interface

uses
  Emetra.Azure.Table.Interfaces,
  Emetra.Azure.Table.Row,
  Emetra.Logging.Interfaces,
  {Standard}
  Data.Cloud.AzureAPI, Data.Cloud.CloudAPI, Data.Db,
  System.Generics.Collections, System.SysUtils, System.Classes;

type
  ECreateTableFailed = class( Exception );
  ECreateTableForbidden = class( Exception );

  TSimpleAzureTableAPI = class( TAzureConnectionInfo, IDatasetPublisher )
  strict private
    fLog: ILog;
    fBreakOnConflict: boolean;
    fResponseInfo: TCloudResponseInfo;
    fSettings: TFormatSettings;
    fTableService: TAzureTableService;
    fRowsPublished: integer;
    fRowChar: char;
  private
    { Propery accessors }
    function Get_BreakOnConflict: boolean;
    function Get_ResponseCode: integer;
    function Get_RowsPublished: integer;
    procedure Set_BreakOnConflict( const AValue: boolean );
    { Other methods }
    function TryRowOperation( const ATableRow: TAzTableRow; const AOperation: TEntityOperation ): boolean;
    function BreakAfterInsert( const AResult: boolean ): boolean;
    procedure ValidateKeys( const ATableRow: TAzTableRow );
    procedure SetRowKey( const ATableRow: TAzTableRow; const ADataset: TDataset );
    procedure SetCenterId( const ACenterId: integer );
    procedure Dispose;
  public
    { Initialization }
    constructor Create( const AOwner: TComponent; const AAccountName, AAccountKey: string; const ALog: ILog ); reintroduce;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    { Other members }
    function TryDelete( const ATableRow: TAzTableRow ): boolean;
    function TryInsert( const ATableRow: TAzTableRow ): boolean;
    function TryMerge( const ATableRow: TAzTableRow ): boolean;
    function TryUpdate( const ATableRow: TAzTableRow ): boolean;
    procedure GetTableNames( ATableNames: TList<string> );
    procedure PublishDataset( const ADataset: TDataset; const ATableName: string; out ARowsAdded: integer ); overload;
    procedure PublishDataset( const ADataset: TDataset; const ATableName: string; const AUpdateStrategy: TEntityUpdateStrategy; const AMaxRows, AMaxErrors: integer; out AErrors: integer ); overload;
    function TryRetrieveDataset( const ADataset: TDataset; const AFieldAdd: IDatasetAddColumn; const ATableName, APartitionKey: string; const AMinTimestamp: TDate ): boolean;
    procedure TruncateTable( const ATableName: string );
    { Properties }
    property BreakOnConflict: boolean read fBreakOnConflict write fBreakOnConflict;
    property ResponseCode: integer read Get_ResponseCode;

  end;

implementation

{ %CLASSGROUP 'System.Classes.TPersistent' }

uses
  {Standard}
  System.DateUtils;

const
  StrNextPartitionKey = 'x-ms-continuation-NextPartitionKey';
  StrNextRowKey       = 'x-ms-continuation-NextRowKey';

type
  TResponseInfoHelper = class helper for TCloudResponseInfo
    procedure Clear;
  end;

{$REGION 'Initialization'}

constructor TSimpleAzureTableAPI.Create( const AOwner: TComponent; const AAccountName, AAccountKey: string; const ALog: ILog );
begin
  inherited Create( AOwner );
  AccountKey := AAccountKey;
  AccountName := AAccountName;
  fLog := ALog;
  fBreakOnConflict := true;
end;

procedure TSimpleAzureTableAPI.Dispose;
begin
  Free;
end;

procedure TSimpleAzureTableAPI.AfterConstruction;
begin
  inherited;
  fTableService := TAzureTableService.Create( Self );
  fResponseInfo := TCloudResponseInfo.Create;
  fSettings := TFormatSettings.Create( 'en-US' );
end;

procedure TSimpleAzureTableAPI.BeforeDestruction;
begin
  fResponseInfo.Free;
  inherited;
end;

function TSimpleAzureTableAPI.BreakAfterInsert( const AResult: boolean ): boolean;
begin
  if AResult = true then
    Result := false
  else
    Result := ( AResult = false ) and ( fResponseInfo.StatusCode = HTTP_CONFLICT ) and ( fBreakOnConflict );
end;

{$ENDREGION}
{$REGION 'Property accessors'}

procedure TSimpleAzureTableAPI.GetTableNames( ATableNames: TList<string> );
var
  tableList: TStrings;
begin
  tableList := fTableService.QueryTables( );
  try
    while tableList.Count > 0 do
    begin
      ATableNames.Add( tableList[0] );
      tableList.Delete( 0 );
    end;
  finally
    tableList.Free;
  end;
end;

function TSimpleAzureTableAPI.Get_BreakOnConflict: boolean;
begin
  Result := fBreakOnConflict;
end;

function TSimpleAzureTableAPI.Get_ResponseCode: integer;
begin
  Result := fResponseInfo.StatusCode;
end;

function TSimpleAzureTableAPI.Get_RowsPublished: integer;
begin
  Result := fRowsPublished;
end;

{$ENDREGION}
{$REGION 'Logging and validation'}

procedure TSimpleAzureTableAPI.ValidateKeys( const ATableRow: TAzTableRow );
var
  dummy: string;
begin
  if not( ATableRow.GetColumnValue( 'RowKey', dummy ) and ATableRow.GetColumnValue( 'PartitionKey', dummy ) ) then
    raise EAssertionFailed.Create( 'RowKey and/or PartitionKey is empty.' );
end;

{$ENDREGION}
{$REGION 'Azure table operations'}

procedure TSimpleAzureTableAPI.TruncateTable( const ATableName: string );
const
  PROC_NAME = 'TruncateTable';
var
  entityList: TList<TCloudTableRow>;
  entity: TCloudTableRow;
  successCount: integer;
  failCount: integer;
begin
  fLog.EnterMethod( Self, PROC_NAME );
  try
    successCount := 0;
    failCount := 0;
    entityList := fTableService.QueryEntities( ATableName );
    try
      fLog.Event( 'Deleting %d entries from "%s"', [entityList.Count, ATableName] );
      for entity in entityList do
        if fTableService.DeleteEntity( ATableName, entity ) then
          inc( successCount )
        else
          inc( failCount );
      if failCount = 0 then
        fLog.Event( 'Deleted %d rows succesfully.', [successCount] )
      else
        fLog.SilentError( 'Failed to delete %d of %d rows.', [failCount, successCount] )
    finally
      entityList.Free;
    end;
  finally
    fLog.LeaveMethod( Self, PROC_NAME );
  end;
end;

function TSimpleAzureTableAPI.TryInsert( const ATableRow: TAzTableRow ): boolean;
begin
  Result := TryRowOperation( ATableRow, eoInsert );
  if Result then
    fRowChar := 'I';
end;

function TSimpleAzureTableAPI.TryDelete( const ATableRow: TAzTableRow ): boolean;
begin
  Result := TryRowOperation( ATableRow, eoDelete );
  if Result then
    fRowChar := 'D';
end;

function TSimpleAzureTableAPI.TryMerge( const ATableRow: TAzTableRow ): boolean;
begin
  Result := TryRowOperation( ATableRow, eoMerge );
  if Result then
    fRowChar := 'M';
end;

function TSimpleAzureTableAPI.TryUpdate( const ATableRow: TAzTableRow ): boolean;
begin
  Result := TryRowOperation( ATableRow, eoUpdate );
  if Result then
    fRowChar := 'U';
end;

function TSimpleAzureTableAPI.TryRowOperation( const ATableRow: TAzTableRow; const AOperation: TEntityOperation ): boolean;
const
  LOG_TEMPLATE = '%s.TryRowOperation(%s.%s): %d - %s ';
begin
  Result := false;
  try
    fResponseInfo.Clear;
    ValidateKeys( ATableRow );
    case AOperation of
      eoDelete: Result := fTableService.DeleteEntity( ATableRow.TableName, ATableRow, fResponseInfo );
      eoInsert: Result := fTableService.InsertEntity( ATableRow.TableName, ATableRow, fResponseInfo );
      eoMerge: Result := fTableService.MergeEntity( ATableRow.TableName, ATableRow, fResponseInfo );
      eoUpdate: Result := fTableService.UpdateEntity( ATableRow.TableName, ATableRow, fResponseInfo );
    end;
    if Result then
      fLog.Event( LOG_TEMPLATE, [ClassName, ATableRow.TableName, ENTITY_OPERATION_NAME[AOperation], fResponseInfo.StatusCode, fResponseInfo.StatusMessage] )
    else
    begin
      fLog.SilentWarning( LOG_TEMPLATE, [ClassName, ATableRow.TableName, ENTITY_OPERATION_NAME[AOperation], fResponseInfo.StatusCode, fResponseInfo.StatusMessage] );
      if fResponseInfo.StatusCode = HTTP_BAD_REQUEST then
        ATableRow.SaveToFile;
    end;
  except
    on E: Exception do
      fLog.SilentError( E.Message );
  end;
end;

{$ENDREGION}

procedure TSimpleAzureTableAPI.PublishDataset( const ADataset: TDataset; const ATableName: string; out ARowsAdded: integer );
var
  errCount: integer;
begin
  PublishDataset( ADataset, ATableName, epsInsert, maxint, maxint, errCount );
  ARowsAdded := fRowsPublished;
end;

procedure TSimpleAzureTableAPI.PublishDataset( const ADataset: TDataset; const ATableName: string; const AUpdateStrategy: TEntityUpdateStrategy; const AMaxRows, AMaxErrors: integer;
  out AErrors: integer );
var
  azTableRow: TAzTableRow;
  rowCount: integer;
  successfulOperation: boolean;
  dsField: TField;
  pkField: TField;
  localPartitionKey: string;
begin
  fTableService.CreateTable( ATableName, fResponseInfo );
  with fResponseInfo do
  begin
    if ( StatusCode < 299 ) or ( StatusCode = 409 ) then
      { All is fine }
    else if StatusCode = 403 then
      raise ECreateTableForbidden.CreateFmt( '%d: %s', [StatusCode, StatusMessage] )
    else
      raise ECreateTableFailed.CreateFmt( '%d: %s', [StatusCode, StatusMessage] );
  end;
  pkField := ADataset.FindField( 'PartitionKey' );
  Assert( Assigned( pkField ), 'PartitionKey field missing' );
  localPartitionKey := pkField.AsString;
  fRowsPublished := 0;
  AErrors := 0;
  rowCount := 0;
  azTableRow := TAzTableRow.Create( ATableName );
  with azTableRow do
    try
      Assert( ADataset.Bof );
      while ( not ADataset.Eof ) and ( rowCount < AMaxRows ) do
      begin
        fRowChar := '?';
        azTableRow.Clear;
        SetColumn( 'PartitionKey', localPartitionKey );
        SetRowKey( azTableRow, ADataset );
        { Loop through all fields and map to OData field types }
        for dsField in ADataset.Fields do
          if ( dsField.FieldKind = fkData ) and not( dsField.IsNull ) then
          begin
            case dsField.DataType of
              ftSmallInt: azTableRow.AddInt16Column( dsField.FieldName, dsField.AsInteger );
              ftInteger, ftWord: AddInt32Column( dsField.FieldName, dsField.AsInteger );
              ftAutoInc, ftLargeInt: AddInt64Column( dsField.FieldName, dsField.AsLargeInt );
              ftFloat: AddFloatColumn( dsField.FieldName, dsField.AsFloat );
              ftBCD, ftFMTBCD: AddFloatColumn( dsField.FieldName, dsField.AsFloat );
              ftBoolean: AddBoolColumn( dsField.FieldName, dsField.AsBoolean );
              ftGuid: AddGuidColumn( dsField.FieldName, dsField.AsString );
              ftString, ftWideString, ftMemo: SetColumn( dsField.FieldName, dsField.AsString );
              ftDate: AddDateColumn( dsField.FieldName, dsField.AsDateTime );
              ftDateTime: AddDateTimeColumn( dsField.FieldName, dsField.AsDateTime );
            else raise ENotSupportedException.CreateFmt( 'Field "%s" has an unsupported DataType [%d]', [dsField.FieldName, ord( dsField.DataType )] );
            end;
          end;
        successfulOperation := false;
        case AUpdateStrategy of
          epsInsert:
            begin
              successfulOperation := TryInsert( azTableRow );
              if BreakAfterInsert( successfulOperation ) then
                break;
            end;
          epsInsertThenUpdate:
            begin
              successfulOperation := TryInsert( azTableRow );
              if BreakAfterInsert( successfulOperation ) then
                break
              else
                successfulOperation := TryUpdate( azTableRow );
            end;
          epsUpdate: successfulOperation := TryUpdate( azTableRow );
          epsUpdateThenInsert:
            begin
              successfulOperation := TryUpdate( azTableRow );
              if not successfulOperation and ( fResponseInfo.StatusCode = HTTP_NOT_FOUND ) then
                successfulOperation := TryInsert( azTableRow );
            end;
        end;
        if not successfulOperation then
        begin
          inc( AErrors )
        end
        else
        begin
          inc( fRowsPublished );
        end;
{$IFDEF Console}
        write( fRowChar );
{$ENDIF}
        ADataset.Next;
        inc( rowCount );
      end;
    finally
      azTableRow.Free;
    end;
end;

function TSimpleAzureTableAPI.TryRetrieveDataset( const ADataset: TDataset; const AFieldAdd: IDatasetAddColumn; const ATableName, APartitionKey: string; const AMinTimestamp: TDate ): boolean;
var
  entityList: TList<TCloudTableRow>;
  entity: TCloudTableRow;
  colValue: string;
  column: TCloudTableColumn;
  field: TField;
  fieldMap: TDictionary<string, TField>;
  usFormat: TFormatSettings;
  filterExpression: string;
  nextPartitionKey: string;
  nextRowKey: string;
  batchCount: integer;
  entityCount: integer;
begin
  Result := false;
  batchCount := 0;
  entityCount := 0;
  usFormat := TFormatSettings.Create( 'en-US' );
  nextPartitionKey := EmptyStr;
  nextRowKey := EmptyStr;
  fieldMap := TDictionary<string, TField>.Create;
  filterExpression := 'Timestamp gt datetime' + QuotedStr( FormatDateTime( 'yyyy-mm-dd"T"hh:mm:ss"Z"', AMinTimestamp ) );
  {
    if APartitionKey <> EmptyStr then
    filterExpression := Format( 'PartitionKey eq %s', [QuotedStr( APartitionKey )] )
    else
    filterExpression := EmptyStr;
  }
  repeat
    entityList := fTableService.QueryEntities( ATableName, filterExpression, fResponseInfo, nextPartitionKey, nextRowKey );
    { Save partition and row keys }
    nextPartitionKey := fResponseInfo.Headers.Values[StrNextPartitionKey];
    nextRowKey := fResponseInfo.Headers.Values[StrNextRowKey];
    if nextPartitionKey <> EmptyStr then
      fLog.Event( 'There are more rows (NextPartitionKey="%s", NextRowKey="%s")', [nextPartitionKey, nextRowKey] );
    { Log error details }
    if fResponseInfo.StatusCode <> 200 then
      fLog.SilentError( '%s: Failed with %d - %s ', [ATableName, fResponseInfo.StatusCode, fResponseInfo.StatusMessage] )
    else
    begin
      inc( entityCount, entityList.Count );
      fLog.Event( '%s: Retrieved %d entities (total=%d, batches=%d) ', [ATableName, entityList.Count, entityCount, batchCount + 1] );
      try
        if batchCount = 0 then
        begin
          ADataset.Close;
          { Make sure we have all columns in the dataset }
          for entity in entityList do
            for column in entity.Columns do
            begin
              field := AFieldAdd.AddColumn( ADataset, column );
              fieldMap.AddOrSetValue( column.Name, field );
              Assert( Assigned( field ) );
            end;
          { Loop through the entities and add data }
          ADataset.Open;
        end;
        for entity in entityList do
        begin
          ADataset.Append;
          { Loop through the columns }
          try
            for column in entity.Columns do
              if fieldMap.TryGetValue( column.Name, field ) and entity.GetColumnValue( column.Name, colValue ) then
                if column.DataType = EDM_DOUBLE then
                  field.AsFloat := StrToFloat( colValue, usFormat )
                else if column.DataType = EDM_DATETIME then
                  field.AsDateTime := ISO8601ToDate( colValue, true )
                else
                  field.AsString := colValue;
            ADataset.Post;
          except
            on E: Exception do
            begin
              ADataset.Cancel;
              fLog.SilentWarning( E.Message );
            end;
          end;
        end;
        Result := true;
      finally
        entityList.Free;
      end;
    end;
    inc( batchCount );
  until nextPartitionKey = EmptyStr;
  fieldMap.Free;
end;

procedure TSimpleAzureTableAPI.SetCenterId( const ACenterId: integer );
begin
  { Does nothing }
end;

procedure TSimpleAzureTableAPI.SetRowKey( const ATableRow: TAzTableRow; const ADataset: TDataset );
var
  dsField: TField;
begin
  dsField := ADataset.FieldByName( 'RowKey' );
  Assert( Assigned( dsField ), 'The RowKey field was not found in the dataset' );
  { The row key field with appear twice in the Azure table, under its original name and under the name RowKey }
  if dsField.DataType = ftGuid then
    ATableRow.RowKeyValue := Copy( dsField.AsString, 2, 36 )
  else
    ATableRow.RowKeyValue := dsField.AsString;
end;

procedure TSimpleAzureTableAPI.Set_BreakOnConflict( const AValue: boolean );
begin
  fBreakOnConflict := AValue;
end;

{ TResponseInfoHelper }

procedure TResponseInfoHelper.Clear;
begin
  StatusCode := 0;
  StatusMessage := 'No response info';
end;

end.
