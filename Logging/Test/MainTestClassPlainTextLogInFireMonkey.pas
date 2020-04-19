unit MainTestClassPlainTextLogInFireMonkey;

interface

uses
  Emetra.Logging.Interfaces,
  Emetra.Logging.LogItem.Interfaces,

  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Diagnostics,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ListBox, FMX.Edit, FMX.SearchBox,
  FMX.Objects, System.ImageList, FMX.ImgList, FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView;

type
  TfrmMain = class( TForm )
    lboxLogItems: TListBox;
    ListBoxItem1: TListBoxItem;
    imgzLogIcons: TImageList;
    Panel1: TPanel;
    btnAddDebugEvent: TButton;
    btnAddInfoEvent: TButton;
    btnAddMessageEvent: TButton;
    btnAddWarningEvent: TButton;
    btnAdd1000Events: TButton;
    cmbThresholdForDialog: TComboBox;
    lblThreshold: TLabel;
    Splitter2: TSplitter;
    lblFormHeader: TLabel;
    rctFormHeader: TRectangle;
    edtListBoxSearch: TSearchBox;
    chkAlternateRowColors: TCheckBox;
    btnAskYesNoQuestion: TButton;
    lblThresholdForLogging: TLabel;
    cmbThreshold: TComboBox;
    Panel2: TPanel;
    edtListViewSearch: TEdit;
    Image1: TImage;
    lviewLogItems: TListView;
    btnAddSilentMessages: TButton;
    procedure FormCreate( Sender: TObject );
    procedure btnAddDebugEventClick( Sender: TObject );
    procedure btnAddInfoEventClick( Sender: TObject );
    procedure btnAddMessageEventClick( Sender: TObject );
    procedure btnAddWarningEventClick( Sender: TObject );
    procedure btnAddErrorEventClick( Sender: TObject );
    procedure btnAdd1000EventsClick( Sender: TObject );
    procedure cmbThresholdForDialogChange( Sender: TObject );
    procedure cmbThresholdChange( Sender: TObject );
    procedure lviewLogItemsResized( Sender: TObject );
    procedure edtListviewSearchChanged( Sender: TObject );
    procedure chkAlternateRowColorsChange( Sender: TObject );
    procedure btnAskYesNoQuestionClick( Sender: TObject );
    procedure btnAddSilentMessagesClick( Sender: TObject );
  private
    { Private declarations }
    fItemList: ILogItemList;
    sw: TStopWatch;
    function FilterPredicate( s: string ): boolean;
    procedure AddItemsToListbox;
    procedure AddItemsToListview;
    procedure AddActualLogItemsToGUI;
    procedure CopyActualLogLevelsToGUI;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  DateUtils,
  Emetra.Logging.Target.Interfaces,
  Emetra.Logging.Colors,
  System.UIConsts;

resourcestring
  StrElementCount = 'The log now has a grand total of %d elements.';
  StrTestDebug = 'This is a test at debug level tick %d ';
  StrTestInfo = 'This is a test at info level at tick %d ';
  StrTestMessage = 'This message should be shown with an Information dialog type.';
  StrTestWarning = 'This message should be shown with a Warning dialog type.';
  StrTestError = 'This message should be shown with an Error dialog type.';
  StrLogMessageNo = 'This is message nummer %d in the log.';
  StrAskQuestion = 'Do you want to use alternating colors in the log?\nSome shortsighted and\or nearsighted people prefer that.';
  StrLogLiewViewTime = 'Legge til i listVIEW tok %d ms.';
  StrLogListBoxTime = 'Legge til i listBOX tok %d ms.';
  StrLogLoggerTime = 'Logget %d på %d ms.';

procedure TfrmMain.FormCreate( Sender: TObject );
begin
  with GlobalLog as ILogMultiTarget do
    ClearAllTargets;
  GlobalLog.Threshold := ltDebug;
  GlobalLog.ThresholdForDialog := ltCritical;
  CopyActualLogLevelsToGUI;
  sw := TStopWatch.StartNew;
  Assert( Supports( GlobalLog, ILogItemList, fItemList ) );
  lboxLogItems.ItemHeight := ListBoxItem1.Height;
  lboxLogItems.Clear;
  edtListViewSearch.Height := edtListBoxSearch.Height;
  edtListViewSearch.Font := edtListBoxSearch.Font;
  AddActualLogItemsToGUI;
end;

procedure TfrmMain.edtListviewSearchChanged( Sender: TObject );
begin
  if Trim( edtListViewSearch.Text ) = EmptyStr then
    lviewLogItems.Items.Filter := nil
  else
    lviewLogItems.Items.Filter := FilterPredicate;
end;

function TfrmMain.FilterPredicate( s: string ): boolean;
begin
  Result := Pos( edtListViewSearch.Text, s ) > 0;
end;

procedure TfrmMain.lviewLogItemsResized( Sender: TObject );
begin
  exit;
  with lviewLogItems.ItemAppearanceObjects.ItemObjects do
  begin
    Detail.Width := lviewLogItems.Width - 72;
  end;
end;

procedure TfrmMain.AddActualLogItemsToGUI;
begin
  AddItemsToListbox;
  AddItemsToListview;
  lblFormHeader.Text := Format( StrElementCount, [fItemList.Count] );
end;

procedure TfrmMain.CopyActualLogLevelsToGUI;
begin
  cmbThresholdForDialog.ItemIndex := ord( GlobalLog.ThresholdForDialog );
  cmbThreshold.ItemIndex := ord( GlobalLog.Threshold );
end;

{$REGION 'Add Single events for various log levels.' }

procedure TfrmMain.btnAddDebugEventClick( Sender: TObject );
begin
  GlobalLog.Event( StrTestDebug, [sw.ElapsedTicks], ltDebug );
  AddActualLogItemsToGUI;
end;

procedure TfrmMain.btnAddInfoEventClick( Sender: TObject );
begin
  GlobalLog.Event( StrTestInfo, [sw.ElapsedTicks], ltInfo );
  AddActualLogItemsToGUI;
end;

procedure TfrmMain.btnAddMessageEventClick( Sender: TObject );
begin
  GlobalLog.Event( StrTestMessage, ltMessage );
  AddActualLogItemsToGUI;
end;

procedure TfrmMain.btnAddWarningEventClick( Sender: TObject );
begin
  GlobalLog.Event( StrTestWarning, ltWarning );
  AddActualLogItemsToGUI;
end;

procedure TfrmMain.btnAddErrorEventClick( Sender: TObject );
begin
  GlobalLog.Event( StrTestError, ltError );
  AddActualLogItemsToGUI;
end;

{$ENDREGION}

procedure TfrmMain.btnAdd1000EventsClick( Sender: TObject );
var
  i: integer;
  addw: TStopWatch;
  lbw: TStopWatch;
  lvw: TStopWatch;
  lvl: TLogLevel;
begin
  addw := TStopWatch.StartNew;
  i := 0;
  repeat
    lvl := TLogLevel( Random( ord( GlobalLog.ThresholdForDialog ) ) );
    GlobalLog.Event( StrLogMessageNo, [i], lvl );
    inc( i );
  until i = 1000;
  GlobalLog.SilentSuccess( StrLogLoggerTime, [i, addw.ElapsedMilliseconds] );
  lbw := TStopWatch.StartNew;
  AddItemsToListbox;
  GlobalLog.SilentSuccess( StrLogListBoxTime, [lbw.ElapsedMilliseconds] );
  lvw := TStopWatch.StartNew;
  AddItemsToListview;
  GlobalLog.SilentSuccess( StrLogLiewViewTime, [lvw.ElapsedMilliseconds] );
  AddActualLogItemsToGUI;
end;

procedure TfrmMain.btnAskYesNoQuestionClick( Sender: TObject );
begin
  GlobalLog.ThresholdForDialog := ltMessage;
  CopyActualLogLevelsToGUI;
  chkAlternateRowColors.IsChecked := GlobalLog.LogYesNo( StrAskQuestion );
  AddActualLogItemsToGUI;
end;

procedure TfrmMain.btnAddSilentMessagesClick( Sender: TObject );
begin
  GlobalLog.SilentSuccess( 'All is well, silent success.' );
  GlobalLog.SilentWarning( 'Not all is well, silent warning.' );
  GlobalLog.SilentError( 'Not all is well, silent error.' );
  AddActualLogItemsToGUI;
end;

procedure TfrmMain.chkAlternateRowColorsChange( Sender: TObject );
begin
  lviewLogItems.AlternatingColors := chkAlternateRowColors.IsChecked;
  lboxLogItems.AlternatingRowBackground := chkAlternateRowColors.IsChecked;
end;

{$REGION 'Log threshold combobox handlersæ}

procedure TfrmMain.cmbThresholdForDialogChange( Sender: TObject );
begin
  if cmbThresholdForDialog.ItemIndex > -1 then
    GlobalLog.ThresholdForDialog := TLogLevel( cmbThresholdForDialog.ItemIndex )
  else
    GlobalLog.ThresholdForDialog := ltMessage;
  btnAdd1000Events.ImageIndex := cmbThresholdForDialog.ItemIndex - 1;
end;

procedure TfrmMain.cmbThresholdChange( Sender: TObject );
begin
  if cmbThreshold.ItemIndex > -1 then
    GlobalLog.Threshold := TLogLevel( cmbThreshold.ItemIndex )
  else
    GlobalLog.Threshold := ltMessage;
end;

{$ENDREGION}
{$REGION 'Populating listbox and listview'}

procedure TfrmMain.AddItemsToListbox;
var
  LogItem: IBasicLogItem;
  colItem: IColoredLogItem;
  lbItem: TListBoxItem;
  n: integer;
  rct: TRectangle;
begin
  lboxLogItems.BeginUpdate;
  try
    n := lboxLogItems.Count;
    while n < fItemList.Count do
    begin
      if fItemList.TryGetItem( n, LogItem ) then
      begin
        lbItem := TListBoxItem.Create( lboxLogItems );
        lbItem.name := Format( 'Item%d', [lboxLogItems.Count] );
        lbItem.Text := DateToISO8601( LogItem.Timestamp );
        lbItem.Height := lboxLogItems.Count;
        lbItem.ItemData.Detail := LogItem.LogText;
        lbItem.Data := TObject( LogItem );
        lbItem.StyledSettings := [];
        lbItem.TextSettings.Font.Size := 12;
        lbItem.TextSettings.Font.Style := [TFontStyle.fsBold];
        { Add a colored rectangle }
        if Supports( LogItem, IColoredLogItem, colItem ) then
        begin
          rct := TRectangle.Create( lbItem );
          rct.Parent := lbItem;
          rct.Stroke.Kind := TBrushKind.None;
          rct.Fill.Color := ColorToAlphaColor( colItem.BrushColor );
          rct.Align := TAlignLayout.Left;
          rct.Width := 8;
        end;
        lboxLogItems.AddObject( lbItem );
      end;
      inc( n );
    end;
  finally
    lboxLogItems.EndUpdate;
  end;
end;

procedure TfrmMain.AddItemsToListview;
var
  n: integer;
  LogItem: IBasicLogItem;
  lvItem: TListViewItem;
begin
  lviewLogItems.BeginUpdate;
  try
    lviewLogItems.Items.Filter := nil;
    n := lviewLogItems.Items.Count;
    while n < fItemList.Count do
    begin
      if fItemList.TryGetItem( n, LogItem ) then
      begin
        lvItem := lviewLogItems.Items.Add;
        lvItem.Text := DateToISO8601( LogItem.Timestamp );
        lvItem.Detail := LogItem.LogText;
        if LogItem.LogLevel > ltInfo then
          lvItem.ImageIndex := ord( LogItem.LogLevel );
      end;
      inc( n );
    end;
  finally
    edtListviewSearchChanged( Self );
    lviewLogItems.EndUpdate;
  end;

end;

{$ENDREGION}

end.
