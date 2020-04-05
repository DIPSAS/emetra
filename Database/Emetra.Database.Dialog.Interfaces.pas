unit Emetra.Database.Dialog.Interfaces;

interface

uses
  Emetra.Database.Interfaces,
  Emetra.Logging.Interfaces,
  {General classes}
  System.Classes, System.Contnrs;

type
  { Dialog boxes must support these interfaces }

  IDatabaseLoginDialog = interface
    ['{12FEE87B-826F-4FB0-BECC-FE253517539A}']
    function Login( var AUsername, APassword: string ): boolean;
  end;

  IDatabasePickList = interface
    ['{928994A6-C604-40B8-A4B0-2E138376B2A9}']
    { Other members }
    function SelectInteger( const AQuery: string; const AParams: array of Variant; const AHeader, AText, AEmptyMsg: string; const AutoSelectSingle: boolean = true;
      const AMissingLevel: TLogLevel = ltMessage ): Integer; overload;
    function SelectInteger( const AQuery: string; const AParams: array of Variant; const AHeader, AText: string ): Integer; overload;
    function SelectString( const AQuery: string; const AParams: array of Variant; const AHeader, AText, AEmptyMsg: string; const AutoSelectSingle: boolean = true;
      const AMissingLevel: TLogLevel = ltMessage ): string; overload;
    function SelectString( const AHeader, AText: string; AItems: TStrings ): string; overload;
    function SelectInteger( const AHeader, AText: string; AItems: TStrings ): Integer; overload;
    function TrySelectInteger( const AQuery: string; const AParams: array of Variant; const AHeader, AText: string; out ASelected: Integer ): boolean;
    function TrySelectObject( const AHeader, AText: string; AItems: TObjectList; out ASelectedObject: TObject ): boolean;
    function TryGetFieldValue( const AFieldName: string; out AValue: string ): boolean; overload;
    function TryGetFieldValue( const AFieldName: string; out AValue: Integer ): boolean; overload;
  end;

  IAddUserDialog = interface
    ['{137396B4-A516-4391-A3DA-175B62611422}']
    { Property accessors }
    function Get_UserName: string;
    function Get_Password: string;
    { Other members }
    procedure AddUser( Sender: TObject );
    function Success: boolean;
    { Properties }
    property UserName: string read Get_UserName;
    property Password: string read Get_Password;
  end;

  IChangePasswordDialog = interface
    ['{D2CBE02E-B60F-4E62-B31C-B862F2574974}']
    { Property accessors }
    function Get_Password: string;
    function Success: boolean;
    { Other members }
    procedure ChangePassword( Sender: TObject );
    { Properties }
    property Password: string read Get_Password;
  end;

var
  GlobalPickList: IDatabasePickList = nil;

implementation

end.
