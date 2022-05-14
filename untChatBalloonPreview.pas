unit untChatBalloonPreview;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, untChatBalloon,
  untEmojiList, untChatRichText;

type
  TfrmChatBalloonPreview = class(TForm)
    Panel1: TPanel;
    btnClose: TButton;
    pnlPreview: TPanel;
    pbPreview: TPaintBox;
    EmojiList: TEmojiList;
    procedure pbPreviewPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure pbPreviewMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
    FBuffer       : TBitmap;
    FRedrawBuffer : Boolean;
    FChatBalloon  : TChatBalloonBase;

    Words           : TWordInfoList;
    Lines           : TLineInfoList;
    FHoverLinkIndex : Integer;
    UsernameRect    : TRect;
    DateRect        : TRect;
  public
    { Public declarations }
    property ChatBalloon: TChatBalloonBase read FChatBalloon write FChatBalloon;
  end;

var
  frmChatBalloonPreview: TfrmChatBalloonPreview;

const
  DemoUsername = 'JDoe01';
  DemoFullname = 'John Doe';
  DemoDate     = 44694.00;
  DemoText     = '<b>Lorem ipsum dolor sit amet</b>, consectetur <e>:D</e> adipiscing elit, <i>sed do eiusmod tempor <e>:)</e> incididunt ut labore et dolore magna aliqua.</i> Ut enim ad <e>clown</e> minim veniam, <a>quis nostrud exercitation</a>. ' +
                 'Ullamco laboris <e>ghost</e> nisi ut aliquip ex ea commodo consequat';

implementation

{$R *.dfm}

uses Math;

procedure TfrmChatBalloonPreview.FormCreate(Sender: TObject);
begin
  FBuffer         := TBitmap.Create;
  FRedrawBuffer   := True;
  FHoverLinkIndex := -1;
  Words := TWordInfoList.Create(True);
  Lines := TLineInfoList.Create(True);
  ParseText(DemoText, Words);
end;

procedure TfrmChatBalloonPreview.pbPreviewPaint(Sender: TObject);
const
  GridSize = 10;
  GridCol1 = clBtnFace;
  GridCol2 = $00DBE0E3;

  procedure DrawBackground;
  var
    I, X : Integer;
  begin
    FBuffer.SetSize(pbPreview.Width, pbPreview.Height);
    with FBuffer.Canvas do
    begin
      for I := 0 to Ceil(FBuffer.Height / GridSize) do
      begin
        X := 0;
        if Odd(I) then Brush.Color := GridCol1 else Brush.Color := GridCol2;
        repeat
          FillRect(Rect(X, I * GridSize, X + GridSize, (I +1) * GridSize));
          if Brush.Color = GridCol1 then Brush.Color := GridCol2 else Brush.Color := GridCol1;
          Inc(X, GridSize);
        until (X > FBuffer.Width);
      end;
    end;
  end;

  procedure DrawBalloonPreview;
  var
    BR : TRect;
    TR : TRect;
    S  : TSize;
    TU : string;
    TD : string;
    A  : Integer;
    B  : Integer;
    X  : Integer;
    WI : TWordInfo;
    PX : Integer;
    PY : Integer;
    UR : TRect;
    DR : TRect;
  begin
    S := TSize.Create(18, 18);
    // Draw a simple Chat Bubble (Balloon) with GDI+
    with FBuffer.Canvas do
    begin

      // Username rect
      Font.Assign(ChatBalloon.UsernameFont);
      case ChatBalloon.UsernameFormat of
        unUsername: UR := ChatBalloon.TextSize(DemoUsername, ChatBalloon.UsernameFont, FBuffer.Canvas);
        unFullname: UR := ChatBalloon.TextSize(DemoFullname, ChatBalloon.UsernameFont, FBuffer.Canvas);
      end;

      // Date rect
      Font.Assign(ChatBalloon.DateFont);
      case ChatBalloon.DateFormat of
        dfDateTimeLong  : DR := ChatBalloon.TextSize(FormatDateTime('ddddd hh:mm:ss', TDateTime(DemoDate)), ChatBalloon.DateFont, FBuffer.Canvas);
        dfDateTimeShort : DR := ChatBalloon.TextSize(FormatDateTime('dd/mm/yyyy hh:mm', TDateTime(DemoDate)), ChatBalloon.DateFont, FBuffer.Canvas);
        dtDateLong      : DR := ChatBalloon.TextSize(FormatDateTime('dddddd', TDateTime(DemoDate)), ChatBalloon.DateFont, FBuffer.Canvas);
        dfDateShort     : DR := ChatBalloon.TextSize(FormatDateTime('dd/mm/yyyy', TDateTime(DemoDate)), ChatBalloon.DateFont, FBuffer.Canvas);
        dfTimeLong      : DR := ChatBalloon.TextSize(FormatDateTime('hh:mm:ss', TDateTime(DemoDate)), ChatBalloon.DateFont, FBuffer.Canvas);
        dfTimeShort     : DR := ChatBalloon.TextSize(FormatDateTime('hh:mm', TDateTime(DemoDate)), ChatBalloon.DateFont, FBuffer.Canvas);
        dfCustom        : DR := ChatBalloon.TextSize(FormatDateTime(ChatBalloon.CustomDateFormat, TDateTime(DemoDate)), ChatBalloon.DateFont, FBuffer.Canvas);
      end;

      // Calculate Balloon Rect
      BR := ChatBalloon.CalculateBalloonRect(TRect.Create(20, 20, pbPreview.Width - 20, pbPreview.Height - 20), UR, DR, Words, Lines, FBuffer.Canvas);

      // Draw Balloon
      ChatBalloon.DrawBalloon(BR, FBuffer.Canvas);

      // Draw username
      Brush.Style := bsClear;
      case ChatBalloon.UsernameFormat of
        unUsername: TU := DemoUsername;
        unFullname: TU := DemoFullname;
      end;
      Font.Assign(ChatBalloon.UsernameFont);
      TextOut(BR.Left + ChatBalloon.Spacing, BR.Top + ChatBalloon.Spacing, TU);
      UsernameRect := TRect.Create(BR.Left + ChatBalloon.Spacing, BR.Top + ChatBalloon.Spacing, BR.Left + ChatBalloon.Spacing + UR.Width, BR.Top + ChatBalloon.Spacing + UR.Height);

      // Draw Date
      case ChatBalloon.DateFormat of
        dfDateTimeLong  : TD := FormatDateTime('ddddd hh:mm:ss', TDateTime(DemoDate));
        dfDateTimeShort : TD := FormatDateTime('dd/mm/yyyy hh:mm', TDateTime(DemoDate));
        dtDateLong      : TD := FormatDateTime('dddddd', TDateTime(DemoDate));
        dfDateShort     : TD := FormatDateTime('dd/mm/yyyy', TDateTime(DemoDate));
        dfTimeLong      : TD := FormatDateTime('hh:mm:ss', TDateTime(DemoDate));
        dfTimeShort     : TD := FormatDateTime('hh:mm', TDateTime(DemoDate));
        dfCustom        : TD := FormatDateTime(ChatBalloon.CustomDateFormat, TDateTime(DemoDate));
      end;
      Font.Assign(ChatBalloon.DateFont);
      DateRect := DR;

      // Draw Chat Rich Text
      MoveTo(BR.Left + ChatBalloon.Spacing, BR.Top + ChatBalloon.Spacing + UR.Height + ChatBalloon.Spacing);
      Font.Assign(Self.Font);
      for A := 0 to Lines.Count -1 do
      begin
        // Loop over words in line
        for B := 0 to Lines.Items[A].Words.Count -1 do
        begin
          //
          WI := Lines.Items[A].Words.Items[B];

          // Assign Font Style
          Font.Style := WI.FontStyle;

          // Emoji
          if (WI is TEmojiInfo) then
          begin
            X := PenPos.X;
            WI.Rect := Rect(PenPos.X, PenPos.Y, PenPos.X + WI.WordWidth, PenPos.Y + WI.WordHeight);
            EmojiList.DrawEmoji((WI as TEmojiInfo).Emoji, FBuffer.Canvas, PenPos.X, PenPos.Y);
            MoveTo(X + WI.WordWidth, PenPos.Y);
          end else

          // Link
          if (WI is TLinkInfo) then
          begin
            // Hovered link
            if (WI as TLinkInfo).LinkIndex = FHoverLinkIndex then
            begin
              Font.Color := ChatBalloon.LinkActive.Color;
              Font.Style := ChatBalloon.LinkActive.Style;
            end else
            // Normal link
            begin
              Font.Color := ChatBalloon.LinkNormal.Color;
              Font.Style := ChatBalloon.LinkNormal.Style;
            end;
            PY := PenPos.Y + WI.YOffset;
            WI.Rect := Rect(PenPos.X, PY, PenPos.X + WI.WordWidth, PY + WI.WordHeight);
            PY := PenPos.Y;
            TextOut(PenPos.X, WI.Rect.Top, WI.Text);
            PX := PenPos.X;
            MoveTo(PX, PY);
          end else

          // Text
          begin
            Font.Color := Self.Font.Color;
            PY := PenPos.Y + WI.YOffset;
            WI.Rect := Rect(PenPos.X, PY, PenPos.X + WI.WordWidth, PY + WI.WordHeight);
            PY := PenPos.Y;
            TextOut(PenPos.X, WI.Rect.Top, WI.Text);
            PX := PenPos.X;
            MoveTo(PX, PY);
          end;
        end;

        // Update position
        PX := BR.Left + ChatBalloon.Spacing;
        PY := PenPos.Y + Lines.Items[A].LineHeight;
        MoveTo(PX, PY);
      end;
    end;
  end;

begin
  with pbPreview.Canvas do
  begin
    if FRedrawBuffer then
    begin
      FRedrawBuffer := False;
      DrawBackground;
      DrawBalloonPreview;
    end;
    Draw(0, 0, FBuffer);
  end;
end;

procedure TfrmChatBalloonPreview.pbPreviewMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
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
    C := crHandpoint;
    Break;
  end;
  if PtInRect(UsernameRect, TPoint.Create(X, Y)) then
  begin
    C := ChatBalloon.UsernameCursor;
  end;
  if PtInRect(DateRect, TPoint.Create(X, Y)) then
  begin
    C := ChatBalloon.DateCursor;
  end;
  if (C <> pbPreview.Cursor) then
  begin
    pbPreview.Cursor := C;
  end;
  if (M <> FHoverLinkIndex) then
  begin
    FHoverLinkIndex := M;
    FRedrawBuffer := True;
    pbPreview.Invalidate;
  end;
  inherited;
end;

procedure TfrmChatBalloonPreview.FormDestroy(Sender: TObject);
begin
  FBuffer.Free;
  Words.Free;
  Lines.Free;
end;

procedure TfrmChatBalloonPreview.FormResize(Sender: TObject);
begin
  FRedrawBuffer := True;
end;

end.
