unit Emetra.Person.Simple;

interface

uses
  Emetra.Person.Interfaces,
  Emetra.Database.Interfaces,
  {Standard}
  System.Classes, System.SysUtils;

type
  EPersonNotFoundException = class( Exception );

  TSimplePerson = class( TInterfacedPersistent, IPersonReadOnly, IPersonIdentity )
  private
    fPersonId: integer;
    fDOB: TDate;
    fSex: TSex;
    fLstName: string;
    fFstName: string;
    fNationalId: string;
    procedure Set_GenderId( const Value: integer );
    procedure Set_PersonId( const Value: integer );
  protected
    { Property accessors }
    function Get_Age: double;
    function Get_DOB: TDate;
    function Get_FirstName: string;
    function Get_FullName: string;
    function Get_GenderId: integer;
    function Get_LastName: string;
    function Get_NationalId: string;
    function Get_PersonId: integer;
    function Get_Sex: TSex;
    function Get_VisualId: string;
    { Other members }
    function ShortId: string;
    function Valid: boolean;
  public
    procedure Clear;
    procedure MapId( const ASQL: ISQL );
    { Prioerties }
    property Age: double read Get_Age;
    property DOB: TDate read Get_DOB write fDOB;
    property FirstName: string read Get_FirstName write fFstName;
    property FullName: string read Get_FullName;
    property GenderId: integer read Get_GenderId write Set_GenderId;
    property LastName: string read Get_LastName write fLstName;
    property NationalId: string read Get_NationalId write fNationalId;
    property PersonId: integer read Get_PersonId write Set_PersonId;
    property Sex: TSex read Get_Sex write fSex;
    property VisualId: string read Get_VisualId;
  end;

implementation

uses
  System.DateUtils;

resourcestring
  StrPersonNotFound = 'Fant ingen person med fødselsnummer "%s" i denne databasen.';

const
  QRY_PERSON = 'SELECT PersonId, DOB, GenderId, FstName, LstName FROM dbo.Person WHERE NationalId = :NationalId';

  { TSimplePerson }

procedure TSimplePerson.Clear;
begin
  fPersonId := 0;
  fDOB := 0;
  fSex := sexUnknown;
  fLstName := EmptyStr;
  fFstName := EmptyStr;
  fNationalId := EmptyStr;
end;

function TSimplePerson.Get_Age: double;
begin
  Result := ( Now - fDOB ) / 365.25;
end;

function TSimplePerson.Get_DOB: TDate;
begin
  Result := fDOB;
end;

function TSimplePerson.Get_FirstName: string;
begin
  Result := fFstName;
end;

function TSimplePerson.Get_FullName: string;
begin
  Result := Format( '%s, %s', [fLstName, fFstName] );
end;

function TSimplePerson.Get_GenderId: integer;
begin
  Result := ord( fSex );
end;

function TSimplePerson.Get_LastName: string;
begin
  Result := fLstName;
end;

function TSimplePerson.Get_NationalId: string;
begin
  Result := fNationalId;
end;

function TSimplePerson.Get_PersonId: integer;
begin
  Result := fPersonId;
end;

function TSimplePerson.Get_Sex: TSex;
begin
  Result := fSex;
end;

function TSimplePerson.Get_VisualId: string;
begin
  if NationalId = EmptyStr then
    Result := Format( '%s - %s %s', [DateToStr( DOB ), fFstName, fLstName] )
  else
    Result := Format( '%s - %s %s', [NationalId, fFstName, fLstName] );
end;

procedure TSimplePerson.Set_GenderId( const Value: integer );
begin
  case Value of
    1: fSex := sexMale;
    2: fSex := sexFemale;
  else fSex := sexUnknown;
  end;
end;

procedure TSimplePerson.Set_PersonId( const Value: integer );
begin
  fPersonId := Value;
end;

function TSimplePerson.ShortId: string;
begin
  //
end;

function TSimplePerson.Valid: boolean;
begin
  Result := ( fPersonId > 0 ) and ( fDOB > 0 ) and ( fLstName <> EmptyStr ) and ( fLstName <> EmptyStr );
end;

procedure TSimplePerson.MapId( const ASQL: ISQL );
begin
  { Find person in database }
  with ASQL.FastQuery( QRY_PERSON, [NationalId] ) do
    try
      fPersonId := Fields[0].AsInteger;
      fDOB := Fields[1].AsDateTime;
      GenderId := Fields[2].AsInteger;
      fFstName := Fields[3].AsString;
      fLstName := Fields[4].AsString;
      if not( PersonId > 0 ) then
        raise EPersonNotFoundException.CreateFmt( StrPersonNotFound, [NationalId] );
    finally
      Close;
    end;
end;

end.
