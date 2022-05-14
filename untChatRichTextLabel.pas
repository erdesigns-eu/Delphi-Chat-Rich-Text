unit untChatRichTextLabel;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.StdCtrls,
  untChatRichText;

{*******************************************************}
{                 Chat Rich Text Label                  }
{*******************************************************}
type
  TChatRichTextLabel = class(TChatRichTextBaseControl)
  private
    // Events
    FOnLinkClick : TChatRichTextLinkEvent;

    // Properties
    FNormalLink    : TChatRichTextLinkFont;
    FActiveLink    : TChatRichTextLinkFont;
    FLinkCursor    : TCursor;
    FText          : TChatRichTextString;
    FAlignment     : TAlignment;
    FLayout        : TTextLayout;
    FAutoHeight    : Boolean;
    FAutoWidth     : Boolean;
    FAutoVisitLink : Boolean;

    // Used for drawing
    FWords    : TWordInfoList;
    FLines    : TLineInfoList;
    FUpdating : Boolean;

    //
    FHoverLinkIndex : Integer;

    // Property Setters
    procedure SetNormalLink(const L: TChatRichTextLinkFont);
    procedure SetActiveLink(const L: TChatRichTextLinkFont);
    procedure SetText(const S: TChatRichTextString);
    procedure SetAlignment(const A: TAlignment);
    procedure SetLayout(const L: TTextLayout);
    procedure SetAutoWidth(const B: Boolean);
    procedure SetAutoHeight(const B: Boolean);

    // Events
    procedure OnNormalLinkChange(Sender: TObject);
    procedure OnActiveLinkChange(Sender: TObject);

    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure CreateWnd; override;
    procedure PaintBuffer; override;

    procedure MouseMove(Shift: TShiftState; X: Integer; Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    // Properties
    property Words: TWordInfoList read FWords;
    property Lines: TLineInfoList read FLines;
  published
    // Events
    property OnLinkClick: TChatRichTextLinkEvent read FOnLinkClick write FOnLinkClick;

    // Properties
    property Align;
    property Anchors;
    property BiDiMode;
    property Color nodefault;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Touch;
    property Visible;
    property StyleName;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnStartDock;
    property OnStartDrag;

    property EmojiList;

    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth default False;
    property AutoHeight: Boolean read FAutoHeight write SetAutoHeight default False;
    property AutoVisitLink: Boolean read FAutoVisitLink write FAutoVisitLink default False;
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property Layout: TTextLayout read FLayout write SetLayout default tlTop;
    property LinkNormal: TChatRichTextLinkFont read FNormalLink write SetNormalLink;
    property LinkActive: TChatRichTextLinkFont read FActiveLink write SetActiveLink;
    property LinkCursor: TCursor read FLinkCursor write FLinkCursor default crHandPoint;
    property Text: TChatRichTextString read FText write SetText;
  end;

implementation

uses Winapi.ShellAPI, Vcl.Forms;

{*******************************************************}
{                 Chat Rich Text Label                  }
{*******************************************************}
constructor TChatRichTextLabel.Create(AOwner: TComponent);
begin
  // Create
  inherited Create(AOwner);

  // Control Style
  ControlStyle := [csCaptureMouse, csClickEvents, csDoubleClicks];

  // Create Link font color and style
  FNormalLink := TChatRichTextLinkFont.Create;
  FNormalLink.Color := clHighlight;
  FNormalLink.Style := [];
  FNormalLink.OnChange := OnNormalLinkChange;

  FActiveLink := TChatRichTextLinkFont.Create;
  FActiveLink.Color := clHighlight;
  FActiveLink.Style := [fsUnderline];
  FActiveLink.OnChange := OnActiveLinkChange;

  // Create Words
  FWords := TWordInfoList.Create(True);
  // Create lines
  FLines := TLineInfoList.Create(True);

  // Default settings
  FAutoWidth      := False;
  FAutoHeight     := False;
  FAutoVisitLink  := False;
  FAlignment      := taLeftJustify;
  FLayout         := tlTop;
  FLinkCursor     := crHandpoint;
  FHoverLinkIndex := -1;
  FText := 'TChat<b>Rich</b>Text<b>Label</b>';
end;

destructor TChatRichTextLabel.Destroy;
begin
  // Free Link font color and style
  FNormalLink.Free;
  FActiveLink.Free;

  // Free Words
  FWords.Free;
  // Free Lines
  FLines.Free;

  // Free
  inherited Destroy;
end;

procedure TChatRichTextLabel.Assign(Source: TPersistent);
begin
  if (Source <> nil) and (Source is TChatRichTextLabel) then
  begin
    FNormalLink.Assign((Source as TChatRichTextLabel).LinkNormal);
    FActiveLink.Assign((Source as TChatRichTextLabel).LinkActive);
    FText := (Source as TChatRichTextLabel).Text;
  end else
    inherited;
end;

procedure TChatRichTextLabel.SetNormalLink(const L: TChatRichTextLinkFont);
begin
  FNormalLink.Assign(L);
end;

procedure TChatRichTextLabel.SetActiveLink(const L: TChatRichTextLinkFont);
begin
  FActiveLink.Assign(L);
end;

procedure TChatRichTextLabel.SetText(const S: TChatRichTextString);
begin
  if S <> Text then
  begin
    FText := S;
    ParseText(StringReplace(StringReplace(S, #10, '', [rfReplaceAll]), #13, '', [rfReplaceAll]), FWords);
    PaintBuffer;
  end;
end;

procedure TChatRichTextLabel.SetAlignment(const A: TAlignment);
begin
  if Alignment <> A then
  begin
    FAlignment := A;
    PaintBuffer;
  end;
end;

procedure TChatRichTextLabel.SetLayout(const L: TTextLayout);
begin
  if Layout <> L then
  begin
    FLayout := L;
    PaintBuffer;
  end;
end;

procedure TChatRichTextLabel.SetAutoWidth(const B: Boolean);
begin
  if AutoWidth <> B then
  begin
    FAutoWidth := B;
    PaintBuffer;
  end;
end;

procedure TChatRichTextLabel.SetAutoHeight(const B: Boolean);
begin
  if AutoHeight <> B then
  begin
    FAutoHeight := B;
    PaintBuffer;
  end;
end;

procedure TChatRichTextLabel.OnNormalLinkChange(Sender: TObject);
begin
  PaintBuffer;
end;

procedure TChatRichTextLabel.OnActiveLinkChange(Sender: TObject);
begin
  PaintBuffer;
end;

procedure TChatRichTextLabel.CMColorChanged(var Message: TMessage);
begin
  inherited;
  PaintBuffer;
end;

procedure TChatRichTextLabel.CMFontChanged(var Message: TMessage);
begin
  inherited;
  PaintBuffer;
end;

procedure TChatRichTextLabel.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
end;

procedure TChatRichTextLabel.CMMouseLeave(var Msg: TMessage);
begin
  if (FHoverLinkIndex <> -1) then
  begin
    FHoverLinkIndex := -1;
    PaintBuffer;
  end;
  inherited;
end;

procedure TChatRichTextLabel.CreateWnd;
begin
  PaintBuffer;
  inherited;
end;

procedure TChatRichTextLabel.PaintBuffer;
var
  R        : TRect;
  L, W, X  : Integer;
  PX, PY   : Integer;
  WordInfo : TWordInfo;
begin
  if (not HasParent) or FUpdating then Exit;
  //
  FUpdating := True;
  // Build lines
  //
  // Note:
  // We dont need character info (width/height) here, so to speed up
  // the parsing we dont build character information.
  //
  R := MeasureRichTextRect(FWords, FLines, ClientRect, False);
  // Auto widdth
  if AutoWidth and (R.Width <> Width) then Width := R.Width;
  // Auto Height
  if AutoHeight and (R.Height <> Height) then Height := R.Height;
  // Draw label
  with Buffer.Canvas do
  begin
    Font.Assign(Self.Font);
    // Set initial pen position
    if (FLines.Count > 0) then
    begin
      case Alignment of
        taLeftJustify   : X := 0;
        taRightJustify  : X := ClientWidth - FLines.Items[0].LineWidth;
        taCenter        : X := (ClientWidth div 2) - (FLines.Items[0].LineWidth div 2);
      end;
      case Layout of
        tlTop    : MoveTo(X, 0);
        tlCenter : MoveTo(X, (ClientHeight div 2) - (R.Height div 2));
        tlBottom : MoveTo(X, (ClientHeight - R.Height));
      end;
    end;
    // Draw background
    Brush.Color := Color;
    Brush.Style := bsSolid;
    FillRect(ClientRect);
    Brush.Style := bsClear;
    // Loop over lines
    for L := 0 to FLines.Count -1 do
    begin
      // Loop over words in line
      for W := 0 to FLines.Items[L].Words.Count -1 do
      begin
        //
        WordInfo := FLines.Items[L].Words.Items[W];

        // Assign Font Style
        Font.Style := WordInfo.FontStyle;

        // Emoji
        if (WordInfo is TEmojiInfo) then
        begin
          X := PenPos.X;
          WordInfo.Rect := Rect(PenPos.X, PenPos.Y, PenPos.X + WordInfo.WordWidth, PenPos.Y + WordInfo.WordHeight);
          if Assigned(EmojiList) then
          begin
            EmojiList.DrawEmoji((WordInfo as TEmojiInfo).Emoji, Buffer.Canvas, PenPos.X, PenPos.Y)
          end else
          begin
            // No emoji available
            Rectangle(WordInfo.Rect);
          end;
          MoveTo(X + WordInfo.WordWidth, PenPos.Y);
        end else

        // Link
        if (WordInfo is TLinkInfo) then
        begin
          // Hovered link
          if (WordInfo as TLinkInfo).LinkIndex = FHoverLinkIndex then
          begin
            Font.Color := LinkActive.Color;
            Font.Style := LinkActive.Style;
          end else
          // Normal link
          begin
            Font.Color := LinkNormal.Color;
            Font.Style := LinkNormal.Style;
          end;
          PY := PenPos.Y + WordInfo.YOffset;
          WordInfo.Rect := Rect(PenPos.X, PY, PenPos.X + WordInfo.WordWidth, PY + WordInfo.WordHeight);
          PY := PenPos.Y;
          TextOut(PenPos.X, WordInfo.Rect.Top, WordInfo.Text);
          PX := PenPos.X;
          MoveTo(PX, PY);
        end else

        // Text
        begin
          Font.Color := Self.Font.Color;
          PY := PenPos.Y + WordInfo.YOffset;
          WordInfo.Rect := Rect(PenPos.X, PY, PenPos.X + WordInfo.WordWidth, PY + WordInfo.WordHeight);
          PY := PenPos.Y;
          TextOut(PenPos.X, WordInfo.Rect.Top, WordInfo.Text);
          PX := PenPos.X;
          MoveTo(PX, PY);
        end;
      end;

      // Update position
      if (L < FLines.Count -1) then
      case Alignment of
        taLeftJustify  : PX := 0;
        taRightJustify : PX := ClientWidth - (FLines.Items[L +1].LineWidth);
        taCenter       : PX := (ClientWidth div 2) - (FLines.Items[L +1].LineWidth div 2);
      end;
      PY := PenPos.Y + FLines.Items[L].LineHeight;
      MoveTo(PX, PY);
    end;
  end;
  FUpdating := False;
  Invalidate;
end;

procedure TChatRichTextLabel.MouseMove(Shift: TShiftState; X: Integer; Y: Integer);
var
  M, I : Integer;
  C    : TCursor;
begin
  M := -1;
  C := crDefault;
  for I := 0 to Words.Count -1 do
  if (Words.Items[I] is TLinkInfo) and PtInRect(Words.Items[I].Rect, TPoint.Create(X, Y)) then
  begin
    M := (Words.Items[I] as TLinkInfo).LinkIndex;
    C := FLinkCursor;
    Break;
  end;
  if (C <> Cursor) then
  begin
    Cursor := C;
  end;
  if (M <> FHoverLinkIndex) then
  begin
    FHoverLinkIndex := M;
    PaintBuffer;
  end;
  inherited;
end;

procedure TChatRichTextLabel.MouseDown(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
var
  I : Integer;
  L : TLinkInfo;
begin
  for I := 0 to Words.Count -1 do
  if (Words.Items[I] is TLinkInfo) and PtInRect(Words.Items[I].Rect, TPoint.Create(X, Y)) then
  begin
    L := (Words.Items[I] as TLinkInfo);
    if Assigned(FOnLinkClick) then FOnLinkClick(Self, L.LinkIndex, L.LinkType, L.Link);
    if AutoVisitLink then
    case L.LinkType of
      ltURL     : ShellExecute(Application.Handle, 'open', PChar(L.Link), nil, nil, SW_SHOWNORMAL);
      ltEmail   : ShellExecute(Application.Handle, 'open', PChar('mailto:' + L.Link), nil, nil, SW_SHOWNORMAL);
      ltPhone   :; // Yet to implement
    end;
    Break;
  end;
  inherited;
end;

procedure TChatRichTextLabel.MouseUp(Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
begin
  inherited;
end;

end.
