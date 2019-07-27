unit frmHdrBackupRestore;
 // Description:
 // By Sarah Dean
 // Email: sdean12@sdean12.org
 // WWW:   http://www.FreeOTFE.org/
 //
{backs up and restores hdr for fotfe and linux vols}
                                                       

interface

uses
  //delphi
  Buttons, Classes, Controls, Dialogs, Forms, Graphics, Messages,
  Spin64, StdCtrls, SysUtils, Windows,
  //sdu
  SDUForms, SDUFrames, SDUSpin64Units,
  // LibreCrypt
  fmeVolumeSelect, OTFEFreeOTFEBase_U;

type
  TCDBOperationType = (opBackup, opRestore);

  TfrmHdrBackupRestore = class (TSDUForm)
    pbCancel:       TButton;
    pbOK:           TButton;
    gbDest:         TGroupBox;
    lblFileDescDest: TLabel;
    lblOffsetDest:  TLabel;
    gbSrc:          TGroupBox;
    lblFileDescSrc: TLabel;
    lblOffsetSrc:   TLabel;
    se64UnitOffsetSrc: TSDUSpin64Unit_Storage;
    se64UnitOffsetDest: TSDUSpin64Unit_Storage;
    SelectSrcFile:  TfmeVolumeSelect;
    SelectDestFile: TfmeVolumeSelect;
    procedure FormCreate(Sender: TObject);
    procedure pbOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ControlChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

  private
    procedure SetSrcFilename(const Value: String);
    procedure SetDestFilename(const Value: String);
  protected
    FOpType:       TCDBOperationType;
    fsilent:       Boolean;
    fsilentResult: TModalResult;

    function GetSrcFilename(): String;
    function GetSrcOffset(): Int64;
    function GetDestFilename(): String;
    function GetDestOffset(): Int64;

    procedure SetOpType(dType: TCDBOperationType);

    function SanityCheckBackup(): Boolean;
    function SanityCheckRestore(): Boolean;

    procedure EnableDisableControls();

  public

    property OpType: TCDBOperationType Read FOpType Write SetOpType;
    property silent: Boolean Read fsilent Write fsilent;
    property SrcFilename: String Read GetSrcFilename Write SetSrcFilename;
    property SrcOffset: Int64 Read GetSrcOffset;
    property DestFilename: String Read GetDestFilename Write SetDestFilename;
    property DestOffset: Int64 Read GetDestOffset;

  end;


implementation

{$R *.DFM}


uses
  //delphi

 //lc utils
lcConsts,

  lcDialogs,
  DriverAPI, SDUGeneral,
  SDUi18n;  // Required for CRITICAL_DATA_LENGTH

{$IFDEF _NEVER_DEFINED}
// This is just a dummy const to fool dxGetText when extracting message
// information
// This const is never used; it's #ifdef'd out - SDUCRLF in the code refers to
// picks up SDUGeneral.SDUCRLF
const
  SDUCRLF = ''#13#10;
{$ENDIF}

resourcestring
  USE_NOT_IN_USE = 'Please ensure that the container is not open, or otherwise in use';

procedure TfrmHdrBackupRestore.FormShow(Sender: TObject);
begin
  if not fsilent then begin
    SelectSrcFile.Filename  := '';
    SelectDestFile.Filename := '';
  end;

  //  SelectSrcFile.OTFEFreeOTFE := OTFEFreeOTFE;

  //  SelectDestFile.OTFEFreeOTFE := OTFEFreeOTFE;

  se64UnitOffsetSrc.Value  := 0;
  se64UnitOffsetDest.Value := 0;

  { TODO -otdk -crefactor : have permanant header and volume sections and get rid of swapping round }
  if (FOpType = opBackup) then begin
    self.Caption := _('Backup FreeOTFE Container Header');

    gbSrc.Caption          := _('Container details');
    lblFileDescSrc.Caption := _('&Container:');

    gbDest.Caption          := _('Backup details');
    lblFileDescDest.Caption := _('&Backup filename:');

    // Backup file starts from 0 - don't allow the user to change offset
    se64UnitOffsetDest.Visible := False;
    lblOffsetDest.Visible      := False;

  end else begin
    self.Caption := _('Restore FreeOTFE Container Header');

    gbSrc.Caption          := _('Backup details');
    lblFileDescSrc.Caption := _('&Backup filename:');

    gbDest.Caption          := _('Container details');
    lblFileDescDest.Caption := _('&Container:');

    // Backup file starts from 0 - don't allow the user to change offset
    se64UnitOffsetSrc.Visible := False;
    lblOffsetSrc.Visible      := False;
  end;

  EnableDisableControls();

  if fSilent then begin
    ModalResult := mrCancel;
    pbOKClick(self);
    FSilentResult := ModalResult;
    // if testing and no errors, then close dlg
    if ModalResult = mrOk then
      PostMessage(Handle, WM_CLOSE, 0, 0);
  end;

end;



procedure TfrmHdrBackupRestore.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  // Posting WM_CLOSE causes Delphi to reset ModalResult to mrCancel.
  // As a result, we reset ModalResult here, note will only close automatically if mr = mrok anyway
  if fsilent then
    ModalResult := FSilentResult;

end;

procedure TfrmHdrBackupRestore.FormCreate(Sender: TObject);
begin
  SelectSrcFile.SelectFor  := osOpen;
  SelectDestFile.SelectFor := osSave;

  SelectDestFile.OnChange := ControlChange;
  SelectSrcFile.OnChange  := ControlChange;

  // Default to backup...
  SetOpType(opBackup);
end;


 // Sanity check a BACKUP operation
 // Returns TRUE if all values entered make sense, otherwise FALSE
function TfrmHdrBackupRestore.SanityCheckBackup(): Boolean;
begin
  Result := True;

  // BACKUP SANITY CHECKS

  // If we're backing up, the destination filename MUST NOT EXIST.
  // This is done for safety - if we just prompted the user and asked them
  // to continue, the user may just slam "YES!" without checking - and if
  // they've transposed the filenames, this would overwrite the volume file!
  // Note: You can only backup to a *file*
  if FileExists(GetDestFilename) then begin
    SDUMessageDlg(
      _('The file you are attempting to backup to already exists.') + SDUCRLF +
      SDUCRLF + _(
      'Please delete this backup file and try again, or specify a different filename to backup to.'),
      mtError, [mbOK], 0);
    Result := False;
  end;

  // Note: We're not worried if the source doens't exist - the backup operation
  //       will simply fail in this case

end;


 // Sanity check a RESTORE operation
 // Returns TRUE if all values entered make sense, otherwise FALSE
function TfrmHdrBackupRestore.SanityCheckRestore(): Boolean;
var
  confirm: DWORD;
  srcSize: ULONGLONG;
begin
  Result := False;

  // RESTORE SANITY CHECKS

  // Ensure that both the source (backup) and destination (volume) files
  // exist
  // Note: You can only restore from a *file*
  if not (FileExists(GetSrcFilename)) then begin
    SDUMessageDlg(_('The backup file specified does not exist.'), mtError, [mbOK], 0);
  end else begin
    // Note: We're not worried if the destination doens't exist - the restore
    //       operation will simply fail in this case

    // Check that the source file is the right size for a backup file
    srcSize := SDUGetFileSize(GetSrcFilename);
    if (srcSize <> (CRITICAL_DATA_LENGTH div 8)) then begin
      SDUMessageDlg(
        _('The source file you specified does not appear to be the right size for a backup file') +
        SDUCRLF + SDUCRLF + _('Please check your settings and try again.'),
        mtError
        );
    end else begin
      // Get the user to confirm the restoration

      // We don't need this confirmation when BACKING UP - only when RESTORING
      // Backup is relativly safe as it backs up to a file which doesn't exist
      if fsilent then
        confirm := mrYes
      else
        confirm := SDUMessageDlg(Format(_(
          'Please confirm: Do you wish to restore the header from backup file:' +
          SDUCRLF + SDUCRLF + '%s' + SDUCRLF + SDUCRLF + 'Into the container:' +
          SDUCRLF + SDUCRLF + '%s' + SDUCRLF + SDUCRLF +
          'Starting from offset %d in the container?'), [GetSrcFilename,
          GetDestFilename, GetDestOffset]), mtConfirmation, [mbYes, mbNo], 0);

      if (confirm = mrYes) then begin
        Result := True;
      end;

    end;  // ELSE PART - if (not(CheckDestLarger())) then

  end;  // ELSE PART - if not(FileExists(GetSrcFilename()) then

end;


procedure TfrmHdrBackupRestore.pbOKClick(Sender: TObject);
var
  allOK: Boolean;
begin
  allOK := False;

  if (FOpType = opBackup) then begin
    if SanityCheckBackup() then begin
      if GetFreeOTFEBase().BackupVolumeCriticalData(GetSrcFilename, GetSrcOffset,
        GetDestFilename) then begin
        if not fsilent then
          SDUMessageDlg(_('Backup operation completed successfully.'), mtInformation);
        allOK := True;
      end else begin
        SDUMessageDlg(
          _('Backup operation failed.') + SDUCRLF + SDUCRLF + USE_NOT_IN_USE,
          mtError
          );
      end;

    end;

  end  // if (dlgType = opBackup) then
  else begin
    if SanityCheckRestore() then begin
      if GetFreeOTFEBase().RestoreVolumeCriticalData(GetSrcFilename, GetDestFilename,
        GetDestOffset) then begin
        if not fsilent then
          SDUMessageDlg(_('Restore operation completed successfully.'), mtInformation);
        allOK := True;
      end else begin
        SDUMessageDlg(
          _('Restore operation failed.') + SDUCRLF + SDUCRLF + USE_NOT_IN_USE,
          mtError
          );
      end;

    end;

  end;  // ELSE PART - if (dlgType = opBackup) then


  if allOK then
    ModalResult := mrOk;

end;

function TfrmHdrBackupRestore.GetSrcFilename(): String;
begin
  Result := SelectSrcFile.Filename;
end;

procedure TfrmHdrBackupRestore.SetSrcFilename(const Value: String);
begin
  SelectSrcFile.Filename := Value;
end;


function TfrmHdrBackupRestore.GetSrcOffset(): Int64;
begin
  Result := se64UnitOffsetSrc.Value;
end;

function TfrmHdrBackupRestore.GetDestFilename(): String;
begin
  Result := SelectDestFile.Filename;
end;

procedure TfrmHdrBackupRestore.SetDestFilename(const Value: String);
begin
  SelectDestFile.Filename := Value;
end;

function TfrmHdrBackupRestore.GetDestOffset(): Int64;
begin
  Result := se64UnitOffsetDest.Value;
end;


procedure TfrmHdrBackupRestore.EnableDisableControls();
begin
  // Src and dest must be specified, and different
  // Offsets must be 0 or +ve
  pbOK.Enabled :=
    (SelectSrcFile.Filename <> '') and (SelectDestFile.Filename <> '') and
    (SelectSrcFile.Filename <> SelectDestFile.Filename) and  // Silly!
    (se64UnitOffsetSrc.Value >= 0) and (se64UnitOffsetDest.Value >= 0);

end;



procedure TfrmHdrBackupRestore.SetOpType(dType: TCDBOperationType);
begin
  FOpType := dType;

  SelectSrcFile.AllowPartitionSelect  := (FOpType = opBackup);
  SelectDestFile.AllowPartitionSelect := (FOpType <> opBackup);

  if (FOpType = opBackup) then begin
    SelectSrcFile.SetFileSelectFilter( FILE_FILTER_FLT_VOLUMESANDKEYFILES);
    SelectSrcFile.SetFileSelectDefaultExt  (FILE_FILTER_DFLT_VOLUMESANDKEYFILES);
    SelectDestFile.SetFileSelectFilter( FILE_FILTER_FLT_CDBBACKUPS);
    SelectDestFile.SetFileSelectDefaultExt (FILE_FILTER_DFLT_CDBBACKUPS);
  end else begin
    SelectSrcFile.SetFileSelectFilter      (FILE_FILTER_FLT_CDBBACKUPS);
    SelectSrcFile.SetFileSelectDefaultExt  ( FILE_FILTER_DFLT_CDBBACKUPS);
    SelectDestFile.SetFileSelectFilter( FILE_FILTER_FLT_VOLUMESANDKEYFILES);
    SelectDestFile.SetFileSelectDefaultExt ( FILE_FILTER_DFLT_VOLUMESANDKEYFILES);
  end;

end;



procedure TfrmHdrBackupRestore.ControlChange(Sender: TObject);
begin
  EnableDisableControls();

end;

end.
