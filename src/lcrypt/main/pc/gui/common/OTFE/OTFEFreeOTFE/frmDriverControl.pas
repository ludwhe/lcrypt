unit frmDriverControl;
 // Description: 
 // By Sarah Dean
 // Email: sdean12@sdean12.org
 // WWW:   http://www.SDean12.org/
 //
 // -----------------------------------------------------------------------------
 //


interface

uses

     //delphi & libs
        Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls,
  registry,
    WinSVC,  // Required for service related definitions and functions
  //sdu & LibreCrypt utils
        DriverControl,
  OTFEFreeOTFEBase_U,  OTFEFreeOTFE_U, lcDialogs, SDUDialogs,
   // LibreCrypt forms
  SDUForms;

type
  TfrmDriverControl = class (TSDUForm)
    pbClose:          TButton;
    gbInstallNew:     TGroupBox;
    pbInstall:        TButton;
    lblInstall:       TLabel;
    gbModifyExisting: TGroupBox;
    lbDrivers:        TListBox;
    lblStart:         TLabel;
    pbStart:          TButton;
    pbStop:           TButton;
    pbUninstall:      TButton;
    Label1:           TLabel;
    Label3:           TLabel;
    Label4:           TLabel;
    Panel1:           TPanel;
    Panel2:           TPanel;
    pbUpdate:         TButton;
    cbStartup:        TComboBox;
    OpenDialog:       TSDUOpenDialog;
    procedure lbDriversClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pbStartClick(Sender: TObject);
    procedure pbStopClick(Sender: TObject);
    procedure pbUninstallClick(Sender: TObject);
    procedure pbInstallClick(Sender: TObject);
    procedure pbCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbStartupChange(Sender: TObject);
    procedure pbUpdateClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lbDriversDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
  private
    fDriverControlObj: TDriverControl;

    fBMPModeNormal:    TBitmap;
    fBMPModePortable:  TBitmap;
    fBMPStatusStarted: TBitmap;
    fBMPStatusStopped: TBitmap;
    fBMPStartAuto:     TBitmap;
    fBMPStartManual:   TBitmap;

    procedure EnableDisableControls();

    procedure PopulateDriversList();

    procedure LoadBitmapsFromResources();
    procedure FreeBitmapsFromResources();

    function GetItemWidth(Index: Integer): Integer;
  public
    constructor Create(AOwner: TComponent); override;
  end;

    // Display control for controlling underlying drivers
    procedure ShowDriverControlDlg();


implementation

{$R *.DFM}

{$R OTFEFreeOTFE_DriverImages.dcr}

uses
     //delphi & libs
    Math,    // Required for max(...)
  //sdu & LibreCrypt utils
  lcConsts,   sduGeneral, SDUi18n
   // LibreCrypt forms
  ;


resourcestring
  TEXT_MANUAL_START = 'Manual';
  TEXT_AUTO_START   = 'At system startup';

  FILE_FILTER_FLT_DRIVERS = 'Driver files (*.sys)|*.sys|All files|*.*';

const
  INTER_IMAGE_GAP = 2;

  BMP_MODE_NORMAL    = 'MODE_NORMAL';
  BMP_MODE_PORTABLE  = 'MODE_PORTABLE';
  BMP_STATUS_STARTED = 'STATUS_STARTED';
  BMP_STATUS_STOPPED = 'STATUS_STOPPED';
  BMP_START_AUTO     = 'START_AUTO';
  BMP_START_MANUAL   = 'START_MANUAL';

constructor TfrmDriverControl.Create(AOwner: TComponent);
begin
  inherited;

  // We create the driver control object *here*. We can't create it in
  // OnFormCreate(...) as any exception raised by TDriverControl as
  // a result of it's creation (e.g. user doesn't have admin privs) would just
  // get "swallowed up" and ignored, instead of being propogated back to the
  // caller.
  fDriverControlObj := TDriverControl.Create();

end;


procedure TfrmDriverControl.EnableDisableControls();
var
  driverSelected: Boolean;
  serviceRunning: Boolean;
  serviceState:   DWORD;
  autoStart:      Boolean;
begin
  // Note: We *don't* repaint/refresh lbDrivers in this procedure as that
  //       would cause a flicking effect.

  driverSelected := (lbDrivers.ItemIndex >= 0);

  SDUEnableControl(lblStart, driverSelected);
  SDUEnableControl(cbStartup, driverSelected);

  SDUEnableControl(pbStart, False);
  SDUEnableControl(pbStop, False);
  cbStartup.ItemIndex := -1;

  if driverSelected then begin
    // If the service is still running, warn the user later...
    if (fDriverControlObj.GetServiceState(lbDrivers.Items[lbDrivers.ItemIndex], serviceState)) then
    begin
      serviceRunning := (serviceState = SERVICE_RUNNING);

      SDUEnableControl(pbStop, serviceRunning);
      SDUEnableControl(pbStart, not (serviceRunning));
    end;

    cbStartup.ItemIndex := cbStartup.Items.IndexOf(TEXT_MANUAL_START);
    if fDriverControlObj.GetServiceAutoStart(lbDrivers.Items[lbDrivers.ItemIndex], autoStart) then
    begin
      if autoStart then begin
        cbStartup.ItemIndex := cbStartup.Items.IndexOf(TEXT_AUTO_START);
      end;
    end;

  end;

  SDUEnableControl(pbUninstall, driverSelected);

  SDUEnableControl(pbInstall, True);

  // pbUpdate is a special case; it should only be enabled if the user
  // changes cbStartup
  SDUEnableControl(pbUpdate, False);

end;


procedure TfrmDriverControl.PopulateDriversList();
var
  driverList: TStringList;
  maxWidth:   Integer;
  i:          Integer;
begin
  lbDrivers.Items.Clear();

  driverList := TStringList.Create();
  try
    fDriverControlObj.GetFreeOTFEDrivers(driverList);

    // Bang the sorted flag up & down to ensure that the list is sorted
    // before it is displayed to the user
    driverList.Sorted := False;
    driverList.Sorted := True;

    lbDrivers.Items.AddStrings(driverList);
  finally
    driverList.Free();
  end;


  maxWidth := 0;
  for i := 0 to (lbDrivers.Items.Count - 1) do
    maxWidth := max(maxWidth, GetItemWidth(i));

  lbDrivers.ScrollWidth := maxWidth;


  // Ensure no driver is selected
  lbDrivers.ItemIndex := -1;
  // Ensure that the fact none is selected takes effect...
  lbDriversClick(nil);
end;


procedure TfrmDriverControl.lbDriversClick(Sender: TObject);
begin
  EnableDisableControls();

end;

procedure TfrmDriverControl.FormShow(Sender: TObject);
begin
  // Center label (done dynamically due to language translation size
  // differences)
  SDUCenterControl(lblInstall, ccHorizontal);

  cbStartup.Items.Add(TEXT_MANUAL_START);
  cbStartup.Items.Add(TEXT_AUTO_START);

  PopulateDriversList();

  EnableDisableControls();

end;

procedure TfrmDriverControl.pbStartClick(Sender: TObject);
var
  service: String;
begin
  service := lbDrivers.Items[lbDrivers.ItemIndex];
  if not (fDriverControlObj.StartStopService(service, True)) then begin
    SDUMessageDlg(Format(_('Unable to start driver "%s"'), [service]) + SDUCRLF +
      SDUCRLF + TEXT_NEED_ADMIN,
      mtError
      );
  end;

  EnableDisableControls();

  // Ensure that the icons displayed are correct
  lbDrivers.Refresh();

end;

procedure TfrmDriverControl.pbStopClick(Sender: TObject);
var
  service: String;
begin
  // Note that we *cannot* do this sensibly, and only warn the user if one or
  // more drives are mounted; the user *could* have more than one copy of
  // FreeOTFE (or different apps using the FreeOTFE driver; e.g. different apps
  // using this component).
  // In that scenario, things could get dodgy if the user did something stupid
  // like uninstalling the main driver, while keeping the 2nd app connected to
  // it.
  if (SDUMessageDlg(_('WARNING!') + SDUCRLF + SDUCRLF + _(
    'Stopping a LibreCrypt driver which is currently in use (e.g. by one or more mounted container) can lead to SYSTEM INSTABILITY.')
    + SDUCRLF + SDUCRLF + _(
    'This option is intended for experienced users who REALLY know what they''re doing.') +
    SDUCRLF + SDUCRLF + Format(_('Are you sure you wish to stop the "%s" driver?'),
    [lbDrivers.Items[lbDrivers.ItemIndex]]), mtWarning, [mbYes, mbNo], 0) = mrYes) then begin
    service := lbDrivers.Items[lbDrivers.ItemIndex];

    if not (fDriverControlObj.StartStopService(service, False)) then begin
      SDUMessageDlg(Format(_('Unable to stop driver "%s"'), [service]) +
        SDUCRLF + SDUCRLF + TEXT_NEED_ADMIN,
        mtError
        );
    end;

    EnableDisableControls();
  end;

  // Ensure that the icons displayed are correct
  lbDrivers.Refresh();

end;


procedure TfrmDriverControl.pbUninstallClick(Sender: TObject);
var
  msgReboot:           String;
  msgManualRemoveFile: String;
  driverName:          String;
  status:              DWORD;
begin
  // Note that we *cannot* do this sensibly, and only warn the user if one or
  // more drives are mounted; the user *could* have more than one copy of
  // FreeOTFE (or different apps using the FreeOTFE driver; e.g. different apps
  // using this component).
  // In that scenario, things could get dodgy if the user did something stupid
  // like uninstalling the main driver, while keeping the 2nd app connected to
  // it.
  if (SDUMessageDlg(_('WARNING!') + SDUCRLF + SDUCRLF + _(
    'Uninstalling a LibreCrypt driver which is currently in use (e.g. by one or more mounted volumes) can lead to SYSTEM INSTABILITY.')
    + SDUCRLF + SDUCRLF + _(
    'This option is intended for experienced users who REALLY know what they''re doing.') +
    SDUCRLF + SDUCRLF + Format(_('Are you sure you wish to uninstall the "%s" driver?'),
    [lbDrivers.Items[lbDrivers.ItemIndex]]), mtWarning, [mbYes, mbNo], 0) = mrYes) then begin
    driverName := lbDrivers.Items[lbDrivers.ItemIndex];

    status := fDriverControlObj.UninstallDriver(driverName);

    if ((status and DRIVER_BIT_SUCCESS) = DRIVER_BIT_SUCCESS) then begin
      // Uninstallation SUCCESSFULL
      msgReboot := '';
      if ((status and DRIVER_BIT_REBOOT_REQ) = DRIVER_BIT_REBOOT_REQ) then begin
        msgReboot :=
          SDUCRLF + SDUCRLF +
          // 2 x CRLF - one to end the last line, one for spacing
          _('Please reboot your computer to allow changes to take effect.');
      end;

      msgManualRemoveFile := '';
      if ((status and DRIVER_BIT_FILE_REMAINS) = DRIVER_BIT_FILE_REMAINS) then begin
        msgManualRemoveFile :=
          SDUCRLF + SDUCRLF +
          // 2 x CRLF - one to end the last line, one for spacing
          _(
          'After rebooting, please remove the driver file from your <windows>\system32\drivers directory');
      end;

      SDUMessageDlg(
        Format(_('The "%s" driver has now been uninstalled.'), [driverName]) +
        msgReboot + msgManualRemoveFile,
        mtInformation
        );
    end else begin
      // Uninstallation FAILURE
      SDUMessageDlg(
        Format(_('Unable to delete driver service "%s".'), [driverName]) +
        SDUCRLF + SDUCRLF + _(
        'Please disable this driver from starting up automatically, reboot, and try again.'),
        mtError
        );
    end;

  end;

  // Refresh the drivers list
  PopulateDriversList();
end;


// Install a new FreeOTFE device driver
procedure TfrmDriverControl.pbInstallClick(Sender: TObject);
var
  i: Integer;
begin
  OpenDialog.Filter  := FILE_FILTER_FLT_DRIVERS;
  OpenDialog.Options := OpenDialog.Options + [ofAllowMultiSelect];
  OpenDialog.Options := OpenDialog.Options + [ofDontAddToRecent];
  if (OpenDialog.Execute()) then begin
    for i := 0 to (OpenDialog.files.Count - 1) do begin
      fDriverControlObj.InstallSetAutoStartAndStartDriver(OpenDialog.files[i]);
    end;

    // Refresh the drivers list
    PopulateDriversList();
  end;

end;

procedure TfrmDriverControl.pbCloseClick(Sender: TObject);
begin
  Close();

end;

procedure TfrmDriverControl.FormCreate(Sender: TObject);
begin
  Panel1.Caption := '';
  Panel2.Caption := '';

  LoadBitmapsFromResources();

end;


procedure TfrmDriverControl.cbStartupChange(Sender: TObject);
begin
  // pbUpdate is a special case; it should only be enabled if the user
  // changes cbStartup
  pbUpdate.Enabled := True;

end;


procedure TfrmDriverControl.pbUpdateClick(Sender: TObject);
var
  autoStart: Boolean;
  service:   String;
begin
  if (cbStartup.ItemIndex >= 0) then begin
    autoStart := (cbStartup.ItemIndex = (cbStartup.Items.IndexOf(TEXT_AUTO_START)));
    service   := lbDrivers.Items[lbDrivers.ItemIndex];
    if not (fDriverControlObj.SetServiceAutoStart(service, autoStart)) then begin
      SDUMessageDlg(
        Format(_('Unable to set startup option for driver "%s".'), [service]) +
        SDUCRLF + SDUCRLF + TEXT_NEED_ADMIN,
        mtError
        );
    end;
  end;

  EnableDisableControls();

  // Ensure that the icons displayed are correct
  lbDrivers.Refresh();

end;

procedure TfrmDriverControl.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  FreeBitmapsFromResources();

  fDriverControlObj.Free();

end;



procedure TfrmDriverControl.LoadBitmapsFromResources();
var
  thehBitmap: hBitmap;
begin
  thehBitmap     := LoadBitmap(hInstance, BMP_MODE_NORMAL);
  fBMPModeNormal := TBitmap.Create();
  fBMPModeNormal.ReleaseHandle();
  fBMPModeNormal.handle := thehBitmap;

  thehBitmap       := LoadBitmap(hInstance, BMP_MODE_PORTABLE);
  fBMPModePortable := TBitmap.Create();
  fBMPModePortable.ReleaseHandle();
  fBMPModePortable.handle := thehBitmap;

  thehBitmap        := LoadBitmap(hInstance, BMP_STATUS_STARTED);
  fBMPStatusStarted := TBitmap.Create();
  fBMPStatusStarted.ReleaseHandle();
  fBMPStatusStarted.handle := thehBitmap;

  thehBitmap        := LoadBitmap(hInstance, BMP_STATUS_STOPPED);
  fBMPStatusStopped := TBitmap.Create();
  fBMPStatusStopped.ReleaseHandle();
  fBMPStatusStopped.handle := thehBitmap;

  thehBitmap    := LoadBitmap(hInstance, BMP_START_AUTO);
  fBMPStartAuto := TBitmap.Create();
  fBMPStartAuto.ReleaseHandle();
  fBMPStartAuto.handle := thehBitmap;

  thehBitmap      := LoadBitmap(hInstance, BMP_START_MANUAL);
  FBMPStartManual := TBitmap.Create();
  FBMPStartManual.ReleaseHandle();
  fBMPStartManual.handle := thehBitmap;

end;


procedure TfrmDriverControl.FreeBitmapsFromResources();
var
  thehBitmap: hBitmap;
begin
  thehBitmap := fBMPModeNormal.Handle;
  fBMPModeNormal.ReleaseHandle();
  fBMPModeNormal.Free();
  DeleteObject(thehBitmap);

  thehBitmap := fBMPModePortable.Handle;
  fBMPModePortable.ReleaseHandle();
  fBMPModePortable.Free();
  DeleteObject(thehBitmap);

  thehBitmap := fBMPStatusStarted.Handle;
  fBMPStatusStarted.ReleaseHandle();
  fBMPStatusStarted.Free();
  DeleteObject(thehBitmap);

  thehBitmap := fBMPStatusStopped.Handle;
  fBMPStatusStopped.ReleaseHandle();
  fBMPStatusStopped.Free();
  DeleteObject(thehBitmap);

  thehBitmap := fBMPStartAuto.Handle;
  fBMPStartAuto.ReleaseHandle();
  fBMPStartAuto.Free();
  DeleteObject(thehBitmap);

  thehBitmap := fBMPStartManual.Handle;
  fBMPStartManual.ReleaseHandle();
  fBMPStartManual.Free();
  DeleteObject(thehBitmap);

end;


 // Note: The "Style" property of the TListBox must be set to lbOwnerDrawFixed
 // !! IMPORTANT !!
 // !! IMPORTANT !!
 // lbDriversDrawItem and GetItemWidth *MUST* be kept in sync!
 // !! IMPORTANT !!
 // !! IMPORTANT !!
procedure TfrmDriverControl.lbDriversDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  lbObj:         TListBox;
  canvas:        TCanvas;
  offset:        Integer;
  portableMode:  Boolean;
  serviceState:  DWORD;
  autoStart:     Boolean;
  drawStatusBmp: TBitmap;
  drawModeBmp:   TBitmap;
  drawStartBmp:  TBitmap;
begin
  lbObj  := TListBox(Control);
  canvas := lbObj.Canvas;

  offset := INTER_IMAGE_GAP;  // Default offset

  canvas.FillRect(Rect);  { clear the rectangle }

{
  // Portable Drivers in italics
  canvas.Font.Style := [];
  if fDriverControlObj.IsDriverInstalledPortable(lbObj.Items[Index], portableMode) then
    begin
    if portableMode then
      begin
      canvas.Font.Style := [fsItalic];
      end;

    end;
}

  // Determine which icons are to be displayed...

  // Auto or manual start...
  drawStartBmp := fBMPStartManual;
  if (fDriverControlObj.GetServiceAutoStart(lbObj.Items[Index], autoStart)) then begin
    if (autoStart) then begin
      drawStartBmp := FBMPStartAuto;
    end;
  end;

  // Started or stopped...
  drawStatusBmp := fBMPStatusStopped;
  if (fDriverControlObj.GetServiceState(lbObj.Items[Index], serviceState)) then begin
    if (serviceState = SERVICE_RUNNING) then begin
      drawStatusBmp := fBMPStatusStarted;
    end;
  end;

  // Normal or portable...
  // If running normally, don't display an icon
  //  drawModeBmp := BMPModeNormal;
  drawModeBmp := nil;
  if fDriverControlObj.IsDriverInstalledPortable(lbObj.Items[Index], portableMode) then begin
    if (portableMode) then begin
      drawModeBmp := fBMPModePortable;
    end;
  end;


  // Draw the icons...

  // Auto or manual start...
  lbObj.Canvas.Draw(
    (Rect.Left + offset),
    (Rect.Top + (((Rect.Bottom - Rect.Top) - drawStartBmp.Height) div 2)),
    drawStartBmp
    );
  offset := offset + INTER_IMAGE_GAP + max(fBMPStartAuto.Width, fBMPStartManual.Width);

  // Started or stopped...
  if (drawModeBmp <> nil) then begin
    lbObj.Canvas.Draw(
      (Rect.Left + offset),
      (Rect.Top + (((Rect.Bottom - Rect.Top) - drawModeBmp.Height) div 2)),
      drawModeBmp
      );
  end;
  offset := offset + INTER_IMAGE_GAP + max(FBMPModePortable.Width, FBMPModeNormal.Width);

  // Normal or portable...
  lbObj.Canvas.Draw(
    (Rect.Left + offset),
    (Rect.Top + (((Rect.Bottom - Rect.Top) - drawStatusBmp.Height) div 2)),
    drawStatusBmp
    );
  offset := offset + INTER_IMAGE_GAP + max(FBMPStatusStarted.Width, FBMPStatusStopped.Width);


  // The name...
  canvas.TextOut((Rect.Left + offset), Rect.Top, lbObj.Items[Index]);

end;


function TfrmDriverControl.GetItemWidth(Index: Integer): Integer;
var
  lbObj:  TListBox;
  canvas: TCanvas;
  offset: Integer;
begin
  lbObj  := lbDrivers;
  canvas := lbObj.Canvas;

  offset := INTER_IMAGE_GAP;  // Default offset

  offset := offset + INTER_IMAGE_GAP + max(fBMPStartAuto.Width, fBMPStartManual.Width);
  offset := offset + INTER_IMAGE_GAP + max(FBMPModePortable.Width, fBMPModeNormal.Width);
  offset := offset + INTER_IMAGE_GAP + max(fBMPStatusStarted.Width, fBMPStatusStopped.Width);

  // The name...
  offset := offset + canvas.TextWidth(lbObj.Items[Index]);


  // Tack on a bit so it doesn't look like the text goes right up against the
  // end...
  offset := offset + (2 * INTER_IMAGE_GAP);

  Result := offset;

end;


 // ----------------------------------------------------------------------------
 // Display control for controlling underlying drivers
 // You *shouldn't* call this while the component is active, as the user may
 // try to do something dumn like uninstall the main FreeOTFE driver while we're
 // connected to it!
procedure ShowDriverControlDlg();
var
  dlg: TfrmDriverControl;
begin
  // TfrmDriverControl.Create(nil) will raise an exception if the user doesn't
  // have the required privs to access driver control
  dlg := TfrmDriverControl.Create(nil);
  try
    dlg.ShowModal();
  finally
    dlg.Free();
  end;

  // In case drivers were added/removed...
  GetFreeOTFEBase().CachesFlush();
end;


end.
