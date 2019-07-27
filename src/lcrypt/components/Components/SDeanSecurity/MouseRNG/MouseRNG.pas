unit MouseRNG;
 // Description: MouseRNG Component
 // By Sarah Dean
 // Email: sdean12@sdean12.org
 // WWW:   http://www.SDean12.org/
 //
 // -----------------------------------------------------------------------------
 //

 { TODO -otdk -crefactor : dont use separate control - get mouse movements from all forms. split into two first engine/component }

interface

uses
  Classes, Controls, Dialogs,
  extctrls, Forms, Graphics, Messages, SysUtils, Windows;

const
  // The distance the cursor has to be moved in either the X or Y direction
  // before the new mouse co-ordinates are taken as another "sample"
  // DANGER - If this is set too high, then as the mouse moves, samples will
  //          be the mouse cursor co-ordinates may end up only incrementing my
  //          "MIN_DIFF" each time a sample is taken
  // DANGER - If this is set to 1, then with some mice, the mouse pointer moves
  //          "on it's own" when left alone, and the mouse pointer may
  //          oscillate between two adjacent pixels
  // Set this value to 2 to reduce the risk of this happening
  MIN_DIFF = 2;

  // This specifies the time interval (in ms) between taking samples of the
  // mouse's position
  TIMER_INTERVAL = 100;

  // The different border styles available
  BorderStyles: array [TBorderStyle] of DWORD = (0, WS_BORDER);


type

  // Callback for random data generated
  TDEBUGSampleTakenEvent = procedure(Sender: TObject; X, Y: Integer) of object;

  TBitGeneratedEvent = procedure(Sender: TObject; random: Byte) of object;
  TByteGeneratedEvent = procedure(Sender: TObject; random: Byte) of object;


  // This is used to form the linked list of points for displayed lines
  PPointList = ^TPointList;

  TPointList = packed record
    Point: TPoint;
    Prev:  PPointList;
    Next:  PPointList;
  end;

  TControlFriend = class(TControl);

  {gathers data = pass in form or component}
   TMouseRNGEngine = class (TObject)
   private
    fSavedMouseMoveEvent: TMouseMoveEvent;



   public

    procedure DoMouseMove(Sender: TObject; Shift: TShiftState;
    X, Y: Integer);//  TMouseMoveEvent
     constructor Create;
    procedure RegisterControlForMouseCapture(actrl:TControl);
     procedure DeRegisterControlForMouseCapture(actrl: TControl);
    end;

  TMouseRNG = class (TCustomControl)
  private
    // This stores the random data as it is generated
    frandomByte:     Byte;
    // This stores the number of random bits in RandomByte
    frandomByteBits: Integer;

    // Storage for when the mouse move event is triggered
    flastMouseX: Integer;
    flastMouseY: Integer;


    // The linked list of points on the canvas
    fpointCount:    Cardinal;
    fLinesListHead: PPointList;
    fLinesListTail: PPointList;


    // Style information
    FBorderStyle: TBorderStyle;
    FTrailLines:  Cardinal;
    FLineWidth:   Cardinal;
    FLineColor:   TColor;


    // Callbacks
    FOnDEBUGSampleTaken: TDEBUGSampleTakenEvent;

    FOnBitGenerated:  TBitGeneratedEvent;
    FOnByteGenerated: TByteGeneratedEvent;

  protected
    procedure CreateParams(var Params: TCreateParams); override;

    procedure TimerFired(Sender: TObject);

    procedure SetEnabled(Value: Boolean); override;
    procedure SetBorderStyle(Style: TBorderStyle);

    procedure SetLineWidth(Width: Cardinal);
    procedure SetLineColor(color: TColor);

    // Linked list of points on the canvas handling
    procedure StoreNewPoint(X, Y: Integer);
    procedure RemoveLastPoint();

    // When new mouse cursor co-ordinates are taken 
    procedure ProcessSample(X, Y: Integer);

  public
    fTimer: TTimer;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Repaint(); override;
    procedure Paint(); override;
    function CanResize(var NewWidth, NewHeight: Integer): Boolean; override;


    // Clear display and internal RNG state
    procedure Clear();

    // Clear display only
    procedure ClearDisplay();

  published
    // The number of lines shown
    // Set to 0 to prevent lines from being displayed
    property TrailLines: Cardinal Read FTrailLines Write FTrailLines;
    property LineWidth: Cardinal Read FLineWidth Write SetLineWidth;
    property LineColor: TColor Read FLineColor Write SetLineColor;

    property Align;
    property Anchors;

    property BorderStyle: TBorderStyle Read FBorderStyle Write SetBorderStyle default bsSingle;

    // N/A    property Caption;
    property Color;
    property Constraints;
    property Ctl3D;
    property UseDockManager default True;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ParentColor;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDockDrop;
    property OnDockOver;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;


    property OnDEBUGSampleTakenEvent: TDEBUGSampleTakenEvent
      Read FOnDEBUGSampleTaken Write FOnDEBUGSampleTaken;
    // Note: You can receive callbacks when each bit is generated, or when
    //       every 8 bits. Note that the random data supplied by
    //       FOnByteGenerated is the same as the supplied by FOnBitGenerated,
    //       it's only buffered and delivered in blocks of 8 bits
    property OnBitGenerated: TBitGeneratedEvent Read FOnBitGenerated Write FOnBitGenerated;
    property OnByteGenerated: TByteGeneratedEvent Read FOnByteGenerated Write FOnByteGenerated;

  end;



procedure Register;

implementation

const

  // This specifies how many of the least significant bits from the X & Y
  // co-ordinates will be used as random data.
  // If this is set too high, then
  // If this is set too low, then the user has to move the mouse a greater
  // distance between samples, otherwise the higher bits in the sample won't
  // change.
  // A setting of 1 will use the LSB of the mouse's X, Y co-ordinates
  BITS_PER_SAMPLE = 1;


procedure Register;
begin
  RegisterComponents('SDeanSecurity', [TMouseRNG]);
end;


constructor TMouseRNG.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Color       := clWindow;
  TabStop     := False;
  ParentColor := False;
  BorderStyle := bsSingle;
  TrailLines  := 5;

  LineWidth := 5;
  LineColor := clNavy;


  fTimer          := TTimer.Create(self);
  fTimer.Enabled  := False;
  fTimer.Interval := TIMER_INTERVAL;
  fTimer.OnTimer  := TimerFired;

  fLinesListHead := nil;
  fLinesListTail := nil;
  fpointCount    := 0;


  // Initially, there are no mouse co-ordinates taken
  flastMouseX := -1;
  flastMouseY := -1;

  // Cleardown the random bytes store
  frandomByte     := 0;
  frandomByteBits := 0;


  // Setup the inital size of the component
  // 128 is chosen for this, as it's likely that the BITS_PER_SAMPLE rules
  // will suit it, even for large values of BITS_PER_SAMPLE (like 4 or 5)
  SetBounds(Left, Top, 128, 128);

  Enabled := False;
end;

destructor TMouseRNG.Destroy();
begin
  fTimer.Enabled := False;
  fTimer.Free();

  Enabled := False;
  // Cleardown any points, overwriting them as we do so
  while (fpointCount > 0) do begin
    RemoveLastPoint();
  end;

  inherited Destroy();
end;

procedure TMouseRNG.TimerFired(Sender: TObject);
var
  changed: Boolean;
begin
  changed := False;

  // Handle the situation in which no mouse co-ordinates have yet been taken
  if (flastMouseX > -1) and (flastMouseY > -1) then begin
    // If there are no points, we have a new one
    if (fpointCount = 0) then begin
      changed := True;
    end else begin
      // If the mouse cursor has moved a significant difference, use the new
      // co-ordinates
      // Both the X *and* Y mouse co-ordinates must have changed, to prevent
      // the user from generating non-random data by simply moving the mouse in
      // just a horizontal (or vertical) motion, in which case the X (or Y)
      // position would change, but the Y (or X) position would remain
      // relativly the same. This would only generate 1/2 as much random data
      // The effects of the following code are trivial to see; simply waggle
      // the mouse back and forth horizontally; instead of seeing a new dark
      // line appearing (indicating that the sample has been taken), the
      // inverse coloured line appears, indicating the mouse pointer
      if ((flastMouseX > (fLinesListHead.Point.X + MIN_DIFF)) or
        (flastMouseX < (fLinesListHead.Point.X - MIN_DIFF)) and (flastMouseY >
        (fLinesListHead.Point.Y + MIN_DIFF)) or (flastMouseY < (fLinesListHead.Point.Y - MIN_DIFF)))
      then begin
        changed := True;
      end;

    end;

  end;


  if (not (changed)) then begin
    // User hasn't moved cursor - delete oldest line until we catch up with
    // the cursor
    if ((fLinesListTail <> fLinesListHead) and (fLinesListTail <> nil)) then begin
      Canvas.Pen.Mode := pmMergeNotPen;
      Canvas.MoveTo(fLinesListTail.Point.X, fLinesListTail.Point.Y);
      Canvas.LineTo(fLinesListTail.Next.Point.X, fLinesListTail.Next.Point.Y);
      RemoveLastPoint();
    end;

  end else begin
    // AT THIS POINT, WE USE LastMouseX AND LastMouseY AS THE CO-ORDS TO USE


    // Store the position
    StoreNewPoint(flastMouseX, flastMouseY);

    // User moved cursor - don't delete any more lines unless the max number
    // of lines which may be displayed is exceeded
    if ((fpointCount + 1 > TrailLines) and (fpointCount > 1)) then begin
      Canvas.Pen.Mode := pmMergeNotPen;
      Canvas.MoveTo(fLinesListTail.Point.X, fLinesListTail.Point.Y);
      Canvas.LineTo(fLinesListTail.Next.Point.X, fLinesListTail.Next.Point.Y);
      RemoveLastPoint();
    end;


    // Draw newest line
    if (TrailLines > 0) and (fpointCount > 1) then begin
      Canvas.Pen.Mode := pmCopy;
      Canvas.MoveTo(fLinesListHead.Prev.Point.X, fLinesListHead.Prev.Point.Y);
      Canvas.LineTo(fLinesListHead.Point.X, fLinesListHead.Point.Y);
    end;


    ProcessSample(flastMouseX, flastMouseY);
  end;

end;


procedure TMouseRNG.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);

  if (TrailLines > 0) and (fpointCount >= 1) then begin
    Canvas.Pen.Mode := pmXor;
    Canvas.MoveTo(fLinesListHead.Point.X, fLinesListHead.Point.Y);
    Canvas.LineTo(flastMouseX, flastMouseY);
  end;

  flastMouseX := X;
  flastMouseY := Y;

  if (TrailLines > 0) and (fpointCount >= 1) then begin
    Canvas.Pen.Mode := pmXor;
    Canvas.MoveTo(fLinesListHead.Point.X, fLinesListHead.Point.Y);
    Canvas.LineTo(flastMouseX, flastMouseY);
  end;

end;

procedure TMouseRNG.SetEnabled(Value: Boolean);
var
  oldEnabled: Boolean;
begin
  oldEnabled := Enabled;

  inherited SetEnabled(Value);

  fTimer.Enabled := Value;

  // Only clear the display on an enabled->disabled, or disabled->enabled
  // change.
  // (i.e. If this is called with TRUE, when it's already enabled, do not
  // clear the display)

  if (oldEnabled <> Value) then begin
    ClearDisplay();
  end;

end;



procedure TMouseRNG.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (FBorderStyle = bsSingle) then begin
    Params.Style := Params.Style or WS_BORDER;
  end else begin
    Params.Style := Params.Style and not (WS_BORDER);
  end;

end;

procedure TMouseRNG.SetBorderStyle(Style: TBorderStyle);
begin
  if (Style <> FBorderStyle) then begin
    FBorderStyle := Style;
    { Create new window handle for the control. }
    RecreateWnd;
  end;

end;

procedure TMouseRNG.Clear();
begin
  ClearDisplay();

  // Clear internal RNG state
  frandomByte     := 0;
  frandomByteBits := 0;

end;

procedure TMouseRNG.ClearDisplay();
begin
  // Clear any lines on the display
  // We surround the Canvas blanking with "parent<>nil" to avoid getting
  // "Control '' has no parent window" errors when the component is dropped
  // onto a form
  if (parent <> nil) then begin
    Canvas.Brush.Color := Color;
    Canvas.FillRect(Rect(0, 0, Width, Height));
  end;


  // Because the display's been cleared, the chase position can be set to the
  // current position
  // Delete all lines
  if (fLinesListHead <> nil) then begin
    while (fLinesListTail <> fLinesListHead) do begin
      RemoveLastPoint();
    end;
  end;

end;

 // Repaint? No, we just clear the display
 // This is done so that if the user switches task, then switches back again
 // all trails are gone
procedure TMouseRNG.Repaint();
begin
  inherited Repaint();
  ClearDisplay();

end;

// Paint? No, same as Repaint()
procedure TMouseRNG.Paint();
begin
  inherited Paint();
  ClearDisplay();

end;


// Remove the last point from the tail of the linked list of points
procedure TMouseRNG.RemoveLastPoint();
var
  tmpPoint: PPointList;
begin
  if (fLinesListTail <> nil) then begin
    tmpPoint      := fLinesListTail;
    fLinesListTail := fLinesListTail.Next;
    if (fLinesListTail <> nil) then begin
      fLinesListTail.Prev := nil;
    end;
    // Overwrite position before discarding record
    tmpPoint.Point.X := 0;
    tmpPoint.Point.Y := 0;
    Dispose(tmpPoint);
    Dec(fpointCount);
  end;

  if (fLinesListTail = nil) then begin
    fLinesListHead := nil;
  end;

end;


// Add a new last point onto the head of the linked list of points
procedure TMouseRNG.StoreNewPoint(X, Y: Integer);
var
  tmpPoint: PPointList;
begin
  tmpPoint         := new(PPointList);
  tmpPoint.Point.X := X;
  tmpPoint.Point.Y := Y;
  tmpPoint.Next    := nil;
  tmpPoint.Prev    := fLinesListHead;
  if (fLinesListHead <> nil) then begin
    fLinesListHead.Next := tmpPoint;
  end;
  fLinesListHead := tmpPoint;
  Inc(fpointCount);

  if (fLinesListTail = nil) then begin
    fLinesListTail := fLinesListHead;
  end;

end;

procedure TMouseRNG.ProcessSample(X, Y: Integer);
var
  i: Integer;
begin
  if ((Enabled) and (Assigned(FOnDEBUGSampleTaken))) then
    FOnDEBUGSampleTaken(self, X, Y);

  // This stores the random data as it is generated
  for i := 1 to BITS_PER_SAMPLE do begin
    frandomByte := frandomByte shl 1;
    frandomByte := frandomByte + (X and 1);
    Inc(frandomByteBits);

    if ((Enabled) and (Assigned(FOnBitGenerated))) then begin
      FOnBitGenerated(self, X and $01);
    end;


    frandomByte := frandomByte shl 1;
    frandomByte := frandomByte + (Y and 1);
    Inc(frandomByteBits);

    if ((Enabled) and (Assigned(FOnBitGenerated))) then
      FOnBitGenerated(self, Y and $01);

    X := X shr 1;
    Y := Y shr 1;
  end;


  if (frandomByteBits >= 8) then begin
    if ((Enabled) and (Assigned(FOnByteGenerated))) then
      FOnByteGenerated(self, frandomByte);

    frandomByteBits := 0;
    frandomByte     := 0;
  end;
end;


procedure TMouseRNG.SetLineWidth(Width: Cardinal);
begin
  FLineWidth       := Width;
  Canvas.Pen.Width := FLineWidth;

end;

procedure TMouseRNG.SetLineColor(color: TColor);
begin
  FLineColor       := color;
  Canvas.Pen.Color := FLineColor;

end;


function TMouseRNG.CanResize(var NewWidth, NewHeight: Integer): Boolean;
var
  retVal:   Boolean;
  multiple: Integer;
  i:        Integer;
begin
  retVal := inherited CanResize(NewWidth, NewHeight);

  if (retVal) then begin
    // If a border is selected, decrement the size of the window by 2 pixels in
    // either direction, for the purposes of these calculations
    if (BorderStyle = bsSingle) then begin
      NewWidth  := NewWidth - 2;
      NewHeight := NewHeight - 2;
    end;

    multiple := 1;
    for i := 1 to BITS_PER_SAMPLE do begin
      multiple := multiple * 2;
    end;

    NewWidth  := (NewWidth div multiple) * multiple;
    NewHeight := (NewHeight div multiple) * multiple;

    // We have a minimum size that we will allow; twice the multiple
    if (NewWidth < (multiple * 2)) then begin
      NewWidth := multiple * 2;
    end;

    // We have a minimum size that we will allow; twice the multiple
    if (NewHeight < (multiple * 2)) then begin
      NewHeight := multiple * 2;
    end;

    // If a border is selected, increment the size of the window by 2 pixels in
    // either direction
    if (BorderStyle = bsSingle) then begin
      NewWidth  := NewWidth + 2;
      NewHeight := NewHeight + 2;
    end;

  end;

  Result := retVal;

end;



{ TMouseRNGEngine }

 // register controls to capture mouse move events and use for randomness
constructor TMouseRNGEngine.Create;
begin
  fSavedMouseMoveEvent := nil;
end;

procedure TMouseRNGEngine.DoMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if assigned(fSavedMouseMoveEvent) then  fSavedMouseMoveEvent(Sender,Shift,X,Y);
  // todo: process mouse event ...
end;

procedure TMouseRNGEngine.RegisterControlForMouseCapture(actrl: TControl);
begin
 assert(not assigned(fSavedMouseMoveEvent), 'only one control supported so far');
 fSavedMouseMoveEvent := TControlFriend(actrl).OnMouseMove;
 TControlFriend(actrl).OnMouseMove := DoMouseMove;
end;

procedure TMouseRNGEngine.DeRegisterControlForMouseCapture(actrl: TControl);
begin
TControlFriend(actrl).OnMouseMove := fSavedMouseMoveEvent;
 fSavedMouseMoveEvent := nil;
end;

end.
