unit frmInstallOnUSBDrive;

interface

uses
  Classes, ComCtrls, Controls, Dialogs, Forms,
  Graphics, Messages, OTFEFreeOTFE_InstructionRichEdit, SDUForms, StdCtrls,
  SysUtils, Variants, Windows;

type
  TfrmInstallOnUSBDrive = class (TSDUForm)
    pbOK:                     TButton;
    pbCancel:                 TButton;
    edPath:                   TEdit;
    cbDrive:                  TComboBox;
    Label1:                   TLabel;
    Label2:                   TLabel;
    ckSetupAutoplay:          TCheckBox;
    pbBrowse:                 TButton;
    pbRefreshDrives:          TButton;
    ckHideAutorunInf:         TCheckBox;
    reInstructCopyToUSBDrive: TLabel;
    procedure FormShow(Sender: TObject);
    procedure pbBrowseClick(Sender: TObject);
    procedure edPathChange(Sender: TObject);
    procedure pbRefreshDrivesClick(Sender: TObject);
    procedure pbOKClick(Sender: TObject);
  PRIVATE
    procedure EnableDisableControls();

    function GetInstallDrive(): Char;
    function GetInstallFullPath(): String;
    function GetInstallRelativePath(): String;

    function InstallOnUSBDrive(): Boolean;
    function CreateAutorunInfFile(): Boolean;
  PUBLIC
    procedure PopulateUSBDrives();
  end;


implementation

{$R *.dfm}

uses
//delphi
{$WARN UNIT_PLATFORM OFF}
  FileCtrl,
{$WARN UNIT_PLATFORM ON}
Winapi.ShellApi,
//sdu lcutils
lcConsts,
  lcDialogs,
  SDUGeneral, SDUi18n;

{$IFDEF _NEVER_DEFINED}
// This is just a dummy const to fool dxGetText when extracting message
// information
// This const is never used; it's #ifdef'd out - SDUCRLF in the code refers to
// picks up SDUGeneral.SDUCRLF
const
  SDUCRLF = ''#13#10;
{$ENDIF}

// CopyFile(...), but using Windows API to display "flying files" dialog while copying
function SDUFileCopy(srcFilename: String; destFilename: String): Boolean; forward;

procedure TfrmInstallOnUSBDrive.FormShow(Sender: TObject);
begin
  self.Caption := Format(_(self.Caption), [Application.title]);

  reInstructCopyToUSBDrive.Caption :=
    Format(_(reInstructCopyToUSBDrive.Caption),  [Application.Title,Application.Title]);

  ckSetupAutoplay.Caption := Format(
    _('&Setup autorun.inf to launch %s when drive inserted'), [Application.Title]);

  // Replace any " " with "_", otherwise autorun.inf won't be able to launch
  // the executable
  edPath.Text             := '\' + StringReplace(Application.Title, ' ', '_', [rfReplaceAll]);
  ckSetupAutoplay.Checked := True;

  PopulateUSBDrives();

  EnableDisableControls();
end;


procedure TfrmInstallOnUSBDrive.pbBrowseClick(Sender: TObject);
var
  newPath:  String;
  rootPath: String;
begin
  rootPath := GetInstallDrive() + ':\';
  if SelectDirectory(Format(_('Select location to copy %s to'),
    [Application.Title]), rootPath, newPath
{$IF CompilerVersion >= 18.5}
    , // Comma from previous line
    [sdNewUI, sdNewFolder]
{$IFEND}
    ) then begin
    // 3 and -2 in order to strip off the "<driveletter>:"
    edPath.Text := Copy(newPath, 3, (length(newPath) - 2));
  end;

end;

procedure TfrmInstallOnUSBDrive.pbOKClick(Sender: TObject);
begin
  if InstallOnUSBDrive() then begin
    SDUMessageDlg(Format(_('%s copy complete.'), [Application.Title]),
      mtInformation);
    ModalResult := mrOk;
  end;

end;

function TfrmInstallOnUSBDrive.InstallOnUSBDrive(): Boolean;
var
  destPath: String;
  srcPath:  String;
  copyOK:   Boolean;
begin
  Result := True;

  destPath := GetInstallFullPath();
  srcPath  := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  // Check that if user wants to create an autorun.inf file, they don't have
  // any spaces in teh install path
  if Result then begin
    if ckSetupAutoplay.Checked then begin
      if (Pos(' ', GetInstallRelativePath()) > 0) then begin
        Result := (SDUMessageDlg(Format(
          _('The path specified has spaces in it.' + SDUCRLF + SDUCRLF +
          'Because of this, Windows will be able to show the %s icon for the drive, '+
          'but not launch %0:s automatically when the drive is inserted.'
          + SDUCRLF + SDUCRLF + 'Do you wish to continue?'), [Application.Title]), mtWarning, [mbYes, mbNo], 0) = mrYes);
      end;
    end;
  end;

  if Result then begin
    // Sanity check - user trying to install into root dir?
    // Note: GetInstallRelativePath() will return '\', at a minimum
    if (length(GetInstallRelativePath()) <= 1) then begin
      Result := (SDUMessageDlg(Format(
        _('You have opted to copy %s to the root directory of your USB drive, and not a subdirectory.'),
        [Application.title]) + SDUCRLF + SDUCRLF + _('Are you sure you wish to do this?'),
        mtWarning, [mbYes, mbNo], 0) = mrYes);
    end;
  end;

  // Copy FreeOTFE software to drive
  if Result then begin
    // Disable the form, so the user mess with it while files are being copied
    SDUEnableControl(self, False);

    // CopyFile(...), but using Windows API to display "flying files" dialog
    // while copying
    // Note: This force-creates the destPath directory
    copyOK := SDUFileCopy(srcPath + '\*', destPath);

    if not (copyOK) then begin
      SDUMessageDlg(
        Format(_('Unable to copy %s to:' + SDUCRLF + SDUCRLF + '%s'),
        [Application.Title, destPath]),
        mtError
        );
      Result := False;
    end;

    // Reenable the form
    SDUEnableControl(self, True);
    // SDUEnableControl(...) resets various display properties on the
    // instructions control; reset them here
//    reInstructCopyToUSBDrive.ResetDisplay();
    EnableDisableControls();
  end;

  // Create autorun.inf file, if needed
  if Result then begin
    if ckSetupAutoplay.Checked then begin
      if not (CreateAutorunInfFile()) then begin
        SDUMessageDlg(
          Format(_(
          '%s was successfully copied over, but an autoplay (autorun.inf) file could not be created.'),
          [Application.title]),
          mtWarning
          );
        // We take this as a success - the autorun.inf is pretty minor
        Result := True;
      end;
    end;
  end;

end;

function TfrmInstallOnUSBDrive.CreateAutorunInfFile(): Boolean;
var
  autorunContent:  TStringList;
  partPath:        String;
  srcExeFilename:  String;
  autorunFilename: String;
begin
  Result := False;

  autorunContent := TStringList.Create();
  try
    partPath       := GetInstallRelativePath();
    srcExeFilename := ExtractFileName(ParamStr(0));

    // Strip off any prefixing "\"
    if (length(partPath) > 0) then begin
      if (partPath[1] = '\') then begin
        partPath := Copy(partPath, 2, (length(partPath) - 1));
      end;
    end;

    autorunContent.Add('[autorun]');
    autorunContent.Add('icon=' + partPath + '\' + srcExeFilename);
    autorunContent.Add('open=' + partPath + '\' + srcExeFilename);
    autorunContent.Add('action=' + format(_('Launch %s'), [Application.Title]));
    autorunContent.Add('shell\launch\=' + format(_('Launch %s'), [Application.Title]));
    autorunContent.Add('shell\launch\command=' + partPath + '\' + srcExeFilename);

    autorunFilename := GetInstallDrive() + ':\autorun.inf';

    try
      // Try to delete any existing autorun.inf file
      if FileExists(autorunFilename) then begin
        SysUtils.DeleteFile(autorunFilename);
      end;

      autorunContent.SaveToFile(autorunFilename);

      if ckHideAutorunInf.Checked then begin
        SetFileAttributes(PChar(autorunFilename), FILE_ATTRIBUTE_HIDDEN);
      end;

      Result := True;
    except
      on E: Exception do begin
        // Nothing - just swallow exception
      end;
    end;

  finally
    autorunContent.Free();
  end;

end;

procedure TfrmInstallOnUSBDrive.pbRefreshDrivesClick(Sender: TObject);
begin
  PopulateUSBDrives();
end;

procedure TfrmInstallOnUSBDrive.PopulateUSBDrives();
begin
  SDUPopulateRemovableDrives(cbDrive);

  // Select first drive, if any available
  cbDrive.ItemIndex := -1;
  if (cbDrive.items.Count > 0) then begin
    cbDrive.ItemIndex := 0;
  end;

end;

procedure TfrmInstallOnUSBDrive.edPathChange(Sender: TObject);
begin
  EnableDisableControls();
end;

procedure TfrmInstallOnUSBDrive.EnableDisableControls();
begin
  SDUEnableControl(cbDrive, (cbDrive.Items.Count > 1));

  SDUEnableControl(ckHideAutorunInf, ckSetupAutoplay.Checked);

  SDUEnableControl(
    pbOK,
    ((cbDrive.ItemIndex >= 0) and (Pos(':', edPath.Text) = 0)  // No ":" allowed in path
    )
    );

end;

function TfrmInstallOnUSBDrive.GetInstallDrive(): Char;
begin
  Result := #0;

  if (cbDrive.ItemIndex >= 0) then begin
    // Only the 1st char of the drive...
    Result := cbDrive.Items[cbDrive.ItemIndex][1];
  end;


end;

function TfrmInstallOnUSBDrive.GetInstallFullPath(): String;
begin
  Result := GetInstallDrive() + ':' + GetInstallRelativePath();
end;

function TfrmInstallOnUSBDrive.GetInstallRelativePath(): String;
begin
  Result := trim(edPath.Text);
  if (Pos('\', Result) <> 1) then begin
    Result := '\' + Result;
  end;


end;


 // ----------------------------------------------------------------------------
 // CopyFile(...), but using Windows API to display "flying files" dialog while copying
function SDUFileCopy(srcFilename: String; destFilename: String): Boolean;
var
  fileOpStruct: TSHFileOpStruct;
begin

  Result                     := False;
  // srcFilename and destFilename *MUST* end in a double NULL for
  // SHFileOperation to operate correctly
  srcFilename                := srcFilename + #0 + #0;
  destFilename               := destFilename + #0 + #0;
  fileOpStruct.Wnd           := 0;
  fileOpStruct.wFunc         := FO_COPY;
  fileOpStruct.pFrom         := PChar(srcFilename);
  fileOpStruct.pTo           := PChar(destFilename);
  fileOpStruct.fFlags        := (FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR);
  fileOpStruct.fAnyOperationsAborted := False;
  fileOpStruct.hNameMappings := nil;
  fileOpStruct.lpszProgressTitle := nil;

  if (SHFileOperation(fileOpStruct) = 0) then begin
    Result := not (fileOpStruct.fAnyOperationsAborted);
  end;

//  Tfile.Copy(srcFilename, destFilename);

end;

end.
