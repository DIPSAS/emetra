unit Emetra.Person.RandomNames;

interface

uses
  System.Classes;

const
  { ClassPatient }
  sexUnknown = 0;
  sexMale    = 1;
  sexFemale  = 2;

type
  TNameList = class( TStringList )
    procedure AddMultiple( const ANames: string );
    procedure AfterConstruction; override;
  end;

  TRandomNames = class( TObject )
  strict private
    fDoubleSurnames: boolean;
    fDoubleFirstnames: boolean;
    fBoys: TNameList;
    fGirls: TNameList;
    fSurnames: TNameList;
    fUndefined: TNameList;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function RandomSex: integer;
    function RandomName( const ASex: integer ): string;
    function RandomFirstname( const ASex: integer ): string;
    function RandomSurname: string;
    function RandomDoctor: string;
    { Properties }
    property DoubleFirstnames: boolean read fDoubleFirstnames write fDoubleFirstnames;
    property DoubleSurnames: boolean read fDoubleSurnames write fDoubleSurnames;
  end;

implementation

uses
  System.SysUtils;

{ TNameList }

procedure TNameList.AfterConstruction;
begin
  inherited;
  Duplicates := dupIgnore;
end;

procedure TNameList.AddMultiple( const ANames: string );
var
  nameList: TNameList;
begin
  nameList := TNameList.Create;
  try
    nameList.CommaText := ANames;
    while nameList.Count > 0 do
    begin
      Self.Add( nameList[0] );
      nameList.Delete( 0 );
    end;
  finally
    nameList.Free;
  end;
end;

{ TRandomNames }

procedure TRandomNames.AfterConstruction;
begin
  inherited;
  fSurnames := TNameList.Create;
  fBoys := TNameList.Create;
  fGirls := TNameList.Create;
  fUndefined := TNameList.Create;

  with fUndefined do
  begin
    AddMultiple( 'Alex,Bobby,Chris,Jone,Nicola' );
  end;

  with fBoys do
  begin
    { Guttenavn 50 på topp 2020 }
    AddMultiple( 'Jan,Per,Bjørn,Ole,Lars,Kjell,Knut,Svein,Thomas,Arne' ); // 10
    AddMultiple( 'Geir,Hans,Morten,Tor,Martin,Terje,Erik,Andreas,Odd,Anders' ); // 20
    AddMultiple( 'John,Rune,Daniel,Trond,Tore,Kristian,Marius,Jon,Magnus,Stian' ); // 30
    AddMultiple( 'Tom,Olav,Henrik,Harald,Espen,Fredrik,Øyvind,Jonas,Christian,Eirik' ); // 40
    AddMultiple( 'Gunnar,Rolf,Leif,Nils,Håkon,Helge,Einar,Steinar,Frode,Øystein' ); // 50
    { Tyske 10 på topp 1890-2006 }
    AddMultiple( 'Peter,Mikael,Thomas,Andreas,Wolfgang,Klaus,Jürgen,Günther,Stefan,Kristian' );
    { Ungarske 10 på topp }
    AddMultiple( 'László,István,József,János,Zoltán,Sándor,Ferenc,Gábor,Attila,Péter' );
    { USA 20 på topp 2018 }
    AddMultiple( 'Liam,Noah,William,James,Oliver,Benjamin,Elijah,Lucas,Mason,Logan,Alexander,Ethan,Jacob,Michal,Daniel,Henry,Jackson,Sebastian,Aiden,Matthew' );
  end;

  with fGirls do
  begin
    { Jentenavn 50 på topp 2020 }
    AddMultiple( 'Anne,Inger,Kari,Marit,Ingrid,Liv,Eva,Anna,Maria,Ida' ); // 10
    AddMultiple( 'Hilde,Berit,Nina,Marianne,Astrid,Elisabeth,Bjørg,Kristin,Randi,Solveig' ); // 20
    AddMultiple( 'Bente,Heidi,Silje,Hanne,Linda,Tone,Anita,Elin,Tove,Wenche' ); // 30
    AddMultiple( 'Gerd,Camilla,Ragnhild,Ellen,Hege,Karin,Ann,Julie,Mona,Marie' ); // 40
    AddMultiple( 'Monica,Aud,Else,Kristine,Laila,Turid,Stine,Helene,Mari,Emma' ); // 50
    { Tyske 10 på topp 1890-2006 }
    AddMultiple( 'Ursula,Karin,Helga,Sabine,Ingrid,Renate,Monika,Susanne,Gisela,Petra' );
    { Ungarske 10 på topp }
    AddMultiple( 'Mária,Erzsébet,Ilona,Katalin,Éva,Anna,Margit,Zsuzsanna,Julianna,Judit' );
    { USA 20 på topp 2018 }
    AddMultiple( 'Emma,Olivia,Ava,Isabella,Sophia,Charlotte,Mia,Amelia,Harper,Evelyn,Abigail,Emily,Elizabeth,Mila,Ella,Avery,Sofia,Camila,Aria,Scarlett' )
  end;

  with fSurnames do
  begin
    { 200 vanligste etternavn i Norge 2001 }
    AddMultiple( 'Hansen,Olsen,Johansen,Larsen,Andersen,Nilsen,Pedersen,Kristiansen,Jensen,Karlsen' );
    AddMultiple( 'Johnsen,Pettersen,Eriksen,Berg,Haugen,Hagen,Johannessen,Andreassen,Jacobsen,Dahl' );
    AddMultiple( 'Jørgensen,Henriksen,Halvorsen,Lund,Sørensen,Jakobsen,Moen,Gundersen,Iversen,Strand' );
    AddMultiple( 'Svendsen,Solberg,Martinsen,Eide,Knutsen,Paulsen,Bakken,Kristoffersen,Mathisen,Lie' );
    AddMultiple( 'Amundsen,Rasmussen,Nguyen,Lunde,Solheim,Moe,Berge,Nygård,Kristensen,Bakke' );
    AddMultiple( 'Ali,Fredriksen,Holm,Lien,Hauge,Andresen,Christensen,Nielsen,Knudsen,Evensen' );
    AddMultiple( 'Sæther,Aas,Myhre,Hanssen,Haugland,Thomassen,Sivertsen,Simonsen,Ahmed,Danielsen' );
    AddMultiple( 'Berntsen,Rønning,Sandvik,Arnesen,Næss,Antonsen,Vik,Haug,Ellingsen,Thorsen' );
    AddMultiple( 'Edvarsen,Birkeland,Isaksen,Gulbrandsen,Ruud,Aasen,Strøm,Myklebust,Tangen,Ødegård' );
    AddMultiple( 'Eliassen,Helland,Bøe,Jenssen,Aune,Mikkelsen,Tveit,Brekke,Abrahamsen,Madsen' );
    AddMultiple( 'Engen,Christiansen,Sunde,Bjerke,Mortensen,Torgersen,Thoresen,Hermansen,Mikalsen,Magnussen' );
    AddMultiple( 'Gjerde,Helgesen,Hovland,Nilssen,Wold,Bråthen,Dale,Mohamed,Nygaard,Dahle' );
    AddMultiple( 'Eilertsen,Wilhelmsen,Steen,Foss,Hassan,Bjørnstad,Håland,Jansen,Sætre,Gabrielsen' );
    AddMultiple( 'Hammer,Tran,Gustavsen,Ingebrigtsen,Hoel,Bråten,Solli,Holmen,Lorentzen,Hoff,Monsen' );
    AddMultiple( 'Breivik,Solbakken,Solvang,Fjeld,Egeland,Nordby,Sand,Aase,Jonassen,Bø' );
    AddMultiple( 'Stokke,Dalen,Bye,Johannesen,Johanson,Wiik,Andersson,Syversen,Wang,Ødegaard' );
    AddMultiple( 'Løken,Sørlie,Haga,Møller,Sandberg,Tollefsen,Ibrahim,Sande,Haaland,Viken' );
    AddMultiple( 'Teigen,Berger,Hamre,Eikeland,Kvam,Enger,Torp,Kolstad,Ottesen,Borge' );
    AddMultiple( 'Øien,Holen,Fosse,Langeland,Stene,Nikolaisen,Helle,Kvamme,Skoglund,Sletten' );

    { Vanligste etternavn i Europa }
    Add( 'Almeida' ); // Portugal
    Add( 'Andersson' ); // Sverige
    Add( 'Angelovski' ); // Makedonia
    Add( 'Bērziņš' ); // Latvia
    Add( 'Beqiri' ); // Albania
    Add( 'De Jong' ); // Nederland
    Add( 'Dimitrov' ); // Bulgaria
    Add( 'García' ); // Spania
    Add( 'Gruber' ); // Østerrike
    Add( 'Hodžić' ); // Bosnia
    Add( 'Horvat' ); // Kroatia
    Add( 'Hoxha' ); // Kosovo
    Add( 'Ivanov' ); // Belarus
    Add( 'Joensen' ); // Færøyene
    Add( 'Jones' ); // Wales
    Add( 'Jovanović' ); // Serbia
    Add( 'Kazlauskas' ); // Litauen
    Add( 'Korhonen' ); // Finland
    Add( 'Martin' ); // Frankrike
    Add( 'Melnik' ); // Ukraina
    Add( 'Murphy' ); // Irland
    Add( 'Müller' ); // Tyskland og Sveits
    Add( 'Nagy' ); // Ungarn
    Add( 'Novak' ); // Slovenia
    Add( 'Novák' ); // Tsjekkia
    Add( 'Nowak' ); // Polen
    Add( 'Peeters' ); // Belgia
    Add( 'Popescu' ); // Romania
    Add( 'Popović' ); // Montenegro
    Add( 'Rossi' ); // Italia
    Add( 'Smirnov' ); // Russland
    Add( 'Smith' ); // England og Skottland
    Add( 'Tamm' ); // Estland
    Add( 'Wilson' ); // Nord-Irland
  end;
end;

procedure TRandomNames.BeforeDestruction;
begin
  fUndefined.Free;
  fSurnames.Free;
  fGirls.Free;
  fBoys.Free;
  inherited;
end;

function TRandomNames.RandomSex: integer;
begin
  Result := Random( 20 ) mod 2 + 1;
end;

function TRandomNames.RandomFirstname( const ASex: integer ): string;
var
  firstname1: string;
  firstname2: string;
begin
  Result := EmptyStr;
  case ASex of
    sexUnknown:
      begin
        Result := fUndefined[Random( fUndefined.Count )];;
        exit;
      end;
    sexFemale:
      begin
        firstname1 := fGirls[Random( fGirls.Count )];
        firstname2 := fGirls[Random( fGirls.Count )];
      end;
    sexMale:
      begin
        firstname1 := fBoys[Random( fBoys.Count )];
        firstname2 := fBoys[Random( fBoys.Count )];
      end;
  end;
  if not fDoubleFirstnames then
    Result := firstname1
  else
  begin
    if firstname1 = firstname2 then
      Result := firstname1
    else if Random( 2 ) = 0 then
      Result := firstname2
    else
    begin
      Result := firstname1 + ' ' + firstname2;
      if Random( 5 ) = 0 then
        Result := StringReplace( Result, ' ', '-', [] );
    end;
  end;
end;

function TRandomNames.RandomSurname: string;
var
  surname1: string;
  surname2: string;
begin
  { Prepare name }
  surname1 := fSurnames[Random( fSurnames.Count )];
  if not fDoubleSurnames then
    Result := surname1
  else
  begin
    surname2 := fSurnames[Random( fSurnames.Count )];
    if surname1 = surname2 then
      Result := surname1
    else if Random( 6 ) = 0 then
      Result := surname1 + ' ' + surname2;
    if Random( 20 ) = 0 then
      Result := StringReplace( Result, ' ', '-', [] );
  end;
end;

function TRandomNames.RandomName( const ASex: integer ): string;
begin
  Result := RandomSurname + ', ' + RandomFirstname( ASex );
end;

function TRandomNames.RandomDoctor: string;
begin
  Result := Format( 'DR%d', [Random( 8 ) + 1] );
end;

end.
