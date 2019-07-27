unit ExplorerSettings;
 // Description: 
 // By Sarah Dean
 // Email: sdean12@sdean12.org
 // WWW:   http://www.FreeOTFE.org/
 //
 // -----------------------------------------------------------------------------
 //


interface

uses
  Classes, // Required for TShortCut
  ComCtrls,
  CommonSettings,
  IniFiles,
  Shredder;

{$IFDEF _NEVER_DEFINED}
// This is just a dummy const to fool dxGetText when extracting message
// information
// This const is never used; it's #ifdef'd out - SDUCRLF in the code refers to
// picks up SDUGeneral.SDUCRLF
const
  SDUCRLF = ''#13#10;
{$ENDIF}

const
  FREEOTFE_REGISTRY_SETTINGS_LOCATION = '\Software\FreeOTFEExplorer';

type
  TDefaultStoreOp = (dsoPrompt, dsoCopy, dsoMove);

resourcestring
  DEFAULT_STORE_OP_PROMPT = 'Prompt user';
  DEFAULT_STORE_OP_COPY   = 'Copy';
  DEFAULT_STORE_OP_MOVE   = 'Move';

const
  DefaultStoreOpTitlePtr: array [TDefaultStoreOp] of Pointer =
    (@DEFAULT_STORE_OP_PROMPT, @DEFAULT_STORE_OP_COPY, @DEFAULT_STORE_OP_MOVE
    );

type
  TMoveDeletionMethod = (mdmPrompt, mdmDelete, mdmOverwrite);

resourcestring
  MOVE_DELETION_METHOD_PROMPT    = 'Prompt user';
  MOVE_DELETION_METHOD_DELETE    = 'Delete original';
  MOVE_DELETION_METHOD_OVERWRITE = 'Wipe original';

const
  MoveDeletionMethodTitlePtr: array [TMoveDeletionMethod] of Pointer =
    (@MOVE_DELETION_METHOD_PROMPT, @MOVE_DELETION_METHOD_DELETE, @MOVE_DELETION_METHOD_OVERWRITE
    );

type
  TExplorerBarType = (ebNone, ebFolders);

  TExplorerSettings = class (TCommonSettings)
  private
    fOverwriteWebDAVCacheOnDismount: Boolean;
    fOverwriteMethod: TShredMethod;


    fMoveDeletionMethod: TMoveDeletionMethod;
    fDefaultStoreOp:     TDefaultStoreOp;
    fwebDavShareName:    String;
    ftreeViewWidth:      Integer;

    fWebDavLogAccessFile: String;

    fshowHiddenItems:    Boolean;
    //    fOptShowStatusBar:      Boolean;
    fwebDAVPort:         Integer;
    fkeepTimestampsOnStoreExtract: Boolean;
    fenableWebDAVServer: Boolean;

    fshowAddressBar:      Boolean;
    //    fFlagClearLayoutOnSave: Boolean;
    fhideKnownFileExtns:  Boolean;
    foverwritePasses:     Integer;
    fshowExplorerFolders: Boolean;


    fListViewLayout: String;

    fWebDavLogDebugFile:          String;
    //todo: make private (are used as var params)
    //    fshowVolumeToolbar:       Boolean;
    // 'volume' toolbar settings are 'toolbar' from common settings
    fshowExplorerToolBar:         Boolean;
    //    fOptToolbarVolumeLarge:      Boolean;
    fshowLargerExplorerToolbar:   Boolean;
    //    fOptToolbarVolumeCaptions:   Boolean;
    fshowExplorerToolbarCaptions: Boolean;


  protected
    procedure _LoadOld(iniFile: TCustomINIFile); override;
    procedure _SetDefaults; override;

  public

    function RegistryKey(): String; override;

    //set layout to default
    procedure ClearLayout; override;

    //    function _Save(iniFile: TCustomINIFile): Boolean; override;

  published

    // Layout...
    //    // i.e. All items *not* configured via the "Options" dialog, but by
    //    //      controls on the main window
    //    property FlagClearLayoutOnSave: Boolean Read FFlagClearLayoutOnSave
    //      Write fFlagClearLayoutOnSave; // If set, and not storing layout, any
    //    // existing layout will be deleted -
    //    // resulting in a reset to default after
    //    // restarting

    // General...
    property ShowHiddenItems: Boolean
      Read fshowHiddenItems Write fshowHiddenItems default False;
    property hideKnownFileExtns: Boolean
      Read fhideKnownFileExtns Write fhideKnownFileExtns default True;
    property DefaultStoreOp: TDefaultStoreOp
      Read fDefaultStoreOp Write fDefaultStoreOp default dsoPrompt;
    property MoveDeletionMethod: TMoveDeletionMethod
      Read fMoveDeletionMethod Write fMoveDeletionMethod default mdmDelete;
    property OverwriteMethod: TShredMethod
      Read fOverwriteMethod Write fOverwriteMethod default smPseudorandom;
    property overwritePasses: Integer
      Read foverwritePasses Write foverwritePasses default 1;
    property keepTimestampsOnStoreExtract: Boolean
      Read fkeepTimestampsOnStoreExtract Write fkeepTimestampsOnStoreExtract default True;

    //    property ShowVolumeToolbar: Boolean Read fshowVolumeToolbar
    //      Write fshowVolumeToolbar default True;
    property ShowExplorerToolBar: Boolean Read fshowExplorerToolBar
      Write fshowExplorerToolBar default True;
    //    property OptToolbarVolumeLarge: Boolean Read FOptToolbarVolumeLarge
    //      Write fOptToolbarVolumeLarge default True;
    //    property OptToolbarVolumeCaptions: Boolean Read FOptToolbarVolumeCaptions
    //      Write fOptToolbarVolumeCaptions default True;
    property ShowExplorerToolbarCaptions: Boolean
      Read fshowExplorerToolbarCaptions Write fshowExplorerToolbarCaptions default True;
    property ShowLargerExplorerToolbar: Boolean Read fshowLargerExplorerToolbar
      Write fshowLargerExplorerToolbar default True;
    property ShowAddressBar: Boolean Read fshowAddressBar
      Write fshowAddressBar default True;
    property ShowExplorerFolders: Boolean
      Read fshowExplorerFolders Write fshowExplorerFolders default True;
    //    property OptShowStatusBar: Boolean Read FOptShowStatusBar
    //      Write fOptShowStatusBar default True;

    property TreeViewWidth: Integer Read ftreeViewWidth
      Write ftreeViewWidth default 215;  // set to 0 to indicate hidden
    property ListViewLayout: String Read fListViewLayout Write fListViewLayout;
    //default '';

    // WebDAV related...
    property EnableWebDAVServer: Boolean
      Read fenableWebDAVServer Write fenableWebDAVServer default False;
    property OverwriteWebDAVCacheOnDismount: Boolean
      Read fOverwriteWebDAVCacheOnDismount Write fOverwriteWebDAVCacheOnDismount default True;
    property WebDAVPort: Integer Read fwebDAVPort
      Write fwebDAVPort default 8081;
    property WebDavShareName: String
      Read fwebDavShareName Write fwebDavShareName;//default 'LEXPL';
    property WebDavLogDebugFile: String
      Read fWebDavLogDebugFile Write fWebDavLogDebugFile;//default '';
    property WebDavLogAccessFile: String
      Read fWebDavLogAccessFile Write fWebDavLogAccessFile;// default  '';

  end;

function DefaultStoreOpTitle(defaultStoreOp: TDefaultStoreOp): String;
function MoveDeletionMethodTitle(moveDeletionMethod: TMoveDeletionMethod): String;

{returns an instance of the only object, must be type TExplorerSettings. call SetSettingsType first}
function GetExplorerSettings: TExplorerSettings;

implementation

uses
  Windows,   // Required to get rid of compiler hint re DeleteFile
  SysUtils,  // Required for ChangeFileExt, DeleteFile
  Dialogs,
  Menus, Registry,
  SDUDialogs,
  SDUGeneral,
  SDUi18n,
           // Required for ShortCutToText and TextToShortCut
  ShlObj;  // Required for CSIDL_PERSONAL

const
  // -- General section --
  OPT_SHOWHIDDENITEMS                  = 'ShowHiddenItems';
  DFLT_OPT_SHOWHIDDENITEMS             = False;
  // Default as per MS Windows Explorer default
  OPT_HIDEKNOWNFILEEXTNS               = 'HideKnownFileExtns';
  DFLT_OPT_HIDEKNOWNFILEEXTNS          = True;
  // Default as per MS Windows Explorer default
  OPT_DEFAULTSTOREOP                   = 'DefaultStoreOp';
  DFLT_OPT_DEFAULTSTOREOP              = dsoPrompt;
  OPT_MOVEDELETIONMETHOD               = 'MoveDeletionMethod';
  DFLT_OPT_MOVEDELETIONMETHOD          = mdmDelete;
  OPT_OVERWRITEMETHOD                  = 'OverwriteMethod';
  DFLT_OPT_OVERWRITEMETHOD             = smPseudorandom;
  OPT_OVERWRITEPASSES                  = 'OverwritePasses';
  DFLT_OPT_OVERWRITEPASSES             = 1;
  OPT_PRESERVETIMESTAMPSONSTOREEXTRACT = 'PreserveTimestampsOnStoreExtract';
  DFLT_OPT_PRESERVETIMESTAMPSONSTOREEXTRACT = True;

  // -- Layout section --

  OPT_EXPLORERBARWIDTH             = 'ExplorerBarWidth';
  DFLT_OPT_EXPLORERBARWIDTH        = 215; // Set to 0 to hide
  OPT_SHOWTOOLBARVOLUME            = 'ShowToolbarVolume';
  DFLT_OPT_SHOWTOOLBARVOLUME       = True;
  OPT_SHOWTOOLBAREXPLORER          = 'ShowToolbarExplorer';
  DFLT_OPT_SHOWTOOLBAREXPLORER     = True;
  OPT_TOOLBARVOLUMELARGE           = 'ToolbarVolumeLarge';
  DFLT_OPT_TOOLBARVOLUMELARGE      = True;
  OPT_TOOLBARVOLUMECAPTIONS        = 'ToolbarVolumeCaptions';
  DFLT_OPT_TOOLBARVOLUMECAPTIONS   = True;
  OPT_TOOLBAREXPLORERLARGE         = 'ToolbarExplorerLarge';
  DFLT_OPT_TOOLBAREXPLORERLARGE    = True;
  OPT_TOOLBAREXPLORERCAPTIONS      = 'ToolbarExplorerCaptions';
  DFLT_OPT_TOOLBAREXPLORERCAPTIONS = True;
  // Not the same as MS Windows Explorer, but makes
  // the store/extract operations more obvious
  OPT_SHOWADDRESSBAR               = 'ShowAddressBar';
  DFLT_OPT_SHOWADDRESSBAR          = True;
  OPT_SHOWEXPLORERBAR              = 'ShowExplorerBar';
  DFLT_OPT_SHOWEXPLORERBAR         = ebFolders;
  OPT_SHOWSTATUSBAR                = 'ShowStatusBar';
  DFLT_OPT_SHOWSTATUSBAR           = True;
  OPT_LISTVIEWLAYOUT               = 'ListViewLayout';
  DFLT_OPT_LISTVIEWLAYOUT          = '';

  // -- WebDAV section --
  SECTION_WEBDAV     = 'WedDAV';
  OPT_ENABLESERVER   = 'EnableServer';
  DFLT_OPT_ENABLESERVER = False;
  OPT_OVERWRITECACHEONDISMOUNT = 'OverwriteCacheOnDismount';
  DFLT_OPT_OVERWRITECACHEONDISMOUNT = True;
  OPT_PORT           = 'Port';
  DFLT_OPT_PORT      = 8081;
  OPT_SHARENAME      = 'ShareName';
  DFLT_OPT_SHARENAME = 'LEXPL';
  OPT_LOGDEBUG       = 'LogDebug';
  DFLT_OPT_LOGDEBUG  = '';
  OPT_LOGACCESS      = 'LogAccess';
  DFLT_OPT_LOGACCESS = '';


function DefaultStoreOpTitle(defaultStoreOp: TDefaultStoreOp): String;
begin
  Result := LoadResString(DefaultStoreOpTitlePtr[defaultStoreOp]);
end;

function MoveDeletionMethodTitle(moveDeletionMethod: TMoveDeletionMethod): String;
begin
  Result := LoadResString(MoveDeletionMethodTitlePtr[moveDeletionMethod]);
end;

procedure TExplorerSettings.ClearLayout;
begin
  inherited;

  ftreeViewWidth := 215;

  fshowExplorerToolBar := True;

  fshowLargerExplorerToolbar   := True;
  fshowExplorerToolbarCaptions := True;
  fshowAddressBar              := True;
  fshowExplorerFolders         := True;
  //  fOptShowStatusBar           := True;
  fListViewLayout              := '';
end;

procedure TExplorerSettings._LoadOld(iniFile: TCustomINIFile);
begin
  inherited _LoadOld(iniFile);

  // General section...
  fshowHiddenItems              :=
    iniFile.ReadBool(SECTION_GENERAL, OPT_SHOWHIDDENITEMS, DFLT_OPT_SHOWHIDDENITEMS);
  fhideKnownFileExtns           :=
    iniFile.ReadBool(SECTION_GENERAL, OPT_HIDEKNOWNFILEEXTNS, DFLT_OPT_HIDEKNOWNFILEEXTNS);
  fDefaultStoreOp               :=
    TDefaultStoreOp(iniFile.ReadInteger(SECTION_GENERAL, OPT_DEFAULTSTOREOP,
    Ord(DFLT_OPT_DEFAULTSTOREOP)));
  fMoveDeletionMethod           :=
    TMoveDeletionMethod(iniFile.ReadInteger(SECTION_GENERAL, OPT_MOVEDELETIONMETHOD,
    Ord(DFLT_OPT_MOVEDELETIONMETHOD)));
  fOverwriteMethod              :=
    TShredMethod(iniFile.ReadInteger(SECTION_GENERAL, OPT_OVERWRITEMETHOD,
    Ord(DFLT_OPT_OVERWRITEMETHOD)));
  foverwritePasses              :=
    iniFile.ReadInteger(SECTION_GENERAL, OPT_OVERWRITEPASSES, DFLT_OPT_OVERWRITEPASSES);
  fkeepTimestampsOnStoreExtract :=
    iniFile.ReadBool(SECTION_GENERAL, OPT_PRESERVETIMESTAMPSONSTOREEXTRACT,
    DFLT_OPT_PRESERVETIMESTAMPSONSTOREEXTRACT);

  // Layout section...
  // volume is now main settings 'toolbar' - will reset n first run as new type
  fshowToolbar         :=
    iniFile.ReadBool(SECTION_LAYOUT, OPT_SHOWTOOLBARVOLUME, DFLT_OPT_SHOWTOOLBARVOLUME);
  fshowExplorerToolBar :=
    iniFile.ReadBool(SECTION_LAYOUT, OPT_SHOWTOOLBAREXPLORER, DFLT_OPT_SHOWTOOLBAREXPLORER);
  fshowToolbarLarge    :=
    iniFile.ReadBool(SECTION_LAYOUT, OPT_TOOLBARVOLUMELARGE, DFLT_OPT_TOOLBARVOLUMELARGE);
  fshowToolbarCaptions :=
    iniFile.ReadBool(SECTION_LAYOUT, OPT_TOOLBARVOLUMECAPTIONS, DFLT_OPT_TOOLBARVOLUMECAPTIONS);

  fshowLargerExplorerToolbar   :=
    iniFile.ReadBool(SECTION_LAYOUT, OPT_TOOLBAREXPLORERLARGE, DFLT_OPT_TOOLBAREXPLORERLARGE);
  fshowExplorerToolbarCaptions :=
    iniFile.ReadBool(SECTION_LAYOUT, OPT_TOOLBAREXPLORERCAPTIONS,
    DFLT_OPT_TOOLBAREXPLORERCAPTIONS);
  fTreeViewWidth               :=
    iniFile.ReadInteger(SECTION_LAYOUT, OPT_EXPLORERBARWIDTH, DFLT_OPT_EXPLORERBARWIDTH);
  fshowAddressBar              :=
    iniFile.ReadBool(SECTION_LAYOUT, OPT_SHOWADDRESSBAR, DFLT_OPT_SHOWADDRESSBAR);
  fshowExplorerFolders         :=
    TExplorerBarType(iniFile.ReadInteger(SECTION_LAYOUT, OPT_SHOWEXPLORERBAR,
    Ord(DFLT_OPT_SHOWEXPLORERBAR))) = ebFolders;
  //  OptShowStatusBar           :=
  //    iniFile.ReadBool(SECTION_LAYOUT, OPT_SHOWSTATUSBAR, DFLT_OPT_SHOWSTATUSBAR);
  fListViewLayout              :=
    iniFile.ReadString(SECTION_LAYOUT, OPT_LISTVIEWLAYOUT, DFLT_OPT_LISTVIEWLAYOUT);

  // WebDAV section...
  fenableWebDAVServer             :=
    iniFile.ReadBool(SECTION_WEBDAV, OPT_ENABLESERVER, DFLT_OPT_ENABLESERVER);
  fOverwriteWebDAVCacheOnDismount :=
    iniFile.ReadBool(SECTION_WEBDAV, OPT_OVERWRITECACHEONDISMOUNT,
    DFLT_OPT_OVERWRITECACHEONDISMOUNT);
  fwebDAVPort                     :=
    iniFile.ReadInteger(SECTION_WEBDAV, OPT_PORT, DFLT_OPT_PORT);
  fwebDavShareName                :=
    iniFile.ReadString(SECTION_WEBDAV, OPT_SHARENAME, DFLT_OPT_SHARENAME);
  fWebDavLogDebugFile             :=
    iniFile.ReadString(SECTION_WEBDAV, OPT_LOGDEBUG, DFLT_OPT_LOGDEBUG);
  fWebDavLogAccessFile            :=
    iniFile.ReadString(SECTION_WEBDAV, OPT_LOGACCESS, DFLT_OPT_LOGACCESS);

end;

 //function TExplorerSettings._Save(iniFile: TCustomINIFile): Boolean;
 //begin
 //  result := inherited(iniFile);
 ////  if result and fFlagClearLayoutOnSave then begin
 ////
 ////        // Purge all layout related - next time the application is started,
 ////        // it'll just assume the defaults
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_MAINWINDOWLAYOUT);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_EXPLORERBARWIDTH);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_SHOWTOOLBARVOLUME);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_SHOWTOOLBAREXPLORER);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_TOOLBARVOLUMELARGE);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_TOOLBARVOLUMECAPTIONS);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_TOOLBAREXPLORERLARGE);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_TOOLBAREXPLORERCAPTIONS);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_SHOWADDRESSBAR);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_SHOWEXPLORERBAR);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_SHOWSTATUSBAR);
 ////        iniFile.DeleteKey(SECTION_GENERAL, OPT_LISTVIEWLAYOUT);
 ////  end;
 //
 //end;

procedure TExplorerSettings._SetDefaults;
begin
  inherited;


  fListViewLayout      := '';
  fwebDavShareName     := 'LEXPL';
  fWebDavLogDebugFile  := '';
  fWebDavLogAccessFile := '';

end;

(*
function TExplorerSettings._Save(iniFile: TCustomINIFile): Boolean;
var
  allOK: Boolean;
begin
  allOK := inherited _Save(iniFile);

  if allOK then begin
    try
      // General section...
      iniFile.WriteBool(SECTION_GENERAL, OPT_SHOWHIDDENITEMS,
        OptShowHiddenItems);
      iniFile.WriteBool(SECTION_GENERAL, OPT_HIDEKNOWNFILEEXTNS,
        OptHideKnownFileExtns);
      iniFile.WriteInteger(SECTION_GENERAL, OPT_DEFAULTSTOREOP,
        Ord(OptDefaultStoreOp));
      iniFile.WriteInteger(SECTION_GENERAL, OPT_MOVEDELETIONMETHOD,
        Ord(OptMoveDeletionMethod));
      iniFile.WriteInteger(SECTION_GENERAL, OPT_OVERWRITEMETHOD,
        Ord(OptOverwriteMethod));
      iniFile.WriteInteger(SECTION_GENERAL, OPT_OVERWRITEPASSES,
        OptOverwritePasses);
      iniFile.WriteBool(SECTION_GENERAL, OPT_PRESERVETIMESTAMPSONSTOREEXTRACT,
        OptPreserveTimestampsOnStoreExtract);

      // Layout section...
      iniFile.WriteBool(SECTION_LAYOUT, OPT_STORELAYOUT,
        OptStoreLayout);
      if OptStoreLayout then begin
        iniFile.WriteString(SECTION_LAYOUT, OPT_MAINWINDOWLAYOUT,
          OptMainWindowLayout);
        iniFile.WriteInteger(SECTION_LAYOUT, OPT_EXPLORERBARWIDTH,
          OptExplorerBarWidth);
        iniFile.WriteBool(SECTION_LAYOUT, OPT_SHOWTOOLBARVOLUME,
          OptShowToolbarVolume);
        iniFile.WriteBool(SECTION_LAYOUT, OPT_SHOWTOOLBAREXPLORER,
          OptShowToolbarExplorer);
        iniFile.WriteBool(SECTION_LAYOUT, OPT_TOOLBARVOLUMELARGE,
          OptToolbarVolumeLarge);
        iniFile.WriteBool(SECTION_LAYOUT, OPT_TOOLBARVOLUMECAPTIONS,
          OptToolbarVolumeCaptions);
        iniFile.WriteBool(SECTION_LAYOUT, OPT_TOOLBAREXPLORERLARGE,
          OptToolbarExplorerLarge);
        iniFile.WriteBool(SECTION_LAYOUT, OPT_TOOLBAREXPLORERCAPTIONS,
          OptToolbarExplorerCaptions);
        iniFile.WriteBool(SECTION_LAYOUT, OPT_SHOWADDRESSBAR,
          OptShowAddressBar);
        iniFile.WriteInteger(SECTION_LAYOUT, OPT_SHOWEXPLORERBAR,
          Ord(OptShowExplorerBar));
        iniFile.WriteBool(SECTION_LAYOUT, OPT_SHOWSTATUSBAR,
          OptShowStatusBar);
        iniFile.WriteString(SECTION_LAYOUT, OPT_LISTVIEWLAYOUT,
          OptListViewLayout);
      end else
      if FlagClearLayoutOnSave then begin
        // Purge all layout related - next time the application is started,
        // it'll just assume the defaults
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_MAINWINDOWLAYOUT);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_EXPLORERBARWIDTH);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_SHOWTOOLBARVOLUME);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_SHOWTOOLBAREXPLORER);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_TOOLBARVOLUMELARGE);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_TOOLBARVOLUMECAPTIONS);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_TOOLBAREXPLORERLARGE);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_TOOLBAREXPLORERCAPTIONS);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_SHOWADDRESSBAR);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_SHOWEXPLORERBAR);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_SHOWSTATUSBAR);
        iniFile.DeleteKey(SECTION_LAYOUT, OPT_LISTVIEWLAYOUT);
      end;

      // WebDAV section...
      iniFile.WriteBool(SECTION_WEBDAV, OPT_ENABLESERVER, OptWebDAVEnableServer);
      iniFile.WriteBool(SECTION_WEBDAV, OPT_OVERWRITECACHEONDISMOUNT,
        OptOverwriteWebDAVCacheOnDismount);
      iniFile.WriteInteger(SECTION_WEBDAV, OPT_PORT, OptWebDAVPort);
      iniFile.WriteString(SECTION_WEBDAV, OPT_SHARENAME, OptWebDavShareName);
      iniFile.WriteString(SECTION_WEBDAV, OPT_LOGDEBUG, OptWebDavLogDebug);
      iniFile.WriteString(SECTION_WEBDAV, OPT_LOGACCESS, OptWebDavLogAccess);

    except
      on E: Exception do begin
        allOK := False;
      end;
    end;

  end;

  Result := allOK;
end;   *)

function TExplorerSettings.RegistryKey(): String;
begin
  Result := FREEOTFE_REGISTRY_SETTINGS_LOCATION;
end;


{returns an instance of the only object, must be type TExplorerSettings. call SetSettingsType first}
function GetExplorerSettings: TExplorerSettings;
begin
  assert(GetSettings is TExplorerSettings, 'call SetSettingsType with correct type');
  Result := GetSettings as TExplorerSettings;
end;


end.
