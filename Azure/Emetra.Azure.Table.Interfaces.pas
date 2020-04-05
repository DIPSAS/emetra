unit Emetra.Azure.Table.Interfaces;

interface

uses
  Data.Cloud.CloudAPI,
  Data.Db;

type
  TEntityOperation = ( eoInsert, eoDelete, eoMerge, eoUpdate );

const
  ENTITY_OPERATION_NAME: array [TEntityOperation] of string = ( 'Insert', 'Delete', 'Merge', 'Update' );

type
  TEntityUpdateStrategy = ( epsUpdateThenInsert, epsInsertThenUpdate, epsInsert, epsUpdate );

type
  IDatasetPublisher = interface
    { Property accessors }
    function Get_BreakOnConflict: boolean;
    function Get_RowsPublished: integer;
    procedure Set_BreakOnConflict( const AValue: boolean );
    { Other members }
    procedure PublishDataset( const ADataset: TDataset; const ATableName: string; out ARowsAdded: integer ); overload;
    procedure PublishDataset( const ADataset: TDataset; const ATableName: string; const AUpdateStrategy: TEntityUpdateStrategy;
      const AMaxRows, AMaxErrors: integer; out AErrors: integer ); overload;
    procedure Dispose;
    procedure SetCenterId( const ACenterId: integer );
    { Properties }
    property BreakOnConflict: boolean read Get_BreakOnConflict write Set_BreakOnConflict;
    property RowsPublished: integer read Get_RowsPublished;
  end;

  IDatasetRetriever = interface
    function TryRetrieveDataset( const ACenterId: integer; const ADataset: TDataset; const ATableName: string ): boolean;
  end;

  IDatasetAddColumn = interface
    function AddColumn( const ADataset: TDataset; const AColumn: TCloudTableColumn ): TField;
  end;

type
  IAzureTableRow = interface
    { Property accessors }
    function Get_RowKeyValue: string;
    { Properties }
    property RowKeyValue: string read Get_RowKeyValue;
  end;

  IAzureTableConfig = interface
    function AccountName: string;
    function ApiKey: string;
  end;


const
  { Status codes frequently returned from the Azure table service }

  HTTP_CREATED     = 201;
  HTTP_NO_CONTENT  = 204;
  HTTP_BAD_REQUEST = 400;
  HTTP_NOT_FOUND   = 404;
  HTTP_CONFLICT    = 409;

const
  /// <comment>
  /// See: http://www.odata.org/documentation/odata-version-2-0/overview/
  /// </comment>

  EDM_NULL           = 'Null';
  EDM_BINARY         = 'Edm.Binary';
  EDM_BOOLEAN        = 'Edm.Boolean';
  EDM_BYTE           = 'Edm.Byte';
  EDM_DATETIME       = 'Edm.DateTime';
  EDM_DOUBLE         = 'Edm.Double';
  EDM_SINGLE         = 'Edm.Single';
  EDM_GUID           = 'Edm.Guid';
  EDM_INT32          = 'Edm.Int32';
  EDM_SBYTE          = 'Edm.SByte';
  EDM_STRING         = 'Edm.String';
  EDM_TIME           = 'Edm.Time';
  EDM_DATETIMEOFFSET = 'Edm.DateTimeOffset';

  { Unsupported on Azure Table }
{$IFDEF ShowUnsupported}
  EDM_DECIMAL = 'Edm.Decimal'; { Not supported on Azure Tables }
  EDM_INT16   = 'Edm.Int16';
  EDM_INT64   = 'Edm.Int64';

{$ENDIF}

implementation

end.
