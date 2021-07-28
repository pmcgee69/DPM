object DPMSearchBarFrame: TDPMSearchBarFrame
  Left = 0
  Top = 0
  Width = 767
  Height = 66
  TabOrder = 0
  DesignSize = (
    767
    66)
  object lblProject: TLabel
    Left = 360
    Top = 9
    Width = 117
    Height = 23
    Caption = 'THE PROJECT'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lblSources: TLabel
    Left = 498
    Top = 40
    Width = 88
    Height = 13
    Alignment = taRightJustify
    Anchors = [akTop, akRight]
    Caption = 'Package Sources :'
  end
  object lblPlatform: TLabel
    Left = 539
    Top = 12
    Width = 47
    Height = 13
    Alignment = taRightJustify
    Anchors = [akTop, akRight]
    Caption = 'Platform :'
    Visible = False
  end
  object txtSearch: TButtonedEdit
    Left = 8
    Top = 9
    Width = 241
    Height = 21
    Images = DPMEditorViewImages
    LeftButton.Enabled = False
    ParentShowHint = False
    RightButton.DisabledImageIndex = 0
    RightButton.Hint = 'Clear Search'
    RightButton.HotImageIndex = 6
    RightButton.ImageIndex = 5
    ShowHint = True
    TabOrder = 0
    TextHint = 'Search'
    OnChange = txtSearchChange
    OnKeyDown = txtSearchKeyDown
    OnRightButtonClick = txtSearchRightButtonClick
  end
  object chkIncludePrerelease: TCheckBox
    Left = 8
    Top = 38
    Width = 120
    Height = 20
    Caption = 'Include Prerelease'
    TabOrder = 1
    OnClick = chkIncludePrereleaseClick
  end
  object chkIncludeCommercial: TCheckBox
    Left = 152
    Top = 38
    Width = 128
    Height = 20
    Caption = 'Include Commercial'
    TabOrder = 2
    Visible = False
    OnClick = chkIncludeCommercialClick
  end
  object chkIncludeTrial: TCheckBox
    Left = 300
    Top = 38
    Width = 128
    Height = 20
    Caption = 'Include Trials'
    TabOrder = 3
    Visible = False
    OnClick = chkIncludeTrialClick
  end
  object btnRefresh: TButton
    Left = 255
    Top = 8
    Width = 25
    Height = 25
    Hint = 'Refresh'
    ImageAlignment = iaCenter
    ImageIndex = 2
    Images = DPMEditorViewImages
    TabOrder = 4
    OnClick = btnRefreshClick
  end
  object btnSettings: TButton
    Left = 286
    Top = 8
    Width = 25
    Height = 25
    Hint = 'Settings'
    ImageAlignment = iaCenter
    ImageIndex = 1
    Images = DPMEditorViewImages
    TabOrder = 5
    OnClick = btnSettingsClick
  end
  object btnAbout: TButton
    Left = 316
    Top = 8
    Width = 25
    Height = 25
    Hint = 'About'
    ImageAlignment = iaCenter
    ImageIndex = 3
    Images = DPMEditorViewImages
    TabOrder = 6
    OnClick = btnAboutClick
  end
  object cbSources: TComboBox
    Left = 592
    Top = 37
    Width = 160
    Height = 21
    Style = csDropDownList
    Anchors = [akTop, akRight]
    ItemIndex = 0
    TabOrder = 7
    Text = 'All'
    OnChange = cbSourcesChange
    Items.Strings = (
      'All'
      'DPM'
      'local'
      'Colossus')
  end
  object cbPlatforms: TComboBox
    Left = 592
    Top = 9
    Width = 160
    Height = 21
    Style = csDropDownList
    Anchors = [akTop, akRight]
    TabOrder = 8
    Visible = False
  end
  object DPMEditorViewImages: TImageList
    ColorDepth = cd32Bit
    Left = 712
    Bitmap = {
      494C010107000900080010001000FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000002000000001002000000000000020
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000020023061D077D125816DB16671AF316641AF3125216DB061A077D0002
      0023000000000000000000000000000000000000000000000000000000000000
      0002000000000000000000000000000000000000000000000000000000000000
      0000000000010000000000000000000000000000000000000000000000000000
      0002000000000000000000000000000000000000000000000000000000000000
      0000000000010000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000020E
      0353146918E6409F50FF86CA99FF9AD3AAFF9AD2AAFF82C795FF3B964AFF1458
      17E6020B035300000000000000000000000000000000000000000303032F4D4D
      4DE70A0A0A570000000000000000000000000000000000000000000000000A0A
      0A574D4D4DE60303032F000000000000000000000000000000000604002FA764
      00E7170E0057000000000000000000000000000000000000000000000000170E
      0057A66200E60604002F00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000020F0453177D
      1CF46BBD82FFA7DBB4FF86CC97FF64BB7BFF62B97AFF85CB97FFA4D9B3FF64B6
      7BFF166119F4020B0353000000000000000000000000000000014B4B4BE45E5E
      5EFF5C5C5CFB0A0A0A57000000000000000000000000000000000A0A0A565C5C
      5CFB5E5E5EFF4B4B4BE400000001000000000000000000000001A26100E4CC79
      00FFC67500FB170E005700000000000000000000000000000000170D0056C675
      00FBCC7900FFA26100E400000001000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000020022157824E570C1
      86FFA7DBB1FF5EBB75FF5AB971FF57B76EFF57B46DFF56B46DFF59B672FFA4D9
      B2FF67B77DFF135A17E500010022000000000000000000000000090909505A5A
      5AFA5E5E5EFF5C5C5CFB0A0A0A5600000000000000000A0A0A565C5C5CFB5E5E
      5EFF5A5A5AFA0909095000000000000000000000000000000000140B0050C475
      00FACC7900FFC67500FB170D00560000000000000000170D0056C67500FBCC79
      00FFC47500FA140B005000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000006270E7E4AAF62FFA9DD
      B3FF62C077FF5DBD6FFF73C484FFD4ECD9FF89CD98FF54B56AFF56B46CFF5AB6
      72FFA5DAB3FF3F9A4CFF061C077E000000000000000000000000000000000909
      09515A5A5AFA5E5E5EFF5C5C5CFB0A0A0A560A0A0A565C5C5CFB5E5E5EFF5A5A
      5AFA09090951000000000000000000000000000000000000000000000000140C
      0051C47500FACC7900FFC67500FB170D0056170D0056C67500FBCC7900FFC475
      00FA140C00510000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000167C2FDB90D29EFF8CD4
      99FF62C272FF77C986FFF2FAF4FFFFFFFFFFFDFEFDFF85CB95FF55B66BFF59B8
      70FF84CC96FF86C799FF125716DB000000000000000000000000000000000000
      0000090909515A5A5AFA5E5E5EFF5C5C5CFB5C5C5CFB5E5E5EFF5A5A5AFA0909
      0951000000000000000000000000000000000000000000000000000000000000
      0000140C0051C47500FACC7900FFC67500FBC67500FBCC7900FFC47500FA140C
      0051000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000001BA03CF6A5DCAEFF6ECA
      7DFF71CA7EFFF0F9F1FFFFFFFFFFEBF7EDFFFFFFFFFFFBFDFCFF87CD95FF59B8
      6FFF65BD7BFF9FD7AEFF18701AF6000000000000000000000000000000000000
      000000000000090909525A5A5AFA5E5E5EFF5E5E5EFF5A5A5AFA090909520000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000140C0052C47500FACC7900FFCC7900FFC47500FA140C00520000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000022A744F6A6DDB0FF70CC
      7EFF64C771FFAFE1B6FFD2EED6FF61C06EFFB7E3BEFFFFFFFFFFFBFDFCFF8BD0
      98FF67C07CFFA0D7ADFF18751AF6000000000000000000000000000000000000
      000000000000090909505A5A5AF95E5E5EFF5E5E5EFF595959F80808084E0000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000140B0050C27300F9CC7900FFCC7900FFC07300F8120B004E0000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000020893CDB94D7A0FF90D7
      9AFF67C974FF62C56DFF5FC36CFF5FC26DFF5FC16DFFB8E4BFFFFFFFFFFFE3F4
      E6FF8AD198FF8ACE9CFF136317DB000000000000000000000000000000000000
      0000090909515A5A5AF95E5E5EFF5C5C5CFC5C5C5CFC5E5E5EFF5A5A5AF90909
      0950000000000000000000000000000000000000000000000000000000000000
      0000140C0051C27300F9CC7900FFC77700FCC77700FCCC7900FFC27300F9140B
      0050000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000C2D157E55BE6EFFAEE1
      B6FF6BCC78FF66C870FF63C76EFF61C46CFF60C36CFF61C36FFFB5E3BDFF6DC7
      7CFFABDFB4FF46A85CFF0622087E000000000000000000000000000000000A0A
      0A535A5A5AFA5E5E5EFF5C5C5CFB0B0B0B5A0C0C0C5B5C5C5CFB5E5E5EFF5A5A
      5AFA09090951000000000000000000000000000000000000000000000000150C
      0053C47500FACC7900FFC67500FB190F005A190F005BC67500FBCC7900FFC475
      00FA140C00510000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000030122299843E57DCE
      8FFFADE1B4FF6BCC78FF68CA74FF66C870FF66C872FF66C873FF69C977FFABDF
      B3FF74C388FF157823E5000200220000000000000000000000000A0A0A565C5C
      5CFB5E5E5EFF5C5C5CFB0A0A0A5700000000000000000A0A0A575C5C5CFB5E5E
      5EFF5A5A5AFA0A0A0A5500000000000000000000000000000000170D0056C675
      00FBCC7900FFC67500FB170E00570000000000000000170E0057C67500FBCC79
      00FFC47500FA160D005500000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000061409532EAF
      4CF47DCE8FFFAEE1B6FF91D89CFF75CE82FF75CE82FF91D89CFFADE1B4FF76C8
      8AFF198E2CF402100553000000000000000000000000000000014D4D4DE65E5E
      5EFF5A5A5AFA0A0A0A56000000000000000000000000000000000A0A0A565C5C
      5CFB5E5E5EFF4C4C4CE500000001000000000000000000000001A66200E6CC79
      00FFC47500FA170D005600000000000000000000000000000000170D0056C675
      00FBCC7900FFA46200E500000001000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000615
      0A532B9D46E657C172FF95D7A2FFA4DCADFFA4DCADFF94D6A0FF4EB868FF188A
      35E60311065300000000000000000000000000000000000000000303032E4B4B
      4BE4090909510000000000000000000000000000000000000000000000000A0A
      0A554B4B4BE40303032E000000000000000000000000000000000603002EA261
      00E4140C0051000000000000000000000000000000000000000000000000160D
      0055A26100E40603002E00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000010301230D2E167D298E41DB2BAA4AF327A849F31E883BDB0A2B137D0003
      0123000000000000000000000000000000000000000000000000000000000000
      0001000000000000000000000000000000000000000000000000000000000000
      0000000000010000000000000000000000000000000000000000000000000000
      0001000000000000000000000000000000000000000000000000000000000000
      0000000000010000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000027272789585858CF000000140000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000002A2829888E8A8EF98E8A8EF92A282988000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000001000000010000000000000000000000000000000E000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000585858CF868686FF595959D00000
      0014000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000009201F
      20770000000B0E0D0D4E635F62D0969094FF969094FF635F62D00E0D0D4E0000
      000B201F20770000000900000000000000000000000000000000000000000000
      000000000001060706481D1E1E982E302EBE2E302EBE1C1E1D97060606470000
      00021C1E1D97000000090000000000000000000000001A1003553C25077F0000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000014595959D0868686FF5959
      59D0000000140000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000009535052BF9690
      94FF868084F1969094FF969094FF969094FF969094FF969094FF969094FF8680
      84F1969094FF535052BF00000009000000000000000000000000000000000101
      0122313433C6525654FE333634C91D1E1E981D1F1E99343634CA525654FE4144
      43E3525654FF000000090000000000000000000000001A100355F39620FF4B2E
      098E1A1003551A1003551A1003551A1003551A1003551A1003551A1003551A10
      0355160E034E0000000D00000000000000000000000000000014595959D08686
      86FF595959D00000001400000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000201F2077969094FF9690
      94FF969094FF969094FF969094FF969094FF969094FF969094FF969094FF9690
      94FF969094FF969094FF201F2077000000000000000000000000010101224347
      45E7363937CF0303033100000000000000000000000000000001282928B15256
      54FF525654FF000000090000000000000000000000001A100355F39620FFF396
      20FFF39620FFF39620FFF39620FFF39620FFF39620FFF39620FFF39620FFF396
      20FFF39620FFB36F17DB0000000D000000000000000000000000000000145959
      59D0868686FF595959D00101011C1B1B1B73585858CF808080FA808080FA5858
      58CF1C1C1C75000000090000000000000000000000000000000B868084F19690
      94FF969094FF696568D70E0D0D4E0000000C0000000C0E0D0D4E696568D79690
      94FF969094FF868084F10000000B000000000000000000000001313433C63639
      37CF0000000D000000000000000000000000000000000F100F6E393C3BD5393C
      3BD5393C3BD5000000070000000000000000000000001A100355F39620FFF396
      20FFF39620FFF39620FFF39620FFF39620FFF39620FFF39620FFF39620FFF396
      20FFF39620FFF39620FF160E034E000000000000000000000000000000000000
      0014595959D0868686FF808080FA868686FF868686FF868686FF868686FF8686
      86FF868686FF5E5E5ED60202021F00000000000000000E0D0D4E969094FF9690
      94FF696568D70000001000000000000000000000000000000000000000106965
      68D7969094FF969094FF0E0D0D4E000000000000000006070648525654FE0303
      0331000000000000000000000000000000000000000000000000000000000000
      000000000000060706490404043A00000000000000001A100355F39620FFF396
      20FFF39620FFF39620FFF39620FFF6AD51FFF6AD51FFF39620FFF39620FFF396
      20FFF39620FFF39620FF1A100355000000000000000000000000000000000000
      00000101011C808080FA868686FF606060D80D0D0D510000000D0000000D0D0D
      0D51606060D8868686FF5E5E5ED6000000092A282988635F62D0969094FF9690
      94FF0E0D0D4E0000000000000000000000000000000000000000000000000E0D
      0D4E969094FF969094FF635F62D02A282988000000001D1E1E98333634C90000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000333634C91D1E1E9800000000000000001A100355F39620FFF396
      20FFF39620FFF39620FFF39620FFFBDCB5FFFBDCB5FFF39620FFF39620FFF396
      20FFF39620FFF39620FF1A100355000000000000000000000000000000000000
      00001B1B1B73868686FF606060D8000000110000000000000000000000000000
      000000000011606060D8868686FF1C1C1C758E8A8EF9969094FF969094FF9690
      94FF0000000C0000000000000000000000000000000000000000000000000000
      000C969094FF969094FF969094FF8E8A8EF9000000002E302EBE1D1E1E980000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000001D1F1E992E302EBE00000000000000001A100355F39620FFF396
      20FFF39620FFF39620FFF39620FFFBDCB5FFFBDCB5FFF39620FFF39620FFF396
      20FFF39620FFF39620FF1A100355000000000000000000000000000000000000
      0000585858CF868686FF0D0D0D51000000000000000000000000000000000000
      0000000000000D0D0D51868686FF585858CF8E8A8EF9969094FF969094FF9690
      94FF0000000C0000000000000000000000000000000000000000000000000000
      000C969094FF969094FF969094FF8E8A8EF9000000002E302EBE1D1F1E990000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000001D1E1E982E302EBE00000000000000001A100355F39620FFF396
      20FFF39620FFF39620FFF39620FFFBDCB5FFFBDCB5FFF39620FFF39620FFF396
      20FFF39620FFF39620FF1A100355000000000000000000000000000000000000
      0000808080FA868686FF0000000D000000000000000000000000000000000000
      0000000000000000000D868686FF808080FA2A282988635F62D0969094FF9690
      94FF0E0D0D4E0000000000000000000000000000000000000000000000000E0D
      0D4E969094FF969094FF635F62D02A282988000000001D1E1E98323534C80000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000323534C81D1E1E9800000000000000001A100355F39620FFF396
      20FFF39620FFF39620FFF39620FFF6AD51FFF6AD51FFF39620FFF39620FFF396
      20FFF39620FFF39620FF1A100355000000000000000000000000000000000000
      0000808080FA868686FF0000000D000000000000000000000000000000000000
      0000000000000000000D868686FF808080FA000000000E0D0D4E969094FF9690
      94FF696568D70000001000000000000000000000000000000000000000106965
      68D7969094FF969094FF0E0D0D4E0000000000000000030303340202022E0000
      0000000000000000000000000000000000000000000000000000000000000000
      000003030331525654FE0607064800000000000000001A100355F39620FFF396
      20FFF39620FFF39620FFF39620FFF7BB6EFFF7BB6EFFF39620FFF39620FFF396
      20FFF39620FFF39620FF1A100355000000000000000000000000000000000000
      0000585858CF868686FF0D0D0D51000000000000000000000000000000000000
      0000000000000D0D0D50868686FF585858CF000000000000000B868084F19690
      94FF969094FF696568D70E0D0D4E0000000C0000000C0E0D0D4E696568D79690
      94FF969094FF868084F10000000B00000000000000000000000000000007393C
      3BD5393C3BD5393C3BD50F100F6E000000000000000000000000000000000000
      000D363937CF313433C60000000100000000000000001A100355F39620FFF396
      20FFF39620FFF39620FFF39620FFF7BB6FFFF7BB6EFFF39620FFF39620FFF396
      20FFF39620FFF39620FF1A100355000000000000000000000000000000000000
      00001C1C1C75868686FF606060D8000000110000000000000000000000000000
      000000000011606060D8868686FF1C1C1C7500000000201F2077969094FF9690
      94FF969094FF969094FF969094FF969094FF969094FF969094FF969094FF9690
      94FF969094FF969094FF201F2077000000000000000000000000000000095256
      54FF525654FF282928B100000001000000000000000000000000030303313639
      37CF434745E7010101220000000000000000000000000E08013EF39620FFF396
      20FFF39620FFF39620FFF39620FFF39620FFF39620FFF39620FFF39620FFF396
      20FFF39620FFF39620FF0E08013E000000000000000000000000000000000000
      0000000000095E5E5ED6868686FF606060D80D0D0D500000000D0000000D0D0D
      0D51606060D8868686FF5E5E5ED6000000090000000000000009535052BF9690
      94FF868084F1969094FF969094FF969094FF969094FF969094FF969094FF8680
      84F1969094FF535052BF00000009000000000000000000000000000000095256
      54FF414443E3525654FE333634C91D1E1E981D1E1E98323534C8525654FE3134
      33C60101012200000000000000000000000000000000000000014F310A92E58E
      1FF8F39620FFF39620FFF39620FFF39620FFF39620FFF39620FFF39620FFF396
      20FFE58E1FF84F310A9200000001000000000000000000000000000000000000
      0000000000000202021F5E5E5ED6868686FF868686FF868686FF868686FF8686
      86FF868686FF5E5E5ED60202021F00000000000000000000000000000009201F
      20770000000B0E0D0D4E635F62D0969094FF969094FF635F62D00E0D0D4E0000
      000B201F20770000000900000000000000000000000000000000000000091C1E
      1D9700000002060706481D1E1E982E302EBE2E302EBE1D1E1E98060706480000
      0001000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000091C1C1C75585858CF808080FA808080FA5858
      58CF1C1C1C750000000900000000000000000000000000000000000000000000
      000000000000000000002A2829888E8A8EF98E8A8EF92A282988000000000000
      0000000000000000000000000000000000000000000000000000000000010000
      0001000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000200000000100010000000000000100000000000000000000
      000000000000000000000000FFFFFF0000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000}
  end
  object DebounceTimer: TTimer
    Enabled = False
    Interval = 250
    OnTimer = DebounceTimerTimer
    Left = 552
  end
end
