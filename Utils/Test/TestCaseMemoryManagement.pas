/// <summary>
/// See a couple of articles on StackOverflow why these tests are
/// relevant.<br />
/// <list type="bullet">
/// <item>
/// <see href="https://stackoverflow.com/questions/7640841/in-delphi-why-does-passing-a-interface-variable-sometimes-require-it-to-be-a-co/7640979#7640979">
/// Stack overflow article #1</see>
/// </item>
/// <item><see href="https://stackoverflow.com/questions/31028266/should-i-not-pass-an-interface-as-const">
/// Stack overflow article #2</see>
/// </item>
/// </list>
/// </summary>
unit TestCaseMemoryManagement;

interface

uses
  TestFramework, System.Classes, TestClassesMemoryManagement,
  Emetra.Logging.Interfaces;

type

  { Classes with special names to make it easier to understand the message on shutdown }
  TUnleakedInterfacedObject = class( TInterfacedObject );
  TInterfacedObjectThatWillBeLeaked = class( TInterfacedObject );
  TInterfacedPersistentThatWillBeLeaked = class( TInterfacedPersistent );
  TComponentThatWillBeLeaked = class( TComponent );

  TestTClientObject = class( TTestCase )
  strict private
    fClientObject: TClientObject;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    { Create memory leaks }
    procedure LeakImmortalInterfacedObject;
    procedure LeakComponent;
    procedure LeakInterfacedPersistent;
    procedure LeakNothing;
    procedure LeakSurprise;
    { No leaks with TnterfacedObject }
    procedure TestInterfacedObjectStandardParam;
    procedure TestInterfacedObjectConstParam;
    procedure TestInterfacedObjectConstParamUntouched;
    procedure TestInterfacedObjectConstParamAsIUnknown;
    procedure TestInterfacedObjectStandardParamAsIUnknown;
    { Double Free }
    procedure DoubleFreeInterfacedObject;
    procedure DoubleFreeComponentWithOwnerIsOk;
    { Proper use of }
    procedure ManualFreeInterfacedPersistent;
    procedure ManualFreeImmortalInterfacedObject;
    procedure ManualFreeComponent;
    { Using ownership }
    procedure TestComponentWithOwner;
  end;

implementation

uses
  System.SysUtils;

procedure TestTClientObject.SetUp;
begin
  fClientObject := TClientObject.Create( GlobalLog );
  if GlobalLog.Count = 0 then
    GlobalLog.Event( 'TObject is %d bytes', [TObject.InstanceSize] );
end;

procedure TestTClientObject.TearDown;
begin
  fClientObject.Free;
end;

procedure TestTClientObject.TestInterfacedObjectStandardParam;
begin
  { This will not cause a leak, beause the method call is not using const }
  fClientObject.UseStandardParam( TInterfacedObject.Create );
end;

procedure TestTClientObject.TestInterfacedObjectConstParam;
begin
  { This will not cause a leak even with const parameter, because of what happens inside the FClientObject }
  fClientObject.UseConstParam( TInterfacedObject.Create );
end;

procedure TestTClientObject.TestInterfacedObjectConstParamAsIUnknown;
var
  intf: IUnknown;
begin
  { This will not cause a leak, because the local variable here increments the reference count }
  intf := TInterfacedObject.Create;
  fClientObject.UseConstParamAndDoNothing( intf );
end;

procedure TestTClientObject.TestInterfacedObjectConstParamUntouched;
begin
  { This will cause a memory leak, because the refcount never get down to zero, as it is never incremented }
  fClientObject.UseConstParamAndDoNothing( TInterfacedObjectThatWillBeLeaked.Create );
end;

procedure TestTClientObject.TestInterfacedObjectStandardParamAsIUnknown;
var
  intf: IUnknown;
begin
  { This will not cause a memory leak }
  intf := TInterfacedObject.Create;
  fClientObject.UseStandardParam( intf );
  GlobalLog.Event( 'After call: %d', [intf._AddRef - 1] );
  intf._Release;
end;

procedure TestTClientObject.DoubleFreeInterfacedObject;
var
  o: TInterfacedObject;
begin
  o := TInterfacedObject.Create;
  fClientObject.UseConstParam( o );
  try
    { The object is already freed at this point, which means that the next line gives an access violation }
    o.Free;
    CheckTrue( false, 'This should never happen' );
  except
    on E: Exception do
      CheckEquals( E.ClassType, EAccessViolation );
  end;
end;

procedure TestTClientObject.ManualFreeImmortalInterfacedObject;
var
  o: TImmortalInterfacedObject;
begin
  o := TImmortalInterfacedObject.Create;
  try
    fClientObject.UseConstParam( o );
  finally
    o.Free; { Will not be leaked or give access violation, behaves like TInterfacedPersistent }
  end;
end;

procedure TestTClientObject.ManualFreeInterfacedPersistent;
var
  o: TInterfacedPersistent;
begin
  { This is perfectly fine, no problems }
  o := TInterfacedPersistent.Create;
  try
    fClientObject.UseStandardParam( o );
  finally
    o.Free;
  end;
end;

procedure TestTClientObject.TestComponentWithOwner;
begin
  fClientObject.UseStandardParam( TComponent.Create( fClientObject ) );
end;

procedure TestTClientObject.ManualFreeComponent;
var
  c: TComponent;
begin
  c := TComponent.Create( nil );
  try
    fClientObject.UseStandardParam( c );
  finally
    c.Free;
  end;
end;

procedure TestTClientObject.DoubleFreeComponentWithOwnerIsOk;
var
  c: TComponent;
begin
  c := TComponent.Create( fClientObject );
  try
    fClientObject.UseStandardParam( c );
    CheckEquals( 1, fClientObject.ComponentCount );
  finally
    c.Free;
    CheckEquals( 0, fClientObject.ComponentCount );
  end;
  { There is really no double free, because the client knows that c has been freed }
  CheckEquals( 0, fClientObject.ComponentCount );
end;

{$REGION 'Leaked objects' }

procedure TestTClientObject.LeakInterfacedPersistent;
begin
  fClientObject.UseStandardParam( TInterfacedPersistentThatWillBeLeaked.Create );
end;

procedure TestTClientObject.LeakComponent;
begin
  fClientObject.UseStandardParam( TComponentThatWillBeLeaked.Create( nil ) );
end;

procedure TestTClientObject.LeakImmortalInterfacedObject;
begin
  fClientObject.UseStandardParam( TImmortalInterfacedObject.Create );
end;

procedure TestTClientObject.LeakNothing;
begin
  { Will not leak because of standard parameters }
  fClientObject.UseStandardParam( TUnleakedInterfacedObject.Create );
  fClientObject.UseConstParam( TUnleakedInterfacedObject.Create );
end;

procedure TestTClientObject.LeakSurprise;
begin
  { Will leak because const parameter, and no reference is added in client }
  fClientObject.UseConstParamAndDoNothing( TInterfacedObjectThatWillBeLeaked.Create ); { This will actually create a memory leak }
end;

{$ENDREGION}

initialization

// Register any test cases with the test runner
RegisterTest( TestTClientObject.Suite );

end.
