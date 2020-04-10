unit Emetra.Azure.Table.Column;

interface

uses
  Emetra.Azure.Table.Interfaces,
  {Standard}
  Generics.Collections,
  Data.Cloud.CloudAPI, Data.Db;

type
  TAzureColumnMapper = class( TInterfacedObject, IDatasetAddColumn )
  strict private
    fStringFieldSizes: TDictionary<string, integer>;
  private
    function AddColumn( const ADataset: TDataset; const AColumn: TCloudTableColumn ): TField;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

implementation

const
  MAX_STRING_LENGTH = 128;

function TAzureColumnMapper.AddColumn( const ADataset: TDataset; const AColumn: TCloudTableColumn ): TField;
var
  fieldSize: integer;
begin
  Result := ADataset.FindField( AColumn.Name );
  if not Assigned( Result ) then
  begin
    ADataset.Close;
    if AColumn.DataType = EDM_INT32 then
      Result := TIntegerField.Create( ADataset )
    else if AColumn.DataType = EDM_DATETIME then
      Result := TDateTimeField.Create( ADataset )
    else if AColumn.DataType = EDM_DOUBLE then
      Result := TFloatField.Create( ADataset )
    else
    begin
      Result := TStringField.Create( ADataset );
      if fStringFieldSizes.TryGetValue( AColumn.Name, fieldSize ) then
        Result.Size := fieldSize
      else
        Result.Size := MAX_STRING_LENGTH;
    end;
    Result.FieldName := AColumn.Name;
    Result.DataSet := ADataset;
    ADataset.Open;
  end;
end;

procedure TAzureColumnMapper.AfterConstruction;
begin
  inherited;
  fStringFieldSizes := TDictionary<string, integer>.Create;
  { The sizes are derived from SQL Azure database FastTrakDatabase }
  fStringFieldSizes.Add( 'PartitionKey', 64 );
  fStringFieldSizes.Add( 'RowKey', 64 );
end;

procedure TAzureColumnMapper.BeforeDestruction;
begin
  fStringFieldSizes.Free;
  inherited;
end;

end.
