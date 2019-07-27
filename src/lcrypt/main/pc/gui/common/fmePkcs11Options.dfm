inherited fmePkcs11Options: TfmePkcs11Options
  Width = 492
  Height = 289
  OnClick = FrameClick
  ExplicitWidth = 492
  ExplicitHeight = 289
  object gbPKCS11: TGroupBox
    Left = 16
    Top = 16
    Width = 457
    Height = 241
    Caption = 'Security Token/Smartcard support'
    TabOrder = 0
    object lblLibrary: TLabel
      Left = 36
      Top = 52
      Width = 82
      Height = 13
      Caption = 'PKCS#11 &library:'
      FocusControl = feLibFilename
    end
    object ckEnablePKCS11: TCheckBox
      Left = 16
      Top = 24
      Width = 421
      Height = 17
      Caption = '&Enable PKCS#11 support'
      TabOrder = 0
      OnClick = ControlChanged
    end
    object pbVerify: TButton
      Left = 232
      Top = 76
      Width = 75
      Height = 25
      Caption = '&Verify'
      TabOrder = 2
      OnClick = pbVerifyClick
    end
    object gbPKCS11AutoActions: TGroupBox
      Left = 16
      Top = 120
      Width = 425
      Height = 105
      Caption = 'Autoopen/lock'
      TabOrder = 3
      object lblAutoMountVolume: TLabel
        Left = 32
        Top = 48
        Width = 38
        Height = 13
        Caption = 'V&olume:'
      end
      object ckPKCS11AutoDismount: TCheckBox
        Left = 12
        Top = 72
        Width = 397
        Height = 17
        Caption = 'Auto &lock PKCS#11 containers when associated token is removed'
        TabOrder = 1
        OnClick = ControlChanged
      end
      object ckPKCS11AutoMount: TCheckBox
        Left = 12
        Top = 20
        Width = 397
        Height = 17
        Caption = 'Auto &open specified container on token insertion'
        TabOrder = 0
        OnClick = ControlChanged
      end
      inline OTFEFreeOTFEVolumeSelect1: TfmeVolumeSelect
        Left = 104
        Top = 44
        Width = 310
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        ExplicitLeft = 104
        ExplicitTop = 44
        ExplicitWidth = 310
        ExplicitHeight = 21
        DesignSize = (
          310
          21)
        inherited edFilename: TEdit
          Left = -3
          Top = 1
          ExplicitLeft = -3
          ExplicitTop = 1
        end
      end
    end
    inline feLibFilename: TSDUFilenameEdit
      Left = 148
      Top = 48
      Width = 293
      Height = 21
      Constraints.MaxHeight = 21
      Constraints.MinHeight = 21
      TabOrder = 1
      ExplicitLeft = 148
      ExplicitTop = 48
      ExplicitWidth = 293
      ExplicitHeight = 21
      DesignSize = (
        293
        21)
    end
    object pbAutoDetect: TButton
      Left = 148
      Top = 76
      Width = 75
      Height = 25
      Caption = '&Autodetect'
      TabOrder = 4
      OnClick = pbAutoDetectClick
    end
  end
end
