unit frmKeyEntryFreeOTFE;
 // Description: 
 // By Sarah Dean
 // Email: sdean12@sdean12.org
 // WWW:   http://www.SDean12.org/
 //
 // -----------------------------------------------------------------------------
 //

{ TODO 1 -otdk -crefactor : shares many fields with frmWizardChangePasswordCreateKeyfile - extract to frames}


interface

uses
  //delphi
  Classes, ComCtrls, Controls, Dialogs,
  ExtCtrls,
  Forms, Graphics, Messages, PasswordRichEdit, StdCtrls, SysUtils, Windows,
  // sdu , lc libs
  PKCS11Lib,
  OTFEFreeOTFE_U,
  OTFEFreeOTFEBase_U, pkcs11_library, pkcs11_session,
  SDUDropFiles, SDUFilenameEdit_U, SDUForms, SDUFrames,
lcTypes,
  SDUSpin64Units, Spin64, lcConsts,
  //lc  forms
  fmePassword;

type
  TfrmKeyEntryFreeOTFE = class (TSDUForm)
    SDUDropFiles_Keyfile: TSDUDropFiles;
    pnlButtons: TPanel;
    pbOK: TButton;
    pbCancel: TButton;
    pcKey: TPageControl;
    tsKey: TTabSheet;
    Label6: TLabel;
    lblDrive: TLabel;
    frmePassword1: TfrmePassword;
    feKeyfile: TSDUFilenameEdit;
    rbKeyfileFile: TRadioButton;
    cbPKCS11CDB: TComboBox;
    rbKeyfilePKCS11: TRadioButton;
    cbDrive: TComboBox;
    tsAdvanced: TTabSheet;
    gbAdvanced: TGroupBox;
    Label2: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    Label10: TLabel;
    seSaltLength: TSpinEdit64;
    seKeyIterations: TSpinEdit64;
    cbPKCS11SecretKey: TComboBox;
    pnlLower: TPanel;
    gbMountAs: TGroupBox;
    Label9: TLabel;
    cbMediaType: TComboBox;
    ckMountForAllUsers: TCheckBox;
    gbOffsetOptions: TGroupBox;
    Label8: TLabel;
    ckOffsetPointsToCDB: TCheckBox;
    se64UnitOffset: TSDUSpin64Unit_Storage;
    ckMountReadonly: TCheckBox;
    procedure pbOKClick(Sender: TObject);
    procedure preUserkeyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pbCancelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure feKeyfileChange(Sender: TObject);
    procedure seSaltLengthChange(Sender: TObject);
    procedure seKeyIterationsChange(Sender: TObject);
    procedure cbMediaTypeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
//    procedure pbAdvancedClick(Sender: TObject);
    procedure rbKeyfileFileClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbPKCS11CDBChange(Sender: TObject);
    procedure rbKeyfilePKCS11Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SDUDropFiles_KeyfileFileDrop(Sender: TObject; DropItem: String;
      DropPoint: TPoint);
  protected
    fTokenCDB:       TPKCS11CDBPtrArray;
    fTokenSecretKey: TPKCS11SecretKeyPtrArray;
    fPkcs11session:  TPKCS11Session;

    fsilentResult: TModalResult;
    fsilent:       Boolean;
    fVolumeFile:   String;
    fmountedDrive: DriveLetterChar;
    fisHidden :       Boolean;
    procedure _PopulateDrives();
    procedure _PopulateMountAs();
    procedure _PopulatePKCS11CDB();
    procedure _PopulatePKCS11SecretKey();

    procedure _DoCancel();

    procedure _EnableDisableControls();
    procedure _EnableDisableControls_Keyfile();
    procedure _EnableDisableControls_SecretKey();

    function GetDriveLetter(): Char;
    function GetMountAs(): TMountDiskType;
    function SetMountAs(mountAs: TMountDiskType): Boolean;

    function _IsSaltLengthValid(): Boolean;
    function _AttemptMount(): Boolean;

    function GetPKCS11Session(): TPKCS11Session;

    function _IsVolumeStoredOnReadonlyMedia(): Boolean;
    function _IsVolumeMarkedAsReadonly(): Boolean;

    // only show if not silent
    function _SilencableMessageDlg(Content: String; DlgType: TMsgDlgType): Integer;
//    procedure _DisplayAdvanced(displayAdvanced: Boolean);

  public

    procedure SetPassword(password: TSDUBytes);
    procedure SetReadOnly(ReadOnly: Boolean);
    procedure SetKeyfile(keyFilename: String);
    procedure SetOffset(offset: ULONGLONG);
    procedure SetSaltLength(saltLength: Integer);
    procedure SetKeyIterations(keyIterations: Integer);
    procedure SetCDBAtOffset(CDBAtOffset: Boolean);


//    property silent: Boolean Read fsilent Write fsilent;
    property VolumeFile: String Write fVolumeFile;
    property mountedDrive: DriveLetterChar Read fmountedDrive;
    property isHidden: Boolean Read fisHidden Write fisHidden;

  end;

{ TODO -otdk -crefactor : move into FreeOTFE utils file }
function MountFreeOTFE(volumeFilename: String;
  ReadOnly: Boolean = False; keyfile: String = ''; password: TSDUBytes = nil;
  offset: ULONGLONG = 0; noCDBAtOffset: Boolean = False;
  saltLength: Integer = DEFAULT_SALT_LENGTH;
  keyIterations: Integer = DEFAULT_KEY_ITERATIONS;isHidden: Boolean = False ): DriveLetterChar; overload;

function MountFreeOTFE(volumeFilename: String; var mountedAs: DriveLetterChar;
  ReadOnly: Boolean = False; keyfile: String = ''; password: TSDUBytes = nil;
  offset: ULONGLONG = 0; noCDBAtOffset: Boolean = False;
  saltLength: Integer = DEFAULT_SALT_LENGTH;
  keyIterations: Integer = DEFAULT_KEY_ITERATIONS;isHidden: Boolean = False): TMountResult; overload;

function MountFreeOTFE(volumeFilename: String; UserKey: TSDUBytes;
  Keyfile: String; CDB: Ansistring; // CDB data (e.g. already read in PKCS#11 token)
  // If CDB is specified, "Keyfile" will be ignored
  SlotID: Integer;
  // Set to PKCS#11 slot ID if PKCS#11 slot was *actually* used for mounting
  PKCS11Session: TPKCS11Session;  // Set to nil if not needed
  PKCS11SecretKeyRecord: PPKCS11SecretKey;  // Set to nil if not needed
  KeyIterations: Integer; UserDriveLetter: Char;
  // PC kernel drivers *only* - ignored otherwise
  MountReadonly: Boolean; MountMountAs: TMountDiskType;
  // PC kernel drivers *only* - ignored otherwise
  Offset: Int64; OffsetPointsToCDB: Boolean; SaltLength: Integer;  // In *bits*
  MountForAllUsers: Boolean;
  // PC kernel drivers *only* - ignored otherwise
  var mountedAs: DriveLetterChar): TMountResult;  overload;

implementation

{$R *.DFM}


uses
           //delphi
  ComObj,  // Required for StringToGUID
           // Disable useless warnings about faReadOnly, etc and FileSetAttr(...) being
           // platform-specific
           // This is ineffective?!
{$WARN SYMBOL_PLATFORM OFF}
  FileCtrl,  // Required for TDriveType
{$WARN SYMBOL_PLATFORM ON}
  //sdu, lc libs
  OTFEConsts_U,
  DriverAPI,
  pkcs11_object, lcDialogs,
  SDUi18n,
   sdugeneral, CommonSettings,  MainSettings, Shredder, VolumeFileAPI,
  lcCommandLine
  // lc forms
 ,
  frmPKCS11Session;

resourcestring
  RS_NOT_SELECTED   = '<none selected>';
  RS_NONE_AVAILABLE = '<none available>';

  RS_BUTTON_ADVANCED = '&Advanced';


function TfrmKeyEntryFreeOTFE.GetDriveLetter(): Char;
begin
  Result := #0;
  // Note: The item at index zero is "Use default"; #0 is returned for this
  if (cbDrive.ItemIndex > 0) then begin
    Result := cbDrive.Items[cbDrive.ItemIndex][1];
  end;

end;


procedure TfrmKeyEntryFreeOTFE.SetReadOnly(ReadOnly: Boolean);
begin
  ckMountReadonly.Checked := ReadOnly;
end;

procedure TfrmKeyEntryFreeOTFE.SetKeyfile(keyFilename: String);
begin
  rbKeyfileFile.Checked := True;
  feKeyfile.Filename    := keyFilename;
end;

procedure TfrmKeyEntryFreeOTFE.SetOffset(offset: ULONGLONG);
begin
  se64UnitOffset.Value := offset;
end;

procedure TfrmKeyEntryFreeOTFE.SetSaltLength(saltLength: Integer);
begin
  seSaltLength.Value := saltLength;
end;

procedure TfrmKeyEntryFreeOTFE.SetKeyIterations(keyIterations: Integer);
begin
  seKeyIterations.Value := keyIterations;
end;

procedure TfrmKeyEntryFreeOTFE.SetCDBAtOffset(CDBAtOffset: Boolean);
begin
  ckOffsetPointsToCDB.Checked := CDBAtOffset;
end;

function TfrmKeyEntryFreeOTFE.GetMountAs(): TMountDiskType;
var
  currMountAs: TMountDiskType;
begin
  Result := low(TMountDiskType);

  for currMountAs := low(TMountDiskType) to high(TMountDiskType) do begin
    if (cbMediaType.Items[cbMediaType.ItemIndex] = FreeOTFEMountAsTitle(currMountAs)) then begin
      Result := currMountAs;
      break;
    end;
  end;
end;

function TfrmKeyEntryFreeOTFE.SetMountAs(mountAs: TMountDiskType): Boolean;
var
  idx: Integer;
begin
  idx                   := cbMediaType.Items.IndexOf(FreeOTFEMountAsTitle(mountAs));
  cbMediaType.ItemIndex := idx;

  Result := (idx >= 0);
end;

procedure TfrmKeyEntryFreeOTFE._PopulateDrives();
var
  driveLetters: String;
  i:            Integer;
begin
  cbDrive.Items.Clear();
  cbDrive.Items.Add(_('Use default'));
  driveLetters := SDUGetUnusedDriveLetters();
  for i := 1 to length(driveLetters) do begin
    // Skip the drive letters traditionally reserved for floppy disk drives
    //    if (
    //        (driveLetters[i] <> 'A') AND
    //        (driveLetters[i] <> 'B')
    //       ) then
    //      begin
    cbDrive.Items.Add(driveLetters[i] + ':');
    //      end;
  end;

end;


procedure TfrmKeyEntryFreeOTFE._PopulateMountAs();
var
  currMountAs: TMountDiskType;
begin
  cbMediaType.Items.Clear();
  for currMountAs := low(TMountDiskType) to high(TMountDiskType) do begin
    if (currMountAs <> fomaUnknown) then begin
      cbMediaType.Items.Add(FreeOTFEMountAsTitle(currMountAs));
    end;

  end;

end;

procedure TfrmKeyEntryFreeOTFE._PopulatePKCS11CDB();
var
  errMsg:     String;
  i:          Integer;
  warnBadCDB: Boolean;
  session:    TPKCS11Session;
begin
  // Purge stored CDBs...
  DestroyAndFreeRecord_PKCS11CDB(FTokenCDB);

  session := GetPKCS11Session();

  cbPKCS11CDB.items.Clear();
  if (session <> nil) then begin
    if not (GetAllPKCS11CDB(session, FTokenCDB, errMsg)) then begin
      _SilencableMessageDlg(_('Unable to get list of header entries from Token') +
        SDUCRLF + SDUCRLF + errMsg, mtError);
    end;
  end;


  // Sanity check - the CDBs stored are sensible, right?
  warnBadCDB := False;
  // Populate combobox...
  for i := low(FTokenCDB) to high(FTokenCDB) do begin
    // Sanity check - the CDBs stored are sensible, right?
    if (length(FTokenCDB[i].CDB) <> (CRITICAL_DATA_LENGTH div 8)) then begin
      warnBadCDB := True;
    end else begin
      cbPKCS11CDB.items.AddObject(FTokenCDB[i].XLabel, TObject(FTokenCDB[i]));
    end;
  end;

  if warnBadCDB then begin
    _SilencableMessageDlg(
      _('One or more of the keyfiles stored on your token are invalid/corrupt and will be ignored') +
      SDUCRLF + SDUCRLF + _('Please check which keyfiles are stored on this token and correct'),
      mtWarning
      );
  end;

  if (cbPKCS11CDB.items.Count > 0) then begin
    cbPKCS11CDB.items.InsertObject(0, RS_NOT_SELECTED, nil);
  end else begin
    cbPKCS11CDB.items.InsertObject(0, RS_NONE_AVAILABLE, nil);
  end;

  // If there's only one item in the list (apart from the the none
  // available/selected), select it
  if (cbPKCS11CDB.items.Count = 2) then begin
    cbPKCS11CDB.ItemIndex := 1;
  end else begin
    // Select the none available/selected item
    cbPKCS11CDB.ItemIndex := 0;
  end;

end;

procedure TfrmKeyEntryFreeOTFE._PopulatePKCS11SecretKey();
var
  errMsg:  String;
  i:       Integer;
  session: TPKCS11Session;
begin
  // Purge stored CDBs...
  DestroyAndFreeRecord_PKCS11SecretKey(FTokenSecretKey);

  session := GetPKCS11Session();

  cbPKCS11SecretKey.items.Clear();
  if (session <> nil) then begin
    if not (GetAllPKCS11SecretKey(session, FTokenSecretKey, errMsg)) then begin
      _SilencableMessageDlg(_('Unable to get a list of secret keys from Token') +
        SDUCRLF + SDUCRLF + errMsg, mtError);
    end;
  end;


  // Populate combobox...
  for i := low(FTokenSecretKey) to high(FTokenSecretKey) do
    cbPKCS11SecretKey.items.AddObject(FTokenSecretKey[i].XLabel, TObject(FTokenSecretKey[i]));



  if (cbPKCS11SecretKey.items.Count > 0) then begin
    cbPKCS11SecretKey.items.InsertObject(0, RS_NOT_SELECTED, nil);
  end else begin
    cbPKCS11SecretKey.items.InsertObject(0, RS_NONE_AVAILABLE, nil);
  end;

  // Select the none available/selected item
  cbPKCS11SecretKey.ItemIndex := 0;
end;


// Returns TRUE if at least *one* volume was mounted successfully
function TfrmKeyEntryFreeOTFE._AttemptMount(): Boolean;
var
  errMsg:             String;
  cntMountOK:         Integer;
  cntMountFailed:     Integer;
  useKeyfilename:     String;
  usePKCS11CDB:       Ansistring;
  tmpCDBRecord:       PPKCS11CDB;
  usePKCS11SecretKey: PPKCS11SecretKey;
  usedSlotID:         Integer;
  mountRes:TMountResult;
begin
  Result := False;

  if _IsSaltLengthValid() then begin
    usedSlotID := PKCS11_NO_SLOT_ID;

    useKeyfilename := '';
    if rbKeyfileFile.Checked then
      useKeyfilename := feKeyfile.Filename;


    usePKCS11CDB := '';
    if rbKeyfilePKCS11.Checked then begin
      // >0 here because first item is "none selected/none available"
      if (cbPKCS11CDB.ItemIndex > 0) then begin
        tmpCDBRecord := PPKCS11CDB(cbPKCS11CDB.Items.Objects[cbPKCS11CDB.ItemIndex]);
        usePKCS11CDB := tmpCDBRecord.CDB;
        usedSlotID   := FPKCS11Session.SlotID;
      end;
    end;

    usePKCS11SecretKey := nil;
    // >0 here because first item is "none selected/none available"
    if (cbPKCS11SecretKey.ItemIndex > 0) then begin
      usePKCS11SecretKey := PPKCS11SecretKey(
        cbPKCS11SecretKey.Items.Objects[cbPKCS11SecretKey.ItemIndex]);
      usedSlotID         := FPKCS11Session.SlotID;
    end;

    fMountedDrive := #0;
    { TODO 1 -otdk -cbug : handle non ascii user keys - at least warn user }
      mountRes      := MountFreeOTFE(fVolumeFile, frmePassword1.GetKeyPhrase(),
      useKeyfilename, usePKCS11CDB, usedSlotID, FPKCS11Session, usePKCS11SecretKey,
      seKeyIterations.Value, GetDriveLetter(), ckMountReadonly.Checked,
      GetMountAs(), se64UnitOffset.Value, ckOffsetPointsToCDB.Checked,
      seSaltLength.Value, ckMountForAllUsers.Checked, fMountedDrive);

    result := mountRes = morOK;
    if (mountRes = morFail) then begin
      GetFreeOTFEBase.CountMountedResults(
        fMountedDrive,
        cntMountOK,
        cntMountFailed
        );

      if (cntMountOK = 0) then begin
        // No volumes were mounted...
        errMsg := _('Unable to open container.');

        // Specific problems when mounting...
        if (GetFreeOTFEBase.LastErrorCode = OTFE_ERR_WRONG_PASSWORD) then begin
          errMsg :=
            _('Unable to open container; please ensure that you entered the correct details (keyphrase, etc)');
          if (feKeyfile.Filename <> '') then begin
            errMsg := errMsg + SDUCRLF + SDUCRLF + _(
              'Please ensure that you check/uncheck the "Data from offset includes CDB" option, as appropriate for your container');
          end;
        end else
        if (GetFreeOTFEBase.LastErrorCode = OTFE_ERR_VOLUME_FILE_NOT_FOUND) then begin
          errMsg := _('Unable to find container/read container CDB.');
        end else
        if (GetFreeOTFEBase.LastErrorCode = OTFE_ERR_KEYFILE_NOT_FOUND) then begin
          errMsg := _('Unable to find keyfile/read keyfile.');
        end else
        if (GetFreeOTFEBase.LastErrorCode = OTFE_ERR_PKCS11_SECRET_KEY_DECRYPT_FAILURE) then begin
          errMsg := _('Unable to decrypt using PKCS#11 secret key.');
        end else
        if (GetFreeOTFEBase.LastErrorCode = OTFE_ERR_NO_FREE_DRIVE_LETTERS) then begin
          errMsg :=
            _('Unable to assign a new drive letter; please confirm you have drive letters free!');
        end else
        if (not (ckMountReadonly.Checked) and _IsVolumeStoredOnReadonlyMedia()) then begin
          errMsg :=
            _('Unable to open container; if a container to be mounted is stored on readonly media (e.g. CDROM or DVD), please check the "open readonly" option.');
        end else
        if (not (ckMountReadonly.Checked) and _IsVolumeMarkedAsReadonly()) then begin
          errMsg :=
            _('Unable to open container; if a container is readonly, please check the "open readonly" option.');
        end;

        _SilencableMessageDlg(errMSg, mtError);
      end else
      if (cntMountFailed > 0) then begin
        // At least one volume was mounted, but not all of them
        errMsg := SDUPluralMsg(cntMountOK, Format(
          _('%d container was opened successfully, but %d could not be opened'),
          [cntMountOK, cntMountFailed]), Format(
          _('%d containers were opened successfully, but %d could not be opened'),
          [cntMountOK, cntMountFailed]));

        _SilencableMessageDlg(errMSg, mtWarning);
        Result := True;
      end;

    end;
  end;

end;

function TfrmKeyEntryFreeOTFE._IsVolumeStoredOnReadonlyMedia(): Boolean;
var
  //  i:                   Integer;
  currVol:             String;
  testDriveColonSlash: String;
begin
  Result := False;

  //  for i := 0 to (fVolumeFiles.Count - 1) do begin
  currVol := fVolumeFile;

  if not GetFreeOTFEBase.IsPartitionUserModeName(currVol) then begin
    if (length(currVol) > 2) then begin
      // Check for ":" as 2nd char in filename; i.e. it's a filename with
      // <drive letter>:<path>\<filename>
      if (currVol[2] = ':') then begin
        testDriveColonSlash := currVol[1] + ':\';
        if (TDriveType(GetDriveType(PChar(testDriveColonSlash))) = dtCDROM) then begin
          //  the volume is stored on a CDROM (readonly media)
          Result := True;
          //            break;
        end;

      end;
    end;
  end;

  //  end;
end;

function TfrmKeyEntryFreeOTFE._IsVolumeMarkedAsReadonly(): Boolean;
var
  //  i:       Integer;
  currVol: String;
begin
  Result := False;

  //  for i := 0 to (fVolumeFiles.Count - 1) do begin
  currVol := fVolumeFile;

  if not GetFreeOTFEBase.IsPartitionUserModeName(currVol) then begin
    if (length(currVol) > 2) then begin
      // Check for ":" as 2nd char in filename; i.e. it's a filename with
      // <drive letter>:<path>\<filename>
      if (currVol[2] = ':') then begin
        if FileIsReadOnly(currVol) then begin
          // the volume is readonly
          Result := True;
          //            break;
        end;

      end;
    end;
  end;

  //  end;
end;

function TfrmKeyEntryFreeOTFE._IsSaltLengthValid(): Boolean;
begin
  Result := True;

  if (seSaltLength.Value mod 8 <> 0) then begin
    _SilencableMessageDlg(_('Salt length (in bits) must be a multiple of 8'), mtError);
    Result := False;
  end;
end;

procedure TfrmKeyEntryFreeOTFE.pbOKClick(Sender: TObject);
begin
  if _AttemptMount() then begin
    ModalResult := mrOk;
  end;
end;

procedure TfrmKeyEntryFreeOTFE.preUserkeyKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 27) then begin
    _DoCancel();
  end;
end;

procedure TfrmKeyEntryFreeOTFE.rbKeyfilePKCS11Click(Sender: TObject);
begin
  _PopulatePKCS11CDB();

  // If there are no keyfiles; flip back
  if (cbPKCS11CDB.items.Count <= 1) then begin
    // If we have a session, the user's logged into the token. However, no
    // keyfiles are on the token, warn the user
    if (FPKCS11Session <> nil) then begin
      _SilencableMessageDlg(
        _('No keyfiles could be found on the token inserted.'),
        mtInformation
        );
    end;

    rbKeyfileFile.Checked := True;
  end;

  _EnableDisableControls_Keyfile();
end;

procedure TfrmKeyEntryFreeOTFE.SDUDropFiles_KeyfileFileDrop(Sender: TObject;
  DropItem: String; DropPoint: TPoint);
begin
  SetKeyfile(DropItem);
end;

function TfrmKeyEntryFreeOTFE.GetPKCS11Session(): TPKCS11Session;
var
  pkcs11Dlg: TfrmPKCS11Session;
begin
  if (FPKCS11Session = nil) then begin
    if PKCS11LibraryReady(GPKCS11Library) then begin
      // Setup PKCS11 session, as appropriate
      pkcs11Dlg := TfrmPKCS11Session.Create(nil);
      try
        pkcs11Dlg.PKCS11LibObj := GPKCS11Library;
        pkcs11Dlg.AllowSkip    := False;
        if (pkcs11Dlg.ShowModal = mrOk) then begin
          FPKCS11Session := pkcs11Dlg.Session;
        end;
      finally
        pkcs11Dlg.Free();
      end;
    end;

  end;

  Result := FPKCS11Session;
end;

procedure TfrmKeyEntryFreeOTFE.rbKeyfileFileClick(Sender: TObject);
begin
  _EnableDisableControls_Keyfile();
end;

procedure TfrmKeyEntryFreeOTFE.pbCancelClick(Sender: TObject);
begin
  _DoCancel();
end;

procedure TfrmKeyEntryFreeOTFE._DoCancel();
begin
  ModalResult := mrCancel;
end;

procedure TfrmKeyEntryFreeOTFE.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Posting WM_CLOSE causes Delphi to reset ModalResult to mrCancel.
  // As a result, we reset ModalResult here
  if fsilent then
    ModalResult := FSilentResult;
end;

procedure TfrmKeyEntryFreeOTFE.FormCreate(Sender: TObject);
//var
//  advancedMountDlg   : Boolean;
begin
  inherited;
  //  fVolumeFiles := TStringList.Create;
  fVolumeFile := '';
  fsilent     := GetCmdLine.isSilent;

//  pnlLower.BevelOuter    := bvNone;
//  pnlLower.BevelInner    := bvNone;
//  pnlLower.Caption       := '';
//  pnlBasic.BevelOuter    := bvNone;
//  pnlBasic.BevelInner    := bvNone;
//  pnlBasic.Caption       := '';
//  pnlAdvanced.BevelOuter := bvNone;
//  pnlAdvanced.BevelInner := bvNone;
//  pnlAdvanced.Caption    := '';
//  pnlButtons.BevelOuter  := bvNone;
//  pnlButtons.BevelInner  := bvNone;
//  pnlButtons.Caption     := '';

  rbKeyfileFile.Checked := True;
  feKeyfile.Filename    := '';

  cbPKCS11CDB.Sorted := True;

  SetLength(FTokenCDB, 0);
  cbPKCS11CDB.Items.AddObject(RS_NOT_SELECTED, nil);

  SetLength(FTokenSecretKey, 0);
  cbPKCS11SecretKey.Items.AddObject(RS_NOT_SELECTED, nil);

  // FreeOTFE volumes CAN have newlines in the user's password
  //  preUserKey.WantReturns := True;
  frmePassword1.ClearPassword();

  se64UnitOffset.Value        := 0;
  ckOffsetPointsToCDB.Checked := True;

  seSaltLength.Increment := 8;
  seSaltLength.Value     := DEFAULT_SALT_LENGTH;

  seKeyIterations.MinValue  := 1;
  seKeyIterations.MaxValue  := 999999;
  // Need *some* upper value, otherwise setting MinValue won't work properly
  seKeyIterations.Increment := DEFAULT_KEY_ITERATIONS_INCREMENT;
  seKeyIterations.Value     := DEFAULT_KEY_ITERATIONS;

//  advancedMountDlg   := GetSettings().ShowAdvancedMountDialog;
//  _DisplayAdvanced(advancedMountDlg);


  feKeyfile.TabStop     := False;
  feKeyfile.FilterIndex := 0;
  feKeyfile.OnChange    := feKeyfileChange;

end;

procedure TfrmKeyEntryFreeOTFE.FormDestroy(Sender: TObject);
begin
  DestroyAndFreeRecord_PKCS11CDB(FTokenCDB);
  DestroyAndFreeRecord_PKCS11SecretKey(FTokenSecretKey);

  if (FPKCS11Session <> nil) then begin
    FPKCS11Session.Logout();
    FPKCS11Session.CloseSession();
    FPKCS11Session.Free();
  end;
  //  fVolumeFiles.Free;
end;

procedure TfrmKeyEntryFreeOTFE.FormShow(Sender: TObject);
var
  i:               Integer;
  currDriveLetter: DriveLetterChar;
begin
  feKeyfile.Filter             := FILE_FILTER_FLT_KEYFILES;
  feKeyfile.DefaultExt         := FILE_FILTER_DFLT_KEYFILES;
  feKeyfile.OpenDialog.Options := feKeyfile.OpenDialog.Options + [ofDontAddToRecent];
  feKeyfile.SaveDialog.Options := feKeyfile.SaveDialog.Options + [ofDontAddToRecent];

  // Note: PKCS#11 CDB list only populated when selected; it's at that point
  //       that the user is prompted for their token's PIN
  // PopulatePKCS11CDB();

  _PopulateDrives();
  if (cbDrive.Items.Count > 0) then begin
    cbDrive.ItemIndex := 0;

    if (GetSettings() is TMainSettings) then begin
      if (GetMainSettings().DefaultDriveChar <> #0) then begin
        // Start from 1; skip the default
        for i := 1 to (cbDrive.items.Count - 1) do begin
          currDriveLetter := cbDrive.Items[i][1];
          if (currDriveLetter >= GetMainSettings().DefaultDriveChar) then begin
            cbDrive.ItemIndex := i;
            break;
          end;
        end;
      end;
    end;
  end;

  _PopulateMountAs();

  if (GetSettings is TMainSettings) then begin
    SetMountAs(GetMainSettings().DefaultMountDiskType);
  end else begin
    SetMountAs(fomaRemovableDisk);
  end;

  // Certain controls only visble if used in conjunction with drive mounting
  gbMountAs.Visible := GetFreeOTFEBase is TOTFEFreeOTFE;
  lblDrive.Visible  := GetFreeOTFEBase is TOTFEFreeOTFE;
  cbDrive.Visible   := GetFreeOTFEBase is TOTFEFreeOTFE;

  // If the mount options groupbox isn't visible, widen the volume options
  // groupbox so that there's no blank space to its left
  if not (gbMountAs.Visible) then begin
 //   gbVolumeOptions.Width := gbVolumeOptions.Width + (gbVolumeOptions.left - gbMountAs.left);
//    gbVolumeOptions.left  := gbMountAs.left;
  end;

  // Default to TRUE to allow formatting under Windows Vista
  ckMountForAllUsers.Checked := True;

  _EnableDisableControls();
  _PopulatePKCS11SecretKey();

  if fSilent then begin
    if _AttemptMount() then begin
      ModalResult := mrOk;
    end else begin
      ModalResult := mrCancel;
    end;

    FSilentResult := ModalResult;

    PostMessage(Handle, WM_CLOSE, 0, 0);
  end;


  SDUDropFiles_Keyfile.Active := True;

  // work around bug whereby password not shown.
  pcKey.TabIndex:= 1;
    pcKey.TabIndex:= 0;



end;

procedure TfrmKeyEntryFreeOTFE._EnableDisableControls();
var
  tmpMountAs: TMountDiskType;
begin
  // Ensure we know what to mount as
  ckMountReadonly.Enabled := False;
  tmpMountAs              := GetMountAs();
  if not (CAN_WRITE_TO_MOUNT_TYPE[tmpMountAs]) then begin
    ckMountReadonly.Checked := True;
  end;
  SDUEnableControl(ckMountReadonly, CAN_WRITE_TO_MOUNT_TYPE[tmpMountAs]);

  _EnableDisableControls_Keyfile();
  _EnableDisableControls_SecretKey();

  pbOK.Enabled := (tmpMountAs <> fomaUnknown) and (cbDrive.ItemIndex >= 0) and
    (seKeyIterations.Value > 0) and (seSaltLength.Value >= 0);
end;

procedure TfrmKeyEntryFreeOTFE._EnableDisableControls_SecretKey();
begin
  // PKCS#11 secret key controls...
  SDUEnableControl(cbPKCS11SecretKey, (
    // Must have more than the "none" item
    (cbPKCS11SecretKey.items.Count > 1)));
end;

procedure TfrmKeyEntryFreeOTFE._EnableDisableControls_Keyfile();
begin
  // We never disable rbKeyfileFile, as keeping it enabled gives the user a
  // visual clue that they can enter a keyfile filename
  // SDUEnableControl(rbKeyfileFile, PKCS11LibraryReady(fFreeOTFEObj.PKCS11Library));

  // Protect as this can be called as part of creation
  if (GetFreeOTFEBase <> nil) then begin
    SDUEnableControl(rbKeyfilePKCS11, PKCS11LibraryReady(GPKCS11Library));
    if not (PKCS11LibraryReady(GPKCS11Library)) then begin
      rbKeyfileFile.Checked   := True;
      rbKeyfilePKCS11.Checked := False;
    end;
  end;

  // File based keyfile controls...
  SDUEnableControl(feKeyfile, rbKeyfileFile.Checked);

  // PKCS#11 based keyfile controls...
  SDUEnableControl(cbPKCS11CDB, (rbKeyfilePKCS11.Checked and
    // Must have more than the "none" item
    (cbPKCS11CDB.items.Count > 1)));


  // If no keyfile/PKCS#11 CDB is specified, then the CDB must reside within
  // the volume file
  if ((rbKeyfileFile.Checked and (feKeyfile.Filename = '')) or
    (rbKeyfilePKCS11.Checked and (cbPKCS11CDB.ItemIndex = 0) // None available/none selected
    )) then begin
    ckOffsetPointsToCDB.Enabled := False;
    ckOffsetPointsToCDB.Checked := True;
  end else begin
    // If a keyfile is specified, then the user can specify if the volume file
    // includes a CDB
    ckOffsetPointsToCDB.Enabled := True;
  end;

end;

//procedure TfrmKeyEntryFreeOTFE.pbAdvancedClick(Sender: TObject);
//begin
//  _DisplayAdvanced(not (gbAdvanced.Visible));
//end;

procedure TfrmKeyEntryFreeOTFE.feKeyfileChange(Sender: TObject);
begin
  _EnableDisableControls();

end;

procedure TfrmKeyEntryFreeOTFE.seSaltLengthChange(Sender: TObject);
begin
  _EnableDisableControls();
end;

procedure TfrmKeyEntryFreeOTFE.seKeyIterationsChange(Sender: TObject);
begin
  _EnableDisableControls();
end;


procedure TfrmKeyEntryFreeOTFE.cbMediaTypeChange(Sender: TObject);
begin
  _EnableDisableControls();

end;

procedure TfrmKeyEntryFreeOTFE.cbPKCS11CDBChange(Sender: TObject);
begin
  _EnableDisableControls();
end;
//
//procedure TfrmKeyEntryFreeOTFE._DisplayAdvanced(displayAdvanced: Boolean);
//var
//  displayChanged: Boolean;
//begin
//  displayChanged      := (gbAdvanced.Visible <> displayAdvanced);
//  gbAdvanced.Visible := displayAdvanced;
//  pnlLower.Visible := displayAdvanced;
//
//  if displayChanged then begin
//    if displayAdvanced then begin
//      self.Height := self.Height + gbAdvanced.Height + pnlLower.Height ;
//
//      _PopulatePKCS11SecretKey();
//      _EnableDisableControls_SecretKey();
//    end else begin
//      self.Height := self.Height - gbAdvanced.Height - pnlLower.Height;
//    end;
//
//  end;
//
//  if displayAdvanced then begin
//    pbAdvanced.Caption := '<< ' + RS_BUTTON_ADVANCED;
//  end else begin
//    pbAdvanced.Caption := RS_BUTTON_ADVANCED + ' >>';
//  end;
//
//end;

procedure TfrmKeyEntryFreeOTFE.SetPassword(password: TSDUBytes);
begin
  frmePassword1.SetKeyPhrase(password);
end;

// Display message only if not Silent
function TfrmKeyEntryFreeOTFE._SilencableMessageDlg(Content: String; DlgType: TMsgDlgType): Integer;
begin
  Result := mrOk;
  if not fsilent then
    Result := SDUMessageDlg(Content, DlgType);
end;


function MountFreeOTFE(volumeFilename: String;
  var mountedAs: DriveLetterChar; ReadOnly: Boolean = False; keyfile: String = '';
  password: TSDUBytes = nil; offset: ULONGLONG = 0; noCDBAtOffset: Boolean = False;
   saltLength: Integer = DEFAULT_SALT_LENGTH;
  keyIterations: Integer = DEFAULT_KEY_ITERATIONS;isHidden: Boolean = False): TMountResult;
var
  keyEntryDlg:      TfrmKeyEntryFreeOTFE;
  mr:               Integer;
begin
  GetFreeOTFEBase().LastErrorCode := OTFE_ERR_SUCCESS;
  Result    := morFail;
  mountedAs := AnsiChar(#0);

  GetFreeOTFEBase().CheckActive();

  if (GetFreeOTFEBase().LastErrorCode = OTFE_ERR_SUCCESS) then begin
    keyEntryDlg := TfrmKeyEntryFreeOTFE.Create(nil);
    try

//      keyEntryDlg.Silent := silent;
      keyEntryDlg.SetPassword(password);
      keyEntryDlg.SetReadonly(ReadOnly);
      keyEntryDlg.SetOffset(offset);
      keyEntryDlg.SetCDBAtOffset(not (noCDBAtOffset));
      keyEntryDlg.SetSaltLength(saltLength);
      keyEntryDlg.SetKeyIterations(keyIterations);
      keyEntryDlg.SetKeyfile(keyfile);

        keyEntryDlg.VolumeFile := volumeFilename;
      keyEntryDlg.ishidden := isHidden;
      mr := keyEntryDlg.ShowModal();
      if (mr = mrCancel) then begin
//        GetFreeOTFEBase().LastErrorCode := OTFE_ERR_USER_CANCEL;
        result  := morCancel;
      end else begin
        mountedAs := keyEntryDlg.MountedDrive;
        Result    := morOK;
      end;

    finally
      keyEntryDlg.Free()
    end;
  end;
end;


// ----------------------------------------------------------------------------
function MountFreeOTFE(volumeFilename: String;
  ReadOnly: Boolean = False; keyfile: String = ''; password: TSDUBytes = nil;
  offset: ULONGLONG = 0; noCDBAtOffset: Boolean = False;
  saltLength: Integer = DEFAULT_SALT_LENGTH;
  keyIterations: Integer = DEFAULT_KEY_ITERATIONS;isHidden: Boolean = False): DriveLetterChar;
var
  mountedAs: DriveLetterChar;
begin
  GetFreeOTFEBase().LastErrorCode := OTFE_ERR_SUCCESS;
  Result := #0;

  if MountFreeOTFE(volumeFilename, mountedAs, ReadOnly, keyfile, password,
    offset, noCDBAtOffset,  saltLength, keyIterations,isHidden) = morOK then begin
    Result := mountedAs;
  end;

end;



 // ----------------------------------------------------------------------------
 // Important: To use CDB from keyfile/volume, "CDB" *must* be set to an empty
 //            string
function MountFreeOTFE(volumeFilename: String;
  UserKey: TSDUBytes; Keyfile: String; CDB: Ansistring;
  // CDB data (e.g. already read in PKCS#11 token)
  // If CDB is specified, "Keyfile" will be ignored
  SlotID: Integer;
  // Set to PKCS#11 slot ID if PKCS#11 slot was *actually* used for mounting
  PKCS11Session: TPKCS11Session;  // Set to nil if not needed
  PKCS11SecretKeyRecord: PPKCS11SecretKey;  // Set to nil if not needed
  KeyIterations: Integer; UserDriveLetter: Char; MountReadonly: Boolean;
  MountMountAs: TMountDiskType; Offset: Int64; OffsetPointsToCDB: Boolean;
  SaltLength: Integer;  // In *bits*
  MountForAllUsers: Boolean; var mountedAs: DriveLetterChar): TMountResult;

var
  currMountFilename: String;
  useFileOffset:     Int64;
  mountDriveLetter:  Char;

  volumeDetails: TVolumeDetailsBlock;
  CDBMetaData:   TCDBMetaData;

  useCDB:       Ansistring;
  decryptedCDB: Ansistring;
  commonCDB:    Ansistring;
  errMsg:       String;
  ok   : Boolean;

  prevCursor: TCursor;
begin
  GetFreeOTFEBase().LastErrorCode := OTFE_ERR_SUCCESS;
  Result := morOK;

  GetFreeOTFEBase().CheckActive();

  commonCDB := '';
  if (CDB <> '') then begin
    commonCDB := CDB;
  end else
  if (Keyfile <> '') then begin
    // Attempt to obtain the current file's critical data
    ok := GetFreeOTFEBase().ReadRawVolumeCriticalData(Keyfile, 0, commonCDB);
    if not ok then begin
      GetFreeOTFEBase().LastErrorCode := OTFE_ERR_KEYFILE_NOT_FOUND;
      Result := morFail;
    end;
  end;

  if Result = morOK then begin
    prevCursor    := Screen.Cursor;
    Screen.Cursor := crHourglass;
    try

      useCDB            := commonCDB;
      currMountFilename := volumeFilename;

      if (useCDB = '') then begin
        // Attempt to obtain the current file's critical data
        if not (GetFreeOTFEBase().ReadRawVolumeCriticalData(volumeFilename, Offset, useCDB)) then        begin
          // Bad file...
          GetFreeOTFEBase().LastErrorCode := OTFE_ERR_VOLUME_FILE_NOT_FOUND;
          mountedAs := #0;
          Result := morFail;
          exit;
        end;
      end;

      // If CDB encrypted by PKCS#11 secret key, decrypt it now...
      decryptedCDB := useCDB;
      if ((PKCS11Session <> nil) and (PKCS11SecretKeyRecord <> nil)) then begin
        if not (PKCS11DecryptCDBWithSecretKey(PKCS11Session, PKCS11SecretKeyRecord,
          useCDB, decryptedCDB, errMsg)) then begin
          GetFreeOTFEBase().LastErrorCode := OTFE_ERR_PKCS11_SECRET_KEY_DECRYPT_FAILURE;
          mountedAs := #0;
          Result := morFail;
          // Bail out; can't continue as problem with token
          exit;
        end;
      end;

      // Process CDB passed in into CDBMetaData
      if not (GetFreeOTFEBase().ReadVolumeCriticalData_CDB(decryptedCDB, UserKey, SaltLength,
        // In *bits*
        KeyIterations, volumeDetails, CDBMetaData)) then begin
        // Wrong password, bad volume file, correct hash/cypher driver not installed
        GetFreeOTFEBase().LastErrorCode := OTFE_ERR_WRONG_PASSWORD;
        mountedAs := #0;
        Result := morFail;
        exit;
      end;

      // Mount the volume
      if (volumeDetails.RequestedDriveLetter = #0) then
        // Nudge on to prevent getting drive A: or B:
        volumeDetails.RequestedDriveLetter := 'C';


      mountDriveLetter := GetFreeOTFEBase().GetNextDriveLetter(UserDriveLetter,
        volumeDetails.RequestedDriveLetter);
      if (mountDriveLetter = #0) then begin
        // Skip onto next volume file...
        GetFreeOTFEBase().LastErrorCode := OTFE_ERR_NO_FREE_DRIVE_LETTERS;
        mountedAs := #0;
        Result := morFail;
        exit;
      end;

      // Locate where the actual encrypted partition starts within the
      // volume file
      useFileOffset := Offset;
      if OffsetPointsToCDB then
        useFileOffset := useFileOffset + Int64((CRITICAL_DATA_LENGTH div 8));


      if GetFreeOTFEBase().CreateMountDiskDevice(currMountFilename,
        volumeDetails.MasterKey, volumeDetails.SectorIVGenMethod,
        volumeDetails.VolumeIV, MountReadonly, CDBMetaData.HashDriver,
        CDBMetaData.HashGUID, CDBMetaData.CypherDriver,  // IV cypher
        CDBMetaData.CypherGUID,    // IV cypher
        CDBMetaData.CypherDriver,  // Main cypher
        CDBMetaData.CypherGUID,    // Main cypher
        volumeDetails.VolumeFlags, mountDriveLetter, useFileOffset,
        volumeDetails.PartitionLen, False, SlotID, MountMountAs, MountForAllUsers) then begin
        mountedAs := mountDriveLetter;
      end else begin
        mountedAs := #0;
        // LastErrorCode set by MountDiskDevice (called by CreateMountDiskDevice)????
        GetFreeOTFEBase().LastErrorCode := OTFE_ERR_MOUNT_FAILURE;
        Result := morFail;
      end;


    finally
      Screen.Cursor := prevCursor;
    end;

  end;


  // Pad out unmounted volume files...
  // Yes, it is "+1"; if you have only 1 volume file, you want exactly one #0
  //  for i := (length(mountedAs) + 1) to (volumeFilenames.Count) do begin
  //    mountedAs := mountedAs + #0;
  //
  //    // This should not be needed; included to ensure sanity...
  //    Result := False;
  //  end;
end;


end.

