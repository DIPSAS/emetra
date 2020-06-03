unit Emetra.Person.Interfaces;

interface

uses
  System.SysUtils;

type
  { Genders }
  TSex = ( sexUnknown, sexMale, sexFemale );
  TSexSet = set of TSex;

  EPersonNationalIdRequired = class( EAbort );

  { Demographics editing mode }
  TPersonEditMode = ( emNone, emAddPerson, emEditPerson );

  IPersonId = interface
    ['{87317160-5617-485F-BC32-77DDFC7EBC04}']
    { Property accessors }
    function Get_PersonId: Integer;
    { Other members }
    property PersonId: Integer read Get_PersonId;
  end;

  IPersonIdentity = interface( IPersonId )
    ['{978E986F-9DD0-44DB-8504-F8BC1B1CE0FF}']
    { Property Accessors }
    function Get_DOB: TDate;
    function Get_NationalId: string;
    function Get_PersonId: Integer;
    function Get_Sex: TSex;
    { Properties }
    property DOB: TDate read Get_DOB;
    property NationalId: string read Get_NationalId;
    property PersonId: Integer read Get_PersonId;
    property Sex: TSex read Get_Sex;
  end;

  IPersonIdentityObserver = interface
    ['{D0A7C9DB-F3BC-4196-87A6-737932EA0F67}']
    procedure AfterUpdate( APerson: IPersonIdentity );
  end;

  IPersonReadOnly = interface( IPersonIdentity )
    ['{C2458FA3-50A0-411B-BC10-E4B88EF59E42}']
    { Property accessors }
    function Get_FirstName: string;
    function Get_FullName: string;
    function Get_GenderId: Integer;
    function Get_LastName: string;
    function Get_VisualId: string;
    { Other members }
    function ShortId: string;
    function Valid: boolean;
    { Properties }
    property FirstName: string read Get_FirstName;
    property FullName: string read Get_FullName;
    property GenderId: Integer read Get_GenderId;
    property LastName: string read Get_LastName;
    property VisualId: string read Get_VisualId;
  end;

  IPersonDead = interface['{3F9B2C5F-981B-4BA7-BEED-985A64774004}']
    function IsDead: boolean;
    function DeathDate: TDate;
  end;

  IPersonVisualId = interface
    ['{2C31AE8F-CD32-4490-AEE3-CE2E65932BBB}']
    { Property accessors }
    function Get_VisualId: string;
    { Properties }
    property VisualId: string read Get_VisualId;
  end;

  IPerson = interface( IPersonReadOnly )
    ['{4668C6B3-9211-427C-9D5F-0E08389688AF}']
    { Property accessors }
    function Get_Age: double;
    function Get_PersonId: Integer;
    function Get_SexStr: string;
    procedure Set_DOB( const AValue: TDate );
    procedure Set_FirstName( const AValue: string );
    procedure Set_FullName( const AValue: string );
    procedure Set_GenderId( const AValue: Integer );
    procedure Set_LastName( const AValue: string );
    procedure Set_NationalId( const AValue: string );
    procedure Set_PersonId( const AValue: Integer );
    { Other members }
    function TryGetValue( const AVarName: string; var AValue: Variant ): boolean;
    procedure Clear;
    procedure SetAddress( const AStreet, APostCode, ACity: string );
    { Properties }
    property Age: double read Get_Age;
    property DOB: TDate read Get_DOB write Set_DOB;
    property FirstName: string read Get_FirstName write Set_FirstName;
    property FullName: string read Get_FullName write Set_FullName;
    property GenderId: Integer read Get_GenderId write Set_GenderId;
    property LastName: string read Get_LastName write Set_LastName;
    property NationalId: string read Get_NationalId write Set_NationalId;
    property PersonId: Integer read Get_PersonId write Set_PersonId;
    property SexStr: string read Get_SexStr;
  end;

  IPersonList = interface
    ['{2CCFDBFA-19CB-4BC1-838E-DAA401B15C70}']
    { Property accessors }
    function Get_Count: Integer;
    function Get_Name: string;
    function Get_Person( AIndex: Integer ): IPersonReadOnly;
    function Get_Usable: boolean;
    { Other members }
    function Search( const ASearchText: string ): Integer;
    { Properties }
    property Person[AIndex: Integer]: IPersonReadOnly read Get_Person;
    property Count: Integer read Get_Count;
    property Name: string read Get_Name;
    property Usable: boolean read Get_Usable;
  end;

  IPersonFinder = interface
    ['{0E4CAAC2-B7E2-4742-B8C8-DC9E3BE85CA4}']
    function TryFindPerson( Sender: TObject; out APersonId: Integer ): boolean;
    procedure SelectPerson( Sender: TObject );
  end;

  IPersonDuplicateManager = interface
    ['{C2F28B8B-ABA0-4BCA-9852-BA673C260773}']
    function MustBeSamePerson( const APerson1, APerson2: IPersonReadOnly ): boolean;
    function ProbablySamePerson( const APerson1, APerson2: IPersonReadOnly ): boolean;
    function UserConfirmedSamePerson( const APerson1, APerson2: IPersonReadOnly ): boolean;
  end;

  IPersonIdentityMapper = interface
    ['{3A70BDDC-CEF0-49AE-9151-3817B97D8AA3}']
    function TryMapDOBName( const ADOB: TDateTime; const AFirstName, ALastName: string; out APersonId: Integer ): boolean;
    function TryMapNationalId( const ANationalId: string; out APersonId: Integer ): boolean;
  end;

  IPersonListManager = interface( IPersonDuplicateManager )
    ['{C8A97FC3-2BAD-4086-8DBD-CC2656261218}']
    { Exact matching }
    function TryMapDOBName( const ADOB: TDateTime; const AFirstName, ALastName: string; out APersonId: Integer ): boolean;
    function TryMapNationalId( const ANationalId: string; out APersonId: Integer ): boolean;
    function TryMapUserName( const AUserName: string; out APersonId: integer ): boolean;
    { Add and edit }
    function AddPerson( const APerson: IPersonReadOnly ): Integer; overload;
    function AddPerson( const ADOB: TDateTime; const AGenderId: Integer; const AFirstName, ALastName, ANationalId: string ): Integer; overload;
    procedure EditPerson( const APersonId: Integer; ADOB: TDateTime; AGenderId: Integer; AFirstName, ALastName, ANationalId: string );
    { Fuzzy matching copied from IPersonDuplicateManager }
    function MustBeSamePerson( const APerson1, APerson2: IPersonReadOnly ): boolean;
    function ProbablySamePerson( const APerson1, APerson2: IPersonReadOnly ): boolean;
    function UserConfirmedSamePerson( const APerson1, APerson2: IPersonReadOnly ): boolean;
  end;

  IActiveCaseObserver = interface
    ['{D0A7C9DB-F3BC-4196-87A6-737932EA0F67}']
    procedure LoadActiveCaseData( APerson: IPersonId );
  end;

  IActiveCaseCloseObserver = interface
    ['{1BC26D8C-8C40-4C38-9A3A-097FE6B3A044}']
    procedure SaveActiveCaseData( APerson: IPersonId );
  end;

function SexToStr( const ASex: TSex ): string;

const
  { Regular expressions for searching in a list of persons }
  RGX_DATE              = '^(\d{6}|\d{2}\.\d{2}\.\d{2,4})';
  RGX_VALID_DOB         = RGX_DATE + '$';
  RGX_VALID_NATIONAL_ID = '^\d{11}$';
  RGX_MOBILE_PHONE      = '^\d{8}$';
  RGX_NAME              = '(\p{L}+(\-\p{L}+)*)';
  RGX_TWO_NAMES         = RGX_NAME + '\s+' + RGX_NAME;
  RGX_DOB_AND_NAME      = RGX_DATE + '\s+' + RGX_NAME + '$';
  RGX_DOB_AND_TWO_NAMES = RGX_DATE + '\s+' + RGX_TWO_NAMES + '$';

resourcestring

  StrMaleGender = 'Mann';
  StrFemaleGender = 'Kvinne';
  StrUnknownGender = 'Uspesifisert';

implementation

function SexToStr( const ASex: TSex ): string;
begin
  case ASex of
    sexMale: Result := StrMaleGender;
    sexFemale: Result := StrFemaleGender;
  else Result := StrUnknownGender;
  end;
end;

end.
