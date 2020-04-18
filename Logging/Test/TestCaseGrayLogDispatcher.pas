unit TestCaseGrayLogDispatcher;

interface

uses
  TestFramework, IdUdpClient,
  {General classes}
  Emetra.Logging.Target.GrayLog,
  Emetra.Logging.PlainText.LogItem,
  {General interfaces}
  Emetra.Logging.Target.Interfaces,
  Emetra.Logging.LogItem.Interfaces,
  Emetra.Logging.Target.GrayLog.Interfaces,
  {Standard}
  System.RegularExpressions, System.Generics.Collections, System.Inifiles, System.Classes;

type
  TestTGrayLogDispatcher = class( TTestCase )
  strict private
    fGrayLog: IGrayLogDispatcher;
  private
    procedure TestSendText( const AText: string );
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestMatchExecuteStatement;
    procedure TestMatchObjectName;
    procedure TestMatchSelectStatement;
    procedure TestSendAnonymizedText;
    procedure TestSendExecuteStatement;
    procedure TestSendKeyValueData;
    procedure TestSendRandomNumber;
    procedure TestSendSelectStatement;
  end;

implementation

uses
  Emetra.Logging.Interfaces,
  System.SysUtils;

const
  DEFAULT_GRAYLOG_SERVER = 'graylog.dips.no';

procedure TestTGrayLogDispatcher.SetUp;
begin
  Randomize;
  fGrayLog := TGrayLogDispatcher.Create( DEFAULT_GRAYLOG_SERVER, DEFAULT_GRAYLOG_PORT, true );
end;

procedure TestTGrayLogDispatcher.TearDown;
begin
  fGrayLog := nil;
end;

procedure TestTGrayLogDispatcher.TestMatchExecuteStatement;
begin
  CheckTrue( TRegEx.IsMatch( 'EXEC AddPerson ', RGX_STORED_PROCEDURE, [roIgnoreCase] ), 'Skal matche prosedyre uten dot' );
  CheckTrue( TRegEx.IsMatch( 'EXEC dbo.AddPerson ', RGX_STORED_PROCEDURE, [roIgnoreCase] ), 'Skal matche prosedyre med dot' );
  CheckTrue( TRegEx.IsMatch( 'EXEC  AddPerson  :a,:b,:c ', RGX_STORED_PROCEDURE, [roIgnoreCase] ), 'Skal matche med flere space' );
end;

procedure TestTGrayLogDispatcher.TestMatchObjectName;
begin
  CheckTrue( TRegEx.IsMatch( ' Person ', RGX_DB_OBJECT, [roIgnoreCase] ), 'Skal matche tabellnavn uten dot' );
  CheckTrue( TRegEx.IsMatch( ' dbo.PersonNavn ', RGX_DB_OBJECT, [roIgnoreCase] ), 'Skal matche tabellnavn med dot' );
  CheckFalse( TRegEx.IsMatch( ' 1dbo.PersonNavn ', RGX_DB_OBJECT, [roIgnoreCase] ), 'Skal ikke matche når første del begynner med et tall' );
  CheckTrue( TRegEx.IsMatch( ' dbo.PersonNøvn ', RGX_DB_OBJECT, [roIgnoreCase] ), 'Skal egentlig ikke matche nasjonale tegn, men vanskelig å unngå' );
end;

procedure TestTGrayLogDispatcher.TestMatchSelectStatement;
begin
  CheckTrue( TRegEx.IsMatch( 'SELECT * FROM Person ', RGX_SELECT_STATEMENT, [roIgnoreCase] ), 'Skal matche tabellnavn uten dot' );
  CheckTrue( TRegEx.IsMatch( 'SELECT * FROM dbo.Person ', RGX_SELECT_STATEMENT, [roIgnoreCase] ), 'Skal matche tabellnavn med dot' );
  CheckTrue( TRegEx.IsMatch( 'SELECT  *  FROM  Person ', RGX_SELECT_STATEMENT, [roIgnoreCase] ), 'Skal matche med flere space' );
  CheckTrue( TRegEx.IsMatch( 'SELECT  a,b,c  FROM  Person ', RGX_SELECT_STATEMENT, [roIgnoreCase] ), 'Skal matche med feltnavn' );
end;

procedure TestTGrayLogDispatcher.TestSendAnonymizedText;
begin
  TestSendText( 'Sender inn {{Roland Gundersen}} som skal anonymiseres.' );
end;

procedure TestTGrayLogDispatcher.TestSendExecuteStatement;
begin
  TestSendText( 'EXEC dbo.SendExecuteStatement :PersonId, (22ms).' );
end;

procedure TestTGrayLogDispatcher.TestSendKeyValueData;
begin
  { Norske tegn er ikke gyldige som feltnavn i GrayLog, men det er ikke vårt problem her }
  TestSendText( 'M2M="Marit og Marion", Fornavn= Ærlend, Etternavn =Sørgård, Født="15.07.1965", Personnummer = "{{15076500565}}", År=76år, Alder=76' );
end;

procedure TestTGrayLogDispatcher.TestSendRandomNumber;
begin
  TestSendText( Format( 'Some random number you can recognize: 0x%x', [Random( maxint )] ) );
end;

procedure TestTGrayLogDispatcher.TestSendSelectStatement;
begin
  TestSendText( 'SELECT * FROM dbo.Person WHERE PersonId=1' );
end;

procedure TestTGrayLogDispatcher.TestSendText( const AText: string );
var
  LogItem: TLogItem;
begin
  LogItem := TLogItem.Create( 0, AText, ltInfo );
  try
    fGrayLog.Send( LogItem );
  finally
    LogItem.Free;
  end;
end;

initialization

// Register any test cases with the test runner
RegisterTest( TestTGrayLogDispatcher.Suite );

end.
