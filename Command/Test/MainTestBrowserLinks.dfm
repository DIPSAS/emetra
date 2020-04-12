object frmMainTestBrowserLinks: TfrmMainTestBrowserLinks
  Left = 0
  Top = 0
  BorderWidth = 8
  Caption = 'Browser link tester'
  ClientHeight = 549
  ClientWidth = 611
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 401
    Width = 611
    Height = 10
    Cursor = crVSplit
    Align = alBottom
    ExplicitLeft = -8
    ExplicitTop = 377
  end
  object brwDocumentViewer: TWebBrowser
    Left = 0
    Top = 23
    Width = 611
    Height = 378
    Align = alClient
    TabOrder = 0
    OnBeforeNavigate2 = brwDocumentViewerBeforeNavigate2
    ExplicitLeft = 8
    ExplicitTop = 24
    ExplicitWidth = 393
    ExplicitHeight = 241
    ControlData = {
      4C000000263F0000112700000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126208000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
  object ListBox1: TListBox
    Left = 0
    Top = 432
    Width = 611
    Height = 117
    Align = alBottom
    ItemHeight = 13
    TabOrder = 1
  end
  object ActionToolBar1: TActionToolBar
    Left = 0
    Top = 0
    Width = 611
    Height = 23
    ActionManager = ActionManager1
    Caption = 'ActionToolBar1'
    ColorMap.HighlightColor = clBtnHighlight
    ColorMap.UnusedColor = clWhite
    ColorMap.MenuColor = clMenu
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Spacing = 0
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 411
    Width = 611
    Height = 21
    Align = alBottom
    AutoSize = True
    ButtonHeight = 21
    ButtonWidth = 49
    Caption = 'ToolBar1'
    ShowCaptions = True
    TabOrder = 3
    object ToolButton1: TToolButton
      Left = 0
      Top = 0
      Action = actClearLog
    end
  end
  object ImageList1: TImageList
    Left = 192
    Top = 80
  end
  object ActionManager1: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Action = actLoadFile
            Caption = '&Load file'
          end
          item
            Action = actLoadNewspaper
            Caption = 'L&oad VG'
          end
          item
            Action = actLoadUsaToday
            Caption = 'Lo&ad USA'
          end
          item
            Caption = '-'
          end
          item
            Action = actClearLog
            Caption = '&Clear log'
          end>
        ActionBar = ActionToolBar1
      end>
    Images = ImageList1
    Left = 432
    Top = 56
    StyleName = 'Standard'
    object actLoadFile: TAction
      Caption = 'Load file'
      OnExecute = actLoadFileExecute
    end
    object actLoadNewspaper: TAction
      Caption = 'Load VG'
      OnExecute = actLoadNewspaperExecute
    end
    object actClearLog: TAction
      Caption = 'Clear log'
      OnExecute = actClearLogExecute
    end
    object actLoadUsaToday: TAction
      Caption = 'Load USA'
      OnExecute = actLoadUsaTodayExecute
    end
  end
end
