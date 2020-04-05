unit TestCaseLinkClassifier;

interface

uses
  Emetra.Logging.Interfaces,
  Emetra.Command.LinkClassifier,
  DUnitX.TestFramework;

type

  [TestFixture]
  TTestClassLinkParser = class( TObject )
  private
    fLinkParser: TLinkParser;
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
    [TestCase( 'AddForm', '//AddForm?FormName="GBD_INNLEGGELSE"', 'FormName' ) ]
    [TestCase( 'ActiveCase', '//ActiveCase?StatusId=25', 'StatusId' ) ]
    [TestCase( 'AlertSnooze', '//AlertSnooze?AlertId=n&Delay=14', 'AlertId' ) ]
    procedure TestIsApplicationCommand( const AUrl: string; const AFirstParam: string );
  end;

implementation

procedure TTestClassLinkParser.Setup;
begin
  fLinkParser := TLinkParser.Create;
end;

procedure TTestClassLinkParser.Teardown;
begin
  fLinkParser.Free;
end;

procedure TTestClassLinkParser.TestIsLink( const AUrl: string );
begin
  Assert.AreEqual( ord( fLinkParser.ClassifyUrl( AUrl ) ), ord( urlPassThrough ), 'This link should be classified as pass through (let the browser handle it)' );
end;

procedure TTestClassLinkParser.TestIsApplicationCommand(const AUrl: string; const AFirstParam: string);
begin
  Assert.AreEqual( ord( fLinkParser.ClassifyUrl( AUrl ) ), ord( urlApplicationCommand ), 'This link should be classified as application command' );
end;


initialization

TDUnitX.RegisterTestFixture( TTestClassLinkParser );

end.
