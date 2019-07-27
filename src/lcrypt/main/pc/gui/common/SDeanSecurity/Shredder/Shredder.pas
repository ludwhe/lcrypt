unit Shredder;
// Description: File/Disk Free Space Shredder (overwriter)
// By Sarah Dean
// Email: sdean12@sdean12.org
// WWW:   http://www.SDean12.org/
//
// -----------------------------------------------------------------------------
//


interface

uses
 //delphi
   Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
   //sdu, lcLibs
  lcTypes, lcConsts,
  SDUGeneral,
   dlgProgress,
  frmFileList,
  SDUClasses;
      //forms
type
  TShredDetails = array [0..2] of byte;
  TShredBlock = array of byte;
  TShredFreeSpaceBlock = array of byte;

  TShredFreeSpaceBlockObj = class
  public
    BLANK_FREESPACE_BLOCK: TShredFreeSpaceBlock;
  end;

  TShredResult = (
                  srSuccess    =  1,
                  srError      = -1,
                  srUserCancel = -2
                 );

  TShredMethod = (
                  smZeros,
                  smOnes,
                  smPseudorandom,
                  smRCMP,
                  smUSDOD_E,
                  smUSDOD_ECE,
                  smGutmann
                 );

resourcestring
  SHREDMETHOD_ZEROS             = 'Zeros';
  SHREDMETHOD_ONES              = 'Ones';
  SHREDMETHOD_PSEUDORANDOM_DATA = 'Pseudorandom data';
  SHREDMETHOD_RCMP              = 'RCMP (DSX)';
  SHREDMETHOD_DOD_E             = 'US DoD 5220.22-M (E)';
  SHREDMETHOD_DOD_ECE           = 'US DoD 5220.22-M (ECE)';
  SHREDMETHOD_GUTMANN           = 'Gutmann (35 pass)';
const
  TShredMethodTitle: array [TShredMethod] of Pointer = (
                                                        @SHREDMETHOD_ZEROS,
                                                        @SHREDMETHOD_ONES,
                                                        @SHREDMETHOD_PSEUDORANDOM_DATA,
                                                        @SHREDMETHOD_RCMP,
                                                        @SHREDMETHOD_DOD_E,
                                                        @SHREDMETHOD_DOD_ECE,
                                                        @SHREDMETHOD_GUTMANN
                                                       );
  // Number of each passes for each type.
  // -ve number indicates user specified ("IntPasses" property)
  TShredMethodPasses: array [TShredMethod] of integer = (
                                                        -1,
                                                        -1,
                                                        -1,
                                                        3,
                                                        3,
                                                        7,
                                                        35
                                                       );

type
  // The array passed in is zero-indexed; populate elements zero to "bytesRequired"
//  TGenerateOverwriteDataEvent = procedure (Sender: TObject; passNumber: integer; bytesRequired: cardinal; var generatedOK: boolean; var outputBlock: TShredBlock) of object;
  //encrypt data with IV - if set uses insead of internal prng
  TTweakEncryptDataEvent    = function (cypherKernelModeDeviceName: Ansistring;
      cypherGUID: TGUID; SectorID: LARGE_INTEGER; SectorSize: Integer;
      var key: TSDUBytes; var IV: Ansistring; var plaintext: Ansistring;
      var cyphertext: Ansistring): Boolean of object;

  TNotifyStartingFileOverwritePass = procedure (Sender: TObject; itemName: string; passNumber: integer; totalPasses: integer) of object;
  TCheckForUserCancel = procedure (Sender: TObject; var userCancelled: boolean) of object;
   {$M+}
  TShredder = class(TObject)
  private
    FFileDirUseInt: boolean;
    FFreeUseInt: boolean;
    FExtFileExe: AnsiString;
    FExtDirExe: AnsiString;
    FExtFreeSpaceExe: AnsiString;
    FExtShredFilesThenDir: boolean;
    FIntSegmentOffset: ULONGLONG;
    FIntSegmentLength: ULONGLONG;
    FIntMethod: TShredMethod;
    FIntPasses: integer;
    FIntFreeSpcFileSize: integer;
    FIntFreeSpcSmartFileSize: boolean;
    FIntFreeSpcFileCreationBlkSize: integer;
    FIntFileBufferSize: integer;

//    FOnOverwriteDataReq: TGenerateOverwriteDataEvent;
    FOnTweakEncryptDataEvent :TTweakEncryptDataEvent;

    fwipeCypherBlockSize: Integer;          // In bits - only used if  FOnTweakEncryptDataEvent set
    fwipeCypherEncBlockNo:   Int64;//used by overwrite cypher
    fWipeCypherKey:        TSDUBytes;//used by overwrite cypher
    fwipeCypherDriver:Ansistring;
    fwipeCypherGUID:       TGUID;

    FOnStartingFileOverwritePass: TNotifyStartingFileOverwritePass;
    FOnCheckForUserCancel: TCheckForUserCancel;

    FLastIntShredResult: TShredResult;

    fProgressDlg: TdlgProgress; // created in OverwriteDriveFreeSpace & OverwriteAllFileSlacks only

    function  ShredDir(dirname: string; silent: boolean): TShredResult;
    function  InternalShredFile(
                                filename : string;
                                quickShred: boolean;
                                silent: boolean;
                                              leaveFile: boolean = FALSE
                               ): TShredResult;
    function  DeleteFileOrDir(itemname: string): TShredResult;

    function  BytesPerCluster(filename: string): DWORD;

    function  GetOverwriteDataBlock(passNum: integer; var outputBlock: TShredBlock): boolean;

    procedure GetBlockZeros(var outputBlock: TShredBlock);
    procedure GetBlockOnes(var outputBlock: TShredBlock);
    procedure GetBlockPRNG(var outputBlock: TShredBlock);
    procedure GetBlockRCMP(passNum: integer; var outputBlock: TShredBlock);
    procedure GetBlockDOD(passNum: integer; var outputBlock: TShredBlock);
    procedure GetBlockGutmann(passNum: integer; var outputBlock: TShredBlock);
    function  GetGutmannChars(passNum: integer): TShredDetails;
    function  SetGutmannDetails(nOne: integer; nTwo: integer; nThree: integer): TShredDetails;
    function  CreateEmptyFile(filename: string; size: int64; blankArray: TShredFreeSpaceBlockObj): TShredResult;
    function  GetTempFilename(driveDir: string; serialNo: integer): string;
    function  WipeFileSlacksInDir(dirName: string; problemFiles: TStringList): TShredResult;
    function  CountFiles(dirName: string): integer;
    function  GenerateRndDotFilename(path: string; origFilename: string): string;

    procedure _GenerateOverwriteData(Sender: TObject;
      passNumber: Integer;
      bytesRequired: Cardinal;
      var generatedOK: Boolean;
      var outputBlock: TShredBlock
      );
      //raises EShredderErrorUserCancel
    procedure DoCheckForUserCancel();
          //raises EShredderErrorUserCancel
    procedure CheckProgressCancel;

  protected
    function IsDevice(filename: string): boolean;
    function DeviceDrive(filename: string): char;
  public
//    constructor Create(AOwner: TComponent); override;
    constructor Create({AOwner: TComponent});
    destructor Destroy(); override;

    // Call this to shred all free space on the specified drive
    // Note: Does *not* wipe file slack - OverwriteAllFileSlacks(...) should be
    //       called before this function, if needed
    function  WipeDriveFreeSpace(driveLetter: DriveLetterChar; silent: boolean = FALSE): TShredResult;

    // Call this to a specific file's slack space
    function  WipeFileSlack(filename: string): boolean;

    // Call this to wipe all file slack on the specified drive - raises EShredderErrorUserCancel
    function  OverwriteAllFileSlacks(driveLetter: Ansichar; silent: boolean = FALSE): TShredResult;
function DestroyPart(itemname: string; quickShred: boolean;   {partInfo:TPartitionInformationEx; }silent: boolean = FALSE): TShredResult;


    // You probably don't want to call this one - call
    // OverwriteDriveFreeSpace(...) instead
    function  DestroyDevice(itemname: string; quickShred: boolean; silent: boolean = FALSE): TShredResult;

    // Destroy the specified file or directory
    // Note that, with the internal shredder at any rate, calling WipeFileSlack
    // is not needed before calling this procedure
    function  DestroyFileOrDir(itemname: string; quickShred: boolean; silent: boolean = FALSE; leaveFile: boolean = FALSE): TShredResult;

    // Destroy the specified registry key
    procedure DestroyRegKey(key: string);

  published
    // Set this to TRUE to use the internal shredder when shredding
    // files/directories. Set to FALSE to use a 3rd party executable
    property FileDirUseInt: boolean read FFileDirUseInt write FFileDirUseInt default TRUE;

    // Set this to TRUE to use the internal shredder when shredding
    // free space. Set to FALSE to use a 3rd party executable
    property FreeUseInt: boolean read FFreeUseInt write FFreeUseInt default TRUE;

    // Command to be used when using a 3rd party executable to shred files
    property ExtFileExe: Ansistring read FExtFileExe  write FExtFileExe;

    // Command to be used when using a 3rd party executable to shred directories
    property ExtDirExe: Ansistring read FExtDirExe  write FExtDirExe;

    // Command to be used when using a 3rd party executable to free space
    property ExtFreeSpaceExe: Ansistring read FExtFreeSpaceExe write FExtFreeSpaceExe;

    // When shredding directories, and using a 3rd party executable to do so,
    // if all the files and subdirs within the directory to be destroyed must
    // be destroyed before the directory, this must be set to TRUE.
    property ExtShredFilesThenDir: boolean read FExtShredFilesThenDir write FExtShredFilesThenDir default FALSE;

    // If "quickShred" is set to TRUE on any of the Destroy...(...) calls,
    // then only the FIntSegmentLength bytes of files, starting from offset
    // FIntSegmentOffset will be overwritten before they are deleted
    property IntSegmentOffset: ULONGLONG read FIntSegmentOffset write FIntSegmentOffset default 0;
    property IntSegmentLength: ULONGLONG read FIntSegmentLength write FIntSegmentLength default BYTES_IN_MEGABYTE;  // 1MB

    // Method of shredding to be used.
    // Note: If OnOverwriteDataReq is set, this is ignored (user specified
    //       block generator)
    property IntMethod: TShredMethod read FIntMethod write FIntMethod default smPseudorandom;

    // If IntMethod refers to an overwrite method with a user specified number
    // of passes, this should be set to the required number of passes
    property IntPasses: integer read FIntPasses  write FIntPasses default 1;

    // If this parameter is set, this event will be called to populate the
    // buffer with pseudorandom data before writing.
    // IntMethod will be IGNORED if this is set
    // IF SET, THE METHOD THAT THIS IS SET TO MUST POPULATE THE BUFFER IT IS
    // SUPPLIED WITH
//    property OnOverwriteDataReq: TGenerateOverwriteDataEvent read FOnOverwriteDataReq write FOnOverwriteDataReq default nil;    // if this is set then OverwriteCypherBlockSize,TempCypherKey, and fTempCypherDriver MUST all be set


    property  OnTweakEncryptDataEvent :TTweakEncryptDataEvent write FOnTweakEncryptDataEvent  default nil;
    property  WipeCypherBlockSize :Integer write fwipeCypherBlockSize  default 0;
    property  WipeCypherKey :TSDUBytes write fWipeCypherKey;
    property  wipeCypherDriver :Ansistring write fwipeCypherDriver;
    property  WipeCypherGUID:       TGUID write fwipeCypherGUID;

    // If this parameter is set, this event will be called whenever a file is
    // being overwritten, and it's starting a new pass
    property OnStartingFileOverwritePass: TNotifyStartingFileOverwritePass read FOnStartingFileOverwritePass write FOnStartingFileOverwritePass default nil;

    // If this parameter is set, this event will be called regularly to see if
    // the use has cancelled via some event method
    property OnCheckForUserCancel: TCheckForUserCancel read FOnCheckForUserCancel write FOnCheckForUserCancel default nil;

    // When shredding free space on a drive, the temp files that are created
    // and then overwritten should be of this size
    property IntFreeSpcFileSize: integer read FIntFreeSpcFileSize write FIntFreeSpcFileSize default (50 * BYTES_IN_MEGABYTE);  // 50MB

    // (Used in conjunction with IntFreeSpcFileSize)
    // If this is TRUE, then:
    //   f10 := The amount of free space is computed, and divided by 10
    //   fmax := max(5MB, f10)
    //   If fmax is less than IntFreeSpcFileSize, then fmax will be used
    //   If fmax is more than IntFreeSpcFileSize, then IntFreeSpcFileSize
    //   will be used
    // This means that if progress is being shown to the user, they'll always
    // get at least 10 "blocks" on the progress bar, making the application
    // appear more responsive; to actually be doing something
    property IntFreeSpcSmartFileSize: boolean read FIntFreeSpcSmartFileSize write FIntFreeSpcSmartFileSize default TRUE;

    // When shredding free space on a drive, the temp files that are created
    // are made by repeatedly writing this blocksize amount of data until the
    // file reaches FIntFreeSpcFileSize, or the write fails (at which point,
    // the temp files are overwritten using the normal IntFileBufferSize as
    // with overwriting any other file)
    property IntFreeSpcFileCreationBlkSize: integer read FIntFreeSpcFileCreationBlkSize write FIntFreeSpcFileCreationBlkSize default BYTES_IN_MEGABYTE;  // 1MB

    // When shredding files, blocks of data which are of this buffer length are
    // written to the file to be destroyed until the whole file is overwritten
    property IntFileBufferSize: integer read FIntFileBufferSize write FIntFileBufferSize default BYTES_IN_MEGABYTE;  // 1MB

    property LastIntShredResult: TShredResult read FLastIntShredResult write FLastIntShredResult;
  end;

function ShredMethodTitle(shredMethod: TShredMethod): string;

procedure Overwrite(var x: AnsiString); overload;
procedure Overwrite(var x: TStream); overload;
// Not clear why this next one is needed; descends from TStream, but Delphi
// can't match it when this when a TSDUMemoryStream is passed to the TStream
// version...
procedure Overwrite(var x: TSDUMemoryStream); overload;
procedure Overwrite(var x: TStringList); overload;
procedure OverwriteAndFree(var x: TStream); overload;
// Not clear why this next one is needed; descends from TStream, but Delphi
// can't match it when this when a TSDUMemoryStream is passed to the TStream
// version...
procedure OverwriteAndFree(var x: TSDUMemoryStream); overload;
procedure OverwriteAndFree(var x: TStringList); overload;

function OverwriteVolWithChaff(drive: DriveLetterChar;overwriteWithChaff  : Boolean;
chaffCypherUseKeyLength: Integer  (* In *bits* *);
BlockSize: Integer;CypherDriver: Ansistring;CypherGUID: TGUID;Offset: ULONGLONG;
VolFilename: String): TShredResult;


 // procedure Register;

implementation

uses
//delphi
   Math, Registry,
//sdu , lc utils
  SDUi18n,
  SDUFileIterator_U, SDUDirIterator_U,
  lcDialogs,
  PartitionTools,
  SDURandPool,
  OTFEFreeOTFEBase_U;
//forms

type
  // Exceptions... These should *all* be handled internally
  EShredderError = Exception;
  EShredderErrorUserCancel = EShredderError;


const
  OVERWRITE_FREESPACE_TMP_DIR = '~STUfree';

resourcestring
  USER_CANCELLED = 'User cancelled';


function ShredMethodTitle(shredMethod: TShredMethod): string;
begin
  Result := LoadResString(TShredMethodTitle[shredMethod]);
end;

procedure Overwrite(var x: AnsiString);
begin
  x := StringOfChar(Ansichar(#0), length(x));
end;

procedure Overwrite(var x: TStream);
var
  i: integer;
  tmpByte: byte;
begin
  if (x <> nil) then    begin
    x.Position := 0;
    for i:=0 to (x.Size - 1) do      begin
      tmpByte := random(256);
      x.Write(tmpByte, sizeof(tmpByte));
      end;
    end;
end;

procedure Overwrite(var x: TSDUMemoryStream);
var
  i: integer;
  tmpByte: byte;
begin
  if (x <> nil) then    begin
    x.Position := 0;
    for i:=0 to (x.Size - 1) do      begin
      tmpByte := random(256);
      x.Write(tmpByte, sizeof(tmpByte));
      end;
    end;
end;

procedure Overwrite(var x: TStringList);
var
  i: integer;
begin
  if (x <> nil) then     begin
    for i:=0 to (x.count - 1) do      begin
      x[i] := StringOfChar(#0, length(x[i]));
    end;
  end;

end;

procedure OverwriteAndFree(var x: TSDUMemoryStream);
begin
  if (x <> nil) then    begin
    Overwrite(x);
    x.Free();
    x := nil;
    end;
end;

procedure OverwriteAndFree(var x: TStream);
begin
  if (x <> nil) then    begin
    Overwrite(x);
    x.Free();
    x := nil;
    end;
end;

procedure OverwriteAndFree(var x: TStringList);
begin
  if (x <> nil) then     begin
    Overwrite(x);
    x.Free();
    x := nil;
    end;
end;

constructor TShredder.Create({AOwner: TComponent});
begin
//  inherited;

  FFileDirUseInt:= TRUE;
  FFreeUseInt:= TRUE;
  FExtFileExe:= '';
  FExtDirExe:= '';
  FExtFreeSpaceExe:= '';
  FExtShredFilesThenDir:= FALSE;
  FIntSegmentOffset:= 0;
  FIntSegmentLength:= BYTES_IN_MEGABYTE;  // First MB by default
  FIntMethod:= smPseudorandom;
  FIntPasses:= 1;
  FIntFreeSpcFileSize:= (50 * BYTES_IN_MEGABYTE);  // 50MB by default
  FIntFreeSpcSmartFileSize:= TRUE;
  FIntFreeSpcFileCreationBlkSize:= BYTES_IN_MEGABYTE; // 1MB by default
  FIntFileBufferSize:= BYTES_IN_MEGABYTE; // 1MB by default

end;


destructor TShredder.Destroy();
begin
  inherited;
end;


// Returns #0 on failure
function TShredder.DeviceDrive(filename: string): char;
begin
  Result := #0;
  if IsDevice(filename) then     begin
    Result := filename[5];
  end;

end;

function TShredder.IsDevice(filename: string): boolean;
begin
  Result := (Pos('\\.\', filename) > 0);
end;



// Destroy a given drive.
// !!! WARNING !!!!
// This will overwrite the ENTIRE DRIVE
// !USE WITH EXTREME CAUTION!
// You probably want to call OverwriteDriveFreeSpace(...) - NOT THIS!
// itemname   - The drive to be destroyed e.g. "\\.\Z:"
// quickShred - ignored if not using internal shredding, otherwise if set to
//              FALSE then delete whole file; setting it to TRUE will only
//              delete the first n bytes
// Note: Use LastIntShredResult to determine if user cancelled, or there was a
//       failure in the shredding
function TShredder.DestroyDevice(itemname: string; quickShred: boolean; silent: boolean = FALSE): TShredResult;
begin
  result := srError;
  if IsDevice(itemname) then     begin
    result := InternalShredFile(itemname, quickShred, silent,  TRUE);
  end;
end;


function TShredder.DestroyPart(itemname: string; quickShred: boolean;   {partInfo:TPartitionInformationEx; }silent: boolean = FALSE): TShredResult;
begin
    result := InternalShredFile(itemname, quickShred, silent,  TRUE);
end;


// Destroy a given file/dir, using the method specified in the INI file
// NOTE: When destroying dirs, QUICKSHRED IS ALWAYS FALSE - set in the dir
//       shredding procedure
// itemname   - The file/dir to be destroyed
// quickShred - Ignored if not using internal shredding, otherwise if set to
//              FALSE then delete whole file; setting it to TRUE will only
//              delete the first n bytes
// leaveFile - Ignored if not using internal shredding AND "itemname" refers to
//             a file (NOT dir - not yet implemented with this). Set to TRUE to
//             prevent the final deletion of the file. FALSE to go ahead with
//             the final delete
function TShredder.DestroyFileOrDir(itemname: string; quickShred: boolean; silent: boolean = FALSE; leaveFile: boolean = FALSE): TShredResult;
var
{$IFDEF MSWINDOWS}
  fileAttributes : integer;
{$ENDIF}
  shredderCommandLine : AnsiString;
begin
  // Remove any hidden, system or readonly file attrib
{$IFDEF MSWINDOWS}
{$WARNINGS OFF}  // Useless warning about platform - we're already protecting
                 // against that!
  fileAttributes := FileGetAttr(itemname);
  fileAttributes := fileAttributes AND not(faReadOnly);
  fileAttributes := fileAttributes AND not(faHidden);
  fileAttributes := fileAttributes AND not(faSysFile);
  FileSetAttr(itemname, fileAttributes);
{$WARNINGS ON}
{$ENDIF}
{$IFDEF LINUX}
  xxx - to be implemented: remove any readonly attribute from the file
{$ENDIF}
    fwipeCypherEncBlockNo := 0;

  if (fileAttributes AND faDirectory)<>0 then      begin
    result := ShredDir(itemname, silent);
    end    else    begin
    itemname := SDUConvertLFNToSFN(itemname);
    if FFileDirUseInt then      begin
      result := InternalShredFile(itemname, quickShred, silent,  leaveFile);
    end    else      begin
      shredderCommandLine := format(FExtFileExe, [itemname]); { TODO 1 -otdk -cinvestigate : what happens if unicode filename? }
      WinExec(PAnsiChar(shredderCommandLine), SW_MINIMIZE);
      // Assume success
      result := srSuccess;
      end;
    end;

end;


// Attempt to get the number of bytes/cluster on the drive the specified file is
// stored on
// Returns: The number of bytes per sector; or "1" if this cannot be
//          determined (e.g. the filename is a UNC)
function TShredder.BytesPerCluster(filename: string): DWORD;
var
  driveColon: string;

  dwSectorsPerCluster: DWORD;
  dwBytesPerSector: DWORD;
  dwNumberOfFreeClusters: DWORD;
  dwTotalNumberOfClusters: DWORD;
begin
  // Attempt to get the number of bytes/sector
  result := 1;
  if (
      (Pos(':\', filename) = 2) or
      (Pos(':/', filename) = 2)
     ) then     begin
    driveColon := filename[1]+':\';
    if GetDiskFreeSpace(
                        PChar(driveColon),       // address of root path
                        dwSectorsPerCluster,     // address of sectors per cluster
                        dwBytesPerSector,        // address of bytes per sector
                        dwNumberOfFreeClusters,  // address of number of free clusters
                        dwTotalNumberOfClusters  // address of total number of clusters
                       ) then      begin
      result := (dwBytesPerSector * dwSectorsPerCluster);
      end;

    end;

end;


// leaveFile - Set to TRUE to just leave the file after shredding; don't
//             delete it (default = FALSE). (Used when shredding files created
//             during drive freespace overwriting; the files must remain)
// silentProgressDlg - If silent is set to TRUE, then this may *optionally* be
//                     set to a progress dialog. This progress dialog will
//                     *only* be used for checking to see if the user's
//                     cancelled the operation
// Returns: TShredResult
function TShredder.InternalShredFile(
                                     filename: string;
                                     quickShred: boolean;
                                     silent: boolean;
                                     leaveFile: boolean = FALSE
                                    ): TShredResult;
var
  fileHandle : THandle;
  i: integer;
  blankingBytes: TShredBlock;
  bytesToShredLo: DWORD;
  bytesToShredHi: DWORD;
  bytesWritten: DWORD;
  numPasses: integer;
  progressDlg: TdlgProgress; // two progress dialogs used
  bpc: DWORD;
  bpcMod: DWORD;
  tmpDWORD: DWORD;
  bytesLeftToWrite: int64;
  failure: boolean;
  userCancel: boolean;
  bytesToWriteNow: DWORD;
  gotSize: boolean;
  drive: char;
  partInfo: TSDUPartitionInfo;
  tmpUint64: ULONGLONG;
  useShredMethodTitle: string;
  tmpInt64: int64;
 startOffsetLo: DWORD;
  startOffsetHi: DWORD;
begin
  failure := FALSE;
  userCancel := FALSE;


  // Initilize zeroed IV for encryption
  fwipeCypherEncBlockNo := 0;

  bpc:= BytesPerCluster(filename);

  // Determine number of passes...
  numPasses := TShredMethodPasses[IntMethod];
  if (numPasses < 0) then    begin
    numPasses := FIntPasses;
  end;

  progressDlg:= TdlgProgress.create(nil);
  try
    progressDlg.ShowTimeRemaining := TRUE;
    try  // Exception handler for EShredderErrorUserCancel
      if not(silent) then        begin
        progressDlg.Show();
      end;

      // Nuke any file attributes (e.g. readonly)
{$IFDEF MSWINDOWS}
{$WARN SYMBOL_PLATFORM OFF}  // Useless warning about platform - we're already
                             // protecting against that!
      FileSetAttr(filename, 0);
{$WARN SYMBOL_PLATFORM ON}
{$ENDIF}


      gotSize := FALSE;
      bytesToShredHi := 0;
      bytesToShredLo := 0;
      if IsDevice(filename) then        begin
        drive := DeviceDrive(filename);
        gotSize := SDUGetPartitionInfo(drive, partInfo);
        if gotSize then          begin
          tmpUint64 := (partInfo.PartitionLength shr 32);
          bytesToShredHi := tmpUint64 and $00000000FFFFFFFF;
          bytesToShredLo := partInfo.PartitionLength and $00000000FFFFFFFF;
        end;
      end;

      fileHandle := CreateFile(PChar(filename),
                               GENERIC_READ or GENERIC_WRITE,
                               0,
                               nil,
                               OPEN_EXISTING,
                               FILE_ATTRIBUTE_NORMAL or FILE_FLAG_WRITE_THROUGH,
                               0);
      if (fileHandle = INVALID_HANDLE_VALUE) then         begin
          ShowMessage(SysErrorMessage(GetLastError()));
        failure := TRUE;
      end      else        begin
        try
          // Identify the size of the file being overwritten...
          if not(IsDevice(filename)) then            begin
            bytesToShredLo := GetFileSize(fileHandle, @bytesToShredHi);
            gotSize := not( (bytesToShredLo = $FFFFFFFF) AND (GetLastError()<>NO_ERROR) );
          end;

          // Check that the GetFileSize call was successful...
          if gotSize then            begin
            // Adjust to increase up to the nearest bytes per sector boundry
            // Note: This makes the reasonable assumption that ($FFFFFFFF + 1)
            //       will always be a multiple of "bpc"; so we don't need to
            //       bother involving the high DWORD of the file's size in this
            //       calculation
            bpcMod := (bytesToShredLo mod bpc);
            if (bpcMod>0) then begin
              tmpDWORD := bytesToShredLo + (bpc - bpcMod);
              // In case that causes an overflow...
              if (bytesToShredLo > tmpDWORD) then                begin
                inc(bytesToShredHi);
              end;
              bytesToShredLo := tmpDWORD;
            end;

            // Sanity check - we can only handle files less than 2^63 bytes long
            // tmpInt64 used to prevent Delphi effectivly casting to DWORD
            tmpInt64 := bytesToShredHi;
            bytesLeftToWrite := (tmpInt64 shl 32) + bytesToShredLo;
            if (bytesLeftToWrite < 0) then                begin
              // Do nothing - result defaults to error
            end            else              begin
              startOffsetLo := 0;
              startOffsetHi := 0;
              if quickShred then                 begin
                startOffsetLo := (IntSegmentOffset AND $FFFFFFFF);
                startOffsetHi := (IntSegmentOffset shr 32);

                bytesLeftToWrite := bytesLeftToWrite - IntSegmentOffset;

                // Note: Cast to int64 to ensure that no problems with truncation
                bytesLeftToWrite := min(bytesLeftToWrite, int64(IntSegmentLength));
                bytesToShredHi := (bytesLeftToWrite shr 32);
                bytesToShredLo := (bytesLeftToWrite AND $FFFFFFFF);
              end;

              progressDlg.i64Min := 0;
              progressDlg.i64Max := bytesLeftToWrite;

              for i:=1 to numPasses do                begin
                // Let user know what's going on...
                useShredMethodTitle := ShredMethodTitle(IntMethod);
                if assigned(FOnTweakEncryptDataEvent) then
                  useShredMethodTitle := _('Custom');

                progressDlg.Caption := Format(_('Wiping (%s pass %d/%d) %s'),
                                              [useShredMethodTitle, i, numPasses, filename]
                                             );
                progressDlg.i64Position := 0;

                if assigned(OnStartingFileOverwritePass) then                  begin
                  OnStartingFileOverwritePass(self, filename, i, numPasses);
                end;

                // Has user cancelled?
                Application.ProcessMessages();
                if progressDlg.Cancel then                               begin
                  raise EShredderErrorUserCancel.Create(USER_CANCELLED);
                end;
                CheckProgressCancel;
                DoCheckForUserCancel();

                // Reset the file ptr
                SetFilePointer(
                               fileHandle,
                               startOffsetLo,
                               @startOffsetHi,
                               FILE_BEGIN
                              );

                // Reset the total number of bytes to be written...
                // tmpInt64 used to prevent Delphi effectivly casting to DWORD
                tmpInt64 := bytesToShredHi;
                bytesLeftToWrite := (tmpInt64 shl 32) + bytesToShredLo;

                // Fill a block with random garbage
                SetLength(blankingBytes, FIntFileBufferSize);
                if not(assigned(FOnTweakEncryptDataEvent)) then
                  failure := not(GetOverwriteDataBlock(i, blankingBytes));



                while (
                       (bytesLeftToWrite > 0) AND
                       not(failure)
                      ) do
                  begin
                  progressDlg.i64Position := (progressDlg.i64Max - bytesLeftToWrite);

                  // Has user cancelled?
                  Application.ProcessMessages();
                  if progressDlg.Cancel then                    begin
                    raise EShredderErrorUserCancel.Create(USER_CANCELLED);
                    end;
                  CheckProgressCancel;
                  DoCheckForUserCancel;

                  // Generate new data if user supplied routine...
                  if (assigned(FOnTweakEncryptDataEvent)) then
                    failure := not(GetOverwriteDataBlock(i, blankingBytes));


                  // Note: Cast to int64 to ensure no problems
                  bytesToWriteNow := (min(bytesLeftToWrite, int64(FIntFileBufferSize)) AND $FFFFFFFF);
                  failure := failure or not(WriteFile(fileHandle, blankingBytes[0], bytesToWriteNow, bytesWritten, nil));

                  dec(bytesLeftToWrite, bytesWritten);

                  // Ensure that the buffer is flushed to disk (even through disk caching
                  // software) [from Borland FAQ]
  // xxx - this line commented out - prevents process from exiting?! It remains
  //       visible in task manager, and can't be killed?!
  //                FlushFileBuffers(fileHandle);
                  end;


                if (failure) then                   begin
                  // Get out of loop...
                  break;
                  end;

                end;  // for i:=1 to numPasses do

              end;  // ELSE PART - if (bytesLeftToWrite < 0) then
            end;  // if not( (fileLengthLo = $FFFFFFFF) AND (GetLastError()<>NO_ERROR) ) then
        finally
  // xxx - this line commented out - prevents process from exiting?! It remains
  //       visible in task manager, and can't be killed?!
  //        FlushFileBuffers(fileHandle);
          CloseHandle(fileHandle);
        end;

        end;  // ELSE PART - if (fileHandle = INVALID_HANDLE_VALUE) then

    except
      on EShredderErrorUserCancel do        begin
        // Ensure flag set
        userCancel := TRUE;
        end;

    end;

  finally
    progressDlg.Free();
  end;


  // Clean up file?
  if not(leaveFile) then    begin
    DeleteFileOrDir(filename);
  end;

  // Determine return value...
  result := srSuccess; // Everything OK...
  if userCancel then    begin
    result := srUserCancel;
  end  ;

  if failure then    begin
    result := srError;
  end;

  FLastIntShredResult := result;
end;

// Simple rename a file/dir and then delete it.
function TShredder.DeleteFileOrDir(itemname: string): TShredResult;
const
  // This should be enough to overwrite any LFN directory entries (about 255 chars long)
  MASSIVE_FILENAME = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'+
  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'+
  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaa';
var
  j: integer;
  deleteFilename: string;
  testRenameFilename: string;
  fileAttributes: integer;
  largeFilename: string;
  fileHandle : THandle;
  tmpFsp: string;
  zero: DWORD;
  fileIterator: TSDUFileIterator;
  currFile: string;
begin
  result := srError;

  zero := 0; // Obviously!
  try
    tmpFsp := GenerateRndDotFilename(ExtractFilePath(itemname), ExtractFileName(itemname));
    tmpFsp := ExtractFilePath(itemname)+tmpFsp;
    if tmpFsp<>'' then
      begin
      if RenameFile(itemname, tmpFsp) then
        begin
        itemname := tmpFsp;
        end;
      end;

    deleteFilename := itemname;
    if (Win32Platform=VER_PLATFORM_WIN32_NT) then      begin
      for j:=ord('a') to ord('z') do        begin
        testRenameFilename := ExtractFilePath(itemname) + chr(j)+'.';
        if not(fileexists(testRenameFilename)) then          begin
          deleteFilename := testRenameFilename;
          break;
          end;
        end;

      largeFilename := ExtractFilePath(itemname) + MASSIVE_FILENAME;
      if length(largeFilename)>MAX_PATH then        begin
        Delete(largeFilename, MAX_PATH-1, length(largeFilename)-MAX_PATH+1);
        end;


      if RenameFile(itemname, largeFilename) then        begin
        if not(RenameFile(largeFilename, deleteFilename)) then          begin
          deleteFilename := largeFilename;
        end;
      end      else        begin
        deleteFilename := itemname;
      end;

      end;

{$IFDEF MSWINDOWS}
{$WARN SYMBOL_PLATFORM OFF}  // Useless warning about platform - we're already
                             // protecting against that!
    fileAttributes := FileGetAttr(deleteFilename);
    if (fileAttributes AND faDirectory)=0 then
{$WARN SYMBOL_PLATFORM ON}
{$ENDIF}
{$IFDEF LINUX}
   xxx - to be implemented: test if it's *not* a directory
{$ENDIF}
      begin
      // Truncate the file to 0 bytes and set it's date/time to some junk
      fileHandle := CreateFile(PChar(deleteFilename),
                               GENERIC_READ or GENERIC_WRITE,
                               0,
                               nil,
                               OPEN_EXISTING,
                               FILE_ATTRIBUTE_NORMAL or FILE_FLAG_WRITE_THROUGH,
                               0);
      SetFilePointer(fileHandle, 0, @zero, FILE_BEGIN);
      SetEndOfFile(fileHandle);

      SDUSetAllFileTimes(fileHandle, DateTimeToFileDate(encodedate(1980, 1, 1)));

      CloseHandle(fileHandle);

      if DeleteFile(deleteFilename) then        begin
        result := srSuccess;
        end;

      end    else      begin
      // Delete all files and dirs beneath the directory
      fileIterator := TSDUFileIterator.Create(nil);
      try
        fileIterator.Directory := deleteFilename;
        fileIterator.RecurseSubDirs := FALSE;  // We handle recursion
        fileIterator.IncludeDirNames := TRUE;
        fileIterator.OmitStartDirPrefix := FALSE;
        fileIterator.Reset();

        currFile := fileIterator.Next();
        result := srSuccess;
        while (currFile<>'') do          begin
          result := DeleteFileOrDir(currFile);

          if (result <> srSuccess) then            begin
            break;
            end;

          currFile := fileIterator.Next();
          end;

      finally
        fileIterator.Free();
      end;

      if (result = srSuccess) then        begin
        // Finally, remove the dir itsself...
        if RemoveDir(deleteFilename) then          begin
          result := srSuccess;
          end;
        end;

      end;
  except
    begin
    // Nothing (i.e. ignore all exceptions, e.g. can't open file)
    result := srError;
    end;
  end;


end;


{ The array passed in is zero-indexed; populate elements zero to "bytesRequired"
only called if FOnTweakEncryptDataEvent is set - generates csprng data using encryption }
procedure TShredder._GenerateOverwriteData(
  Sender: TObject;
  passNumber: Integer;
  bytesRequired: Cardinal;
  var generatedOK: Boolean;
  var outputBlock: TShredBlock
  );
var
  i:                Integer;
  tempArraySize:    Cardinal;
  blocksizeBytes:   Cardinal;
  plaintext:        Ansistring;
  cyphertext:       Ansistring;
  IV:               Ansistring;
  localIV:          Int64;
  sectorID:         LARGE_INTEGER;
  tempCipherkeyStr: Ansistring;
const
    DUMMY_SECTOR_SIZE = 512;
begin
   assert(assigned(FOnTweakEncryptDataEvent));
  // Generate an array of random data containing "bytesRequired" bytes of data,
  // plus additional random data to pad out to the nearest multiple of the
  // cypher's blocksize bits
  // Cater for if the blocksize was -ve or zero
  if (fwipeCypherBlockSize < 1) then begin
    blocksizeBytes := 1;
  end else begin
    blocksizeBytes := (fwipeCypherBlockSize div 8);
  end;
  tempArraySize := bytesRequired + (blocksizeBytes - (bytesRequired mod blocksizeBytes));

  plaintext := '';
  for i := 1 to tempArraySize do begin
    plaintext := plaintext + Ansichar(random(256));
    { DONE 2 -otdk -csecurity : This is not secure PRNG - but is encrypted below, so the result is secure }
  end;


  Inc(fwipeCypherEncBlockNo);

  // Adjust the IV so that this block of encrypted pseudorandom data should be
  // reasonably unique
  IV := '';
  if (fwipeCypherBlockSize > 0) then begin
    IV := StringOfChar(AnsiChar(#0), (fwipeCypherBlockSize div 8));

    localIV := fwipeCypherEncBlockNo;

    for i := 1 to min(sizeof(localIV), length(IV)) do begin
      IV[i]   := Ansichar((localIV and $FF));
      localIV := localIV shr 8;
    end;

  end;

  // Adjust the sectorID so that this block of encrypted pseudorandom data
  // should be reasonably unique
  sectorID.QuadPart := fwipeCypherEncBlockNo;
  // Encrypt the pseudorandom data generated
  tempCipherkeyStr := SDUBytesToString(fWipeCypherKey);
  if not (FOnTweakEncryptDataEvent(fwipeCypherDriver, fwipeCypherGUID,
    sectorID, DUMMY_SECTOR_SIZE, fWipeCypherKey, IV, plaintext, cyphertext)) then begin
    SDUMessageDlg(
      _('Error: unable to encrypt pseudorandom data before using for wipe buffer')
//      SDUCRLF + SDUCRLF + Format(_('Error #: %d'), [GetFreeOTFEBase().LastErrorCode])
,
      mtError
      );

    generatedOK := False;
  end else begin
    // Copy the encrypted data into the outputBlock
    for i := 0 to (bytesRequired - 1) do
      outputBlock[i] := Byte(cyphertext[i + 1]);

    generatedOK := True;
  end;
end;



function TShredder.GetOverwriteDataBlock(passNum: integer; var outputBlock: TShredBlock): boolean;
begin
  Result := TRUE;

  if assigned(FOnTweakEncryptDataEvent) then    begin
    _GenerateOverwriteData(self, passNum, (high(outputBlock)-low(outputBlock)), Result, outputBlock);
   end  else    begin
    case IntMethod of
      smZeros:            GetBlockZeros(outputBlock);

      smOnes:             GetBlockOnes(outputBlock);

      smPseudorandom:        GetBlockPRNG(outputBlock);

      smRCMP:                GetBlockRCMP(passNum, outputBlock);

      smUSDOD_E:             GetBlockDOD(passNum, outputBlock);

      smUSDOD_ECE:           GetBlockDOD(passNum, outputBlock);

      smGutmann:             GetBlockGutmann(passNum, outputBlock);

    end;

  end;

end;


procedure TShredder.GetBlockZeros(var outputBlock: TShredBlock);
var
  i: integer;
begin
  for i:=low(outputBlock) to high(outputBlock) do    begin
    outputBlock[i] := 0;
    end;
end;

procedure TShredder.GetBlockOnes(var outputBlock: TShredBlock);
var
  i: integer;
begin
  for i:=low(outputBlock) to high(outputBlock) do    begin
    outputBlock[i] := $FF;
    end;
end;

procedure TShredder.GetBlockPRNG(var outputBlock: TShredBlock);
var
  i: integer;
begin
  for i:=low(outputBlock) to high(outputBlock) do    begin
    outputBlock[i] := random(256);
    end;
end;

procedure TShredder.GetBlockRCMP(passNum: integer; var outputBlock: TShredBlock);
const
  DSX_VERSION_ID = 1.40;
var
  i: integer;
  strBlock: string;
  timeStamp: TDateTime;
  year: WORD;
  month: WORD;
  day: WORD;
  hour: WORD;
  min: WORD;
  sec: WORD;
  msec: WORD;
begin
  if (passNum = 1) then    begin
    // 0x00
    for i:=low(outputBlock) to high(outputBlock) do      begin
      outputBlock[i] := $00;
      end;
    end
  else if (passNum = 2) then    begin
    // 0xFF
    for i:=low(outputBlock) to high(outputBlock) do      begin
      outputBlock[i] := $FF;
      end;
    end
  else if (passNum = 3) then    begin
    // Text with version ID and date/timestamp
    timeStamp := now;
    DecodeDate(timeStamp, year, month, day);
    DecodeTime(timeStamp, hour, min, sec, msec);

    strBlock := Format(
                       '%f%.4d%.2d%.2d%.2d%.2d%.2d',
                       [
                        DSX_VERSION_ID,
                        year,
                        month,
                        day,
                        hour,
                        min,
                        sec
                       ]
                      );
    for i:=low(outputBlock) to high(outputBlock) do      begin
      outputBlock[i] := ord(strBlock[ ((i mod length(strBlock)) + 1) ]);
      end;

    end;

end;


procedure TShredder.GetBlockDOD(passNum: integer; var outputBlock: TShredBlock);
var
  i: integer;
begin
  if (
      (passNum = 1) or
      (passNum = 5)
     ) then
    begin
    // Any character...
    for i:=low(outputBlock) to high(outputBlock) do      begin
      outputBlock[i] := $00;
      end;
    end
  else if (
      (passNum = 2) or
      (passNum = 6)
     ) then
    begin
    // Character's complement...
    for i:=low(outputBlock) to high(outputBlock) do      begin
      outputBlock[i] := $FF;
      end;
    end
  else if (
      (passNum = 3) or
      (passNum = 7)
     ) then    begin
    // Random...
    GetBlockPRNG(outputBlock);
    end
  else if (passNum = 4) then    begin
    // Single character...
    for i:=low(outputBlock) to high(outputBlock) do      begin
      outputBlock[i] := $7F;
      end;
    end;

end;

procedure TShredder.GetBlockGutmann(passNum: integer; var outputBlock: TShredBlock);
var
  i: integer;
  passDetails: TShredDetails;
begin
  if (passNum<5) OR (passNum>31) then    begin
    GetBlockPRNG(outputBlock);
    end  else    begin
    passDetails := GetGutmannChars(passNum);
    for i:=low(outputBlock) to high(outputBlock) do      begin
      outputBlock[i] := passDetails[i mod 3];
      end;
    end;

end;

function TShredder.GetGutmannChars(passNum: integer): TShredDetails;
begin
  case passnum of
   5: Result := SetGutmannDetails($55, $55, $55);
   6: Result := SetGutmannDetails($aa, $aa, $aa);
   7: Result := SetGutmannDetails($92, $49, $24);
   8: Result := SetGutmannDetails($49, $24, $92);
   9: Result := SetGutmannDetails($24, $92, $49);
  10: Result := SetGutmannDetails($00, $00, $00);
  11: Result := SetGutmannDetails($11, $11, $11);
  12: Result := SetGutmannDetails($22, $22, $22);
  13: Result := SetGutmannDetails($33, $33, $33);
  14: Result := SetGutmannDetails($44, $44, $44);
  15: Result := SetGutmannDetails($55, $55, $55);
  16: Result := SetGutmannDetails($66, $66, $66);
  17: Result := SetGutmannDetails($77, $77, $77);
  18: Result := SetGutmannDetails($88, $88, $88);
  19: Result := SetGutmannDetails($99, $99, $99);
  20: Result := SetGutmannDetails($aa, $aa, $aa);
  21: Result := SetGutmannDetails($bb, $bb, $bb);
  22: Result := SetGutmannDetails($cc, $cc, $cc);
  23: Result := SetGutmannDetails($dd, $dd, $dd);
  24: Result := SetGutmannDetails($ee, $ee, $ee);
  25: Result := SetGutmannDetails($ff, $ff, $ff);
  26: Result := SetGutmannDetails($92, $49, $24);
  27: Result := SetGutmannDetails($49, $24, $92);
  28: Result := SetGutmannDetails($24, $92, $49);
  29: Result := SetGutmannDetails($6d, $b6, $db);
  30: Result := SetGutmannDetails($b6, $db, $6d);
  31: Result := SetGutmannDetails($db, $6d, $b6);
  end;

end;

function TShredder.SetGutmannDetails(nOne: integer; nTwo: integer; nThree: integer): TShredDetails;
begin
  Result[0] := nOne;
  Result[1] := nTwo;
  Result[2] := nThree;

end;

// Returns: TShredResult
function TShredder.WipeDriveFreeSpace(driveLetter: DriveLetterChar; silent: boolean): TShredResult;
const
  FIVE_MB = (5 * BYTES_IN_MEGABYTE);
var
  drive: DriveLetterString;
  tempDriveDir: string;
  freeSpace: int64;
  fileNumber: integer;
  currFilename: string;
  blankArray: TShredFreeSpaceBlockObj;
  i: integer;
//  lastFilename: string;
  shredderCommandLine: Ansistring;
  diskNumber: integer;
//  internalShredOK: TShredResult;
  useTmpFileSize,curTempFileSize: int64;
  prevCursor: TCursor;
  free_space_left: boolean;
begin
  result := srSuccess;

  // Initilize zeroed IV for encryption
  fwipeCypherEncBlockNo := 0;

  if not(FFreeUseInt) then begin
    shredderCommandLine := format(FExtFreeSpaceExe, [driveLetter]);  // no data loss in converting to ansi - as driveLetter  is ansichar
    if (WinExec(PAnsiChar(shredderCommandLine), SW_RESTORE))<31 then begin
       result := srError;
      SDUMessageDlg(_('Error running external (3rd party) free space shredder'),
                 mtError,
                 [mbOK],
                 0);
    end;

  end  else    begin
    fProgressDlg := TdlgProgress.Create(nil);
    try
      fProgressDlg.ShowTimeRemaining := TRUE;
      blankArray := TShredFreeSpaceBlockObj.Create();
      try
        SetLength(blankArray.BLANK_FREESPACE_BLOCK, FIntFreeSpcFileCreationBlkSize);
        for i:=0 to FIntFreeSpcFileCreationBlkSize-1 do          begin
          blankArray.BLANK_FREESPACE_BLOCK[i] := 0;
          end;

        // Create a subdir
        drive := uppercase(driveLetter);
        driveLetter := drive[1];
        tempDriveDir := driveLetter + ':\'+OVERWRITE_FREESPACE_TMP_DIR+inttostr(random(10000))+'.tmp';
        diskNumber := ord(drive[1])-ord('A')+1;

        if not CreateDir(tempDriveDir) then            result := srError;

        fileNumber := 0;

        // While there is FIntFreeSpcFileSize (or smart) bytes diskspace
        // left, create a file FIntFreeSpcFileSize (or smart) big
        freeSpace := DiskFree(diskNumber);
        if freeSpace <0 then begin
                             result := srError;
                             exit;
        end;

        fProgressDlg.Caption := Format(_('Wiping free space on drive %s:'), [driveLetter]);
        fProgressDlg.i64Max := freeSpace;
        fProgressDlg.i64Min := 0;
        fProgressDlg.i64Position := 0;
        prevCursor := Screen.Cursor;
        if not(silent) then begin
          Screen.Cursor := crAppStart;
          fProgressDlg.Show();
        end;

        try  // Finally (mouse cursor revert)

           try
            try  // Finally

              if FIntFreeSpcSmartFileSize then begin
                useTmpFileSize:= max((freeSpace div 10), FIVE_MB);
                if (useTmpFileSize >= int64(FIntFreeSpcFileSize)) then begin
                  useTmpFileSize := FIntFreeSpcFileSize;
                end;
              end else begin
                useTmpFileSize:= FIntFreeSpcFileSize;
              end;

              // This is > and not >= so that the last file to be created (outside this
              // loop) isn't zero bytes long
              free_space_left := freeSpace>0;
              while free_space_left do begin

                if freeSpace>useTmpFileSize then begin
                  curTempFileSize :=  useTmpFileSize;
                end else begin
                 // Create a file with the remaining disk bytes
                  curTempFileSize :=  freeSpace;
                  free_space_left  := false;
                end;

                inc(fileNumber);
                currFilename := GetTempFilename(tempDriveDir, fileNumber);

                result := CreateEmptyFile(currFilename, curTempFileSize, blankArray);

                if (result = srUserCancel) then
                  break;

                if (result = srError) then
                  // Quit loop...
                  break;

               DoCheckForUserCancel();


                // Shred the file, but _don't_ _delete_ _it_
                // Note that this will overwrite any slack space at the end of the file
                result := InternalShredFile(currFilename, FALSE, TRUE,  TRUE);
                if (result = srUserCancel) then   break;

                if (result = srError) then
                  // Quit loop...
                 break;

                DoCheckForUserCancel();


                freeSpace := DiskFree(diskNumber);
                assert(freeSpace>=0,'can''t get free space');
                fprogressDlg.i64InversePosition := freeSpace;

                // Check for user cancel...
                Application.ProcessMessages();
                CheckProgressCancel;
                DoCheckForUserCancel();

                end;  // while ... do
             except
                // can be raised by InternalShredFile , DoCheckForUserCancel
               on EShredderErrorUserCancel do
                 result := srUserCancel;
            end;


            finally
              // Remove any files that were created, together with the dir
              DeleteFileOrDir(tempDriveDir);
            end;
        finally
          // Revert the mouse pointer, if we were showing overwrite
          // progress...
          if not(silent) then Screen.Cursor := prevCursor;
        end;


      finally
        blankArray.Free();
      end;

    finally
      freeandnil(fProgressDlg);
    end;

  end; // use internal free space shredder

end;


// progressDlg - This may *optionally* be
//               set to a progress dialog. This progress dialog will
//               *only* be used for checking to see if the user's
//               cancelled the operation
function TShredder.CreateEmptyFile(filename: string; size: int64; blankArray: TShredFreeSpaceBlockObj): TShredResult;
var

  fileHandle : THandle;
  bytesWritten: DWORD;
  bytesInBlock: DWORD;
  totalBytesWritten: int64;

begin
  result := srSuccess;

  fileHandle := CreateFile(PChar(filename),
                           GENERIC_READ or GENERIC_WRITE,
                           0,
                           nil,
                           CREATE_ALWAYS,
                           FILE_ATTRIBUTE_NORMAL or FILE_FLAG_WRITE_THROUGH,
                           0);

  if (fileHandle = INVALID_HANDLE_VALUE) then    begin
    result := srError;
  end  else    begin
    try
      // Fill out the file to the required size
      totalBytesWritten := 0;
      // Set bytesWritten to bootstrap loop
      bytesWritten := 1;
      while ( (totalBytesWritten<size) and (bytesWritten>0) )do        begin
        bytesInBlock := min((size-totalBytesWritten), FIntFreeSpcFileCreationBlkSize);
        WriteFile(fileHandle, blankArray.BLANK_FREESPACE_BLOCK[0], bytesInBlock, bytesWritten, nil);
        inc(totalBytesWritten, bytesWritten);

        // Has user cancelled?
        Application.ProcessMessages();
        CheckProgressCancel;
       DoCheckForUserCancel;

      end;

      // Ensure that the buffer is flushed to disk (even through disk caching
      // software) [from Borland FAQ]
    // xxx - this line commented out - prevents process from exiting?! It remains
    //       visible in task manager, and can't be killed?!
    //  FlushFileBuffers(fileHandle);

    finally
      CloseHandle(fileHandle);
    end;

    end;  // ELSE PART -  if (fileHandle = INVALID_HANDLE_VALUE) then


//  // Determine return value...
//  if (failure) then    begin
//    result := srError;
//    end
//  else if (userCancel) then    begin
//    result := srUserCancel;
//    end  else    begin
//    // Everything OK...
//    result := srSuccess;
//    end;
end;


function TShredder.GetTempFilename(driveDir: string; serialNo: integer): string;
begin
  Result := driveDir + '\~STUtmp.'+inttostr(serialNo);
end;


function TShredder.OverwriteAllFileSlacks(driveLetter: Ansichar; silent: boolean): TShredResult;
var
//  progressDlg: TdlgProgress;
  rootDir: string;
  problemFiles: TStringList;
  reportDlg: TfrmFileList;
  drive: Ansistring;
begin
  drive := uppercase(driveLetter);
  driveLetter := drive[1];
  fprogressDlg := TdlgProgress.Create(nil);
  problemFiles:= TStringList.create();
  try
    rootDir:= driveLetter+':\';

    fProgressDlg.ShowTimeRemaining := TRUE;
    fProgressDlg.Caption := Format(_('Wiping file slack on drive %s:'), [driveLetter]);
    fProgressDlg.i64Max := CountFiles(rootDir);
    fProgressDlg.i64Min := 0;
    fProgressDlg.i64Position := 0;
    if not(silent) then      fProgressDlg.Show();


    Result := WipeFileSlacksInDir(rootDir,  problemFiles);

    if not(silent) AND (problemFiles.count>0) then begin
      reportDlg := TfrmFileList.Create(nil);
      try
        reportDlg.lbFiles.visible := TRUE;
        reportDlg.lblTitle.caption := _('The following files could not have their slack space wiped:');
        reportDlg.lbFiles.items.assign(problemFiles);
        reportDlg.showmodal;
      finally
        reportDlg.Free();
      end;
    end;
  finally
    problemFiles.Free();
    freeandnil(fprogressDlg);
  end;
end;


// Perform file slack shredding on all files in specified dir
function TShredder.WipeFileSlacksInDir(dirName: string;  problemFiles: TStringList): TShredResult;
var
  slackFile: string;
  fileIterator: TSDUFileIterator;
  currFile: string;
//  eventUserCancel: boolean;
begin
  result := srSuccess;
//  eventUserCancel := FALSE;

  fileIterator := TSDUFileIterator.Create(nil);
  try
    fileIterator.Directory := dirName;
    fileIterator.RecurseSubDirs := TRUE;
    fileIterator.IncludeDirNames := FALSE;
    fileIterator.OmitStartDirPrefix := FALSE;

    fileIterator.Reset();

    currFile := fileIterator.Next();
    while (currFile<>'') do
      begin
      slackFile := SDUConvertLFNToSFN(currFile);
      if not(WipeFileSlack(slackFile)) then
        begin
        problemFiles.add(slackFile);
        end;

      fProgressDlg.i64IncPosition();
      if fProgressDlg.Cancel then        begin
        result := srUserCancel;
        break;
        end;
     DoCheckForUserCancel;

      currFile := fileIterator.Next();
      end;

  finally
    fileIterator.Free();
  end;


end;


function TShredder.WipeFileSlack(filename: string): boolean;
var
  fileHandle: THandle;
  fileLengthLo: DWORD;
  fileLengthHi: DWORD;
  numPasses: integer;
  i: integer;
  blankingBytes: TShredBlock;
  bytesWritten: DWORD;
  fileDateStamps: integer;
  fileAttributes : integer;
  slackSize: DWORD;
  writeFailed: boolean;
  bpc: DWORD;
  bpcMod: DWORD;
begin
  // Record any file attributes and remove any hidden, system or readonly file
  // attribs in order to put them back later
{$IFDEF MSWINDOWS}
{$WARN SYMBOL_PLATFORM OFF}  // Useless warning about platform - we're already
                             // protecting against that!
  fileAttributes := FileGetAttr(filename);
  // If got attributes OK, continue...
  result := (fileAttributes <> -1);
  if (fileAttributes <> -1) then
{$WARN SYMBOL_PLATFORM ON}
{$ENDIF}
{$IFDEF LINUX}
   xxx - to be implemented: get all file attributes
{$ENDIF}
    begin
{$IFDEF MSWINDOWS}
{$WARN SYMBOL_PLATFORM OFF}  // Useless warning about platform - we're already
                             // protecting against that!
    if (FileSetAttr(filename, faArchive) = 0) then
{$WARN SYMBOL_PLATFORM ON}
{$ENDIF}
{$IFDEF LINUX}
   xxx - to be implemented: set file attributes to ensure that we can
{$ENDIF}
      begin
      fileHandle := CreateFile(PChar(filename),
                               GENERIC_READ or GENERIC_WRITE,
                               0,
                               nil,
                               OPEN_EXISTING,
                               FILE_ATTRIBUTE_NORMAL or FILE_FLAG_WRITE_THROUGH,
                               0);
      if (fileHandle<>INVALID_HANDLE_VALUE) then        begin
        // Get the date/timestamps before we start changing the file...
        fileDateStamps := FileGetDate(fileHandle);

        fileLengthLo := GetFileSize(fileHandle, @fileLengthHi);
        // Check that the GetFileSize call was successful...
        if not( (fileLengthLo = $FFFFFFFF) AND (GetLastError()<>NO_ERROR) ) then
          begin
          bpc := BytesPerCluster(filename);
          // If the bytes per sector was reported as "1", as assume that it
          // couldn't be determined, and assume a much larger sector size
          if (bpc=1) then            begin
            bpc := (128 * BYTES_IN_KILOBYTE);  // 128K - In practice, it's likely to be much less than this
            end;

          // Reserve block for random garbage
          SetLength(blankingBytes, bpc);

          // Determine the amount of slack space beyond the file to fill the
          // sector
          // Note: This makes the reasonable assumption that ($FFFFFFFF + 1)
          //       will always be a multiple of "bpc"; so we don't need to
          //       bother involving the high DWORD of the file's size in this
          //       calculation
          slackSize := 0;
          bpcMod := (fileLengthLo mod bpc);
          if (bpcMod>0) then            begin
            slackSize := (bpc - bpcMod);
            end;

          // Determine the number of passes...
          numPasses := TShredMethodPasses[IntMethod];
          if (numPasses < 0) then            begin
            numPasses := FIntPasses;
            end;

          // ...and finally, perform the slack space wipe
          writeFailed := FALSE;
          for i:=1 to numPasses do            begin
            // Fill a block with random garbage
            if not(GetOverwriteDataBlock(i, blankingBytes)) then              begin
              writeFailed := TRUE;
              break;
              end;

            // Set the file pointer to the end of the file
            SetFilePointer(fileHandle, fileLengthLo, @fileLengthHi, FILE_BEGIN);

            // Write from there, pass data (e.g. a block of pseudorandom data)
            WriteFile(fileHandle, blankingBytes[0], slackSize, bytesWritten, nil);
            if (bytesWritten<>slackSize) then              begin
              writeFailed := TRUE;
              break;
              end;

            // Ensure that the buffer is flushed to disk (even through disk caching
            // software) [from Borland FAQ]
// xxx - this line commented out - prevents process from exiting?! It remains
//       visible in task manager, and can't be killed?!
//            FlushFileBuffers(fileHandle);
            end; // for each pass

          // Truncate the file back down to the correct length
          SetFilePointer(fileHandle, fileLengthLo, @fileLengthHi, FILE_BEGIN);
          SetEndOfFile(fileHandle);

          result := not(writeFailed);
          end;


        // Reset the date/timestamps
{$WARN SYMBOL_PLATFORM OFF} // Don't care that this is platform specific - if anyone needs this under Kylix, let me know though!
        FileSetDate(fileHandle, fileDateStamps);
{$WARN SYMBOL_PLATFORM ON}

        // Flush and close
// xxx - this line commented out - prevents process from exiting?! It remains
//       visible in task manager, and can't be killed?!
//        FlushFileBuffers(fileHandle);
        CloseHandle(fileHandle);

        end;  // if (fileHandle<>INVALID_HANDLE_VALUE) then

      // Reset the file attributes
{$IFDEF MSWINDOWS}
{$WARN SYMBOL_PLATFORM OFF}  // Useless warning about platform - we're already
                             // protecting against that!
      FileSetAttr(filename, fileAttributes);
{$WARN SYMBOL_PLATFORM ON}
{$ENDIF}
{$IFDEF LINUX}
   xxx - to be implemented: reset file attributes to those stored previously
{$ENDIF}
      end;  // if (FileSetAttr(filename, faArchive) = 0) then

    end;  // if (fileAttributes <> -1) then


end;


// Perform dir shredding, using the method specified in the INI file
// filename - the file to be destroyed
function TShredder.ShredDir(dirname: string; silent: boolean): TShredResult;
var
  dirToDestroy: string;
  shredderCommandLine: Ansistring;
  fileIterator: TSDUFileIterator;
  dirIterator: TSDUDirIterator;
  currFile: string;
  currDir: string;
begin
  result := srSuccess;

  if (not(FFileDirUseInt))         AND
     (not(FExtShredFilesThenDir))  AND
     (FExtDirExe<>'')              then
    begin
    // i.e. we using an external shredder which doesn't need all files to be
    // removed before it can be used
    dirname := SDUConvertLFNToSFN(dirname);
    shredderCommandLine := format(FExtDirExe, [dirname]);{ TODO 1 -otdk -cinvestigate : what happens if unicode dirname? }
    winexec(PAnsiChar(shredderCommandLine), SW_MINIMIZE);
    end
  else
    begin
    // Shred all files in the current directory
    fileIterator := TSDUFileIterator.Create(nil);
    try
      fileIterator.Directory := dirname;
      fileIterator.RecurseSubDirs := TRUE;
      fileIterator.IncludeDirNames := FALSE;
      fileIterator.OmitStartDirPrefix := FALSE;
      fileIterator.Reset();

      currFile := fileIterator.Next();
      while (currFile<>'') do
        begin
        result := DestroyFileOrDir(
                                   currFile,
                                   FALSE,
                                   silent
                                  );

        if (result <> srSuccess) then
          begin
          break;
          end;

        currFile := fileIterator.Next();
        end;
    finally
      fileIterator.Free();
    end;

    if (result = srSuccess) then      begin
      dirIterator := TSDUDirIterator.Create(nil);
      try
        dirIterator.Directory := dirName;
        dirIterator.ReverseFormat := TRUE;
        dirIterator.IncludeStartDir := TRUE;
        dirIterator.Reset();

        // Now do the dir structure
        currDir := dirIterator.Next();
        while currDir<>'' do          begin
          // And finally, remove the current dir...
          //   if external shredder handles dirs, use it
          //   else pass the dirname to the internal shredder for shredding
          if (not(FFileDirUseInt)) AND
             (FExtDirExe<>'')      then
            begin
            // i.e. we using an external shredder which doesn't need all files to be
            // removed before it can be used
            dirToDestroy := SDUConvertLFNToSFN(currDir);
            shredderCommandLine := format(FExtDirExe, [dirToDestroy]);  { TODO 1 -otdk -cinvestigate : what happens if unicode filename? }
            WinExec(PAnsiChar(shredderCommandLine), SW_MINIMIZE);
            end
          else
            begin
            // Fallback to simply removing the dir using internal method
            result := DeleteFileOrDir(currDir);
            end;

          currDir := dirIterator.Next();
          end;
      finally
        dirIterator.Free();
      end;

      end;

    end; // External shredder not being used/needs files deleted first
end;

procedure TShredder.DestroyRegKey(key: string);
var
  registry: TRegistry;
  NTsubkeys: TStrings;
  keyValues: TStrings;
  valueInfo: TRegDataInfo;
  rootStr: string;
  i: integer;
  j: integer;
  buffer: array of byte;
begin
  registry := TRegistry.create();
  try
    registry.LazyWrite := FALSE;

    if Pos('HKCR\', key)=1 then      begin
      registry.RootKey := HKEY_CLASSES_ROOT;
      end
    else if Pos('HKCU\', key)=1 then      begin
      registry.RootKey := HKEY_CURRENT_USER;
      end
    else if Pos('HKLM\', key)=1 then      begin
      registry.RootKey := HKEY_LOCAL_MACHINE;
      end
    else if ( (Pos('HKU \', key)=1) or (Pos('HKU\', key)=1) ) then      begin
      registry.RootKey := HKEY_USERS;
      end
    else if Pos('HKCC\', key)=1 then      begin
      registry.RootKey := HKEY_CURRENT_CONFIG;
      end
    else if Pos('HKDD\', key)=1 then      begin
      registry.RootKey := HKEY_DYN_DATA;
      end;

    rootStr := Copy(key, 1, 5);
    Delete(key, 1, 5);

    if (Win32Platform=VER_PLATFORM_WIN32_NT) then      begin
      NTsubkeys:=TStringList.Create();
      try
        if registry.OpenKey(key, FALSE) then          begin
          if registry.HasSubkeys() then            begin
            registry.GetKeyNames(NTsubkeys);
            end;

          keyValues := TStringList.Create();
          try
            registry.GetValueNames(keyValues);
            for i:=0 to (keyValues.count-1) do              begin
              registry.GetDataInfo(keyValues[i], valueInfo);
              case valueInfo.RegData of
              rdString:
                begin
                registry.WriteString(keyValues[i],
                                      Format('%-'+inttostr(valueInfo.DataSize-1)+'.'+inttostr(valueInfo.DataSize-1)+'s', ['']));
                end;

              rdExpandString:
                begin
                registry.WriteExpandString(keyValues[i],
                                      Format('%-'+inttostr(valueInfo.DataSize-1)+'.'+inttostr(valueInfo.DataSize-1)+'s', ['']));
                end;

              rdInteger:
                begin
                registry.WriteInteger(keyValues[i], 0);
                end;

              rdBinary:
                begin
                setlength(buffer, valueInfo.DataSize);
                for j:=0 to (valueInfo.DataSize-1) do                  begin
                  buffer[j] := $FF;
                  end;
                registry.WriteBinaryData(keyValues[i],
                                         buffer[0],
                                         valueInfo.DataSize);
                end;

              rdUnknown:
                begin
                // Nada - don't know how to overwrite!
                end;

              else
                begin
                // Nada - don't know how to overwrite!
                end;

              end;
              end;

          finally
            keyValues.Free();
          end;

          registry.CloseKey();

          for i:=0 to (NTsubkeys.count-1) do            begin
            DestroyRegKey(rootStr+'\'+NTsubkeys[i]);
            end;
          end;
      finally
        NTsubkeys.Free();
      end;
      end;

    registry.DeleteKey(key);
  finally
    registry.Free();
  end;

end;

procedure TShredder.CheckProgressCancel;
begin
  if (fProgressDlg <> nil) then    begin
    if fProgressDlg.Cancel then      begin
      raise EShredderErrorUserCancel.Create(USER_CANCELLED);
    end;
  end;
end;

procedure TShredder.DoCheckForUserCancel();
var
  eventUserCancel: Boolean  ;
begin
  if assigned(FOnCheckForUserCancel) then  begin
    FOnCheckForUserCancel(self, eventUserCancel);
    if eventUserCancel then    begin
      raise EShredderErrorUserCancel.Create(USER_CANCELLED);
    end;
  end;
end;

// Generate a random filename of the same length as the one supplied, but
// preserving the last "." in the filename
// Give it 5 tries to find a filename that doesn't already exist, if we don't
// find one, just return ''
function TShredder.GenerateRndDotFilename(path: string; origFilename: string): string;
var
  i: integer;
  fndLastDot: boolean;
  finished: boolean;
  count: integer;
begin
  count := 0;
  finished:= FALSE;
  while not(finished) do    begin
    fndLastDot := FALSE;
    for i:=length(origFilename) downto 1 do      begin
      if fndLastDot then        begin
{$WARNINGS OFF}  // Disable useless warning
        origFilename[i] := char(ord('A')+random(26));
{$WARNINGS ON}
        end      else        begin
        if origFilename[i]='.' then          begin
          fndLastDot := TRUE;
          end        else          begin
{$WARNINGS OFF}  // Disable useless warning
          origFilename[i] := char(ord('A')+random(26));
{$WARNINGS ON}
          end;
        end;
      end; // for i:=length(origFilename) downto 1 do

    finished := not(FileExists(path+origFilename));
    if not(finished) then      begin
      inc(count);
      if count=5 then        begin
        origFilename := '';
        end;
      end;
    end; // while not(finished) do

  Result := origFilename;

end;

function TShredder.CountFiles(dirName: string): integer;
var
  fileIterator: TSDUFileIterator;
  cnt: integer;
begin
  fileIterator:= TSDUFileIterator.Create(nil);
  try
    fileIterator.Directory := dirName;
    fileIterator.RecurseSubDirs := TRUE;
    fileIterator.IncludeDirNames := FALSE;
    fileIterator.Reset();

    cnt := fileIterator.Count();

  finally
    fileIterator.Free();
  end;

  Result := cnt;

end;


function OverwriteVolWithChaff(drive: DriveLetterChar ;overwriteWithChaff  : Boolean;chaffCypherUseKeyLength: Integer  (* In *bits* *);
BlockSize: Integer;CypherDriver: Ansistring;CypherGUID: TGUID;Offset: ULONGLONG;
VolFilename: String): TShredResult;
var
  shredder: TShredder;

  //  partInfo:TPartitionInformationEx;
  chaffCypherKey: TSDUBytes;
  len: Integer;
  IsPartition: Boolean;
begin
  IsPartition := IsPartitionPath(VolFilename);
  shredder := TShredder.Create();
  try
    shredder.FileDirUseInt := True;
    if overwriteWithChaff then begin
      // Initilize zeroed IV for encryption
      //    ftempCypherEncBlockNo := 0;

      // Get *real* random data for encryption key
        len := (chaffCypherUseKeyLength div 8);
      { DONE 2 -otdk -crefactor : use randpool object that asserts if data isnt available - for now check not empty }
      GetRandPool().GetRandomData(len, chaffCypherKey);

//      chaffCypherKey                    := getRandomData_ChaffKey();
      shredder.IntMethod                := smPseudorandom;
      // Note: Setting this event overrides shredder.IntMethod
      shredder.OnTweakEncryptDataEvent  := GetFreeOTFEBase().EncryptSectorData;
      shredder.WipeCypherBlockSize := BlockSize;
      shredder.WipeCypherKey            := chaffCypherKey;
      shredder.wipeCypherDriver         := CypherDriver;
      shredder.WipeCypherGUID           := CypherGUID;
    end else begin
      shredder.IntMethod := smZeros;
    end;

    shredder.IntPasses        := 1;
    shredder.IntSegmentOffset := Offset;
    // cdb is written after so can overwrite. if hidden dont overwrite main data
    // will be 0 for non hidden vols

    //      shredder.IntSegmentLength := todo; ignored as quickshred = false


    { done 2 -otdk -ctest : this has not been tested for devices }
    if IsPartition then begin
      //       partInfo := fmeselectpartition.SDUDiskPartitionsPanel1.PartitionInfo[fmeselectpartition.SDUDiskPartitionsPanel1.Selected];
      { TODO 2 -otdk -cfix : this doesnt work for partitions - need mounted drive filename }
      // think need to use WriteRawVolumeData - as otherwise cant get low level access to drive.
      // for now create vol first then shred opened volume (slower)
      //        overwriteOK := shredder.DestroyPart(GetVolFilename(), False, False);
      assert(drive <> #0);
      result := shredder.WipeDriveFreeSpace(drive);

    end else begin
      result := shredder.DestroyFileOrDir(VolFilename,
                 { TODO 1 -otdk -ccheck : check use of quickshred here }
        False,   // quickShred - do all
        False,   // silent
        True     // leaveFile
        );
    end;





  finally
    shredder.Free();
  end;


end;//


END.


