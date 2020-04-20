unit Emetra.Database.Interfaces;

interface

uses
  {General interfaces}
  Emetra.Logging.Interfaces,
  Emetra.Person.Interfaces,
  {Standard}
  System.Classes, System.Contnrs, Data.Db, System.SysUtils;

type
  { Exception raised when a the user canceled a login dialog }
  EDatabaseLoginCancelled = class( EAbort );

  { Normal runtime exceptions }
  EDatabaseCommandFailed = class( EDatabaseError );
  EDatabaseQueryFailed = class( EDatabaseError );

  /// <summary>
  ///   This exception should be raised when the database facade object tries
  ///   to call a ILoginObserver's AfterLogin method, but this causes an
  ///   exception. This can be because some submodule is unconfigured, doesn't
  ///   have permissions for some operations etc. It can not be classified as
  ///   an EDatabaseError, as it could be other reasons why this happens (e.g.
  ///   disabled module etc).
  /// </summary>
  EDatabaseLoginObserverError = class( Exception );

  { Exceptions that should be caught during development }
  /// <summary>
  ///   This exception is generated when a client attempts to run a query or a
  ///   command against the database when
  /// </summary>
  EDatabaseImplicitConnectError = class( EAssertionFailed );
  /// <summary>
  ///   This exception is thrown when parameters to a query or command is not
  ///   properly configured.
  /// </summary>
  EDatabaseParameterError = class( EAssertionFailed );
  /// <summary>
  ///   This exception is thrown when the database connection can not be
  ///   established, because there is no single-sign-on, and username/login or
  ///   other types of credentials can not be found.
  /// </summary>
  EDatabaseCredentialsMissing = class( EAssertionFailed );

  /// <summary>
  ///   This corresponds to a subset of <see href="https://docs.microsoft.com/en-us/sql/t-sql/functions/object-definition-transact-sql?view=sql-server-ver15">
  ///   MS SQL Object Types</see>.
  /// </summary>
  TDbObjectType = (
    /// <summary>
    ///   U = Table (user-defined)
    /// </summary>
    otUserTable,
    /// <summary>
    ///   V = View
    /// </summary>
    otView,
    /// <summary>
    ///   FN = SQL scalar function
    /// </summary>
    otScalarFunction,
    /// <summary>
    ///   P = SQL Stored Procedure
    /// </summary>
    otStoredProcedure,
    /// <summary>
    ///   F = FOREIGN KEY constraint
    /// </summary>
    otForeignKeyConstraint,
    /// <summary>
    ///   A table valued function, which is a function that returns a table
    ///   instead of a scalar value.
    /// </summary>
    otTableValuedFunction,
    /// <summary>
    ///   SN = Synonym. A synonym to some other object, which can be of any
    ///   type.
    /// </summary>
    otSynonym );

  /// <summary>
  ///   An event signature to be triggered when a combination of username and
  ///   password is needed. An event handler can present a dialogue to the
  ///   user, read this from the registry etc. based on the needs of the
  ///   applicaton.
  /// </summary>
  TOnPasswordEvent = function( var AUsername, APassword: string ): boolean of object;

  IDatabaseConnectionString = interface
    ['{8174CF1E-3D9B-4EEF-992C-D5AEC1C3AC8C}']
    { Accessors }
    function Get_ConnectionString: string;
    procedure Set_ConnectionString( Value: string );
    { Properties }
    property ConnectionString: string read Get_ConnectionString write Set_ConnectionString;
  end;

  IDatabaseConnection = interface
    ['{F944444D-6FEE-46F3-AB00-BE2521EC7AE5}']
    { Accessors }
    function Get_ConnectionString: string;
    function Get_Connected: boolean;
    { Other members }
    procedure Connect;
    procedure Disconnect;
    property ConnectionString: string read Get_ConnectionString;
    property Connected: boolean read Get_Connected;
  end;

  ILoginObserver = interface
    ['{47CF1A13-91C9-414F-868B-3630FB2586A2}']
    procedure AfterLogin( Sender: IDatabaseConnection );
    function GetNamePath: string;
    function FriendlyName: string;
  end;

  IObservableDatabase = interface
    ['{0C078096-1218-4E96-8E8F-DB98F05F25AE}']
    procedure AddLoginObserver( AObserver: ILoginObserver );
    procedure RemoveLoginObserver( AObserver: ILoginObserver );
  end;

  IDatabaseAddUser = interface
    ['{6398B958-9DB5-47D8-9801-1DEED5D219E2}']
    procedure AddUser( const AUsername, APassword: string );
  end;

  IDatabaseChangePassword = interface
    ['{0A309176-F937-4B0B-9351-D2123B96ADCD}']
    function TryChangePassword( const AOldPassword, ANewPassword: string; out AErrorMessage: string ): boolean;
    function CanChangePassword: boolean;
  end;

  IDatabaseLoginContext = interface
    ['{49A6B91F-3186-4FCF-8B0C-02A00E602E66}']
    { Accessors }
    function Get_ConnectionString: string;
    function Get_UserName: string;
    function Get_Password: string;
    { Other methods }
    property Password: string read Get_Password;
    property UserName: string read Get_UserName;
    property ConnectionString: string read Get_ConnectionString;
  end;

  IDatabaseUser = interface( IPersonReadOnly )
    ['{338F0CCD-2436-4926-8DC7-DEC86463A85A}']
    { Accessors }
    function Get_UserId: Integer;
    function Get_UserName: string;
    { Other members }
    function AddUser( const AUsername, APassword: string ): boolean;
    procedure Clear;
    procedure Populate;
    { Properties }
    property UserId: Integer read Get_UserId;
    property UserName: string read Get_UserName;
  end;

  ISimpleDatabase = interface( IDatabaseLoginContext )
    ['{2713F75C-2FBE-4551-AE3A-4EBFC829CA2A}']
    { Accessors }
    function Get_Dataset: TDataset;
    function Get_OnLogin: TOnPasswordEvent;
    function Get_User: IDatabaseUser;
    procedure Set_OnLogin( AOnPassword: TOnPasswordEvent );
    { Other methods }
    function Connect( AUser: IDatabaseUser; AConnectionString: string ): boolean;
    function Connected: boolean;
    function Connection: TObject;
    function ExecuteCommand( const ASQL: string ): Integer; overload;
    function ExecuteCommand( const ASQL: string; const AParams: array of Variant ): Integer; overload;
    function FastQuery( const ASQL: string ): TDataset; overload;
    function FastQuery( const ASQL: string; const AParams: array of Variant ): TDataset; overload;
    procedure Disconnect;
    { Properties }
    property OnPassword: TOnPasswordEvent read Get_OnLogin write Set_OnLogin;
    property User: IDatabaseUser read Get_User;
    property Dataset: TDataset read Get_Dataset;
  end;

  ICheckPermissionProblem = interface
    ['{15C4AE37-980C-4192-B963-8E3C5C3D78D0}']
    procedure CheckPermissionProblem( const E: Exception; const AMsgTemplate: string );
  end;

  IDatabaseScript = interface
    ['{BBA10392-6943-4EAD-ACE3-516704AA0C62}']
    procedure ExecuteScript( const AFileName, ATransName: string );
  end;

  IDatabaseName = interface
    ['{74246387-0269-4EB9-A9E3-D03E979048B4}']
    { Accessors }
    function Get_DbName: string;
    function Get_HostName: string;
    { Properties }
    property DbName: string read Get_DbName;
    property HostName: string read Get_HostName;
  end;

  IDatabaseInfo = interface
    ['{8AC118E8-5929-4013-9197-59E173263CF8}']
    { Property Accessors }
    function Get_Collation: string;
    function Get_DbName: string;
    function Get_DbVersion: Integer;
    function Get_EventScale: Integer;
    function Get_ServerName: string;
    function Get_ServerVersion: string;
    { Other members }
    property Collation: string read Get_Collation;
    property DbName: string read Get_DbName;
    property DbVersion: Integer read Get_DbVersion;
    property EventScale: Integer read Get_EventScale;
    property ServerName: string read Get_ServerName;
    property ServerVersion: string read Get_ServerVersion;
  end;

  IDatabaseUpgrade = interface
    ['{C9EE5380-F43E-4F59-A1A5-1F567C60555C}']
    procedure UpgradeDatabase( const ADesiredVersion: Integer; const ASkipConfirmation: boolean );
  end;

  ISQLWriteOnly = interface( IDatabaseConnection )
    function ExecuteAsync( const ASQL: string ): Integer; overload; overload;
    function ExecuteAsync( const ASQL: string; const AParams: array of Variant ): Integer; overload;
    function ExecuteCommand( const ASQL: string ): Integer; overload;
    function ExecuteCommand( const ASQL: string; const AParams: array of Variant ): Integer; overload;
  end;

  ISQLBatch = interface( ISQLWriteOnly )
    ['{F986BA61-499B-4C6F-ABA0-A9BF5C3F2D13}']
    procedure StartBatch;
    procedure ExecuteBatch;
  end;

  ISQLReadOnly = interface
    ['{4D6B1482-C6B9-40E7-B90E-AE2B36A2F94B}']
    function FastQuery( const ASQL: string ): TDataset; overload;
    function FastQuery( const ASQL: string; const AParams: array of Variant ): TDataset; overload;
  end;

  ISQL = interface( IDatabaseConnection )
    ['{217F1F15-D8EC-4591-A608-E0199A28FB32}']
    { Property accesors }
    function Get_Dataset: TDataset;
    { Other members }
    function ExecuteAsync( const ASQL: string ): Integer; overload;
    function ExecuteAsync( const ASQL: string; const AParams: array of Variant ): Integer; overload;
    function ExecuteCommand( const ASQL: string ): Integer; overload;
    function ExecuteCommand( const ASQL: string; const AParams: array of Variant ): Integer; overload;
    function FastQuery( const ASQL: string ): TDataset; overload;
    function FastQuery( const ASQL: string; const AParams: array of Variant ): TDataset; overload;
    { POroperties }
    property Dataset: TDataset read Get_Dataset;
  end;

  IMultipleRecordsets = interface
    ['{D2298BEE-3BBA-4DA8-9C12-1DD534933EC0}']
    function Get_Dataset: TDataset;
    property Dataset: TDataset read Get_Dataset;
    function NextRecordset: boolean;
  end;

  IMSSQL = interface( ISQL )
    ['{9352202B-6E3A-43AE-9A54-12D3B9155BF6}']
    function Get_NativeError: Integer;
    function GetMultipleRecordsets( const AProcName: string; const AParams: array of Variant ): IMultipleRecordsets;
    property NativeError: Integer read Get_NativeError; { Returns last native error }
  end;

  ITransactions = interface
    ['{45B88F9E-2C37-4EE9-B5D7-7A55BED648CE}']
    procedure BeginTrans( const ATransName: string );
    procedure CommitTrans( const ATransName: string );
    procedure RollbackTrans( const ATransName: string );
  end;

  IDatabaseUserManager = interface
    ['{5A7CFE82-7D2A-43C1-A5A0-68E887BE0A89}']
    procedure AddUser( Sender: TObject );
    procedure ManageDatabaseUsers( Sender: TObject );
  end;

implementation

end.
