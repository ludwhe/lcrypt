unit frmSelectPartition;
// Description: 
// By Sarah Dean
// Email: sdean12@sdean12.org
// WWW:   http://www.SDean12.org/
//
// -----------------------------------------------------------------------------
//


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,
  OTFEFreeOTFEBase_U, fmeSelectPartition, ExtCtrls, SDUForms;

type
  TfrmSelectPartition = class(TSDUForm)
    Label1: TLabel;
    pnlButtonCenter: TPanel;
    pbOK: TButton;
    pbCancel: TButton;
    fmeSelectPartition1: TfmeSelectPartition;
    procedure FormShow(Sender: TObject);
    procedure pbOKClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure fmeSelectPartitionSDUDiskPartitionsPanel1DblClick(
      Sender: TObject);
    procedure fmeSelectPartitionpnlNoPartitionDisplayDblClick(
      Sender: TObject);
  private
    procedure EnableDisableControls();

    function GetPartition(): string;

    procedure fmeSelectPartitionChanged(Sender: TObject);
  public

  published
    property Partition: string read GetPartition;

  end;


// Display dialog to allow user to select a partition
// Returns '' if the user cancels/on error, otherwise returns a partition
// identifier
function SelectPartition(): String;

implementation

{$R *.DFM}

uses
  SDUGeneral,
  SDUDialogs;
	

procedure TfrmSelectPartition.FormCreate(Sender: TObject);
begin
//  SDUClearPanel(pnlButtonCenter);
end;

procedure TfrmSelectPartition.FormResize(Sender: TObject);
begin
//  SDUCenterControl(pnlButtonCenter, ccHorizontal);
end;

procedure TfrmSelectPartition.FormShow(Sender: TObject);
begin
  fmeSelectPartition1.AllowCDROM := TRUE;
  fmeSelectPartition1.OnChange := fmeSelectPartitionChanged;
  fmeSelectPartition1.Initialize();
  EnableDisableControls();
end;

procedure TfrmSelectPartition.pbOKClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;


procedure TfrmSelectPartition.EnableDisableControls();
begin
  pbOK.Enabled := (Partition <> '');
end;


function TfrmSelectPartition.GetPartition(): string;
begin
  Result := fmeSelectPartition1.SelectedDevice;
end;

procedure TfrmSelectPartition.fmeSelectPartitionChanged(Sender: TObject);
begin
  EnableDisableControls();
end;

procedure TfrmSelectPartition.fmeSelectPartitionSDUDiskPartitionsPanel1DblClick(
  Sender: TObject);
begin
  pbOKClick(Sender);
end;

procedure TfrmSelectPartition.fmeSelectPartitionpnlNoPartitionDisplayDblClick(
  Sender: TObject);
begin
  pbOKClick(Sender);
end;


 // ----------------------------------------------------------------------------
 // Display dialog to allow user to select a partition
 // Returns '' if the user cancels/on error, otherwise returns a partition
 // identifier
function SelectPartition(): String;
var
  dlg: TfrmSelectPartition;
begin
  Result := '';

  dlg := TfrmSelectPartition.Create(nil);
  try
    if (dlg.ShowModal() = mrOk) then
      Result := dlg.Partition;
  finally
    dlg.Free();
  end;
end;

END.


