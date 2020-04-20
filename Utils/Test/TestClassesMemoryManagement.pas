unit TestClassesMemoryManagement;

interface

uses
  Emetra.Logging.Interfaces,
  System.Classes;

type
  TImmortalInterfacedObject = class( TObject, IUnknown )
  protected
    { IInterface }
    function _AddRef: integer; stdcall;
    function _Release: integer; stdcall;
  public
    function QueryInterface( const IID: TGUID; out Obj ): HResult; virtual; stdcall;
    function RefCount: integer;
  end;

  TClientObject = class( TComponent )
  strict private
    fLog: ILog;
  public
    constructor Create( const ALog: ILog ); reintroduce;
    procedure UseStandardParam( AInterface: IInterface );
    procedure UseConstParam( const AInterface: IInterface );
    procedure UseConstParamAndDoNothing( const AInterface: IInterface );
  end;

implementation

uses
  System.Types;

{ TImmortalInterfacedObject }

function TImmortalInterfacedObject.QueryInterface( const IID: TGUID; out Obj ): HResult;
const
  E_NOINTERFACE = HResult( $80004002 );
begin
  if GetInterface( IID, Obj ) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TImmortalInterfacedObject.RefCount: integer;
begin
  Result := -1;
end;

function TImmortalInterfacedObject._AddRef: integer;
begin
  Result := -1;
end;

function TImmortalInterfacedObject._Release: integer;
begin
  Result := -1;
end;

{ TClientObject }

constructor TClientObject.Create( const ALog: ILog );
begin
  inherited Create( nil );
  fLog := ALog;
end;

procedure TClientObject.UseStandardParam( AInterface: IInterface );
var
  RefCount: integer;
begin
  AInterface._AddRef;
  RefCount := AInterface._Release;
  fLog.Event( 'Class %s has %d bytes, RefCount=%d (standard parameter)', [TObject( AInterface ).ClassName, TObject( AInterface ).InstanceSize, RefCount] );
end;

procedure TClientObject.UseConstParam( const AInterface: IInterface );
var
  RefCount: integer;
begin
  AInterface._AddRef;
  RefCount := AInterface._Release;
  fLog.Event( 'Class %s has %d bytes, RefCount=%d (const parameter)', [TObject( AInterface ).ClassName, TObject( AInterface ).InstanceSize, RefCount] );
end;

procedure TClientObject.UseConstParamAndDoNothing( const AInterface: IInterface );
begin
  fLog.Event( 'Class %s has %d bytes, (const parameter, doing nothing)', [TObject( AInterface ).ClassName, TObject( AInterface ).InstanceSize] );
end;

end.
