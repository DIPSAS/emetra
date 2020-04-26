unit Emetra.Logging.Base;

interface

uses
  {General}
  Emetra.Logging.Interfaces,
  {Standard}
  System.Classes, System.UITypes, Generics.Collections;

type

  TOnDialogFunction = function( const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons; HelpCtx: Longint ): Integer;

  TLogAdapter = class( TInterfacedObject )
  strict private
    fThresholdForDialog: TLogLevel;
    fThreshold: TLogLevel;
    fModalResult: Integer;
    fLogCallStack: boolean;
    fEnabled: boolean;
    fButtonSet: TMsgDlgButtons;
    fDefaultButton: TMsgDlgBtn;
    fShowCounter: TDictionary<cardinal, cardinal>;
  private
    function MapButtonToResult( const ABtn: TMsgDlgBtn ): TModalResult;
  protected
    { Property accessors }
    function Get_Enabled: boolean;
    function Get_LogCallStack: boolean;
    function Get_ModalResult: Integer;
    function Get_Threshold: TLogLevel;
    function Get_ThresholdForDialog: TLogLevel;
    procedure Set_Enabled( const AValue: boolean );
    procedure Set_LogCallStack( const AValue: boolean );
    procedure Set_Threshold( ALogLevel: TLogLevel );
    procedure Set_ThresholdForDialog( ALogLevel: TLogLevel );
    { Button sets }
    procedure PrepareButtonOk;
    procedure PrepareButtonsOkIgnore;
    procedure PrepareButtonsYesNo( const ACancel: boolean );
    procedure SetDefaultResult;
    { other members }
    procedure ShowCrossPlatformDialog( const ALogMessage: string; const AButtons: TMsgDlgButtons; const ADefaultBtn: TMsgDlgBtn; const AHelpCtx: Longint; const ALogLevel: TLogLevel );
    { Properties }
    property ButtonSet: TMsgDlgButtons read fButtonSet;
    property DefaultButton: TMsgDlgBtn read fDefaultButton;
    property ModalResult: Integer read fModalResult;
  protected
    { Mapping log level to dialog type }
    function MapDlggType( const ALogLevel: TLogLevel ): TMsgDlgType;
    { Show counter for ignoreable messages }
    function HashMessage( const s: string ): cardinal;
    procedure ResetCounter( const AMessage: string );
    procedure IncrementShowCounter( const AKey: cardinal ); dynamic;
    function ShowCounter( const AKey: cardinal ): cardinal; dynamic;
  protected
    { The actual logging is performed by overriding these two }
    procedure Event( s: string; const ALogLevel: TLogLevel = ltInfo ); overload; virtual; abstract;
    procedure ShowMessage( const AMessage: string; const ALevel: TLogLevel = ltMessage; const AMaxTimes: cardinal = maxint ); {
      Summary:
      Allows AMessage to be shown, but limited to AMaxTimes number of times,
      or to let the user click Ignore never to see this message again,
      provided that FIniFile is assigned.  The message is not shown if it is below the
      threshold, but the counter is incremented.
      Note:
      This method uses a simple checksum as a digest of the message.  Usually the chance
      of collision is small, as the number of messages in an application is not that great. }
  public
    { Intialization }
    constructor Create; dynamic;
    destructor Destroy; override;
    { The three basic event types }
    function LogYesNo( const s: string; const ALevel: TLogLevel = ltMessage; const ACancel: boolean = false ): boolean;
    procedure Event( const s: string; const AParams: array of const; const ALogLevel: TLogLevel = ltInfo ); overload;
    { Properties }
    property Enabled: boolean read fEnabled write fEnabled;
    property LogCallStack: boolean read Get_LogCallStack write Set_LogCallStack;
    property Threshold: TLogLevel read Get_Threshold write Set_Threshold;
    property ThresholdForDialog: TLogLevel read Get_ThresholdForDialog write Set_ThresholdForDialog;
  end;

implementation

uses
  Emetra.Hash.CRC32,
  Emetra.Logging.Utilities,
{$IFDEF MSWINDOWS}
{$IFDEF FireMonkey}
  FMX.DialogService.Sync,
{$ELSE}
  Vcl.Dialogs,
{$ENDIF}
{$ELSE}
  FMX.DialogService.Sync,
{$ENDIF}
{$IFDEF iOS }
  FMX.DialogService.Sync,
{$ENDIF}
  System.SysUtils;

{$REGION 'Initialization'}

constructor TLogAdapter.Create;
begin
  inherited;
  fThresholdForDialog := ltMessage;
  fThreshold := ltInfo;
  fShowCounter := TDictionary<cardinal, cardinal>.Create;
  PrepareButtonOk;
end;

destructor TLogAdapter.Destroy;
begin
  fShowCounter.Free;
  inherited;
end;

{$ENDREGION}
{$REGION 'Button sets'}

procedure TLogAdapter.PrepareButtonOk;
begin
  fButtonSet := [TMsgDlgBtn.mbOK];
  fDefaultButton := TMsgDlgBtn.mbOK;
end;

procedure TLogAdapter.PrepareButtonsOkIgnore;
begin
  PrepareButtonOk;
  Include( fButtonSet, TMsgDlgBtn.mbIgnore );
end;

procedure TLogAdapter.PrepareButtonsYesNo( const ACancel: boolean );
begin
  fDefaultButton := TMsgDlgBtn.mbYes;
  { Set up correct buttons }
  fButtonSet := [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo];
  if ACancel then
    fButtonSet := fButtonSet + [TMsgDlgBtn.mbCancel];
end;

procedure TLogAdapter.SetDefaultResult;
begin
  fModalResult := MapButtonToResult( fDefaultButton );
end;

{$ENDREGION}
{$REGION 'Simple accessors'}

function TLogAdapter.Get_Enabled: boolean;
begin
  Result := fEnabled;
end;

function TLogAdapter.Get_LogCallStack: boolean;
begin
  Result := fLogCallStack;
end;

function TLogAdapter.Get_ModalResult: Integer;
begin
  Result := fModalResult;
end;

function TLogAdapter.Get_Threshold: TLogLevel;
begin
  Result := fThreshold;
end;

function TLogAdapter.Get_ThresholdForDialog: TLogLevel;
begin
  Result := fThresholdForDialog;
end;

procedure TLogAdapter.Set_Enabled( const AValue: boolean );
begin
  fEnabled := AValue;
end;

procedure TLogAdapter.Set_LogCallStack( const AValue: boolean );
begin
  fLogCallStack := AValue;
end;

procedure TLogAdapter.Set_Threshold( ALogLevel: TLogLevel );
begin
  fThreshold := ALogLevel;
end;

procedure TLogAdapter.Set_ThresholdForDialog( ALogLevel: TLogLevel );
begin
  fThresholdForDialog := ALogLevel;
end;

{$ENDREGION}
{$REGION 'Mapping functions'}

function TLogAdapter.MapButtonToResult( const ABtn: TMsgDlgBtn ): TModalResult;
begin
  case ABtn of
    TMsgDlgBtn.mbYes: Result := mrYes;
    TMsgDlgBtn.mbNo: Result := mrNo;
    TMsgDlgBtn.mbOK: Result := mrOk;
    TMsgDlgBtn.mbCancel: Result := mrCancel;
    TMsgDlgBtn.mbAbort: Result := mrAbort;
    TMsgDlgBtn.mbRetry: Result := mrRetry;
    TMsgDlgBtn.mbIgnore: Result := mrIgnore;
    TMsgDlgBtn.mbAll: Result := mrAll;
    TMsgDlgBtn.mbNoToAll: Result := mrNoToAll;
    TMsgDlgBtn.mbYesToAll: Result := mrYesToAll;
    TMsgDlgBtn.mbHelp: Result := mrHelp;
    TMsgDlgBtn.mbClose: Result := mrClose;
  else Result := mrNone;
  end;
end;

function TLogAdapter.MapDlggType( const ALogLevel: TLogLevel ): TMsgDlgType;
begin
  case ALogLevel of
    ltWarning: Result := TMsgDlgType.mtWarning;
    ltError: Result := TMsgDlgType.mtError;
    ltCritical: Result := TMsgDlgType.mtError;
  else Result := TMsgDlgType.mtInformation;
  end;
end;

{$ENDREGION}
{$REGION 'Duplicate message counter'}

procedure TLogAdapter.ResetCounter( const AMessage: string );
var
  key: cardinal;
begin
  key := HashMessage( AMessage );
  fShowCounter.AddOrSetValue( key, 0 );
end;

procedure TLogAdapter.IncrementShowCounter( const AKey: cardinal );
begin
  fShowCounter.AddOrSetValue( AKey, ShowCounter( AKey ) + 1 );
end;

function TLogAdapter.ShowCounter( const AKey: cardinal ): cardinal;
begin
  if not fShowCounter.TryGetValue( AKey, Result ) then
    Result := 0;
end;

{$ENDREGION}

procedure TLogAdapter.Event( const s: string; const AParams: array of const; const ALogLevel: TLogLevel );
begin
  Event( Format( s, AParams ), ALogLevel );
end;

function TLogAdapter.LogYesNo( const s: string; const ALevel: TLogLevel; const ACancel: boolean ): boolean;
begin
  PrepareButtonsYesNo( ACancel );
  try
    { Log the event, with callback to ShowMessage from descendant if needed }
    Event( s, ALevel );
    Result := ( fModalResult = mrYes );
  finally
    PrepareButtonOk;
  end;
end;

procedure TLogAdapter.ShowCrossPlatformDialog( const ALogMessage: string; const AButtons: TMsgDlgButtons; const ADefaultBtn: TMsgDlgBtn; const AHelpCtx: Longint; const ALogLevel: TLogLevel );
var
  msgDlgType: TMsgDlgType;
begin
  if ALogLevel >= ThresholdForDialog then
  begin
    msgDlgType := MapDlggType( ALogLevel );
    if ( TMsgDlgBtn.mbNo in AButtons ) and ( msgDlgType = TMsgDlgType.mtInformation ) then
      msgDlgType := TMsgDlgType.mtConfirmation;
{$IFDEF MSWINDOWS}
{$IFDEF FireMonkey}
    fModalResult := TDialogServiceSync.MessageDialog( PrepareForDialog( ALogMessage ), msgDlgType, AButtons, ADefaultBtn, 0 )
{$ELSE}
    fModalResult := MessageDlg( PrepareForDialog( ALogMessage ), msgDlgType, AButtons, 0 )
{$ENDIF}
{$ENDIF}
{$IFDEF IOS}
      fModalResult := TDialogServiceSync.MessageDialog( PrepareForDialog( ALogMessage ), msgDlgType, AButtons, ADefaultBtn, 0 )
{$ENDIF}
  end
  else
    fModalResult := MapButtonToResult( fDefaultButton );
end;

function TLogAdapter.HashMessage( const s: string ): cardinal;
begin
  Result := StrCRC32( s );
end;

procedure TLogAdapter.ShowMessage( const AMessage: string; const ALevel: TLogLevel; const AMaxTimes: cardinal );
resourcestring
  LOG_IGNORE = 'Klikk "%s" hvis du ikke vil se denne meldingen igjen.';
  BTN_IGNORE_TEXT = 'Ignore';
var
  msgKey: cardinal;
  shownBefore: cardinal;
  savedLevel: TLogLevel;
begin
  savedLevel := ThresholdForDialog;
  try
    ThresholdForDialog := ltCritical;
    msgKey := HashMessage( AMessage );
    shownBefore := ShowCounter( msgKey );
    if shownBefore >= AMaxTimes then
    begin
      { Log the event but without dialog }
      Event( 'IGNORED ( ShownBefore=%d, MaxTimes = %d ): ' + AMessage, [shownBefore, AMaxTimes], ALevel );
      ThresholdForDialog := savedLevel;
      fModalResult := mrIgnore;
    end
    else
    begin
      { Log the event but without dialog }
      Event( AMessage, ALevel );
      ThresholdForDialog := savedLevel;
      { Now show the dialog and increment counter }
      ShowCrossPlatformDialog( AMessage + '\n\n' + Format( LOG_IGNORE, [BTN_IGNORE_TEXT] ), [TMsgDlgBtn.mbOK, TMsgDlgBtn.mbIgnore], TMsgDlgBtn.mbOK, 0, ALevel );
    end;
    IncrementShowCounter( msgKey );
  finally
    PrepareButtonOk;
  end;
end;

end.
