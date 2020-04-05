unit TestCaseTokenizer;

interface

uses
  Emetra.Classes.Tokenizer,
  DUnitX.TestFramework;

type

  [TestFixture]
  TTestCaseTokenizer = class( TObject )
  strict private
    fTokenizer: TTokenizer;
  private
    procedure TestGetAtPosition( const AInputString: string; const AIndex: integer; const AExpectedValue: string );
    procedure TestExtractPosition( const AInputString: string; const AIndex: integer; const AExpectedValue: string );
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    // [TestCase( 'Zero', '000|111|222', 1, '' )]
    procedure TestGetAt;
    [Test]
    procedure TestExtract;
    [Test]
    procedure TestStringOfDelimiters;
    [Test]
    procedure TestCrLf;
  end;

implementation

uses
  System.SysUtils;

procedure TTestCaseTokenizer.Setup;
begin
  fTokenizer := TTokenizer.Create;
end;

procedure TTestCaseTokenizer.TearDown;
begin
  fTokenizer.Free;
end;

procedure TTestCaseTokenizer.TestCrLf;
begin
  fTokenizer.Prepare( 'FirstLine'#13#10'SecondLine', #13#10 );
  Assert.AreEqual( 'FirstLine', fTokenizer[0] );
  Assert.AreEqual( 'SecondLine', fTokenizer[1] );
end;

procedure TTestCaseTokenizer.TestExtract;
begin
  TestExtractPosition( '0;1;2;', -1, EmptyStr );
  TestExtractPosition( '0;1;2;', 0, '0' );
  TestExtractPosition( '0;1;2;', 2, '2' );
  TestExtractPosition( '0;1;2;', 3, EmptyStr );
end;

procedure TTestCaseTokenizer.TestExtractPosition( const AInputString: string; const AIndex: integer; const AExpectedValue: string );
begin
  fTokenizer.Extract( AInputString, AIndex, ';' );
  Assert.AreEqual( AExpectedValue, fTokenizer[AIndex], ';' );
end;

procedure TTestCaseTokenizer.TestGetAt;
begin
  TestGetAtPosition( '0;1;2;', 0, EmptyStr );
  TestGetAtPosition( '0;1;2;', 1, '0' );
  TestGetAtPosition( '0;1;2;', 3, '2' );
  TestGetAtPosition( '0;1;2;', 4, EmptyStr );
end;

procedure TTestCaseTokenizer.TestGetAtPosition( const AInputString: string; const AIndex: integer; const AExpectedValue: string );
begin
  fTokenizer.Prepare( AInputString, ';' );
  Assert.AreEqual( AExpectedValue, fTokenizer[AIndex - 1], ';' );
end;

procedure TTestCaseTokenizer.TestStringOfDelimiters;
begin
  fTokenizer.Prepare( 'https://www.emetra.no', '://' );
  Assert.AreEqual( 'https', fTokenizer[0] );
  Assert.AreEqual( 'www.emetra.no', fTokenizer[1] );
end;

initialization

TDUnitX.RegisterTestFixture( TTestCaseTokenizer );

end.
