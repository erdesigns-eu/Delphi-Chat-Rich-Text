{*******************************************************}
{                                                       }
{                  untChatBaloon.pas                    }
{               Author: Ernst Reidinga                  }
{                                                       }
{       Draw various styles of Balloons for Chat        }
{       messages. (Used in TChatBox)                    }
{                                                       }
{*******************************************************}

unit untChatBalloon;

interface

uses
  System.Types,
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.Messages,
  System.Generics.Collections,
  Vcl.Controls,
  Vcl.Graphics,
  untChatRichText;

{*******************************************************}
{                  Chat Balloon Shapes                  }
{*******************************************************}
type
  TChatBalloonShape = (
    bsRectangle,
    bsRoundRect
  );

{*******************************************************}
{                  Chat Balloon Border                  }
{*******************************************************}
type
  TChatBalloonBorder = (
    bbTopLeft,
    bbTopRight,
    bbBottomLeft,
    bbBottomRight
  );

type
  TChatBaloonBorders = set of TChatBalloonBorder;

{*******************************************************}
{               Chat Balloon Date Format                }
{*******************************************************}
type
  TChatBalloonDateFormat = (
    dfDateTimeLong,
    dfDateTimeShort,
    dtDateLong,
    dfDateShort,
    dfTimeLong,
    dfTimeShort,
    dfCustom
  );

{*******************************************************}
{             Chat Balloon Username Format              }
{*******************************************************}
type
  TChatBalloonUsernameFormat = (
    unUsername,
    unFullname
  );

{*******************************************************}
{             Chat Balloon Base Component               }
{*******************************************************}
type
  TChatBalloonBase = class(TComponent)
  private
    // Events
    FOnChange : TNotifyEvent;

    // Properties (Balloon)
    FShape        : TChatBalloonShape;
    FBorders      : TChatBaloonBorders;
    FBorderRadius : Integer;
    FMaxWidthP    : Integer; // Max width in percent
    FColor        : TColor;
    FBorderWidth  : Integer;
    FBorderColor  : TColor;
    FSpacing      : Integer;
    FFont         : TFont;

    // Properties (Date)
    FDateFormat        : TChatBalloonDateFormat;
    FCustomDateFormat  : string;
    FDateFont          : TFont;
    FDateCursor        : TCursor;
    FDateShowThreshold : Integer; // Seconds between messages to show the date

    // Properties (Username)
    FUsernameFormat    : TChatBalloonUsernameFormat;
    FUsernameFont      : TFont;
    FUsernameCursor    : TCursor;

    // Properties (Link)
    FNormalLink : TChatRichTextLinkFont;
    FActiveLink : TChatRichTextLinkFont;

    // Events
    procedure OnFontChange(Sender: TObject);
    procedure OnDateFontChange(Sender: TObject);
    procedure OnUsernameFontChange(Sender: TObject);
    procedure OnNormalLinkChange(Sender: TObject);
    procedure OnActiveLinkChange(Sender: TObject);

    // Property Setters
    procedure SetShape(const S: TChatBalloonShape);
    procedure SetBorders(const B: TChatBaloonBorders);
    procedure SetBorderRadius(const I: Integer);
    procedure SetMaxWidthP(const I: Integer);
    procedure SetColor(const C: TColor);
    procedure SetBorderWidth(const I: Integer);
    procedure SetBorderColor(const C: TColor);
    procedure SetSpacing(const I: Integer);
    procedure SetFont(const F: TFont);

    procedure SetDateFormat(const F: TChatBalloonDateFormat);
    procedure SetCustomDateFormat(const S: string);
    procedure SetDateFont(const F: TFont);
    procedure SetDateCursor(const C: TCursor);
    procedure SetDateShowThreshold(const I: Integer);

    procedure SetUsernameFormat(const F: TChatBalloonUsernameFormat);
    procedure SetUsernameFont(const F: TFont);
    procedure SetUsernameCursor(const C: TCursor);

    procedure SetNormalLink(const L: TChatRichTextLinkFont);
    procedure SetActiveLink(const L: TChatRichTextLinkFont);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    function TextSize(const Text: string; const Font: TFont; const Canvas: TCanvas) : TRect;
    function CalculateBalloonRect(const R: TRect; const UR: TRect; const DR: TRect; var Words: TWordInfoList;
      var Lines: TLineInfoList; const Canvas: TCanvas) : TRect; virtual; abstract;
    procedure DrawBalloon(const R: TRect; const Canvas: TCanvas); virtual; abstract;
  published
    // Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    // Properties (Balloon)
    property Shape: TChatBalloonShape read FShape write SetShape default bsRectangle;
    property Borders: TChatBaloonBorders read FBorders write SetBorders default [bbTopLeft, bbTopRight, bbBottomLeft, bbBottomRight];
    property BorderRadius: Integer read FBorderRadius write SetBorderRadius default 10;
    property MaxWidth: Integer read FMaxWidthP write SetMaxWidthP default 80;
    property Color: TColor read FColor write SetColor default clWhite;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 1;
    property BorderColor: TColor read FBorderColor write SetBorderColor default clGray;
    property Spacing: Integer read FSpacing write SetSpacing default 10;
    property Font: TFont read FFont write SetFont;

    // Properties (Date)
    property DateFormat: TChatBalloonDateFormat read FDateFormat write SetDateFormat default dfTimeShort;
    property CustomDateFormat: string read FCustomDateFormat write SetCustomDateFormat;
    property DateFont: TFont read FDateFont write SetDateFont;
    property DateCursor: TCursor read FDateCursor write SetDateCursor default crDefault;
    property DateShowThreshold: Integer read FDateShowThreshold write SetDateShowThreshold default 720;

    // Properties (Username)
    property UsernameFormat: TChatBalloonUsernameFormat read FUsernameFormat write SetUsernameFormat default unFullname;
    property UsernameFont: TFont read FUsernameFont write SetUsernameFont;
    property UsernameCursor: TCursor read FUsernameCursor write SetUsernameCursor default crDefault;

    // Properties (Link)
    property LinkNormal: TChatRichTextLinkFont read FNormalLink write SetNormalLink;
    property LinkActive: TChatRichTextLinkFont read FActiveLink write SetActiveLink;
  end;

{*******************************************************}
{                  Simple Chat Balloon                  }
{*******************************************************}
type
  TSimpleChatBalloon = class(TChatBalloonBase)
  private
    FUseGDIPlus : Boolean;

    procedure SetUseGDIPlus(const B: Boolean);
  protected
    procedure DrawRoundRectGDIP(const R: TRect; const Canvas: TCanvas);
    procedure DrawRectangleGDIP(const R: TRect; const Canvas: TCanvas);
    procedure DrawRoundRect(const R: TRect; const Canvas: TCanvas);
    procedure DrawRectangle(const R: TRect; const Canvas: TCanvas);
  public
    constructor Create(AOwner: TComponent); override;
  
    function CalculateBalloonRect(const R: TRect; const UR: TRect; const DR: TRect; var Words: TWordInfoList;
      var Lines: TLineInfoList; const Canvas: TCanvas) : TRect; override;
    procedure DrawBalloon(const R: TRect; const Canvas: TCanvas); override;
  published
    // Events
    property OnChange;

    //
    property UseGDIPlus: Boolean read FUseGDIPlus write SetUseGDIPlus default True;

    // Properties (Balloon)
    property Shape;
    property Borders;
    property BorderRadius;
    property MaxWidth;
    property Color;
    property BorderWidth;
    property BorderColor;
    property Spacing;
    property Font;

    // Properties (Date)
    property DateFormat;
    property CustomDateFormat;
    property DateFont;
    property DateCursor;
    property DateShowThreshold;

    // Properties (Username)
    property UsernameFormat;
    property UsernameFont;
    property UsernameCursor;
  end;

implementation

uses GdiPlus;

{*******************************************************}
{             Chat Balloon Base Component               }
{*******************************************************}
constructor TChatBalloonBase.Create(AOwner: TComponent);
begin
  // Create
  inherited Create(AOwner);

  // Default Settings
  FShape         := bsRectangle;
  FBorders       := [bbTopLeft, bbTopRight, bbBottomLeft, bbBottomRight];
  FBorderRadius  := 10;
  FMaxWidthP     := 80;
  FColor         := clWhite;
  FBorderWidth   := 1;
  FBorderColor   := clGray;
  FSpacing       := 10;
  FFont          := TFont.Create;
  FFont.OnChange := OnFontChange;

  // Properties (Date)
  FDateFormat        := dfTimeShort;
  FCustomDateFormat  := '';
  FDateFont          := TFont.Create;
  FDateFont.OnChange := OnDateFontChange;
  FDateCursor        := crDefault;
  FDateShowThreshold := 720;

  // Properties (Username)
  FUsernameFormat        := unFullname;
  FUsernameFont          := TFont.Create;
  FUsernameFont.OnChange := OnUsernameFontChange;
  FUsernameCursor        := crDefault;

  // Properties (Link)
  FNormalLink := TChatRichTextLinkFont.Create;
  FNormalLink.OnChange := OnNormalLinkChange;
  FNormalLink.Color := clHighlight;
  FActiveLink := TChatRichTextLinkFont.Create;
  FActiveLink.OnChange := OnActiveLinkChange;
  FActiveLink.Color := clHighlight;
  FActiveLink.Style := [fsUnderline];
end;

destructor TChatBalloonBase.Destroy;
begin
  // Free Fonts
  FFont.Free;
  FDateFont.Free;
  FUsernameFont.Free;

  // Free Links
  FNormalLink.Free;
  FActiveLink.Free;

  // Free
  inherited Destroy;
end;

procedure TChatBalloonBase.OnFontChange(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TChatBalloonBase.OnDateFontChange(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TChatBalloonBase.OnUsernameFontChange(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TChatBalloonBase.OnNormalLinkChange(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TChatBalloonBase.OnActiveLinkChange(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TChatBalloonBase.SetShape(const S: TChatBalloonShape);
begin
  if Shape <> S then
  begin
    FShape := S;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetBorders(const B: TChatBaloonBorders);
begin
  if Borders <> B then
  begin
    FBorders := B;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetBorderRadius(const I: Integer);
begin
  if (BorderRadius <> I) and (I > 0) then
  begin
    FBorderRadius := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetMaxWidthP(const I: Integer);
begin
  if (MaxWidth <> I) and (I >= 50) then
  begin
    FMaxWidthP := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetColor(const C: TColor);
begin
  if Color <> C then
  begin
    FColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetBorderWidth(const I: Integer);
begin
  if (BorderWidth <> I) and (I >= 0) then
  begin
    FBorderWidth := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetBorderColor(const C: TColor);
begin
  if BorderColor <> C then
  begin
    FBorderColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetSpacing(const I: Integer);
begin
  if (Spacing <> I) and (I >= 0) then
  begin
    FSpacing := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetFont(const F: TFont);
begin
  FFont.Assign(F);
end;

procedure TChatBalloonBase.SetDateFormat(const F: TChatBalloonDateFormat);
begin
  if DateFormat <> F then
  begin
    FDateFormat := F;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetCustomDateFormat(const S: string);
begin
  if CustomDateFormat <> S then
  begin
    FCustomDateFormat := S;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetDateFont(const F: TFont);
begin
  FDateFont.Assign(F);
end;

procedure TChatBalloonBase.SetDateCursor(const C: TCursor);
begin
  if DateCursor <> C then
  begin
    FDateCursor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetDateShowThreshold(const I: Integer);
begin
  if DateShowThreshold <> I then
  begin
    FDateShowThreshold := I;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetUsernameFormat(const F: TChatBalloonUsernameFormat);
begin
  if UsernameFormat <> F then
  begin
    FUsernameFormat := F;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetUsernameFont(const F: TFont);
begin
  FUsernameFont.Assign(F)
end;

procedure TChatBalloonBase.SetUsernameCursor(const C: TCursor);
begin
  if UsernameCursor <> C then
  begin
    FUsernameCursor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatBalloonBase.SetNormalLink(const L: TChatRichTextLinkFont);
begin
  FNormalLink.Assign(L);
end;

procedure TChatBalloonBase.SetActiveLink(const L: TChatRichTextLinkFont);
begin
  FActiveLink.Assign(L);
end;

procedure TChatBalloonBase.Assign(Source: TPersistent);
begin
  if (Source <> nil) and (Source is TChatBalloonBase) then
  begin
    FShape        := (Source as TChatBalloonBase).Shape;
    FBorders      := (Source as TChatBalloonBase).Borders;
    FBorderRadius := (Source as TChatBalloonBase).BorderRadius;
    FMaxWidthP    := (Source as TChatBalloonBase).MaxWidth;
    FColor        := (Source as TChatBalloonBase).Color;
    FBorderWidth  := (Source as TChatBalloonBase).BorderWidth;
    FBorderColor  := (Source as TChatBalloonBase).BorderColor;
    FFont.Assign((Source as TChatBalloonBase).Font);

    // Properties (Date)
    FDateFormat        := (Source as TChatBalloonBase).DateFormat;
    FCustomDateFormat  := (Source as TChatBalloonBase).CustomDateFormat;
    FDateFont.Assign((Source as TChatBalloonBase).DateFont);
    FDateCursor        := (Source as TChatBalloonBase).DateCursor;
    FDateShowThreshold := (Source as TChatBalloonBase).DateShowThreshold;

    // Properties (Username)
    FUsernameFormat    := (Source as TChatBalloonBase).UsernameFormat;
    FUsernameFont.Assign((Source as TChatBalloonBase).UsernameFont);
    FUsernameCursor    := (Source as TChatBalloonBase).UsernameCursor;

    // Properties (Link):
    FNormalLink.Assign((Source as TChatBalloonBase).LinkNormal);
    FActiveLink.Assign((Source as TChatBalloonBase).LinkActive);
  end else
    inherited;
end;

function TChatBalloonBase.TextSize(const Text: string; const Font: TFont; const Canvas: TCanvas) : TRect;
begin
  with Canvas do
  begin
    Font.Assign(Font);
    Result := TRect.Create(0, 0, TextWidth(Text), TextHeight(Text));
  end;
end;

{*******************************************************}
{                  Simple Chat Balloon                  }
{*******************************************************}
constructor TSimpleChatBalloon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Use GDI+ by default
  FUseGDIPlus := True;
end;

procedure TSimpleChatBalloon.SetUseGDIPlus(const B: Boolean);
begin
  if B <> UseGDIPlus then
  begin
    FUseGDIPlus := B;
    if Assigned(OnChange) then OnChange(Self);
  end;
end;

procedure TSimpleChatBalloon.DrawRoundRectGDIP(const R: TRect; const Canvas: TCanvas);
var
  Pen      : IGPPen;
  Brush    : IGPSolidBrush;
  Path     : IGPGraphicsPath;
  Graphics : IGPGraphics;
begin
  Graphics := TGPGraphics.Create(Canvas.Handle);
  Graphics.SmoothingMode := SmoothingModeHighQuality;
  Path := TGPGraphicsPath.Create;
  // Top Left
  if bbTopLeft in Borders then
    Path.AddArc(R.Left, R.Top, BorderRadius, BorderRadius, 180, 90)
  else
    Path.AddArc(R.Left, R.Top, 0.1, 0.1, 180, 90);
  // Top Right
  if bbTopRight in Borders then
    Path.AddArc(R.Right - BorderRadius, R.Top, BorderRadius, BorderRadius, 270, 90)
  else
    Path.AddArc(R.Right, R.Top, 0.1, 0.1, 270, 90);
  // Bottom Right
  if bbBottomRight in Borders then
    Path.AddArc(R.Right - BorderRadius, R.Bottom - BorderRadius, BorderRadius, BorderRadius, 0, 90)
  else
    Path.AddArc(R.Right, R.Bottom, 0.1, 0.1, 0, 90);
  // Bottom Left
  if bbBottomLeft in Borders then
    Path.AddArc(R.Left, R.Bottom - BorderRadius, BorderRadius, BorderRadius, 90, 90)
  else
    Path.AddArc(R.Left, R.Bottom, 0.1, 0.1, 90, 90);
  Path.CloseFigure;
  Brush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Color));
  Graphics.FillPath(Brush, Path);
  if (BorderColor <> clNone) and (BorderWidth > 0) then
  begin
    Pen := TGPPen.Create(TGPColor.CreateFromColorRef(BorderColor));
    Pen.Width := BorderWidth;
    Graphics.DrawPath(Pen, Path);
  end;
end;

procedure TSimpleChatBalloon.DrawRectangleGDIP(const R: TRect; const Canvas: TCanvas);
var
  Pen      : IGPPen;
  Brush    : IGPSolidBrush;
  Graphics : IGPGraphics;
begin
  Graphics := TGPGraphics.Create(Canvas.Handle);
  Graphics.SmoothingMode := SmoothingModeHighQuality;
  Brush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(Color));
  Graphics.FillRectangle(Brush, TGPRect.Create(R));
  if (BorderColor <> clNone) and (BorderWidth > 0) then
  begin
    Pen := TGPPen.Create(TGPColor.CreateFromColorRef(BorderColor));
    Pen.Width := BorderWidth;
    Graphics.DrawRectangle(Pen, TGPRect.Create(R));
  end;
end;

procedure TSimpleChatBalloon.DrawRoundRect(const R: TRect; const Canvas: TCanvas);
begin
  with Canvas do
  begin
    Brush.Color := Color;
    Brush.Style := bsSolid;
    if (BorderColor <> clNone) and (BorderWidth > 0) then
    begin
      Pen.Color := BorderColor;
      Pen.Width := BorderWidth;
      Pen.Style := psSolid; 
    end else
    begin
      Pen.Style := psClear;
    end;
    RoundRect(R, BorderRadius, BorderRadius);
  end;
end;

procedure TSimpleChatBalloon.DrawRectangle(const R: TRect; const Canvas: TCanvas);
begin
  with Canvas do
  begin
    Brush.Color := Color;
    Brush.Style := bsSolid;
    if (BorderColor <> clNone) and (BorderWidth > 0) then
    begin
      Pen.Color := BorderColor;
      Pen.Width := BorderWidth;
      Pen.Style := psSolid; 
    end else
    begin
      Pen.Style := psClear;
    end;
    Rectangle(R);
  end;
end;

function TSimpleChatBalloon.CalculateBalloonRect(const R: TRect; const UR: TRect; 
  const DR: TRect; var Words: TWordInfoList; var Lines: TLineInfoList; const Canvas: TCanvas) : TRect;
var
  TR : TRect;
  S  : TSize;
begin
  S := TSize.Create(18, 18);
  // Calculate Text Rect
  Canvas.Font.Assign(Self.Font);
  TR := TRect.Create(R.Left + Spacing, R.Top + Spacing, R.Right - Spacing, R.Bottom - Spacing);
  TR := BuildLines(Words, Lines, S, TR, True, Canvas);
  // Calculate output rect
  Result := TRect.Create(
    R.Left,
    R.Top,
    R.Left + TR.Width + (Spacing * 2),
    R.Top + Spacing + UR.Height + Spacing + TR.Height + Spacing
  );
end;

procedure TSimpleChatBalloon.DrawBalloon(const R: TRect; const Canvas: TCanvas);
begin
  // Draw Balloon
  case Shape of
    // Rectangle
    bsRectangle: if useGDIPlus then DrawRectangleGDIP(R, Canvas) else DrawRectangle(R, Canvas);
    // Rounded Rectangle
    bsRoundRect: if useGDIPlus then DrawRoundRectGDIP(R, Canvas) else DrawRoundRect(R, Canvas);
  end;
end;

end.
