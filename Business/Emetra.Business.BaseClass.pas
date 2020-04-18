unit Emetra.Business.BaseClass;

interface

uses
  {General interfaces}
  Emetra.Logging.Interfaces,
  {Standard}
  System.Classes, System.Generics.Collections;

type
  /// <summary>
  /// Business objects are lightweight objects that can be used as base classes
  /// for more complex objects that contain business logic. Typically they
  /// are not used for smaller data objects with limited scope. Data objects may not
  /// need a logger, and they usually don't need to implement interfaces. More
  /// complex data objects like <b>TPatient</b> in an EHR application may
  /// need both of these. Because TCustomBusiness inherits from <b>TInterfacedPersistent</b> (a
  /// standard RTL class) it is not reference counted and must be freed when
  /// it is no longer used. If it it is added to a <b>TBusinessObjectCatalog</b>,
  /// the lifetime and destruction is handled by the catalog.
  /// </summary>
  /// <remarks>
  /// All TCustomBusiness descendants need to have a logger injected upon
  /// construction.
  /// </remarks>
  /// <seealso cref="TBusinessObjectCatalog" />
  TCustomBusiness = class( TInterfacedPersistent )
  strict private
    fLog: ILog;
  protected
    procedure CheckAssigned( const AInterface: IInterface; const ANameOfInterface: string );
    procedure EnterMethod( const AProcName: string );
    procedure LeaveMethod( const AProcName: string );
    procedure VerifyConstructorParameters; dynamic;
  public
    { Initialization }
    constructor Create( const ALog: ILog ); reintroduce;
    { Properties }
    property Log: ILog read fLog;
  end;

implementation

uses
  System.SysUtils;

constructor TCustomBusiness.Create( const ALog: ILog );
begin
  inherited Create;
  fLog := ALog;
end;

procedure TCustomBusiness.EnterMethod( const AProcName: string );
begin
  fLog.EnterMethod( Self, AProcName );
end;

procedure TCustomBusiness.LeaveMethod( const AProcName: string );
begin
  fLog.LeaveMethod( Self, AProcName );
end;

procedure TCustomBusiness.VerifyConstructorParameters;
begin
  CheckAssigned( fLog, 'Log' );
end;

procedure TCustomBusiness.CheckAssigned( const AInterface: IInterface; const ANameOfInterface: string );
const
  PROC_NAME = 'CheckAssigned';
  ERR_MSG   = LOG_STUB_STRING + 'The interface is not assigned.';
var
  errorMessage: string;
begin
  if not Assigned( AInterface ) then
  begin
    errorMessage := Format( ERR_MSG, [ClassName, PROC_NAME, ANameOfInterface] );
    if Assigned( fLog ) then
      fLog.SilentError( errorMessage )
    else if Assigned( GlobalLog ) then
      GlobalLog.SilentError( errorMessage );
    raise EArgumentNilException.Create( errorMessage );
  end;
end;

{$ENDREGION}

end.
