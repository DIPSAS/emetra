unit Emetra.Azure.Table.Row;

interface

uses
  Data.Cloud.AzureAPI, Data.Cloud.CloudAPI, System.SysUtils;

type
  TAzTableRow = class( TCloudTableRow )
  class var
    FormatSettings: TFormatSettings;
  strict private
    fTableName: string;
  private
    function Get_RowKeyValue: string;
    procedure Set_RowKeyValue( const ARowKeyValue: string );
  public
    { Initialization }
    class constructor Create;
    constructor Create( const ATableName: string ); reintroduce;
    { Other methods }
    procedure AddBoolColumn( const AColumnName: string; const AValue: boolean );
    procedure AddDateColumn( const AColumnName: string; const AValue: TDate );
    procedure AddDateTimeColumn( const AColumnName: string; const AValue: TDateTime );
    procedure AddFloatColumn( const AColumnName: string; const AValue: double );
    procedure AddGuidColumn( const AColumnName: string; const AValue: string );
    procedure AddInt16Column( const AColumnName: string; const AValue: smallint );
    procedure AddInt32Column( const AColumnName: string; const AValue: integer );
    procedure AddInt64Column( const AColumnName: string; const AValue: int64 );
    procedure AddStringColumn( const AColumnName: string; const AValue: string );
    procedure Clear;
    procedure CopyObject( const AObject: TObject; const AObjectFieldToUseForRowKey: string );
    procedure SaveToFile;
    { Properties }
    property TableName: string read fTableName;
    property RowKeyValue: string read Get_RowKeyValue write Set_RowKeyValue;
  end;

implementation

uses
  Emetra.Azure.Table.Interfaces,
  {Standard}
  System.StrUtils, System.DateUtils, System.Rtti, System.Classes;

const
  EXC_ROWKEY_FIELD_MISSING = 'The specified ARowKeyField name "%s" was not found, missing the initial "F", perhaps?';

  { TAzTableRow }

{$REGION 'Initialization'}

class constructor TAzTableRow.Create;
begin
  inherited;
  TAzTableRow.FormatSettings := TFormatSettings.Create( 'en-US' );
end;

constructor TAzTableRow.Create( const ATableName: string );
begin
  inherited Create;
  fTableName := ATableName;
end;

{$ENDREGION}

{$REGION 'Adding columns/properties to the entity'}

procedure TAzTableRow.AddBoolColumn( const AColumnName: string; const AValue: boolean );
begin
  SetColumn( AColumnName, BoolToStr( AValue, true ), EDM_BOOLEAN );
end;

procedure TAzTableRow.AddDateColumn( const AColumnName: string; const AValue: TDate );
begin
  { Use true for UTCEncoded to avoid offset on server }
  SetColumn( AColumnName, DateToISO8601( AValue, true ), EDM_DATETIME );
end;

procedure TAzTableRow.AddDateTimeColumn( const AColumnName: string; const AValue: TDateTime );
begin
  { Use false for UTCEncoded, meaning that the time is local }
  SetColumn( AColumnName, DateToISO8601( AValue, false ), EDM_DATETIME );
end;

procedure TAzTableRow.AddFloatColumn( const AColumnName: string; const AValue: double );
begin
  SetColumn( AColumnName, FloatToStr( AValue, FormatSettings ), EDM_DOUBLE );
end;

procedure TAzTableRow.AddGuidColumn( const AColumnName, AValue: string );
begin
  SetColumn( AColumnName, Copy( AValue, 2, 36 ), EDM_GUID );
end;

procedure TAzTableRow.AddInt16Column( const AColumnName: string; const AValue: smallint );
begin
  SetColumn( AColumnName, AValue.ToString, EDM_INT32 ); { Yes, not supported 16 bit }
end;

procedure TAzTableRow.AddInt32Column( const AColumnName: string; const AValue: integer );
begin
  SetColumn( AColumnName, AValue.ToString, EDM_INT32 );
end;

procedure TAzTableRow.AddInt64Column( const AColumnName: string; const AValue: int64 );
begin
  SetColumn( AColumnName, AValue.ToString, EDM_INT32 ); { Yes, not supported 64 bit }
end;

procedure TAzTableRow.AddStringColumn( const AColumnName, AValue: string );
begin
  SetColumn( AColumnName, AValue, EDM_STRING );
end;

procedure TAzTableRow.Clear;
begin
  Columns.Clear;
end;

{$ENDREGION}

function TAzTableRow.Get_RowKeyValue: string;
begin
  GetColumnValue( 'RowKey', Result );
end;

procedure TAzTableRow.SaveToFile;
var
  Column: TCloudTableColumn;
  lstFile: TStringList;
begin
  lstFile := TStringList.Create;
  try
    for Column in Columns do
      lstFile.Add( Column.Name + #9 + Column.DataType + #9 + Column.Value );
    lstFile.SaveToFile( Self.RowKeyValue + '.csv' );
  finally
    lstFile.Free;
  end;
end;

procedure TAzTableRow.Set_RowKeyValue( const ARowKeyValue: string );
begin
  SetColumn( 'RowKey', ARowKeyValue );
end;

procedure TAzTableRow.CopyObject( const AObject: TObject; const AObjectFieldToUseForRowKey: string );
var
  columnName: string;
  ctx: TRttiContext;
  rtTypeInfo: TRttiType;
  rtFieldInfo: TRttiField;
  keyFound: boolean;
begin
  Clear;
  ctx := TRttiContext.Create( );
  keyFound := false;
  try
    rtTypeInfo := ctx.GetType( AObject.ClassType );
    for rtFieldInfo in rtTypeInfo.GetFields( ) do
    begin
      { Note that it is the actual field name (including "F"] thas should match }
      if SameText( rtFieldInfo.Name, AObjectFieldToUseForRowKey ) then
      begin
        RowKeyValue := rtFieldInfo.GetValue( AObject ).AsString;
        keyFound := true;
      end;
      { Remove conventional F from field name }
      if StartsText( 'F', rtFieldInfo.Name ) then
        columnName := Copy( rtFieldInfo.Name, 2, maxint )
      else
        columnName := rtFieldInfo.Name;
      case rtFieldInfo.FieldType.TypeKind of
        tkFloat: AddFloatColumn( columnName, rtFieldInfo.GetValue( AObject ).AsExtended );
        tkInteger: AddInt32Column( columnName, rtFieldInfo.GetValue( AObject ).AsInteger );
        tkInt64: AddInt64Column( columnName, rtFieldInfo.GetValue( AObject ).AsInt64 );
        tkUString, tkString, tkWString, tkLString: SetColumn( columnName, rtFieldInfo.GetValue( AObject ).AsString );
      else continue;
      end;
    end;
    if not keyFound then
      raise EAssertionFailed.CreateFmt( EXC_ROWKEY_FIELD_MISSING, [AObjectFieldToUseForRowKey] );
  finally
    ctx.Free( );
  end;
end;

end.
