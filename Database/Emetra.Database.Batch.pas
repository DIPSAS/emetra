unit Emetra.Database.Batch;

interface

uses
  Emetra.Classes.Business,
  Emetra.Database.Command,
  Emetra.Database.Interfaces,
  Emetra.Logging.Interfaces,
  Data.Db,
  Generics.Collections, System.Classes;

type
  TSqlCommandBatch = class( TBusiness, ISQLWriteOnly )
  strict private
    fAutoExecute: boolean;
    fSQL: ISQL;
    fCommands: TObjectList<TSqlCommand>;
    fBatchSize: integer;
  private
    function Get_Connected: boolean;
    function Get_ConnectionString: string;
    function Get_Count: integer;
  public
    { Initialization }
    constructor Create( ASQL: ISQL; ALog: ILog );
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    { Other members }
    function ExecuteAsync( const ASQL: string ): integer; overload;
    function ExecuteAsync( const ASQL: string; const AParams: array of Variant ): integer; overload;
    function ExecuteCommand( const ASQL: string ): integer; overload;
    function ExecuteCommand( const ASQL: string; const AParams: array of Variant ): integer; overload;
    procedure Clear;
    procedure Connect;
    procedure Disconnect;
    procedure StartBatch;
    procedure ExecuteBatch;
    procedure GetBatch( AStrings: TStrings );
    { Properties }
    property AutoExecute: boolean read fAutoExecute write fAutoExecute;
    property BatchSize: integer read fBatchSize write fBatchSize;
    property Count: integer read Get_Count;
    property ConnectionString: string read Get_ConnectionString;
  end;

implementation

uses
  System.SysUtils;

{ TSqlCommandBatch }

constructor TSqlCommandBatch.Create( ASQL: ISQL; ALog: ILog );
begin
  inherited Create( ALog );
  fSQL := ASQL;
end;

procedure TSqlCommandBatch.AfterConstruction;
begin
  inherited;
  fAutoExecute := true;
  fBatchSize := 25;
  FCommands := TObjectList<TSqlCommand>.Create( true );
end;

procedure TSqlCommandBatch.BeforeDestruction;
begin
  FreeAndNil( FCommands );
  inherited;
end;

procedure TSqlCommandBatch.Clear;
begin
  FCommands.Clear;
end;

procedure TSqlCommandBatch.Connect;
begin
  fSQL.Connect;
end;

function TSqlCommandBatch.ExecuteCommand( const ASQL: string ): integer;
begin
  FCommands.Add( TSqlCommand.Create( ASQL ) );
  Result := FCommands.Count;
end;

procedure TSqlCommandBatch.Disconnect;
begin
  fSQL.Disconnect;
end;

procedure TSqlCommandBatch.StartBatch;
begin
  Assert( Count = 0, 'Batch must be empty before starting a new one.' );
end;

procedure TSqlCommandBatch.ExecuteBatch;
var
  sqlScript: TStringList;
begin
  if FCommands.Count <> 0 then
  begin
    sqlScript := TStringList.Create;
    try
      GetBatch( sqlScript );
      fSQL.ExecuteCommand( sqlScript.Text, [] );
      FCommands.Clear;
    finally
      sqlScript.Free;
    end;
  end;
end;

function TSqlCommandBatch.ExecuteAsync( const ASQL: string ): integer;
begin
  Result := ExecuteCommand( ASQL, [] );
  if ( FCommands.Count >= fBatchSize ) and fAutoExecute then
    ExecuteBatch;
end;

function TSqlCommandBatch.ExecuteAsync( const ASQL: string; const AParams: array of Variant ): integer;
begin
  Result := ExecuteCommand( ASQL, AParams );
  if ( FCommands.Count >= fBatchSize ) and fAutoExecute then
    ExecuteBatch;
end;

function TSqlCommandBatch.ExecuteCommand( const ASQL: string; const AParams: array of Variant ): integer;
var
  n: integer;
  newCommand: TSqlCommand;
begin
  newCommand := TSqlCommand.Create( ASQL );
  n := 0;
  while n < Length( AParams ) do
  begin
    newCommand.SetParam( n, AParams[n] );
    inc( n );
  end;
  FCommands.Add( newCommand );
  Result := FCommands.Count;
end;

procedure TSqlCommandBatch.GetBatch( AStrings: TStrings );
var
  n: integer;
begin
  AStrings.BeginUpdate;
  try
    AStrings.Clear;
    n := 0;
    while n < FCommands.Count do
    begin
      AStrings.Add( FCommands[n].AsString + ';' );
      inc( n );
    end;
  finally
    AStrings.EndUpdate;
  end;
end;

function TSqlCommandBatch.Get_Connected: boolean;
begin
  Result := fSQL.Connected;
end;

function TSqlCommandBatch.Get_ConnectionString: string;
begin
  Result := fSQL.ConnectionString;
end;

function TSqlCommandBatch.Get_Count: integer;
begin
  Result := FCommands.Count;
end;

end.
