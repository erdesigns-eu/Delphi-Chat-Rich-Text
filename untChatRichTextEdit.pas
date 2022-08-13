{*******************************************************}
{                                                       }
{                untChatRichTextEdit.pas                }
{                Author: Ernst Reidinga                 }
{                                                       }
{     TEdit like control with HTML Like formatting,     }
{     and support for Emoji's.                          }
{                                                       }
{     Note: This control is build from the ground up.   }
{     It is not based on TCustomEdit but based on       }
{     TCustomControl.                                   }
{                                                       }
{*******************************************************}

unit untChatRichTextEdit;

interface

uses
  System.Types,
  System.SysUtils,
  System.Classes,
  System.UITypes,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Clipbrd,
  Vcl.Menus,
  Vcl.Consts,
  Winapi.UxTheme,
  System.Generics.Collections,
  untEmojiList,
  untChatRichText;

const
  SpaceChar : WideChar = ' ';
  TabChar   : WideChar = Chr(9);

const
  TextStartOffset = 4;
  SelectionOffset = 3;

type
  // Reference
  TChatRichTextEdit = class;
  
  // Type of TChatRichTextChar
  TChatRichTextCharType = (
    ctCharacter,
    ctEmoji,
    ctSpace,
    ctTab
  );

  // Emoji shortcode consists of max 50 characters
  //
  // Note: Edit the length if shortcodes exceed a
  // length of 50 characters.
  TEmojiShortCode = record
    Value : array [1..50] of AnsiChar;

    procedure FromString(const S: AnsiString);
    function ToString : string;
  end;

  // Chat Rich Text Character
  TChatRichTextChar = record
    // Width of character
    CharWidth  : Integer;
    // Height of character
    CharHeight : Integer;
    // Rect of character
    CharRect   : TRect;
    // Extra data for character
    case CharType: TChatRichTextCharType of

      // Character
      ctCharacter: (
        Char      : WideChar;
        FontStyle : TFontStyles
      );

      // Emoji
      ctEmoji: (
        Emoji : TEmojiShortCode
      );

      // Space
      ctSpace: (
        //
      );

      // Tab
      ctTab: (
        //
      );
  end;

  // Create our custom string type
  TChatRichTextString = array of TChatRichTextChar;

  // Undo class
  TUndo = class
  private
    Edit        : TChatRichTextEdit;
    FCaretIndex : Integer;
    FText       : TChatRichTextString;
  public
    constructor Create(CaretIndex: Integer; Text: TChatRichTextString);

    procedure Undo;
    procedure Redo;
    procedure PerformUndo; virtual; abstract;
    procedure PerformRedo; virtual; abstract;
  
    property CaretIndex: Integer read FCaretIndex write FCaretIndex;
    property Text: TChatRichTextString read FText write FText;
  end;

  // Insert character(s) Undo
  TInsertCharUndo = class(TUndo)
    procedure PerformUndo; override;
    procedure PerformRedo; override;
  end;
  
  // Delete character(s) Undo
  TDeleteCharUndo = class(TUndo)
    procedure PerformUndo; override;
    procedure PerformRedo; override;
  end;

  // Paste Undo
  TPasteUndo = class(TUndo)
    procedure PerformUndo; override;
    procedure PerformRedo; override;
  end;

  // List with Undo items
  TUndoList = TObjectList<TUndo>;

  // Undo/Redo manager class
  TUndoRedoManager = class
  private
    FEdit     : TChatRichTextEdit;
    
    FUndoList : TUndoList;
    FRedoList : TUndoList;

    FMaxUndo : Integer;
    FMaxRedo : Integer;

    procedure SetMaxUndo(const I: Integer);
    procedure SetMaxRedo(const I: Integer);
  public
    constructor Create(const Edit: TChatRichTextEdit); virtual;
    destructor Destroy; override;

    function CanUndo : Boolean;
    function CanRedo : Boolean;

    procedure AddUndo(var Undo: TUndo);

    procedure Undo;
    procedure Redo;

    procedure Clear;

    property MaxUndo: Integer read FMaxUndo write SetMaxUndo;
    property MaxRedo: Integer read FMaxRedo write SetMaxRedo;
  end;

  // UI Language class
  TUILanguage = class(TPersistent)
  private
    FCut             : string;
    FCopy            : string;
    FPaste           : string;
    FDelete          : string;
    FSelectAll       : string;
    FUndo            : string;
    FRedo            : string;
    FBold            : string;
    FItalic          : string;
    FUnderline       : string;
    FStrikeOut       : string;
    FClearFormatting : string;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
  published
    property Cut: string read FCut write FCut;
    property Copy: string read FCopy write FCopy;
    property Paste: string read FPaste write FPaste;
    property Delete: string read FDelete write FDelete;
    property SelectAll: string read FSelectAll write FSelectAll;
    property Undo: string read FUndo write FUndo;
    property Redo: string read FRedo write FRedo;
    property Bold: string read FBold write FBold;
    property Italic: string read FItalic write FItalic;
    property Underline: string read FUnderline write FUnderline;
    property StrikeOut: string read FStrikeOut write FStrikeOut;
    property ClearFormatting: string read FClearFormatting write FClearFormatting;
  end;

  // TChatRichTextEdit control
  TChatRichTextEdit = class(TCustomControl)
  private
    // Events
    FOnChange : TNotifyEvent;
  
    // Properties
    FChatRichText   : TChatRichTextString;
    FAutoSize       : Boolean;
    FBorderStyle    : TBorderStyle;
    FEmojiList      : TEmojiList;
    FAutoSelect     : Boolean;
    FTextHint       : string;
    FSelectionColor : TColor;
    FHideSelection  : Boolean;
    FReadOnly       : Boolean;
    FUILanguage     : TUILanguage;
    FMaxLength      : Integer;

    // Used for drawing
    FScrollOffset   : Integer;
    FCaretCharIndex : Integer;
    FCaretX         : Integer;
    FCaretHeight    : Integer;
    FInitSelStart   : Integer;
    FSelStart       : Integer;
    FSelLength      : Integer;
    FMouseOver      : Boolean;
    FBuffer         : TBitmap; // Buffer to avoid flickering
    FTempBitmap     : TBitmap; // This is used only for measuring font sizes
    FUpdateRect     : TRect;
    FShowEmojiHint  : Boolean;

    // Used for text selection
    FMouseDown      : Boolean;
    FMouseDownStart : TPoint;

    // Default popupmenu - when no popupmenu is assigned
    FStdMenu        : TPopupMenu;

    // Undo / Redo manager
    FUndoManager : TUndoRedoManager;

    // Property Setters
    procedure SetText(const S: string);
    procedure SetChatRichText(const T: TChatRichTextString);
    procedure SetAutoSize(const B: Boolean);
    procedure SetBorderStyle(const S: TBorderStyle);
    procedure SetSelStart(const I: Integer);
    procedure SetSelLength(const I: Integer);
    procedure SetTextHint(const S: string);
    procedure SetSelectionColor(const C: TColor);
    procedure SetUILanguage(const L: TUILanguage);
    procedure SetMaxUndo(const I: Integer);
    procedure SetMaxRedo(const I: Integer);

    // Property Getters
    function GetText : string;
    function GetHTML : string;
    function GetMaxUndo : Integer;
    function GetMaxRedo : Integer;

    // Update size of the Edit
    procedure AdjustHeight;
    procedure UpdateHeight;

    // Set caret position
    procedure SetCaretHome;
    procedure SetCaretEnd;

    // Default popupmenu item click
    procedure OnContextMenuClick(Sender: TObject);

    // Catch changes
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
    procedure WMContextMenu(var Message: TWMContextMenu); message WM_CONTEXTMENU;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    // Get the size of Char
    function SizeOfChar(const C: TChatRichTextChar) : TSize;

    // Caret position from mouse position
    function GetCaretPosition(const X: Integer; const Y: Integer) : Integer;
     // Caret index from mouse position
    function GetCaretIndex(const X: Integer; const Y: Integer) : Integer;
    // Set caret position
    procedure SetCaretPosition(X : Integer);
    // Set caret position by character index
    procedure SetCaretCharIndex(I : Integer);
    procedure SetCaretCharIndexEx(I: Integer);

    //
    procedure UpdateCharRects;
    procedure InvalidateBuffer;
    procedure Paint; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    //
    procedure WndProc(var Message: TMessage); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure CMGotFocus(var Message: TCMGotFocus); message CM_ENTER;
    procedure CMLostFocus(var Message: TCMLostFocus); message CM_EXIT;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Conversion functions, convert HTML to TChatRichTextString
    function HTMLToChatRichTextString(const S: string) : TChatRichTextString;
    // Conversion functions, convert string to TChatRichTextString
    function WideStringToChatRichTextString(const S: WideString) : TChatRichTextString;
    function AnsiStringToChatRichTextString(const S: AnsiString) : TChatRichTextString;
    function StringToChatRichTextString(const S: string) : TChatRichTextString;
    // Conversion functions, convert TChatRichTextString to string
    function ChatRichTextStringToWideString(const S: TChatRichTextString) : WideString;
    function ChatRichTextStringToAnsiString(const S: TChatRichTextString) : AnsiString;
    function ChatRichTextStringToString(const S: TChatRichTextString) : string;
    // Conversion functions, convert TChatRichTextString to HTML
    function ChatRichTextStringToHTML(const S: TChatRichTextString) : string;

    //
    procedure AddChar(const C: TChatRichTextChar);
    procedure InsertChar(const C: TChatRichTextChar; const Index: Integer);
    procedure DeleteChar(const Index: Integer);
    procedure DeleteSelection;
    procedure Clear;
    procedure ClearSelection;
    procedure SelectAll;

    procedure SetSelectedFontStyle(const F: TFontStyles);
    procedure ToggleSelectedBold;
    procedure ToggleSelectedItalic;
    procedure ToggleSelectedUnderline;
    procedure ToggleSelectedStrikeOut;
    procedure ClearSelectedFontStyles;

    procedure CopyToClipboard;
    procedure CutToClipboard;
    procedure PasteFromClipboard;
    function CanPaste : Boolean;

    function CanUndo : Boolean;
    function CanRedo : Boolean;
    procedure Undo;
    procedure Redo;

    // Properties
    property SelStart: Integer read FSelStart write SetSelStart;
    property SelLength: Integer read FSelLength write SetSelLength;
    property Text: string read GetText write SetText;
    property HTML: string read GetHTML;
  published
    // Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;  

    // Properties
    property Align;
    property Anchors;
    property BevelEdges;
    property BevelInner;
    property BevelKind default bkNone;
    property BevelOuter;
    property BevelWidth;
    //property BiDiMode;
    //property CharCase;
    property Color default clWindow;
    property Constraints;
    property Ctl3D;
    property DoubleBuffered default False;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ImeMode;
    property ImeName;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentCtl3D;
    property ParentDoubleBuffered default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint default True;
    property TabOrder;
    property TabStop default True;
    property Touch;
    property Visible;
    //property StyleElements;
    //property StyleName;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGesture;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  
    // Properties
    property ChatRichText: TChatRichTextString read FChatRichText write SetChatRichText;
    property AutoSize: Boolean read FAutoSize write SetAutoSize default True;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property EmojiList: TEmojiList read FEmojiList write FEmojiList;
    property AutoSelect: Boolean read FAutoSelect write FAutoSelect default True;
    property TextHint: string read FTextHint write SetTextHint;
    property SelectionColor: TColor read FSelectionColor write SetSelectionColor default clHighlight;
    property HideSelection: Boolean read FHideSelection write FHideSelection default True;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default False;
    property ShowEmojiHint: Boolean read FShowEmojiHint write FShowEmojiHint default True;
    property UILanguage : TUILanguage read FUILanguage write SetUILanguage;
    property MaxLength: Integer read FMaxLength write FMaxLength default 0;
    property MaxUndo: Integer read GetMaxUndo write SetMaxUndo default 25;
    property MaxRedo: Integer read GetMaxRedo write SetMaxRedo default 25;
  end;

implementation

procedure TEmojiShortCode.FromString(const S: AnsiString);
var
  I : Integer;
begin
  FillChar(Value, Length(Value), #0);
  for I := 1 to Length(Value) do 
  if I <= Length(S) then Value[I] := S[I];
end;

function TEmojiShortCode.ToString: string;
var
  I : Integer;
begin
  Result := '';
  for I := Low(Value) to High(Value) do
  if Value[I] <> #0 then Result := Result + String(Value[I]);
end;

constructor TUndo.Create(CaretIndex: Integer; Text: TChatRichTextString);
begin
  inherited Create;
  
  FCaretIndex := CaretIndex;
  FText       := Text;
end;

procedure TUndo.Undo;
begin
  if Assigned(Edit) then
  begin
    PerformUndo;
    Edit.UpdateCharRects;
    Edit.InvalidateBuffer;
    Edit.SetCaretCharIndexEx(CaretIndex);
    if Assigned(Edit.OnChange) then Edit.OnChange(Edit);
  end;
end;

procedure TUndo.Redo;
begin
  if Assigned(Edit) then
  begin
    PerformRedo;
    Edit.UpdateCharRects;
    Edit.InvalidateBuffer;
    if CaretIndex + Length(Text) <= Length(Edit.ChatRichText) then
      Edit.SetCaretCharIndexEx(CaretIndex + Length(Text))
    else
      Edit.SetCaretCharIndex(-1);
    if Assigned(Edit.OnChange) then Edit.OnChange(Edit);
  end;
end;

procedure TInsertCharUndo.PerformUndo;
var
  I : Integer;
begin
  for I := High(Text) downto Low(Text) do
  Delete(Edit.FChatRichText, (FCaretIndex +1) - I, 1);
end;

procedure TInsertCharUndo.PerformRedo;
var
  I : Integer;
begin
  for I := Low(Text) to High(Text) do
  Insert(Text[I], Edit.FChatRichText, FCaretIndex +1);
end;

procedure TDeleteCharUndo.PerformUndo;
var
  I : Integer;
begin
  for I := Low(Text) to High(Text) do
  Insert(Text[I], Edit.FChatRichText, FCaretIndex +1);
end;

procedure TDeleteCharUndo.PerformRedo;
var
  I : Integer;
begin
  for I := High(Text) downto Low(Text) do
  Delete(Edit.FChatRichText, (FCaretIndex - Length(Text)) + I +1, 1);
end;

procedure TPasteUndo.PerformUndo;
var
  I : Integer;
begin
  for I := High(Text) downto Low(Text) do
  Delete(Edit.FChatRichText, (FCaretIndex +1), 1);
end;

procedure TPasteUndo.PerformRedo;
var
  I : Integer;
begin
  for I := Low(Text) to High(Text) do
  Insert(Text[I], Edit.FChatRichText, (CaretIndex +1) + I);
end;

constructor TUndoRedoManager.Create(const Edit: TChatRichTextEdit);
begin
  inherited Create;

  FEdit := Edit;

  FUndoList := TUndoList.Create(True);
  FRedoList := TUndoList.Create(True);

  FMaxUndo := 25;
  FMaxRedo := 25;
end;

destructor TUndoRedoManager.Destroy;
begin
  FUndoList.Clear;
  FUndoList.Free;
  FRedoList.Clear;
  FRedoList.Free;

  inherited Destroy;
end;

procedure TUndoRedoManager.SetMaxUndo(const I: Integer);
var
  D : Integer;
begin
  // 
  if (I < FUndoList.Count) then
  begin
    D := FUndoList.Count - I;
    FUndoList.DeleteRange(FundoList.Count - D, D);
  end;
  //
  FMaxUndo := I;
end;

procedure TUndoRedoManager.SetMaxRedo(const I: Integer);
var
  D : Integer;
begin
  // 
  if (I < FRedoList.Count) then
  begin
    D := FRedoList.Count - I;
    FRedoList.DeleteRange(FRedoList.Count - D, D);
  end;
  //
  FMaxRedo := I;
end;

function TUndoRedoManager.CanUndo: Boolean;
begin
  Result := FUndoList.Count > 0;
end;

function TUndoRedoManager.CanRedo: Boolean;
begin
  Result := FRedoList.Count > 0;
end;

procedure TUndoRedoManager.AddUndo(var Undo: TUndo);
begin
  // Clear redo list when we add a new undo
  FRedoList.Clear;
  // If we reached the max undo, remove last undo action
  if (FUndoList.Count >= MaxUndo) then
  begin
    FUndoList.Delete(FUndoList.Count -1);
  end;
  //
  Undo.Edit := FEdit;
  FUndoList.Insert(0, Undo);
end;

procedure TUndoRedoManager.Undo;
begin
  if CanUndo then
  begin
    // Execute
    FUndoList.Items[0].Undo;
    // Add to redo list
    FRedoList.Insert(0, FUndoList.Extract(FUndoList.Items[0]));
  end;
end;

procedure TUndoRedoManager.Redo;
begin
  if CanRedo then
  begin
    // Execute
    FRedoList.Items[0].Redo;
    // Add to redo list
    FUndoList.Insert(0, FRedoList.Extract(FRedoList.Items[0]));
  end;
end;

procedure TUndoRedoManager.Clear;
begin
  FUndoList.Clear;
  FRedoList.Clear;
end;

constructor TUILanguage.Create;
begin
  inherited Create;

  FCut             := 'Cut';
  FCopy            := 'Copy';
  FPaste           := 'Paste';
  FDelete          := 'Delete';
  FSelectAll       := 'Select All';
  FUndo            := 'Undo';
  FRedo            := 'Redo';
  FBold            := 'Bold';
  FItalic          := 'Italic';
  FUnderline       := 'Underline';
  FStrikeOut       := 'StrikeOut';
  FClearFormatting := 'Clear Formatting';
end;

procedure TUILanguage.Assign(Source: TPersistent);
begin
  if Source is TUILanguage then
  begin
    FCut             := (Source as TUILanguage).Cut;
    FCopy            := (Source as TUILanguage).Copy;
    FPaste           := (Source as TUILanguage).Paste;
    FDelete          := (Source as TUILanguage).Delete;
    FSelectAll       := (Source as TUILanguage).SelectAll;
    FUndo            := (Source as TUILanguage).Undo;
    FRedo            := (Source as TUILanguage).Redo;
    FBold            := (Source as TUILanguage).Bold;
    FItalic          := (Source as TUILanguage).Italic;
    FUnderline       := (Source as TUILanguage).Underline;
    FStrikeOut       := (Source as TUILanguage).StrikeOut;
    FClearFormatting := (Source as TUILanguage).ClearFormatting;
  end;
end;

constructor TChatRichTextEdit.Create(AOwner: TComponent);
const
  EditStyle = [
    csCaptureMouse,
    csClickEvents,
    csDoubleClicks,
    csFixedHeight,
    csReplicatable];
begin
  // Create
  inherited Create(AOwner);

  // Control Style
  if NewStyleControls then ControlStyle := EditStyle else ControlStyle := EditStyle + [csFramed];

  // Default width/height are the same as TEdit
  Width  := 121;
  Height := 21;

  // Default Settings
  FAutoSize    := True;
  FBorderStyle := bsSingle;

  // Default Settings
  ParentColor          := False;
  Color                := clWindow;
  ParentDoubleBuffered := False;
  DoubleBuffered       := False;
  TabStop              := True;
  FMaxLength           := 0;

  // Create temp bitmap for measuring char size
  FTempBitmap := TBitmap.Create(1, 1);
  // Buffer to avoid flickering
  FBuffer := TBitmap.Create;

  // Initial Caret Position
  FCaretCharIndex := -1;
  // Initial Caret Height
  with FTempBitmap.Canvas do
  begin
    Font.Assign(Self.Font);
    FCaretHeight := TextHeight('A');
  end;

  // Undo / Redo manager
  FUndoManager := TUndoRedoManager.Create(Self);

  // Selection
  FInitSelStart   := -1;
  FSelStart       := -1;
  FSelLength      := 0;
  FSelectionColor := clHighlight;
  FHideSelection  := True;

  // Autoselect
  FAutoSelect := True;

  // Emoji Hint
  ShowHint       := True;
  FShowEmojiHint := True;

  // UI Language for contextmenu
  FUILanguage := TUILanguage.Create;
end;

destructor TChatRichTextEdit.Destroy;
begin
  // Free temp bitmap
  FTempBitmap.Free;
  // Free Buffer
  FBuffer.Free;
  // Free UI Language
  FUILanguage.Free;
  // Free undo/redo manager
  FUndoManager.Free;

  // Free
  inherited Destroy;
end;

procedure TChatRichTextEdit.SetText(const S: string);
begin
  SetChatRichText(StringToChatRichTextString(S));
  UpdateCharRects;
  InvalidateBuffer;
end;

procedure TChatRichTextEdit.SetChatRichText(const T: TChatRichTextString);
var
  Undo : TUndo;
begin
  Undo := TDeleteCharUndo.Create(FCaretCharIndex, FChatRichText);
  FUndoManager.AddUndo(Undo);
  Undo := TInsertCharUndo.Create(FCaretCharIndex, T);
  FUndoManager.AddUndo(Undo);
  FChatRichText := T;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TChatRichTextEdit.SetAutoSize(const B: Boolean);
begin
  if AutoSize <> B then
  begin
    FAutoSize := B;
    UpdateHeight;
  end;
end;

procedure TChatRichTextEdit.SetBorderStyle(const S: TBorderStyle);
begin
  if BorderStyle <> S then
  begin
    FBorderStyle := S;
    InvalidateBuffer;
  end;
end;

procedure TChatRichTextEdit.SetSelStart(const I: Integer);
begin
  FSelStart := I;
  InvalidateBuffer;
end;

procedure TChatRichTextEdit.SetSelLength(const I: Integer);
begin
  FSelLength := I;
  InvalidateBuffer;
end;

procedure TChatRichTextEdit.SetTextHint(const S: string);
begin
  if TextHint <> S then
  begin
    FTextHint := S;
    InvalidateBuffer;
  end;
end;

procedure TChatRichTextEdit.SetSelectionColor(const C: TColor);
begin
  if SelectionColor <> C then
  begin
    FSelectionColor := C;
    InvalidateBuffer;
  end;
end;

procedure TChatRichTextEdit.SetUILanguage(const L: TUILanguage);
begin
  FUILanguage.Assign(L);
end;

procedure TChatRichTextEdit.SetMaxUndo(const I: Integer);
begin
  FUndoManager.MaxUndo := I;
end;

procedure TChatRichTextEdit.SetMaxRedo(const I: Integer);
begin
  FUndoManager.MaxRedo := I;
end;

function TChatRichTextEdit.GetText: string;
begin
  Result := ChatRichTextStringToString(FChatRichText);
end;

function TChatRichTextEdit.GetHTML: string;
begin
  Result := ChatRichTextStringToHTML(FChatRichText);
end;

function TChatRichTextEdit.GetMaxUndo: Integer;
begin
  Result := FUndoManager.MaxUndo;
end;

function TChatRichTextEdit.GetMaxRedo: Integer;
begin
  Result := FUndoManager.MaxRedo;
end;

procedure TChatRichTextEdit.AdjustHeight;
var
  DC         : HDC;
  SaveFont   : HFont;
  I          : Integer;
  SysMetrics : TTextMetric;
  Metrics    : TTextMetric;
begin
  DC := GetDC(0);
  try
    GetTextMetrics(DC, SysMetrics);
    SaveFont := SelectObject(DC, Font.Handle);
    GetTextMetrics(DC, Metrics);
    SelectObject(DC, SaveFont);
  finally
    ReleaseDC(0, DC);
  end;
  if NewStyleControls then
  begin
    if Ctl3D then I := 8 else I := 6;
    I := GetSystemMetrics(SM_CYBORDER) * I;
  end else
  begin
    I := SysMetrics.tmHeight;
    if I > Metrics.tmHeight then I := Metrics.tmHeight;
    I := I div 4 + GetSystemMetrics(SM_CYBORDER) * 4;
  end;
  if Metrics.tmHeight + I > 21 then
  Height := Metrics.tmHeight + I else Height := 21;
end;

procedure TChatRichTextEdit.UpdateHeight;
begin
  if AutoSize then
  begin
    ControlStyle := ControlStyle + [csFixedHeight];
    AdjustHeight;
  end else
    ControlStyle := ControlStyle - [csFixedHeight];
end;

procedure TChatRichTextEdit.SetCaretHome;
begin
  FScrollOffset := 0;
  UpdateCharRects;
  InvalidateBuffer;
  SetCaretCharIndex(-1);
end;

procedure TChatRichTextEdit.SetCaretEnd;
begin
  FScrollOffset := 0;
  UpdateCharRects;
  FScrollOffset := -(FChatRichText[High(FChatRichText)].CharRect.Right - (ClientWidth - (TextStartOffset * 2)));
  UpdateCharRects;
  InvalidateBuffer;
  SetCaretCharIndex(High(FChatRichText));
end;

procedure TChatRichTextEdit.OnContextMenuClick(Sender: TObject);
begin
  if (Sender is TMenuItem) then
  case (Sender as TMenuItem).Tag of

    // Undo
    $900001: Undo;

    // Redo
    $900002: Redo;

    // Cut
    $900003: CutToClipboard;

    // Copy
    $900004: CopyToClipboard;

    // Paste
    $900005: PasteFromClipboard;

    // Select All
    $900006: SelectAll;

    // Delete
    $900007: DeleteSelection;

    // Bold
    $900011: ToggleSelectedBold;

    // Italic
    $900012: ToggleSelectedItalic;

    // Underline
    $900013: ToggleSelectedUnderline;

    // Strikeout
    $900014: ToggleSelectedStrikeOut;

    // Clear Formatting
    $900019: ClearSelectedFontStyles;
  end;
end;

procedure TChatRichTextEdit.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TChatRichTextEdit.WMSize(var Message: TWMSize);
begin
  InvalidateBuffer;
  inherited;
end;

procedure TChatRichTextEdit.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  // Draw Buffer to control canvas
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TChatRichTextEdit.WMContextMenu(var Message: TWMContextMenu);

  function SelectionHasFormatting : Boolean;
  var
    I : Integer;
  begin
    Result := False;
    for I := SelStart to (SelStart + SelLength) -1 do
    if (FChatRichText[I].CharType = ctCharacter) and (FChatRichText[I].FontStyle <> []) then
    begin
      Result := True;
      Break;
    end;
  end;

var
  M : TMenuItem;
begin
  //
  if CanFocus and (not Focused) then SetFocus;
  //
  if not Assigned(PopupMenu) then
  begin
    if Assigned(FStdMenu) then FStdMenu.Free;

    // Create standard popupmenu
    FStdMenu := TPopupMenu.Create(Owner);

    // Undo
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.Undo + #9+ SmkcCtrl + 'Z';
    M.Tag := $900001;
    M.Enabled := CanUndo and not ReadOnly;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Redo
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.Redo + #9 + SmkcCtrl + 'Y';
    M.Tag := $900002;
    M.Enabled := CanRedo and not ReadOnly;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Divider
    M := TMenuItem.Create(FStdMenu);
    M.Caption := '-';
    M.Tag := 0;
    FStdMenu.Items.Add(M);

    // Cut
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.Cut + #9 + SmkcCtrl + 'X';
    M.Tag := $900003;
    M.Enabled := (SelStart >= 0) and (SelLength > 0) and not ReadOnly;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Copy
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.Copy + #9 + SmkcCtrl + 'C';
    M.Tag := $900004;
    M.Enabled := (SelStart >= 0) and (SelLength > 0);
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Paste
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.Paste + #9 + SmkcCtrl + 'V';
    M.Tag := $900005;
    M.Enabled := CanPaste and not ReadOnly;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Delete
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.Delete + #9 + 'Del';
    M.Tag := $900007;
    M.Enabled := (SelStart >= 0) and (SelLength > 0) and not ReadOnly;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Divider
    M := TMenuItem.Create(FStdMenu);
    M.Caption := '-';
    M.Tag := 0;
    FStdMenu.Items.Add(M);

    // Select All
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.SelectAll + #9 + SmkcCtrl + 'A';
    M.Tag := $900006;
    M.Enabled := true;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Divider
    M := TMenuItem.Create(FStdMenu);
    M.Caption := '-';
    M.Tag := 0;
    FStdMenu.Items.Add(M);

    // Bold
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.Bold + #9 + SmkcCtrl + 'B';
    M.Tag := $900011;
    M.Enabled := (SelStart >= 0) and (SelLength > 0) and not ReadOnly;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Italic
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.Italic + #9 + SmkcCtrl + 'I';
    M.Tag := $900012;
    M.Enabled := (SelStart >= 0) and (SelLength > 0) and not ReadOnly;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Underline
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.Underline + #9 + SmkcCtrl + 'U';
    M.Tag := $900013;
    M.Enabled := (SelStart >= 0) and (SelLength > 0) and not ReadOnly;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // StrikeOut
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.StrikeOut;
    M.Tag := $900014;
    M.Enabled := (SelStart >= 0) and (SelLength > 0) and not ReadOnly;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    // Divider
    M := TMenuItem.Create(FStdMenu);
    M.Caption := '-';
    M.Tag := 0;
    FStdMenu.Items.Add(M);

    // Clear Formatting
    M := TMenuItem.Create(FStdMenu);
    M.Caption := FUILanguage.ClearFormatting + #9 + SmkcCtrl + 'Space';
    M.Tag := $900019;
    M.Enabled := (SelStart >= 0) and (SelLength > 0) and (not ReadOnly) and SelectionHasFormatting;
    M.OnClick := OnContextMenuClick;
    FStdMenu.Items.Add(M);

    FStdMenu.Popup(Message.XPos, Message.YPos);
  end
  else
    inherited;
end;

procedure TChatRichTextEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  if (csFixedHeight in ControlStyle) and not ((csDesigning in
    ComponentState) and (csLoading in ComponentState)) then AdjustHeight;
  Canvas.Font := Font;
  InvalidateBuffer;
end;

procedure TChatRichTextEdit.CMColorChanged(var Message: TMessage);
begin
  inherited;
  Canvas.Brush.Color := Color;
  InvalidateBuffer;
end;

procedure TChatRichTextEdit.CMMouseEnter(var Msg: TMessage);
begin
  //
  inherited;
end;

procedure TChatRichTextEdit.CMMouseLeave(var Msg: TMessage);
begin
  if FMouseDown then FMouseDown := False;
  inherited;
end;

function TChatRichTextEdit.SizeOfChar(const C: TChatRichTextChar): TSize;
begin
  with FTempBitmap.Canvas do
  begin
    Font.Assign(Self.Font);
    case C.CharType of

      // Character
      ctCharacter:
      begin
        Font.Style := C.FontStyle;
        Result.Width  := TextWidth(C.Char);
        Result.Height := TextHeight(C.Char);
      end;

      // Space
      ctSpace:
      begin
        Result.Width  := TextWidth(SpaceChar);
        Result.Height := TextWidth(SpaceChar);
      end;

      // Tab
      ctTab:
      begin
        Result.Width  := TextWidth(TabChar);
        Result.Height := TextWidth(TabChar);
      end;

      // Emojis are fixed size
      ctEmoji:
      begin
        if Assigned(EmojiList) then
        begin
          Result.Width  := EmojiList.Width; 
          Result.Height := EmojiList.Height;
        end else
        begin
          Result.Width  := 18; // Fallback width
          Result.Height := 18; // Fallback height
        end;
      end;
    end;
  end;
end;

function TChatRichTextEdit.GetCaretPosition(const X: Integer; const Y: Integer) : Integer;
var
  I : Integer;
begin
  Result := 0;
  for I := Low(ChatRichText) to High(ChatRichText) do
  begin
    if PtInRect(ChatRichText[I].CharRect, Point(X, Y)) then
    begin
      Result := ChatRichText[I].CharRect.Left;
      Break;
    end;
  end;
end;

function TChatRichTextEdit.GetCaretIndex(const X: Integer; const Y: Integer) : Integer;
var
  I : Integer;
begin
  if (X <= TextStartOffset) then
    Result := -1
  else
    Result := High(FChatRichText);
  for I := Low(ChatRichText) to High(ChatRichText) do
  begin
    if PtInRect(ChatRichText[I].CharRect, Point(X, Y)) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

procedure TChatRichTextEdit.SetCaretPosition(X: Integer);

  function FirstVisibleCharacter : Integer;
  var
    I : Integer;
    R : TRect;
  begin
    R := TRect.Create(TextStartOffset, 0, ClientWidth - TextStartOffset, ClientHeight);
    Result := High(FChatRichText);
    for I := Low(FChatRichText) to High(FChatRichText) do
    if FChatRichText[I].CharRect.IntersectsWith(R) then
    begin
      Result := I;
      Break;
    end;
  end;

  function LastVisibleCharacter : Integer;
  var
    I : Integer;
    R : TRect;
  begin
    R := TRect.Create(TextStartOffset, 0, ClientWidth - TextStartOffset, ClientHeight);
    Result := High(FChatRichText);
    for I := High(FChatRichText) downto Low(FChatRichText) do
    if FChatRichText[I].CharRect.IntersectsWith(R) then
    begin
      Result := I;
      Break;
    end;
  end;

begin
  if X >= (ClientWidth - TextStartOffset) then
  begin
    Dec(FScrollOffset, FChatRichText[LastVisibleCharacter].CharRect.Width);
    UpdateCharRects;
    InvalidateBuffer;
  end else

  if X <= 0 then
  begin
    if (FCaretCharIndex = 0) then FScrollOffset := 0 else
    Inc(FScrollOffset, FChatRichText[FirstVisibleCharacter].CharRect.Width);
    if (FScrollOffset > 0) then FScrollOffset := 0;
    UpdateCharRects;
    InvalidateBuffer;
  end else

  begin
    FCaretX := X;
    SetCaretPos(X, (ClientHeight div 2) - (FCaretHeight div 2));
  end;
end;

procedure TChatRichTextEdit.SetCaretCharIndex(I: Integer);
begin
  // Update caret position
  if (I >= 0) and (I < Length(FChatRichText)) then
  begin
    // Update the index
    FCaretCharIndex := I;
    // Set Caret position
    SetCaretPosition(FChatRichText[I].CharRect.Right)
  end else
  begin
    if (I > Length(FChatRichText)) then
    begin
      FCaretCharIndex := High(FChatRichText);
      SetCaretPosition(FChatRichText[FCaretCharIndex].CharRect.Right)
    end;
    if (I < 0) then
    begin
      FCaretCharIndex := -1;
      // Set Caret position
      SetCaretPosition(TextStartOffset);
    end;
  end;
end;

procedure TChatRichTextEdit.SetCaretCharIndexEx(I: Integer);
begin
  if (I >= 0) and (I < Length(FChatRichText)) then
  begin
    FScrollOffset := 0;
    UpdateCharRects;
    if (FChatRichText[I].CharRect.Right > (ClientWidth - TextStartOffset)) then
    FScrollOffset := -(FChatRichText[I].CharRect.Right - (ClientWidth - (TextStartOffset * 2)));
    UpdateCharRects;
    InvalidateBuffer;
    SetCaretCharIndex(I);
  end else
  begin
    FScrollOffset := 0;
    UpdateCharRects;
    InvalidateBuffer;
    SetCaretCharIndex(-1);
  end;
end;

function TChatRichTextEdit.HTMLToChatRichTextString(const S: string) : TChatRichTextString;
var
  Words   : TWordInfoList;
  I, L, P : Integer;
  C       : TChatRichTextChar;
begin
  Words := TWordInfoList.Create(True);
  try
    ParseText(S, Words); 
    L := 0;
    //
    for I := 0 to Words.Count -1 do
    begin
      if (Words.Items[I] is TEmojiInfo) or (Words.Items[I] is TSpaceInfo) or (Words.Items[I] is TBreakInfo) then 
      begin
        // These word types are one character
        Inc(L);
      end else 
        Inc(L, Length(Words[I].Text));
    end;
    //
    SetLength(Result, L);
    P := Low(Result);
    for I := 0 to Words.Count -1 do
    begin
      // Emoji
      if (Words.Items[I] is TEmojiInfo) then
      begin
        C.CharType := ctEmoji;
        C.Emoji.FromString(AnsiString((Words.Items[I] as TEmojiInfo).Emoji));
        C.FontStyle := [];
        Result[P] := C;
        Inc(P);
      end else
      // Space (convert linebreaks to space)
      if (Words.Items[I] is TSpaceInfo) or (Words.Items[I] is TBreakInfo) then
      begin
        C.CharType  := ctCharacter;
        C.Char      := SpaceChar;
        C.FontStyle := [];
        Result[P]   := C;
        Inc(P);
      end else
      // Link (convert to character with underline)
      if (Words.Items[I] is TLinkInfo) then
      for L := 1 to Length(Words[I].Text) do
      begin
        C.CharType  := ctCharacter;
        C.Char      := Words.Items[I].Text[L];
        C.FontStyle := Words.Items[I].FontStyle + [fsUnderline];
        Result[P] := C;
        Inc(P);
      end else
      // Characters
      for L := 1 to Length(Words[I].Text) do
      begin
        C.CharType  := ctCharacter;
        C.Char      := Words.Items[I].Text[L];
        C.FontStyle := Words.Items[I].FontStyle;
        Result[P] := C;
        Inc(P);
      end;
    end;
  finally
    Words.Free;
  end;
end;

function TChatRichTextEdit.WideStringToChatRichTextString(const S: WideString): TChatRichTextString;
var
  I : Integer;
begin
  SetLength(Result, Length(S));
  for I := Low(S) to High(S) do 
  begin
    Result[I].CharType := ctCharacter;
    Result[I].Char     := S[I];
  end;
end;

function TChatRichTextEdit.AnsiStringToChatRichTextString(const S: AnsiString): TChatRichTextString;
var
  I : Integer;
begin
  SetLength(Result, Length(S));
  for I := Low(S) to High(S) do 
  begin
    Result[I].CharType := ctCharacter;
    Result[I].Char     := WideChar(S[I]);
  end;
end;

function TChatRichTextEdit.StringToChatRichTextString(const S: string): TChatRichTextString;
var
  I : Integer;
begin
  SetLength(Result, Length(S));
  for I := Low(S) to High(S) do 
  begin
    Result[I].CharType := ctCharacter;
    Result[I].Char     := WideChar(S[I]);
  end;
end;

function TChatRichTextEdit.ChatRichTextStringToWideString(const S: TChatRichTextString): WideString;
var
  I : Integer;
begin
  Result := '';
  for I := Low(S) to High(S) do
  begin
    case S[I].CharType of
      ctCharacter : Result := Result + S[I].Char;
      ctEmoji     : Result := Result + S[I].Emoji.ToString;
      ctSpace     : Result := Result + SpaceChar;
      ctTab       : Result := Result + TabChar;
    end;
  end;
end;

function TChatRichTextEdit.ChatRichTextStringToAnsiString(const S: TChatRichTextString) : AnsiString;
var
  I : Integer;
begin
  Result := '';
  for I := Low(S) to High(S) do
  begin
    case S[I].CharType of
      ctCharacter : Result := Result + AnsiChar(S[I].Char);
      ctEmoji     : Result := Result + AnsiString(S[I].Emoji.ToString);
      ctSpace     : Result := Result + AnsiChar(SpaceChar);
      ctTab       : Result := Result + AnsiChar(TabChar);
    end;
  end;
end;

function TChatRichTextEdit.ChatRichTextStringToString(const S: TChatRichTextString): string;
var
  I : Integer;
begin
  Result := '';
  for I := Low(S) to High(S) do
  begin
    case S[I].CharType of
      ctCharacter : Result := Result + S[I].Char;
      ctEmoji     : Result := Result + S[I].Emoji.ToString;
      ctSpace     : Result := Result + SpaceChar;
      ctTab       : Result := Result + TabChar;
    end;
  end;
end;

function TChatRichTextEdit.ChatRichTextStringToHTML(const S: TChatRichTextString): string;
const
  Bold      : array [Boolean] of WideString = ('</b>', '<b>');
  Italic    : array [Boolean] of WideString = ('</i>', '<i>');
  Underline : array [Boolean] of WideString = ('</u>', '<u>');
  StrikeOut : array [Boolean] of WideString = ('</s>', '<s>');
  Emoji     : array [Boolean] of WideString = ('</e>', '<e>');
var
  I : Integer;
  F : TFontStyles;
  C : TChatRichTextChar;
begin
  Result := '';
  // Start fontstyle
  F := Font.Style;
  // Position of char
  I := Low(S);
  while (I < Length(S)) do
  begin
    // Char
    C := S[I];

    // If char is of type ctChatacter, process fontstyle
    if (C.CharType = ctCharacter) and (F <> C.FontStyle) then
    begin
      // Bold
      if (fsBold in C.FontStyle) and not (fsBold in F) then
      Result := Result + Bold[True];
      if not (fsBold in C.FontStyle) and (fsBold in F) then
      Result := Result + Bold[False];
      // Italic
      if (fsItalic in C.FontStyle) and not (fsItalic in F) then
      Result := Result + Italic[True];
      if not (fsItalic in C.FontStyle) and (fsItalic in F) then
      Result := Result + Italic[False];
      // Underline
      if (fsUnderline in C.FontStyle) and not (fsUnderline in F) then
      Result := Result + Underline[True];
      if not (fsUnderline in C.FontStyle) and (fsUnderline in F) then
      Result := Result + Underline[False];
      // StrikeOut
      if (fsStrikeOut in C.FontStyle) and not (fsStrikeOut in F) then
      Result := Result + StrikeOut[True];
      if not (fsStrikeOut in C.FontStyle) and (fsStrikeOut in F) then
      Result := Result + StrikeOut[False];
    end;

    // Add character to the string
    case C.CharType of

      // Character
      ctCharacter: 
      begin
        Result := Result + C.Char;
      end;
      
      // Emoji
      ctEmoji:
      begin
        Result := Result + Emoji[True] + S[I].Emoji.ToString + Emoji[False];
      end;
      
      // Space
      ctSpace:
      begin
        Result := Result + SpaceChar;
      end;
      
      // Tab
      ctTab:
      begin
        Result := Result + TabChar;
      end;
    end;

    // Assign current fontstyle
    if (C.CharType = ctCharacter) then
    F := C.FontStyle;

    // Increase position
    Inc(I);
  end;
  // Close text formatting tags (if needed)
  if (fsBold in F) and not (fsBold in Font.Style) then Result := Result + Bold[False];
  if (fsItalic in F) and not (fsItalic in Font.Style) then Result := Result + Italic[False];
  if (fsUnderline in F) and not (fsUnderline in Font.Style) then Result := Result + Underline[False];
  if (fsStrikeOut in F) and not (fsStrikeOut in Font.Style) then Result := Result + StrikeOut[False];
end;

procedure TChatRichTextEdit.AddChar(const C: TChatRichTextChar);
var
  Undo : TUndo;
  S    : TChatRichTextString;
begin
  if ((MaxLength > 0) and (Length(FChatRichText) < MaxLength)) or (MaxLength = 0) then
  begin
    SetLength(S, 1);
    S[Low(S)] := C;
    Undo := TInsertCharUndo.Create(FCaretCharIndex, S);
    FUndoManager.AddUndo(Undo);
    Insert(C, FChatRichText, FCaretCharIndex +1);
    //
    UpdateCharRects;
    InvalidateBuffer;
    //
    if CanFocus and (not Focused) then
    begin
      SetFocus;
      SetCaretCharIndex(FCaretCharIndex +1);
    end;
    //
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextEdit.InsertChar(const C: TChatRichTextChar; const Index: Integer);
var
  Undo : TUndo;
  S    : TChatRichTextString;
begin
  if ((MaxLength > 0) and (Length(FChatRichText) < MaxLength)) or (MaxLength = 0) then
  begin
    if (Index > 0) and (Index <= Length(FChatRichText)) then
    begin
      SetLength(S, 1);
      S[Low(S)] := C;
      Undo := TInsertCharUndo.Create(FCaretCharIndex, S);
      FUndoManager.AddUndo(Undo);
      Insert(C, FChatRichText, Index);
      //
      UpdateCharRects;
      InvalidateBuffer;
      //
      if CanFocus and (not Focused) then
      begin
        SetFocus;
        SetCaretCharIndex(Index +1);
      end;
      //
      if Assigned(FOnChange) then FOnChange(Self);
    end;
  end;
end;

procedure TChatRichTextEdit.DeleteChar(const Index: Integer);
var
  Undo : TUndo;
  S    : TChatRichTextString;
begin
  if (Index >= 0) and (Index <= Length(FChatRichText)) then
  begin
    SetLength(S, 1);
    S[Low(S)] := FChatRichText[Index];
    Undo := TDeleteCharUndo.Create(FCaretCharIndex, S);
    FUndoManager.AddUndo(Undo);
    Delete(FChatRichText, Index, 1);
    //
    UpdateCharRects;
    InvalidateBuffer;
    //
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextEdit.DeleteSelection;
var
  I, L, C : Integer;
  Undo    : TUndo;
begin
  if (SelStart >= -1) and (SelLength > 0) then
  begin
    Undo := TDeleteCharUndo.Create((SelStart + SelLength) -1, Copy(FChatRichText, SelStart, SelLength));
    FUndoManager.AddUndo(Undo);
    //
    L := 0;
    C := SelLength;
    //
    for I := High(FChatRichText) downto Low(FChatRichText) do
    if (I >= SelStart) and (I < SelStart + SelLength) then
    begin
      Inc(L, FChatRichText[I].CharRect.Width);
      Delete(FChatRichText, I, 1);
    end;
    //
    if (FScrollOffset < 0) and (FCaretCharIndex > 0) then
    Inc(FSCrollOffset, L);
    if (FSCrollOffset > 0) then FSCrollOffset := 0;
    //
    UpdateCharRects;
    InvalidateBuffer;
    //
    ClearSelection;
    //
    SetCaretCharIndex(FCaretCharIndex - C);
    //
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextEdit.Clear;
var
  Undo : TUndo;
begin
  Undo := TInsertCharUndo.Create(FCaretCharIndex, FChatRichText);
  FUndoManager.AddUndo(Undo);
  //
  Delete(FChatRichText, Low(FChatRichText), High(FChatRichText));
  SetCaretCharIndex(-1);
  //
  UpdateCharRects;
  InvalidateBuffer;
  //
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TChatRichTextEdit.ClearSelection;
begin
  FInitSelStart := -1;
  SelStart  := -1;
  SelLength := 0;
end;

procedure TChatRichTextEdit.SelectAll;
begin
  SelStart  := 0;
  SelLength := Length(FChatRichText);
  InvalidateBuffer;
end;

procedure TChatRichTextEdit.SetSelectedFontStyle(const F: TFontStyles);
var
  I : Integer;
begin
  for I := SelStart to SelStart + SelLength do
  if FChatRichText[I].CharType = ctCharacter then
  begin
    FChatRichText[I].FontStyle := F;
  end;
  UpdateCharRects;
  InvalidateBuffer;
  // Reset Caret position
  SetCaretCharIndex(FCaretCharIndex);
  //
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TChatRichTextEdit.ToggleSelectedBold;
var
  I : Integer;
  B : Boolean;
begin
  if (SelStart >= 0) and (SelLength > 0) then
  begin
    B := fsBold in FChatRichText[SelStart].FontStyle;
    for I := SelStart to (SelStart + SelLength) -1 do
    if FChatRichText[I].CharType = ctCharacter then
    begin
      if B then
        FChatRichText[I].FontStyle := FChatRichText[I].FontStyle - [fsBold]
      else
        FChatRichText[I].FontStyle := FChatRichText[I].FontStyle + [fsBold];
    end;
    UpdateCharRects;
    InvalidateBuffer;
    // Reset Caret position
    SetCaretCharIndex(FCaretCharIndex);
    //
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextEdit.ToggleSelectedItalic;
var
  I : Integer;
  B : Boolean;
begin
  if (SelStart >= 0) and (SelLength > 0) then
  begin
    B := fsItalic in FChatRichText[SelStart].FontStyle;
    for I := SelStart to (SelStart + SelLength) -1 do
    if FChatRichText[I].CharType = ctCharacter then
    begin
      if B then
        FChatRichText[I].FontStyle := FChatRichText[I].FontStyle - [fsItalic]
      else
        FChatRichText[I].FontStyle := FChatRichText[I].FontStyle + [fsItalic];
    end;
    UpdateCharRects;
    InvalidateBuffer;
    // Reset Caret position
    SetCaretCharIndex(FCaretCharIndex);
    //
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextEdit.ToggleSelectedUnderline;
var
  I : Integer;
  B : Boolean;
begin
  if (SelStart >= 0) and (SelLength > 0) then
  begin
    B := fsUnderline in FChatRichText[SelStart].FontStyle;
    for I := SelStart to (SelStart + SelLength) -1 do
    if FChatRichText[I].CharType = ctCharacter then
    begin
      if B then
        FChatRichText[I].FontStyle := FChatRichText[I].FontStyle - [fsUnderline]
      else
        FChatRichText[I].FontStyle := FChatRichText[I].FontStyle + [fsUnderline];
    end;
    UpdateCharRects;
    InvalidateBuffer;
    // Reset Caret position
    SetCaretCharIndex(FCaretCharIndex);
    //
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextEdit.ToggleSelectedStrikeOut;
var
  I : Integer;
  B : Boolean;
begin
  if (SelStart >= 0) and (SelLength > 0) then
  begin
    B := fsStrikeOut in FChatRichText[SelStart].FontStyle;
    for I := SelStart to (SelStart + SelLength) -1 do
    if FChatRichText[I].CharType = ctCharacter then
    begin
      if B then
        FChatRichText[I].FontStyle := FChatRichText[I].FontStyle - [fsStrikeOut]
      else
        FChatRichText[I].FontStyle := FChatRichText[I].FontStyle + [fsStrikeOut];
    end;
    UpdateCharRects;
    InvalidateBuffer;
    // Reset Caret position
    SetCaretCharIndex(FCaretCharIndex);
    //
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextEdit.ClearSelectedFontStyles;
var
  I : Integer;
begin
  if (SelStart >= 0) and (SelLength > 0) then
  begin
    for I := SelStart to (SelStart + SelLength) -1 do
    if FChatRichText[I].CharType = ctCharacter then
    FChatRichText[I].FontStyle := [];
    //
    UpdateCharRects;
    InvalidateBuffer;
    // Reset Caret position
    SetCaretCharIndex(FCaretCharIndex);
    //
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextEdit.CopyToClipboard;
var
  S : string;
begin
  // Copy selection
  if (SelStart > -1) and (SelLength > 0) then
  begin
    S := ChatRichTextStringToHTML(Copy(FChatRichText, SelStart, SelLength));
    Clipboard.Open;
    Clipboard.AsText := S;
    Clipboard.Close;
  end else

  // Copy all text
  begin
    Clipboard.Open;
    Clipboard.AsText := ChatRichTextStringToHTML(FChatRichText);
    Clipboard.Close;
  end;
end;

procedure TChatRichTextEdit.CutToClipboard;
var
  S : string;
begin
  // Cut selection
  if (SelStart >= -1) and (SelLength > 0) and (not ReadOnly) then
  begin
    S := ChatRichTextStringToHTML(Copy(FChatRichText, SelStart, SelLength));
    Clipboard.Open;
    Clipboard.AsText := S;
    Clipboard.Close;
    DeleteSelection;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextEdit.PasteFromClipboard;
var
  I, C : Integer;
  S    : string;
  CRTS : TChatRichTextString;
  Char : TChatRichTextChar;
  Undo : TUndo;
begin
  if (SelStart >= 0) and (SelLength > 0) then DeleteSelection;
  // Text format
  if Clipboard.HasFormat(CF_TEXT) and (not ReadOnly) then
  begin
    Clipboard.Open;
    S := Clipboard.AsText;
    Clipboard.Close;

    // ChatRichText formatting
    if IsStringChatRichText(S) then
    begin
      CRTS := HTMLToChatRichTextString(S);
      if (MaxLength > 0) then
      begin
        C := 0;
        if Length(FChatRichText) < MaxLength then
        begin
          C := MaxLength - Length(FChatRichText);
          Undo := TPasteUndo.Create(FCaretCharIndex, Copy(CRTS, Low(CRTS), Low(CRTS) + C));
          FUndoManager.AddUndo(Undo);
          for I := Low(CRTS) to (Low(CRTS) + C) -1 do
          Insert(CRTS[I], FChatRichText, FCaretCharIndex + I);
        end;
      end else
      begin
        C := Length(CRTS);
        Undo := TPasteUndo.Create(FCaretCharIndex, CRTS);
        FUndoManager.AddUndo(Undo);
        for I := Low(CRTS) to Length(CRTS) -1 do
        Insert(CRTS[I], FChatRichText, FCaretCharIndex + (I +1));
      end;
    end else

    // Regular text (without formatting)
    begin
      if (MaxLength > 0) then
      begin
        C := 0;
        if Length(FChatRichText) < MaxLength then
        begin
          C := MaxLength - Length(FChatRichText);
          for I := Low(S) to (Low(S) + C) -1 do
          begin
            Char.CharType  := ctCharacter;
            Char.Char      := S[I];
            Char.FontStyle := [];
            Insert(Char, FChatRichText, FCaretCharIndex + I);
          end;
          Undo := TPasteUndo.Create(FCaretCharIndex, Copy(FChatRichText, FCaretCharIndex, C));
          FUndoManager.AddUndo(Undo);
        end;
      end else
      begin
        C := Length(S);
        for I := Low(S) to High(S) do
        begin
          Char.CharType  := ctCharacter;
          Char.Char      := S[I];
          Char.FontStyle := [];
          Insert(Char, FChatRichText, FCaretCharIndex + I);
        end;
        Undo := TPasteUndo.Create(FCaretCharIndex, Copy(FChatRichText, FCaretCharIndex, C));
        FUndoManager.AddUndo(Undo);
      end;
    end;

    FScrollOffset := 0;
    UpdateCharRects;

    if (FChatRichText[FCaretCharIndex + C].CharRect.Right > (ClientWidth - TextStartOffset)) then
    FScrollOffset := -(FChatRichText[FCaretCharIndex + C].CharRect.Right - (ClientWidth - (TextStartOffset * 2)));
    UpdateCharRects;
    InvalidateBuffer;
    SetCaretCharIndex(FCaretCharIndex + C);

    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

function TChatRichTextEdit.CanPaste: Boolean;
begin
  Result := Clipboard.HasFormat(CF_TEXT) and (not ReadOnly);
end;

function TChatRichTextEdit.CanUndo: Boolean;
begin
  Result := FUndoManager.CanUndo;
end;

function TChatRichTextEdit.CanRedo: Boolean;
begin
  Result := FUndoManager.CanRedo;
end;

procedure TChatRichTextEdit.Undo;
begin
  FUndoManager.Undo;
end;

procedure TChatRichTextEdit.Redo;
begin
  FUndoManager.Redo;
end;

procedure TChatRichTextEdit.UpdateCharRects;
var
  I, X, Y: Integer;
  S      : TSize;
begin
  X := TextStartOffset + FScrollOffset;
  Y := ClientHeight div 2;
  for I := Low(FChatRichText) to High(FChatRichText) do
  begin
    // Get size of character
    S := SizeOfChar(FChatRichText[I]);
    // Update width of character
    FChatRichText[I].CharWidth := S.Width;
    // Update height of character
    FChatRichText[I].CharHeight := S.Height;
    // Update char rect
    FChatRichText[I].CharRect := Rect(
      X,
      Y - (FChatRichText[I].CharHeight div 2),
      X + FChatRichText[I].CharWidth,
      Y + FChatRichText[I].CharHeight
    );
    Inc(X, FChatRichText[I].CharWidth);
  end;
end;

procedure TChatRichTextEdit.InvalidateBuffer;

  procedure DrawControlStyle;
  var
    R    : TRect;
    Y, I : Integer;
    D    : TThemedElementDetails;
  begin
    R := Rect(0, 0, FBuffer.Width, FBuffer.Height);
    with FBuffer.Canvas do
    begin
      if StyleServices.Enabled then
        Brush.Color := StyleServices.GetSystemColor(Color)
      else
        Brush.Color := Color;
      Brush.Style := bsSolid;
      FillRect(R);
    end;

    // Enabled and focused
    if Enabled and Focused then
    begin
      D := StyleServices.GetElementDetails(teBackgroundWithBorderFocused);
      StyleServices.DrawElement(FBuffer.Canvas.Handle, D, ClientRect);
      if (BorderStyle = bsSingle) then
      begin
        D := StyleServices.GetElementDetails(teEditBorderNoScrollFocused);
        StyleServices.DrawElement(FBuffer.Canvas.Handle, D, ClientRect);
      end;
    end else

    // Enabled and mouse is over the control, but the control is not focused
    if Enabled and FMouseOver and not Focused then
    begin
      D := StyleServices.GetElementDetails(teBackgroundWithBorderHot);
      StyleServices.DrawElement(FBuffer.Canvas.Handle, D, ClientRect);
      if (BorderStyle = bsSingle) then
      begin
        D := StyleServices.GetElementDetails(teEditBorderNoScrollHot);
        StyleServices.DrawElement(FBuffer.Canvas.Handle, D, ClientRect);
      end;
    end else

    // Enabled and not focused
    if Enabled then
    begin
      D := StyleServices.GetElementDetails(teBackgroundWithBorderNormal);
      StyleServices.DrawElement(FBuffer.Canvas.Handle, D, ClientRect);
      if (BorderStyle = bsSingle) then
      begin
        D := StyleServices.GetElementDetails(teEditBorderNoScrollNormal);
        StyleServices.DrawElement(FBuffer.Canvas.Handle, D, ClientRect);
      end;
    end else

    // Disabled
    begin
      D := StyleServices.GetElementDetails(teBackgroundWithBorderDisabled);
      StyleServices.DrawElement(FBuffer.Canvas.Handle, D, ClientRect);
      if (BorderStyle = bsSingle) then
      begin
        D := StyleServices.GetElementDetails(teEditBorderNoScrollDisabled);
        StyleServices.DrawElement(FBuffer.Canvas.Handle, D, ClientRect);
      end;
    end;

    if ((not Focused) and (Length(FChatRichText) = 0)) or ((csDesigning in ComponentState) and (Length(FChatRichText) = 0)) then
    with FBuffer.Canvas do
    begin
      Brush.Style := bsClear;
      Font.Assign(Self.Font);
      Font.Color := StyleServices.GetSystemColor(clGrayText);
      I := TextHeight(TextHint);
      Y := (ClientHeight div 2) - (I div 2);
      TextOut(TextStartOffset, Y, TextHint);
    end;
  end;

  procedure DrawSelection;
  var
    I : Integer;
  begin
    if Focused or (not HideSelection) then
    with FBuffer.Canvas do
    begin
      // Set Brush
      Brush.Style := bsSolid;
      Brush.Color := StyleServices.GetSystemColor(SelectionColor);
      // If character is in the selection, fill the rect behind the character
      for I := Low(FChatRichText) to High(FChatRichText) do
      if (I >= SelStart) and (I < SelStart + SelLength) then
      FillRect(Rect(
        FChatRichText[I].CharRect.Left,
        SelectionOffset,
        FChatRichText[I].CharRect.Left + FChatRichText[I].CharRect.Width,
        ClientHeight - SelectionOffset
      ));
    end;
  end;

  procedure DrawChatRichText;
  var
    I : Integer;
  begin
    for I := Low(FChatRichtext) to High(FChatRichtext) do
    with FBuffer.Canvas do
    begin
      Font.Assign(Self.Font);
      Font.Color := StyleServices.GetSystemColor(Font.Color);
      Brush.Style := bsClear;
      // Selected?
      if (I >= SelStart) and (I < SelStart + SelLength) then
      if Focused or (not HideSelection) then
      begin
        Font.Color := StyleServices.GetSystemColor(clHighlightText);
      end;
      // Character
      if (FChatRichtext[I].CharType = ctCharacter) then
      begin
        Font.Style := FChatRichtext[I].FontStyle;
        TextOut(FChatRichtext[I].CharRect.Left, FChatRichtext[I].CharRect.Top, FChatRichtext[I].Char);
      end;
      // Emoji
      if (FChatRichtext[I].CharType = ctEmoji) then
      begin
        if Assigned(EmojiList) then
          EmojiList.DrawEmoji(FChatRichtext[I].Emoji.ToString, FBuffer.Canvas, FChatRichtext[I].CharRect.Left, FChatRichtext[I].CharRect.Top)
        else
          Rectangle(FChatRichtext[I].CharRect);
      end;
      // Space
      if (FChatRichtext[I].CharType = ctSpace) then
      begin
        TextOut(FChatRichtext[I].CharRect.Left, FChatRichtext[I].CharRect.Top, SpaceChar);
      end;
      // Tab
      if (FChatRichtext[I].CharType = ctTab) then
      begin
        TextOut(FChatRichtext[I].CharRect.Left, FChatRichtext[I].CharRect.Top, TabChar);
      end;
      
    end;
  end;

begin
  // Update size of buffer (if needed)
  if (FBuffer.Width <> ClientWidth) or (FBuffer.Height <> ClientHeight) then
  begin
    FBuffer.SetSize(ClientWidth, ClientHeight);
  end;
  // Draw the control (TEdit) style
  DrawControlStyle;
  // Draw the selection (if needed)
  if (SelLength > 0) then DrawSelection;
  // Draw the formatted text
  DrawChatRichText;
  //
  Invalidate;
end;

procedure TChatRichTextEdit.Paint;
var
  X, Y : Integer;
  W, H : Integer;
begin
  //
  X := FUpdateRect.Left;
  Y := FUpdateRect.Top;
  W := FUpdateRect.Right - FUpdateRect.Left;
  H := FUpdateRect.Bottom - FUpdateRect.Top;

  // Draw Buffer to canvas
  if (W <> 0) and (H <> 0) then
    BitBlt(Canvas.Handle, X, Y, W, H, FBuffer.Canvas.Handle, X,  Y, SRCCOPY)
  else
    BitBlt(Canvas.Handle, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, X,  Y, SRCCOPY);
end;

procedure TChatRichTextEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FEmojiList) then
  begin
    // Remove Emoji List
    FEmojiList.OnChange := nil;
    FEmojiList := nil;
    // Repaint
    InvalidateBuffer;
  end;
end;

procedure TChatRichTextEdit.WndProc(var Message: TMessage);
begin
  if (csDestroying in ComponentState) then
  begin
    inherited;
    Exit;
  end;

  inherited;

  if (Message.Msg = WM_COPY) then CopyToClipboard
  else
  if (Message.Msg = WM_CUT) then CutToClipboard
  else
  if (Message.Msg = WM_PASTE) then PasteFromClipboard
  else
  if (Message.Msg = EM_GETSEL) then
  begin
    PInteger(Message.WParam)^ := SelStart;
    PInteger(Message.LParam)^ := SelStart + SelLength;
  end;
end;

procedure TChatRichTextEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  if Button = mbRight then
  begin
    if Enabled and CanFocus and (not Focused) then
    begin
      SetFocus;
      if AutoSelect then SelectAll;
    end;
  end;
  if Button = mbLeft then
  begin
    if Enabled and CanFocus and (not Focused) then SetFocus;
    begin
      if (not (ssShift in Shift)) then
      begin
        SetCaretCharIndex(GetCaretIndex(X, Y));
        FInitSelStart := FCaretCharIndex +1;
        SelStart  := FCaretCharIndex +1;
        SelLength := 0;
      end else
      begin
        FInitSelStart := FCaretCharIndex +1;
        SelStart := FCaretCharIndex +1;
        SetCaretCharIndex(GetCaretIndex(X, Y));
        SelLength := (FCaretCharIndex - SelStart) +1;
      end;
      FMouseDown := True;
      FMouseDownStart.X := X;
      FMouseDownStart.Y := Y;
      if (not (ssShift in Shift)) and (SelLength > 0) then ClearSelection;
    end;
  end;
  inherited;
end;

procedure TChatRichTextEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  FMouseDown := False;
  inherited;
end;

procedure TChatRichTextEdit.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);
var
  C : Integer;
begin
  if Enabled and FMouseDown then
  begin
    if (X > FMouseDownStart.X) then
    begin
      C := GetCaretIndex(X, Y);
      SelLength := (C - SelStart) +1;
    end else
    begin
      C := GetCaretIndex(X, Y);
      if FInitSelStart > C then SelStart := C;
      SelLength := SelLength +1;
    end;
    SetCaretCharIndexEx(GetCaretIndex(X, Y));
  end;
  inherited;
end;

procedure TChatRichTextEdit.KeyDown(var Key: Word; Shift: TShiftState);

  function VKeytoWideString(Key : Word) : WideString;
  var
    WBuff         : array [0..255] of WideChar;
    KeyboardState : TKeyboardState;
    UResult       : Integer;
  begin
    Result := '';
    GetKeyBoardState (KeyboardState);
    ZeroMemory(@WBuff[0], SizeOf(WBuff));
    UResult := ToUnicode(key, MapVirtualKey(key, 0), KeyboardState, WBuff, Length(WBuff), 0);
    if UResult > 0 then
      SetString(Result, WBuff, UResult)
    else if UResult = -1 then
      Result := WBuff;
  end;

var
  S : string;
  C : TChatRichTextChar;
begin
  if Enabled then
    begin
    case Key of

      VK_LEFT, VK_UP:
      begin
        if (FCaretCharIndex > 0) then
        begin
          if (FChatRichText[FCaretCharIndex -1].CharRect.Left < TextStartOffset) then
          Inc(FSCrollOffset, FChatRichText[FCaretCharIndex +1].CharRect.Width);
          if FCaretCharIndex <= Low(FChatRichText) +1 then FScrollOffset := 0;
          UpdateCharRects;
          InvalidateBuffer;
        end;
        SetCaretCharIndex(FCaretCharIndex -1);
        if ssShift in Shift then
        begin
          if (SelStart >= 0) and (SelLength > 0) then
          begin
            if (FInitSelStart < SelStart) then
            begin
              SelLength := SelLength -1;
            end else
            begin
              SelStart  := SelStart -1;
              SelLength := SelLength +1;
            end;
          end else

          if (SelStart <= 0) and (SelLength = 0) then
          begin
            FInitSelStart := FCaretCharIndex +1;
            SelStart  := FCaretCharIndex +1;
            SelLength := 1;
          end;
        end else
        begin
          FInitSelStart := -1;
        end;
      end;

      VK_RIGHT, VK_DOWN:
      if (FCaretCharIndex < Length(FChatRichText) -1) then
      begin
        if (FCaretCharIndex < Length(FChatRichText)) then
        begin
          if (FChatRichText[FCaretCharIndex +1].CharRect.Left > ClientWidth) then
          Dec(FSCrollOffset, FChatRichText[FCaretCharIndex +1].CharRect.Width);
        end;
        SetCaretCharIndex(FCaretCharIndex +1);
        if ssShift in Shift then
        begin
          if (SelStart >= 0) then
          begin
            SelLength := SelLength +1;
          end else
          begin
            FInitSelStart := FCaretCharIndex;
            SelStart  := FCaretCharIndex;
            SelLength := 1;
          end;
        end else
        begin
          FInitSelStart := -1;
        end;
      end;

      VK_BACK:
      begin
        if (not ReadOnly) then
        if (SelStart >= -1) and (SelLength > 0) then DeleteSelection else
        begin
          ClearSelection;
          if (FScrollOffset < 0) and (FCaretCharIndex > 0) then
          Inc(FSCrollOffset, FChatRichText[FCaretCharIndex -1].CharRect.Width);
          DeleteChar(FCaretCharIndex);
          SetCaretCharIndex(FCaretCharIndex -1);
        end;
      end;

      VK_DELETE:
      begin
        if (not ReadOnly) then
        if (SelStart >= -1) and (SelLength > 0) then DeleteSelection else 
        begin
          ClearSelection;
          DeleteChar(FCaretCharIndex +1);
        end;
      end;

      VK_HOME:
      begin
        ClearSelection;
        SetCaretHome;
      end;

      VK_END:
      begin
        ClearSelection;
        SetCaretEnd;
      end;

      // Hotkeys
      else
      if (ssCtrl in Shift) then
      begin
        // Select all
        if Key = Ord('A') then SelectAll;
        // Copy
        if Key = Ord('C') then CopyToClipboard;
        // Cut
        if Key = Ord('X') then CutToClipboard;
        // Paste
        if Key = Ord('V') then PasteFromClipboard;
        // Undo
        if Key = Ord('Z') then Undo;
        // Redo
        if Key = Ord('Y') then Redo;
        // Bold
        if Key = Ord('B') then ToggleSelectedBold;
        // Italic
        if Key = Ord('I') then ToggleSelectedItalic;
        // Underine
        if Key = Ord('U') then ToggleSelectedUnderline;
        // Clear Formatting 
        if Key = Ord(' ') then ClearSelectedFontStyles;
      end

      // Insert character
      else
      if (not (ssCtrl in Shift)) and  (not (ssAlt in Shift)) and (not ReadOnly) then
      begin
        if not (ssShift in Shift) then
        begin
          if (SelLength > 1) then
            DeleteSelection
          else
          if (SelLength > 0) then
            ClearSelection;
        end;
        S := VKeytoWideString(Key);
        if (Length(S) = 1) then
        begin
          if (SelStart >= 0) and (SelLength > 0) then DeleteSelection;
          C.CharType  := ctCharacter;
          C.Char      := S[1];
          C.FontStyle := Font.Style;
          AddChar(C);
          SetCaretCharIndex(FCaretCharIndex +1);
        end;
      end;
    end;
    if (not (ssShift in Shift)) and (not (ssCtrl in Shift)) and (SelLength > 0) then ClearSelection;
  end;
  inherited;
end;

procedure TChatRichTextEdit.CMGotFocus(var Message: TWMNoParams);
begin
  InvalidateBuffer;
end;

procedure TChatRichTextEdit.CMLostFocus(var Message: TWMNoParams);
begin
  InvalidateBuffer;
end;

procedure TChatRichTextEdit.CMEnabledChanged(var Message: TMessage);
begin
  InvalidateBuffer;
end;

procedure TChatRichTextEdit.CMHintShow(var Message: TCMHintShow);
var
  I : Integer;
begin
  if ShowEmojiHint and Assigned(EmojiList) then
  for I := Low(FChatRichText) to High(FChatRichText) do
  if PtInRect(FChatRichText[I].CharRect, Message.HintInfo.CursorPos) then
  begin
    if FChatRichText[I].CharType = ctEmoji then
    begin
      Message.HintInfo.HintStr := EmojiList.GetEmoji(FChatRichText[I].Emoji.ToString).DisplayName;
    end;
    Break;
  end;

  inherited;
end;

procedure TChatRichTextEdit.WMSetCursor(var Message: TWMSetCursor);
begin
  if not (csDesigning in ComponentState) then
  begin
    Message.Result := 1;
    if Enabled then
      SetCursor(Screen.Cursors[crIBeam])
    else
      SetCursor(Screen.Cursors[Cursor]);
  end else inherited;
end;

procedure TChatRichTextEdit.WMSetFocus(var Message: TWMSetFocus);
begin
  if (not (csDesigning in ComponentState)) and Enabled then
  begin
    inherited;
    CreateCaret(Handle, HBITMAP(0), 1, FCaretHeight);
    SetCaretCharIndex(FCaretCharIndex);
    ShowCaret(Handle);
    InvalidateBuffer;
  end else
    inherited;
end;

procedure TChatRichTextEdit.WMKillFocus(var Message: TWMKillFocus);
begin
  if not (csDesigning in ComponentState) and Enabled then
  begin
    DestroyCaret;
    InvalidateBuffer;
  end;
  inherited;
end;

procedure TChatRichTextEdit.WMGetDlgCode(var Message: TWMNoParams);
begin
  Message.Result := DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

procedure TChatRichTextEdit.WMLButtonDblClk(var Message: TWMMouse);

  function SpaceBefore(const I: Integer) : Integer;
  var
    X : Integer;
  begin
    Result := 0;
    for X := I downto Low(FChatRichText) do
    if (I > -1) and (FChatRichText[X].CharType = ctCharacter) and (FChatRichText[X].Char = SpaceChar) then
    begin
      Result := X;
      Break;
    end;
  end;

  function SpaceAfter(const I: Integer) : Integer;
  var
    X : Integer;
  begin
    Result := Length(FChatRichText);
    for X := I to High(FChatRichText) do
    if (I > -1) and (FChatRichText[X].CharType = ctCharacter) and (FChatRichText[X].Char = SpaceChar) then
    begin
      Result := X;
      Break;
    end;
  end;

var
  C, S, E : Integer;
begin
  // Clear selection
  ClearSelection;
  // Try to find a "word" .. Find text between spaces..
  C := GetCaretIndex(Message.XPos, Message.YPos);
  S := SpaceBefore(C);
  E := SpaceAfter(C);
  if (S >= -1) and (E > 0) and (E > S) then
  begin
    if (S >= 0) then
    begin
      if S = 0 then
      begin
        SelStart  := S;
        SelLength := (E - S) +1;
      end else
      begin
        SelStart  := S +1;
        SelLength := E - S;
      end;
    end else
    begin
      SelStart  := S;
      SelLength := (E - S) +1;
    end;
    if (((SelStart + SelLength) -1) < Length(FChatRichText)) and (FChatRichText[(SelStart + SelLength) -1].CharRect.Right > (ClientWidth - TextStartOffset)) then
    begin
      FScrollOffset := 0;
      UpdateCharRects;
      FScrollOffset := -(FChatRichText[(SelStart + SelLength) -1].CharRect.Right - (ClientWidth - (TextStartOffset * 2)));
      UpdateCharRects;
      InvalidateBuffer;
    end;
    SetCaretCharIndex((SelStart + SelLength) -1);
  end else
    SelectAll;
end;

end.
