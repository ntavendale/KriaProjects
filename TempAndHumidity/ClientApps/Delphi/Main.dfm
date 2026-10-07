object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'Temp & Humidity Client'
  ClientHeight = 365
  ClientWidth = 641
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object gbEndPoint: TGroupBox
    Left = 0
    Top = 0
    Width = 641
    Height = 65
    Caption = 'End Point'
    TabOrder = 0
    object ebHost: TEdit
      Left = 16
      Top = 24
      Width = 505
      Height = 29
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = 'http://192.168.9.37'
    end
    object spPort: TSpinEdit
      Left = 527
      Top = 24
      Width = 82
      Height = 31
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      MaxValue = 65536
      MinValue = 0
      ParentFont = False
      TabOrder = 1
      Value = 8080
    end
  end
  object gbData: TGroupBox
    Left = 0
    Top = 71
    Width = 641
    Height = 66
    Caption = 'Temperature && Humidity'
    TabOrder = 1
    object lbData: TLabel
      Left = 16
      Top = 24
      Width = 55
      Height = 25
      Caption = 'lbData'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object btnGetData: TButton
      Left = 550
      Top = 24
      Width = 75
      Height = 25
      Caption = 'Get'
      TabOrder = 0
      OnClick = btnGetDataClick
    end
  end
  object gbResolution: TGroupBox
    Left = 0
    Top = 143
    Width = 641
    Height = 106
    Caption = 'Resolution'
    TabOrder = 2
    object Label1: TLabel
      Left = 16
      Top = 24
      Width = 87
      Height = 21
      Caption = 'Temperature'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 192
      Top = 24
      Width = 64
      Height = 21
      Caption = 'Humidity'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object cbTemperatureResolution: TComboBox
      Left = 16
      Top = 51
      Width = 145
      Height = 29
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 0
      ParentFont = False
      TabOrder = 0
      Text = '14 Bit'
      Items.Strings = (
        '14 Bit'
        '11 Bit')
    end
    object cbHumidityResolution: TComboBox
      Left = 192
      Top = 51
      Width = 145
      Height = 29
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 0
      ParentFont = False
      TabOrder = 1
      Text = '14 Bit'
      Items.Strings = (
        '14 Bit'
        '11 Bit'
        '8 Bit')
    end
    object btnSetResolution: TButton
      Left = 550
      Top = 24
      Width = 75
      Height = 25
      Caption = 'Set'
      TabOrder = 2
      OnClick = btnSetResolutionClick
    end
  end
  object gb7SegDisplay: TGroupBox
    Left = 0
    Top = 245
    Width = 641
    Height = 81
    Caption = '7 Segment Display'
    TabOrder = 3
    object cb7Segment: TComboBox
      Left = 16
      Top = 32
      Width = 226
      Height = 29
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 0
      ParentFont = False
      TabOrder = 0
      Text = 'Temperature Resolution'
      Items.Strings = (
        'Temperature Resolution'
        'Humidity Resolution')
    end
    object btnSetDisplay: TButton
      Left = 550
      Top = 24
      Width = 75
      Height = 25
      Caption = 'Set'
      TabOrder = 1
      OnClick = btnSetDisplayClick
    end
  end
  object btnClose: TButton
    Left = 558
    Top = 332
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 4
    OnClick = btnCloseClick
  end
end
