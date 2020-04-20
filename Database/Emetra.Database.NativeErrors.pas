unit Emetra.Database.NativeErrors;

interface

uses
  Generics.Collections,
  Data.Db;

type
  /// <summary>
  /// This exception is raised when a user defined RAISERROR event is created
  /// on the database server, typically in a stored procedure.
  /// </summary>
  EDatabaseUserDefinedError = class( EDatabaseError );

  /// <summary>
  /// <para>
  /// This exception is raised when the native error on the MS SQL
  /// database server corresponds to a privilege error. To get the
  /// messages from SQL Server that matches the current set, run this
  /// query:
  /// </para>
  /// <para>
  /// <c>SELECT * FROMsys.messages WHERE message_id IN (229,230,262,300)
  /// AND language_id = 1033</c>.
  /// </para>
  /// </summary>
  EDatabasePrivilegeError = class( EDatabaseError );

  /// <summary>
  /// Base class for native error dictionaries.
  /// </summary>
  TNativeErrorList = class( TDictionary<integer, string> )
    function Includes( const ANativeError: integer ): boolean;
  end;

  /// <summary>
  /// Contains native errors that should generate a EDatabasePrivilegeError
  /// exception. This list is not complete, but it covers the most common
  /// scenarios.
  /// </summary>
  /// <remarks>
  /// <para>
  /// To get error messages from SQL Server, run this query:
  /// </para>
  /// <para>
  /// <c>SELECT * FROM sys.messages WHERE text LIKE '%permiss%deni%' AND
  /// language_id = 1033</c>
  /// </para>
  /// </remarks>
  TPrivilegeErrors = class( TNativeErrorList )
  public
    procedure AfterConstruction; override;
  end;

const
  /// <summary>
  /// Defines the starting point for user defined errors in MS SQL Server.
  /// </summary>
  ERR_USER_DEFINED_START = 50000;

implementation

{ TErrorList }

function TNativeErrorList.Includes( const ANativeError: integer ): boolean;
begin
  Result := ContainsKey( ANativeError );
end;

{ TPrivilegeErrors }

procedure TPrivilegeErrors.AfterConstruction;
begin
  inherited;
  Add( 229, 'Tillatelsen ble avslått for objektet i databaseskjemaet.' );
  Add( 230, 'Tillatelsen ble avslått for kolonnen.' );
  Add( 262, 'Tillatelse avslått i database i databasen.' );
  Add( 300, 'Tillatelse ble avslått for objektet i databasen' );
  Add( 1971, 'Kan ikke deaktivere indeks på tabellen. Ingen tilgang til å deaktivere sekundærnøkkel på tabellen som bruker denne indeksen.' );
  Add( 1972 'Kan ikke deaktivere gruppert indeks på tabellen. Ingen tilgang til å endre den refererende visningen samtidig som den grupperte indeksen deaktiveres.' );
  Add( 1972 'Kan ikke deaktivere den grupperte indeksen på tabellen. Ingen tilgang til å deaktivere sekundærnøkkel på tabellen som refererer til denne tabellen.' );
end;

end.
