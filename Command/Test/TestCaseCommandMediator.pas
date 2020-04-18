unit TestCaseCommandMediator;

interface

{$M+}

uses

  System.Classes,
  Emetra.Logging.Interfaces,
  Emetra.Command.Mediator,
  Emetra.Command.Interfaces,
  DUnitX.TestFramework;

type

  [TestFixture]
  TTestCommandMediator = class( TInterfacedPersistent, ICommandReceiver )
  strict private
    fCommandHandler: TCommandMediator;
    fExecutions: integer;
  private
    function ExecuteCmd( const ACommand: ICommand ): boolean;
  public
    procedure NonInvokablePublicMethod( const ARandomInteger: integer );
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SendRandomNumberToPublishedMethod;
    [Test]
    procedure AddPerson;
    [Test]
    procedure SendRandomNumberToPrivateMethod;
    [Test]
    procedure FindNonExistingObject;
  published
    procedure InvokablePublishedMethod( const ARandomInteger: integer );
  end;

implementation

uses
  Emetra.Command.Factory,
  {Standard}
  System.DateUtils, System.SysUtils, System.Variants, System.Math;

const
  INVOKABLE_METHOD     = 'InvokablePublishedMethod';
  NON_INVOKABLE_METHOD = 'NonInvokablePublicMethod';

const
  NON_EXISTING_OBJECT = 'SomeNonExistingObject';
  NON_EXISTING_METHOD = 'NonExistingMethod';

resourcestring
  StrRolandGundersen = 'Roland Gundersen';
  PRM_NAME = 'FullName';
  PRM_GENDER_ID = 'GenderId';
  PRM_DOB = 'DateOfBirth';
  PRM_PERSON_NUMBER = 'PersonNumber';
  PRM_NATIONAL_ID = 'NationalId';

const
  YYYY          = 1965;
  MM            = 7;
  DD            = 15;
  PERSON_NUMBER = 65535;
  NATIONAL_ID   = 15076500565;
  GENDER_ID     = 1;

const
  CMD_ADD_PERSON = 'AddPerson';
  CMDTARGET_TEST = 'Test';

procedure TTestCommandMediator.Setup;
begin
  fCommandHandler := TCommandMediator.Create( GlobalLog );
  fCommandHandler.RegisterReceiver( CMDTARGET_TEST, Self );
  fCommandHandler.RegisterReceiver( CMD_ADD_PERSON, Self );
  NonInvokablePublicMethod( -1 ); { Just to avoid compiler hint }
  fExecutions := 0;
end;

procedure TTestCommandMediator.TearDown;
begin
  fCommandHandler.Free;
end;

function TTestCommandMediator.ExecuteCmd( const ACommand: ICommand ): boolean;
var
  varValue: Variant;
begin
  GlobalLog.Event( 'ExecuteCommand: %s, Params: %s', [ACommand.Name, ACommand.CommaText] );
  Result := false;
  if ACommand.Matches( CMD_ADD_PERSON ) then
  begin
    { Check that the DateOfBirth is of the expected type and has the expected value }
    Assert.IsTrue( ACommand.TryGetValue( PRM_DOB, varValue ), 'A person should definitely have a date of birth.' );
    Assert.AreEqual( integer( varDate ), integer( VarType( varValue ) ), 'Expected to see a date.' );
    Assert.AreEqual( EncodeDate( YYYY, MM, DD ), VarToDateTime( varValue ) );

    { Check that the name is of the expected type and also correct }
    Assert.IsTrue( ACommand.TryGetValue( PRM_NAME, varValue ), 'A person should also have a name.' );
    Assert.AreEqual( TVarType( varUString ), VarType( varValue ), 'Expected to see unicode string.' );
    Assert.AreEqual( StrRolandGundersen, VarToStr( varValue ), 'The name should be ' + StrRolandGundersen );

    { Check GenderId, short integer or byte }
    Assert.IsTrue( ACommand.TryGetValue( PRM_GENDER_ID, varValue ), 'A person should also have a GenderId.' );
    Assert.AreEqual( TVarType( varByte ), VarType( varValue ), 'Expected to see a byte.' );
    Assert.AreEqual( byte( GENDER_ID ), byte( varValue ) );

    { Check PersonNumber, 16 bit cardinal (word) }
    Assert.IsTrue( ACommand.TryGetValue( PRM_PERSON_NUMBER, varValue ), 'A person should also have a PersonNumber.' );
    Assert.AreEqual( TVarType( varWord ), VarType( varValue ), 'Expected to see a word.' );
    Assert.AreEqual( PERSON_NUMBER, word( varValue ) );

    { Check nationalId, 64 bit integer }
    Assert.IsTrue( ACommand.TryGetValue( PRM_NATIONAL_ID, varValue ), 'A person should also have a NationalId.' );
    Assert.AreEqual( integer( varInt64 ), integer( VarType( varValue ) ), 'Expected to see an Int64.' );
    Assert.AreEqual( NATIONAL_ID, int64( varValue ) );
    Result := true;
  end;
end;

procedure TTestCommandMediator.FindNonExistingObject;
var
  cmd: ICommand;
begin
  try
    cmd := TCommandFactory.CreateInvokable( NON_EXISTING_OBJECT, NON_EXISTING_METHOD, pi );
    fCommandHandler.RaiseExceptionIfTargetNotFound := false;
    Assert.IsFalse( fCommandHandler.InvokeMethod( cmd ) );
    fCommandHandler.RaiseExceptionIfTargetNotFound := true;
    { The next assertion is not actually checked, because of the exception that happens inside InvokeMethod }
    Assert.IsTrue( fCommandHandler.InvokeMethod( cmd ) );
    { should not reach this point }
    { ignore [dcc32 Warning] TestCaseCommandMediator.pas(100): W1012 Constant expression violates subrange bounds }
    fExecutions := trunc( 1.0 / 0.0 );
  except
    on E: Exception do
    begin
      Assert.AreEqual( E.ClassName, ETargetObjectNotFound.ClassName );
      GlobalLog.SilentSuccess( '"Exceptions are good" (Magne Gekko), as %s should not be invokable', [NON_EXISTING_METHOD] );
    end;
  end;
end;

procedure TTestCommandMediator.NonInvokablePublicMethod( const ARandomInteger: integer );
begin
  inc( fExecutions );
end;

procedure TTestCommandMediator.InvokablePublishedMethod( const ARandomInteger: integer );
const
  PROC_NAME = INVOKABLE_METHOD;
begin
  GlobalLog.SilentSuccess( '%s.%s(%d): Yes, %s was actually invoked :-)', [ClassName, PROC_NAME, ARandomInteger, PROC_NAME] );
  inc( fExecutions );
end;

procedure TTestCommandMediator.SendRandomNumberToPrivateMethod;
begin
  fExecutions := 0;
  Assert.IsFalse( fCommandHandler.ExecuteCmd( TCommandFactory.CreateInvokable( 'Test', NON_INVOKABLE_METHOD, Random( 1000 ) ) ), 'Should not invoke public' );
  Assert.AreEqual( fExecutions, 0 );
end;

procedure TTestCommandMediator.SendRandomNumberToPublishedMethod;
begin
  fExecutions := 0;
  Assert.IsTrue( fCommandHandler.ExecuteCmd( TCommandFactory.CreateInvokable( 'Test', INVOKABLE_METHOD, Random( 1000 ) ) ), 'Should invoke published' );
  Assert.AreEqual( fExecutions, 1 );
end;

procedure TTestCommandMediator.AddPerson;
begin
  fExecutions := 0;
  Assert.IsTrue( fCommandHandler.ExecuteCmd(
    { } TCommandFactory.Create( CMD_ADD_PERSON, PRM_NAME, StrRolandGundersen, PRM_GENDER_ID, GENDER_ID, PRM_DOB, EncodeDate( YYYY, MM, DD ),
    { } PRM_PERSON_NUMBER, PERSON_NUMBER, PRM_NATIONAL_ID, NATIONAL_ID ) ), 'Should AddPerson successfully' );
end;

initialization

TDUnitX.RegisterTestFixture( TTestCommandMediator );

end.
