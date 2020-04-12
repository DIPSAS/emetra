unit TestCaseLinkClassifier;

interface

uses
  Emetra.Logging.Interfaces,
  Emetra.Command.LinkClassifier,
  DUnitX.TestFramework,
  System.Classes;

type

  [TestFixture]
  TTestClassLinkParser = class( TObject )
  private
    fLinkParser: TLinkParser;
    fParams: TStringList;
  public
    [Setup]
    procedure Setup;
    [Teardown]
    procedure Teardown;
    [Test]
    [TestCase( 'https with slash', 'https://www.dips.no/' )]
    [TestCase( 'http with slash', 'http://www.dips.no/' )]
    [TestCase( 'https without slash', 'https://www.emetra.no' )]
    [TestCase( 'http without slash', 'http://www.emetra.no' )]
    [TestCase( 'https short', 'https://emetra.no' )]
    [TestCase( 'http short', 'http://emetra.no' )]
    [TestCase( 'https shortest', 'https://insite' )]
    [TestCase( 'http shortest', 'http://kvalitet' )]
    procedure TestIsLink( const AUrl: string );
    [Test]
    [TestCase( 'about with AddForm', 'about://AddForm?FormName=TESTFORM,AddForm,FormName' )]
    [TestCase( 'Snooze', '//AlertSnooze?AlertId=12,AlertSnooze,AlertId' )]
    procedure TestIsApplicationCommand( const AUrl: string; const ACommandName, AFirstParam: string );
    [Test]
    procedure TestManyApplicationCommands;
  end;

implementation

procedure TTestClassLinkParser.Setup;
begin
  fLinkParser := TLinkParser.Create;
  fParams := TStringList.Create;
end;

procedure TTestClassLinkParser.Teardown;
begin
  fParams.Free;
  fLinkParser.Free;
end;

procedure TTestClassLinkParser.TestIsLink( const AUrl: string );
begin
  Assert.AreEqual( ord( urlPassThrough ), ord( fLinkParser.ClassifyUrl( AUrl ) ), 'This link should be classified as pass through (let the browser handle it)' );
end;

procedure TTestClassLinkParser.TestManyApplicationCommands;
begin
  TestIsApplicationCommand( 'about://AddForm?FormName="GBD_INNLEGGELSE"', 'AddForm', 'FormName' );
  TestIsApplicationCommand( 'about://ActiveCase?StatusId=25', 'ActiveCase', 'StatusId' );
  TestIsApplicationCommand( 'about://AlertSnooze?AlertId=n&Delay=14', 'AlertSnooze', 'AlertId' );
  TestIsApplicationCommand( '//AddForm?FormName=GBD_INNLEGGELSE', 'AddForm', 'FormName' );
  TestIsApplicationCommand( '//ActiveCase?StatusId=25', 'ActiveCase', 'StatusId' );
  TestIsApplicationCommand( '//AlertSnooze?AlertId=n&Delay=14', 'AlertSnooze', 'AlertId' );
end;

procedure TTestClassLinkParser.TestIsApplicationCommand( const AUrl: string; const ACommandName, AFirstParam: string );
var
  commandName: string;
begin
  Assert.AreEqual( ord( urlApplicationCommand ), ord( fLinkParser.ClassifyUrl( AUrl ) ), 'This link should be classified as application command' );
  Assert.IsTrue( fLinkParser.TryParseCommand( AUrl, commandName, fParams ) );
  Assert.AreEqual( ACommandName, commandName, 'Unexpected command name' );
  Assert.AreEqual( AFirstParam, fParams.Names[0], 'Unexcpected parameter name' );
end;

initialization

TDUnitX.RegisterTestFixture( TTestClassLinkParser );

end.
