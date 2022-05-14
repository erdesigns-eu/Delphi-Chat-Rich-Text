{*******************************************************}
{                                                       }
{                 untChatRichText.pas                   }
{               Author: Ernst Reidinga                  }
{                                                       }
{     Parse and draw Rich Text for Chat Components.     }
{              Note: Uses html like tags.               }
{                                                       }
{*******************************************************}

unit untChatRichText;

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
  untEmojiList;

{*******************************************************}
{                   Tag Token Record                    }
{*******************************************************}
type
  TTagToken = record
    Kind  : Integer;
    Text  : WideString;
    Value : WideString;
  end;

{*******************************************************}
{                   Character Info                      }
{*******************************************************}
type
  TCharInfo = class
  private
    FCharacter  : WideString;
    FRect       : TRect;
    FCharHeight : Integer;
    FCharWidth  : Integer;
  public
    constructor Create(const Character: WideString; const Width: Integer; const Height: Integer);

    property Character: WideString read FCharacter write FCharacter;
    property Rect: TRect read FRect write FRect;
    property CharHeight: Integer read FCharHeight write FCharHeight;
    property CharWidth: Integer read FCharWidth write FCharWidth;
  end;

{*******************************************************}
{                 Character Info List                   }
{*******************************************************}
type
  TCharInfoList = TObjectList<TCharInfo>;

{*******************************************************}
{                 Word Info Link Type                   }
{*******************************************************}
type
  TWordInfoLinkType = (ltURL, ltEmail, ltPhone, ltUnknown);

{*******************************************************}
{                      Word Info                        }
{*******************************************************}
type
  TWordInfo = class
  private
    FText       : WideString;
    FRect       : TRect;
    FFontStyle  : TFontStyles;
    FWordHeight : Integer;
    FWordWidth  : Integer;
    FYOffset    : Integer;
    FCharacters : TCharInfoList;
  public
    constructor Create(const Text: WideString; const FontStyle: TFontStyles);
    destructor Destroy; override;

    property Text: WideString read FText write FText;
    property Rect: TRect read FRect write FRect;
    property FontStyle: TFontStyles read FFontStyle write FFontStyle;
    property WordHeight: Integer read FWordHeight write FWordHeight;
    property WordWidth: Integer read FWordWidth write FWordWidth;
    property YOffset: Integer read FYOffset write FYOffset;
    property Characters: TCharInfoList read FCharacters;
  end;

  TLinkInfo = class(TWordInfo)
  private
    FLink      : WideString;
    FLinkType  : TWordInfoLinkType;
    FLinkIndex : Integer;
    FMouseOver : Boolean;
  public
    constructor Create(const Text: WideString; const Link: WideString; const LinkType: TWordInfoLinkType); virtual;

    property Link: WideString read FLink write FLink;
    property LinkType: TWordInfoLinkType read FLinkType write FLinkType;
    property LinkIndex: Integer read FLinkIndex write FLinkIndex;
    property MouseOver: Boolean read FMouseOver write FMouseOver;
  end;

  TEmojiInfo = class(TWordInfo)
  private
    FEmoji : WideString;
  public
    constructor Create(const Text: WideString; const FontStyle: TFontStyles); virtual;

    property Emoji: WideString read FEmoji write FEmoji;
  end;

  TSpaceInfo = class(TWordInfo)
  end;

  TBreakInfo = class(TWordInfo)
  end;

{*******************************************************}
{                   Word Info List                      }
{*******************************************************}
type
  TWordInfoList = TObjectList<TWordInfo>;

{*******************************************************}
{                      Line Info                        }
{*******************************************************}
type
  TLineInfo = class
  private
    FWords      : TWordInfoList;
    FLineWidth  : Integer;
    FLineHeight : Integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    property Words: TWordInfoList read FWords;
    property LineWidth: Integer read FLineWidth write FLineWidth;
    property LineHeight: Integer read FLineHeight write FLineHeight;
  end;

{*******************************************************}
{                   Line Info List                      }
{*******************************************************}
type
  TLineInfoList = TObjectList<TLineInfo>;

{*******************************************************}
{                Chat Rich Text String                  }
{*******************************************************}
type
  TChatRichTextString = type string;

{*******************************************************}
{              Chat Rich Text Base Control              }
{*******************************************************}
type
  TChatRichTextBaseControl = class(TCustomControl)
  private
    // Properties
    FEmojiList   : TEmojiList;

    // Used for Drawing
    FBuffer      : TBitmap;
    FUpdateRect  : TRect;

    // Property Setters
    procedure SetEmojiList(const L: TEmojiList);

    // Events
    procedure OnEmojiListChange(Sender: TObject);

    // Catch messages
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Loaded; override;

    // This procedure needs to be implemented!
    procedure PaintBuffer; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Assign
    procedure Assign(Source: TPersistent); override;

    // Build lines from words, and measure output rect
    function MeasureRichTextRect(var Words: TWordInfoList; var Lines: TLineInfoList; const R: TRect; const BuildCharacters: Boolean) : TRect;

    // Properties
    property UpdateRect: TRect read FUpdateRect;
    property Buffer: TBitmap read FBuffer;
  published
    // Properties
    property EmojiList: TEmojiList read FEmojiList write SetEmojiList;
  end;

{*******************************************************}
{               Chat Rich Text Link Font                }
{*******************************************************}
type
  TChatRichTextLinkFont = class(TPersistent)
  private
    // Events
    FOnChange : TNotifyEvent;

    // Properties
    FColor : TColor;
    FStyle : TFontStyles;

    // Property Setters
    procedure SetColor(const C: TColor);
    procedure SetStyle(const S: TFontStyles);
  public
    procedure Assign(Source: TPersistent); override;
  published
    // Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    // Properties
    property Color: TColor read FColor write SetColor;
    property Style: TFontStyles read FStyle write SetStyle;
  end;

{*******************************************************}
{               Chat Rich Text Link Event               }
{*******************************************************}
type
  TChatRichTextLinkEvent = procedure(Sender: TObject; LinkIndex: Integer; LinkType: TWordInfoLinkType; Link: string) of object;

{*******************************************************}
{                   Common Constantes                   }
{*******************************************************}
const
  DummyChar       : WideChar   = 'a';
  EmptyChar       : WideChar   = #0;
  EmptyString     : WideString = '';
  EmptyValue      : Integer    = 0;
  EntityStartChar : WideChar   = '&';
  EntityEndChar   : WideChar   = ';';
  OpenTagChar     : WideChar   = '<';
  CloseTagChar    : WideChar   = '>';
  SpaceChar       : WideChar   = ' ';
  TabSpaces       : Integer    = 4;

const
  Space           : TSysCharSet = [' ', #9, #10, #13];
  WhiteSpace      : TSysCharSet = [' ', #9];
  LineBreak       : TSysCharSet = [#10, #13];

const
  EmojiWidth  : Integer = 18;
  EmojiHeight : Integer = 18;

{*******************************************************}
{                HTML Tag Token Kinds                   }
{*******************************************************}
const
  TOKEN_UNKNOWN    = 0;  // Unknown
  TOKEN_TEXT       = 1;  // Text
  TOKEN_A          = 2;  // Link
  TOKEN_B_ON       = 4;  // Bold On
  TOKEN_B_OFF      = 5;  // Bold Off
  TOKEN_I_ON       = 6;  // Italic On
  TOKEN_I_OFF      = 7;  // Italic Off
  TOKEN_U_ON       = 8;  // Underline On
  TOKEN_U_OFF      = 9;  // Underline Off
  TOKEN_S_ON       = 10; // Strikeout On
  TOKEN_S_OFF      = 11; // Strikeout Off
  TOKEN_EMOJI      = 12; // Emoji
  TOKEN_SPACE      = 14; // Space
  TOKEN_LINE_BREAK = 15; // Line Break

{*******************************************************}
{                 HTML Tag Token States                 }
{*******************************************************}
const
  STATE_START           = 0;   // Start
  STATE_TAG_START       = 1;   // Tag Start
  STATE_TAG_END         = 2;   // Tag End
  STATE_TAG_A           = 3;   // Link
  STATE_TAG_B           = 4;   // Bold
  STATE_TAG_I           = 5;   // Italic
  STATE_TAG_U           = 6;   // Underline
  STATE_TAG_S           = 7;   // Strikeout
  STATE_TAG_B_END       = 8;   // Bold End
  STATE_TAG_I_END       = 9;   // Italic End
  STATE_TAG_U_END       = 10;  // Underline End
  STATE_TAG_S_END       = 11;  // Strikeout End
  STATE_TAG_EMOJI       = 12;  // Emoji
  STATE_TAG_SPACE       = 13;  // Space
  STATE_TAG_LINE_BREAK  = 14;  // Line Break

// Replace HTML entities with Character
function ReplaceHTMLEntities(const Str: WideString) : WideString;
// Find tokens - used in Parsing
function GetToken(const Line: WideString; var Index: Integer; out Token: TTagToken) : Boolean;
// Parse input text to a list of words
procedure ParseText(const Text: WideString; var Words: TWordInfoList);
// Build lines and measure the output Rect
function BuildLines(var Words: TWordInfoList; var Lines: TLineInfoList; const EmojiSize: TSize;
  const R: TRect; const BuildCharacters: Boolean; const Canvas: TCanvas) : TRect; overload;

implementation

{*******************************************************}
{         Replace HTML Entities with Character          }
{*******************************************************}
function ReplaceHTMLEntities(const Str: WideString) : WideString;

  // Unicode tag to WideChar
  function UTagToStr(const R: WideString; const Tag: WideString) : WideString;
  begin
    Result := R + WideString(WideChar(StrToInt('$' + Tag)));
  end;

var
  I, P, X   : Integer;
  C, E      : WideChar;
  StrLength : Integer;
  Entity    : WideString;
begin
  // Set string length
  StrLength := Length(Str);
  // Find "&" which indicates start of HTML Entity
  P := Pos(EntityStartChar, Str);
  // If start of HTML Entity is not found, just return the string.
  if (P = 0) then
    Result := Str
  else
  // Found start of HTML Entity, so start processing.
  begin
    // Add text before entity to the resulting string.
    Result := Copy(Str, 1, P - 1);
    // Set entity start index
    I := P;
    // Loop
    while I <= StrLength do
    begin
      // Set Char
      C := Str[I];
      // Check if current character is Entity start character.
      if C = EntityStartChar then
      begin
        // Set Character index
        X := I + 1;
        // Find Entity value
        while X <= StrLength do
        begin
          // Entity value character
          E := Str[X];
          // Entity end character
          if E = EntityEndChar then
          begin
            Entity := Lowercase(Copy(Str, I +1, X - I -1));
            // Entity value to character
            if Entity <> '' then
            begin
              case Entity[1] of

                'a':
                begin
                  // Acute
                  if Entity = 'acute' then Result := UTagToStr(Result, '00B4');
                  // Ampersand
                  if Entity = 'amp' then Result := UTagToStr(Result, '0026');
                  // Apostrophe (single quotation mark)
                  if Entity = 'apos' then Result := UTagToStr(Result, '0027');
                end;

                'b':
                begin
                  // Bullet
                  if Entity = 'bull' then Result := UTagToStr(Result, '2022');
                  // Broken vertical Bar
                  if Entity = 'brvbar' then Result := UTagToStr(Result, '00A6');
                  // Double low-9 quotation mark
                  if Entity = 'bdquo' then Result := UTagToStr(Result, '201E');
                  //
                end;

                'c':
                begin
                  // Cent
                  if Entity = 'cent' then Result := UTagToStr(Result, '00A2');
                  // Copyright
                  if Entity = 'copy' then Result := UTagToStr(Result, '00A9');
                end;

                'd':
                begin
                  // Degree
                  if Entity = 'deg' then Result := UTagToStr(Result, '00B0');
                  // Divide
                  if Entity = 'divide' then Result := UTagToStr(Result, '00F7');
                end;

                'e':
                begin
                  // Equivalent
                  if Entity = 'equiv' then Result := UTagToStr(Result, '2261');
                  // Euro
                  if Entity = 'euro' then Result := UTagToStr(Result, '20AC');
                end;

                'f':
                begin
                  // Fraction 1/4
                  if Entity = 'frac14' then Result := UTagToStr(Result, '00BC');
                  // Fraction 1/2
                  if Entity = 'frac12' then Result := UTagToStr(Result, '00BD');
                  // Fraction 3/4
                  if Entity = 'frac34' then Result := UTagToStr(Result, '00BE');
                end;

                'g':
                begin
                  // Greater than
                  if Entity = 'gt' then Result := UTagToStr(Result, '003E');
                  // Greater than or equal to
                  if Entity = 'ge' then Result := UTagToStr(Result, '2265');
                end;

                'i':
                begin
                  // Inverted exclamation mark
                  if Entity = 'iexcl' then Result := UTagToStr(Result, '00A1');
                  // Inverted question mark
                  if Entity = 'iquest' then Result := UTagToStr(Result, '00BF');
                  // Infinity
                  if Entity = 'infin' then Result := UTagToStr(Result, '221E');
                end;

                'l':
                begin
                  // Less than
                  if Entity = 'lt' then Result := UTagToStr(Result, '003C');
                  // Left-pointing double angle quotation mark
                  if Entity = 'laquo' then Result := UTagToStr(Result, '00AB');
                  // Low asterisk
                  if Entity = 'lowast' then Result := UTagToStr(Result, '2217');
                  // Less or equal
                  if Entity = 'le' then Result := UTagToStr(Result, '2264');
                  // Left single quotation mark
                  if Entity = 'lsquo' then Result := UTagToStr(Result, '2018');
                  // Left double quotation mark
                  if Entity = 'ldquo' then Result := UTagToStr(Result, '201C');
                  // Single left-pointing angle quotation mark
                  if Entity = 'lsaquo' then Result := UTagToStr(Result, '2039');
                end;

                'm':
                begin
                  // Macron
                  if Entity = 'macr' then Result := UTagToStr(Result, '00AF');
                  // Micro
                  if Entity = 'micro' then Result := UTagToStr(Result, '00B5');
                  // Minus
                  if Entity = 'minus' then Result := UTagToStr(Result, '2212');
                  // MDash
                  if Entity = 'mdash' then Result := UTagToStr(Result, '2014');
                end;

                'n':
                begin
                  // Non breaking space
                  if Entity = 'nbsp' then Result := UTagToStr(Result, '00A0');
                  // Not sign
                  if Entity = 'not' then Result := UTagToStr(Result, '00AC');
                  // Not equal
                  if Entity = 'ne' then Result := UTagToStr(Result, '2260');
                  // Not a subset of
                  if Entity = 'nsub' then Result := UTagToStr(Result, '2284');
                  // Ndash
                  if Entity = 'ndash' then Result := UTagToStr(Result, '2013');
                end;

                'o':
                begin
                  // Feminine ordinal indicator
                  if Entity = 'ordf' then Result := UTagToStr(Result, '00AA');
                  // Masculine ordinal indicator
                  if Entity = 'ordm' then Result := UTagToStr(Result, '00BA');
                  // Overline
                  if Entity = 'oline' then Result := UTagToStr(Result, '203E');
                end;

                'p':
                begin
                  // Per mille sign
                  if Entity = 'permil' then Result := UTagToStr(Result, '2030');
                  // Prime
                  if Entity = 'prime' then Result := UTagToStr(Result, '2032');
                  // Pound
                  if Entity = 'pound' then Result := UTagToStr(Result, '00A3');
                  // Plus-minus sign
                  if Entity = 'plusmn' then Result := UTagToStr(Result, '00B1');
                  // Pilcrow sign
                  if Entity = 'para' then Result := UTagToStr(Result, '00B6');
                end;

                'r':
                begin
                  // Registered sign
                  if Entity = 'reg' then Result := UTagToStr(Result, '00AE');
                  // Right-pointing double angle quotation mark
                  if Entity = 'raquo' then Result := UTagToStr(Result, '00BB');
                  // Square root
                  if Entity = 'radic' then Result := UTagToStr(Result, '221A');
                  // Right single quotation mark
                  if Entity = 'rsquo' then Result := UTagToStr(Result, '2019');
                  // Right double quotation mark
                  if Entity = 'rdquo' then Result := UTagToStr(Result, '201D');
                  // Single right-pointing angle quotation mark
                  if Entity = 'rsaquo' then Result := UTagToStr(Result, '203A');
                end;

                's':
                begin
                  // Section sign
                  if Entity = 'sect' then Result := UTagToStr(Result, '00A7');
                  // Superscript one
                  if Entity = 'sup1' then Result := UTagToStr(Result, '00B9');
                  // Superscript two
                  if Entity = 'sup2' then Result := UTagToStr(Result, '00B2');
                  // Superscript three
                  if Entity = 'sup3' then Result := UTagToStr(Result, '00B3');
                  // N-ary summation
                  if Entity = 'sum' then Result := UTagToStr(Result, '2211');
                  // Tilde operator
                  if Entity = 'sim' then Result := UTagToStr(Result, '223C');
                  // Single low-9 quotation mark
                  if Entity = 'sbquo' then Result := UTagToStr(Result, '201A');
                  // Latin small letter sharp S
                  if Entity = 'szlig' then Result := UTagToStr(Result, '00DF');
                end;

                't':
                begin
                  // Multiplication sign
                  if Entity = 'times' then Result := UTagToStr(Result, '00D7');
                  // Therefore
                  if Entity = 'there4' then Result := UTagToStr(Result, '2234');
                  // Fullwidth tilde
                  if Entity = 'tilde' then Result := UTagToStr(Result, 'FF5E');
                  // Trade Mark sign
                  if Entity = 'trade' then Result := UTagToStr(Result, '2122');
                end;

                'u':
                begin
                  // Diaeresis
                  if Entity = 'uml' then Result := UTagToStr(Result, '00A8');
                end;

                'y':
                begin
                  // Yen sign
                  if Entity = 'yen' then Result := UTagToStr(Result, '00A5');
                end;

              end;
            end;
            I := X;
            Break;
          end else
          // Entity start character
          if E = EntityStartChar then
          begin
            Result := Result + Copy(Str, I, X - I);
            I := X - 1;
            Break;
          end;
          // Increase character position.
          Inc(X);
        end;
        // If no Entity end character is found, return the rest of the string.
        if X > StrLength then
        begin
          Result := Result + Copy(Str, I, StrLength);
          Exit;
        end;
      end else
        // Char is not a Entity start character, so add to resulting string.
        Result := Result + C;
      // Increase position
      Inc(I);
    end;
  end;
end;

{*******************************************************}
{                 Get Token from Line                   }
{*******************************************************}
function GetToken(const Line: WideString; var Index: Integer; out Token: TTagToken) : Boolean;
var
  C          : WideChar;
  P1, P2, X  : Integer;
  State      : Integer;
  StartIndex : Integer;
  LineLength : Integer;
begin
  //
  Token.Kind  := TOKEN_UNKNOWN;
  Token.Text  := EmptyStr;
  Token.Value := EmptyStr;
  //
  State      := STATE_START;
  StartIndex := Index;
  LineLength := Length(Line);
  //
  while True do
  begin

    // Get Character
    if Index <= LineLength then
    begin
      if Integer(Line[Index]) < 256 then
        C := WideChar(Line[Index])
      else
        C := DummyChar;
    end else
    begin
      Result := (Token.Kind <> TOKEN_UNKNOWN);
      if Result then
      begin
        Token.Text := Copy(Line, StartIndex, Index - StartIndex);
        if Token.Kind = TOKEN_TEXT then Token.Text := ReplaceHTMLEntities(Token.Text);
      end;
      Exit;
    end;

    // Case of state
    case State of

      STATE_START:
      begin
        if C = OpenTagChar then
        begin
          if Token.Kind = TOKEN_TEXT then
          begin
            Token.Text := ReplaceHTMLEntities(Copy(Line, StartIndex, Index - StartIndex));
            Exit(True);
          end
          else State := STATE_TAG_START;
        end else
        begin
          if CharInSet(C, Space) then
          begin
            if Token.Kind = TOKEN_TEXT then
            begin
              Token.Text := ReplaceHTMLEntities(Copy(Line, StartIndex, Index - StartIndex));
              Exit(True);
            end else
            begin
              State := STATE_TAG_SPACE;
              Token.Kind := TOKEN_SPACE;
              if CharInSet(C, WhiteSpace) then Token.Text := C else
              if CharInSet(C, LineBreak) then Token.Text := SpaceChar else Token.Text := EmptyString;
            end;
          end else
            Token.Kind := TOKEN_TEXT;
        end;
      end;

      STATE_TAG_SPACE:
      begin
        if CharInSet(C, Space) then
        begin
          if CharInSet(C, WhiteSpace) then Token.Text := Token.Text + C else
          if (C = #10) then Token.Text := Token.Text + SpaceChar;
        end else
          Exit(True);
      end;

      STATE_TAG_START:
      begin
        if CharInSet(C, Space) then State := STATE_TAG_START      else
        if CharInSet(C, ['B', 'b']) then State := STATE_TAG_B     else
        if CharInSet(C, ['I', 'i']) then State := STATE_TAG_I     else
        if CharInSet(C, ['U', 'u']) then State := STATE_TAG_U     else
        if CharInSet(C, ['S', 's']) then State := STATE_TAG_S     else
        if CharInSet(C, ['A', 'a']) then State := STATE_TAG_A     else
        if CharInSet(C, ['E', 'e']) then State := STATE_TAG_EMOJI else
        if C = '/' then State := STATE_TAG_END else
        if C <> '<' then
        begin
          Token.Kind := TOKEN_TEXT;
          State      := STATE_TAG_START;
        end;
      end;

      STATE_TAG_B:
      begin
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_B_ON;
          Inc(Index);
          Exit(True);
        end else
        // If next character is R, this tag is a line break
        if CharInSet(C, ['R', 'r']) then State := STATE_TAG_LINE_BREAK else State := STATE_START;
      end;

      STATE_TAG_LINE_BREAK:
      begin
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_LINE_BREAK;
          Inc(Index);
          Exit(True);
        end else
          State := STATE_START;
      end;

      STATE_TAG_A:
      begin
        if (C = SpaceChar) then
        begin
          Token.Kind := TOKEN_A;
          P1 := Pos('</a>', Lowercase(Line), Index);
          P2 := Pos('>', String(Line), Index);
          if (P1 > 0) and (P2 > 0) then
          begin
            X := Index;
            Inc(P2);
            // Copy link text
            Token.Text := Copy(Line, P2, P1 - P2);
            Index := (P1 + 4);
            // Copy link value
            P1 := Pos('href="', String(Line), X);
            P2 := Pos('"', String(Line), P1 + 6);
            if (P1 > 0) and (P2 > 0) then
            begin
              Inc(P1, 6);
              Token.Value := Copy(Line, P1, P2 - P1);
            end;
          end else Inc(Index);
          Exit(True);
        end else
        if (C = CloseTagChar) then
        begin
          Token.Kind := TOKEN_A;
          P1 := Pos('</a>', Lowercase(Line), Index);
          P2 := Pos('>', String(Line), Index);
          if (P1 > 0) and (P2 > 0) then
          begin
            Inc(P2);
            // Copy link text
            Token.Text := Copy(Line, P2, P1 - P2);
            Index := (P1 + 4);
          end else Inc(Index);
          Exit(True);
        end;
          State := STATE_START;
      end;

      STATE_TAG_I:
      begin
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_I_ON;
          Inc(Index);
          Exit(True);
        end else
          State := STATE_START;
      end;

      STATE_TAG_U:
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_U_ON;
          Inc(Index);
          Exit(True);
        end else
          State := STATE_START;

      STATE_TAG_S:
      begin
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_S_ON;
          Inc(Index);
          Exit(True);
        end else
          State := STATE_START;
      end;

      STATE_TAG_EMOJI:
      begin
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_EMOJI;
          P1 := Pos('</e>', Lowercase(Line), Index);
          P2 := Pos('>', String(Line), Index);
          if (P1 > 0) and (P2 > 0) then
          begin
            Inc(P2);
            Token.Text  := Copy(Line, P2, P1 - P2);
            Token.Value := Token.Text;
            Index := (P1 + 4);
          end else Inc(Index);
          Exit(True);
        end else
          State := STATE_START;
      end;

      STATE_TAG_END:
      begin
        if CharInSet(C, Space)      then State := STATE_TAG_END       else
        if CharInSet(C, ['B', 'b']) then State := STATE_TAG_B_END     else
        if CharInSet(C, ['I', 'i']) then State := STATE_TAG_I_END     else
        if CharInSet(C, ['U', 'u']) then State := STATE_TAG_U_END     else
        if CharInSet(C, ['S', 's']) then State := STATE_TAG_S_END     else
        begin
          Token.Kind := TOKEN_TEXT;
          State      := STATE_START;
        end;
      end;

      STATE_TAG_B_END:
      begin
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_B_OFF;
          Inc(Index);
          Exit(True);
        end else
          State := STATE_START;
      end;

      STATE_TAG_I_END:
      begin
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_I_OFF;
          Inc(Index);
          Exit(True);
        end
        else
          State := STATE_START;
      end;

      STATE_TAG_U_END:
      begin
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_U_OFF;
          Inc(Index);
          Exit(True);
        end else
          State := STATE_START;
      end;

      STATE_TAG_S_END:
      begin
        if C = CloseTagChar then
        begin
          Token.Kind := TOKEN_S_OFF;
          Inc(Index);
          Exit(True);
        end else
          State := STATE_START;
      end;

    end;
    Inc(Index);
  end;
end;

{*******************************************************}
{                 Parse Text to Words                   }
{*******************************************************}
procedure ParseText(const Text: WideString; var Words: TWordInfoList);
const
  HTTP  = 'http:';
  HTTPS = 'https:';
  MAIL  = 'mailto:';
  PHONE = 'tel:';

  function URLType(const Text: WideString) : TWordInfoLinkType;
  begin
    // Default
    Result := ltUnknown;
    // URL
    if (Pos(HTTP, Lowercase(Text)) > 0) or (Pos(HTTPS, Lowercase(Text)) > 0) then
      Result := ltURL
    else
    // Email
    if (Pos(MAIL, Lowercase(Text)) > 0) then
      Result := ltEmail
    else
    // Phone
    if (Pos(PHONE, Lowercase(Text)) > 0) then
      Result := ltPhone;
  end;

  function ExtractURLValue(const Text: WideString) : WideString;
  var
    P, L : Integer;
  begin
    // Default
    Result := Text;
    // URL
    if (Pos(HTTP, Lowercase(Text)) > 0) or (Pos(HTTPS, Lowercase(Text)) > 0) then
    begin
      P := Pos(HTTP, Lowercase(Text));
      if (P = 0) then 
      P := Pos(HTTPS, Lowercase(Text));
      Result := Copy(Text, P, Length(Text));
    end else
    // Email
    if (Pos(MAIL, Lowercase(Text)) > 0) then
    begin
      P := Pos(MAIL, Lowercase(Text));
      L := Length(MAIL);
      Result := Copy(Text, P + L, Length(Text));
    end else
    // Phone
    if (Pos(PHONE, Lowercase(Text)) > 0) then
    begin
      P := Pos(PHONE, Lowercase(Text));
      L := Length(PHONE);
      Result := Copy(Text, P + L, Length(Text));
    end;
  end;

var
  Token     : TTagToken;
  Index     : Integer;
  FontStyle : TFontStyles;
begin
  // Clear list, remove all existing words
  Words.Clear;
  // If text is empty, exit
  if Text = EmptyString then Exit;
  // Start at index 1
  Index := 1;
  // Get tokens
  while GetToken(Text, Index, Token) do
  case Token.Kind of

    TOKEN_TEXT:
    begin
      Words.Add(TWordInfo.Create(Token.Text, FontStyle));
    end;

    TOKEN_A:
    begin
      Words.Add(TLinkInfo.Create(Token.Text, ExtractURLValue(Token.Value), URLType(Token.Value)));
    end;

    TOKEN_B_ON:
    begin
      FontStyle := FontStyle + [fsBold];
    end;

    TOKEN_B_OFF:
    begin
      FontStyle := FontStyle - [fsBold];
    end;

    TOKEN_I_ON:
    begin
      FontStyle := FontStyle + [fsItalic];
    end;

    TOKEN_I_OFF:
    begin
      FontStyle := FontStyle - [fsItalic];
    end;

    TOKEN_U_ON:
    begin
      FontStyle := FontStyle + [fsUnderline];
    end;

    TOKEN_U_OFF:
    begin
      FontStyle := FontStyle - [fsUnderline];
    end;

    TOKEN_S_ON:
    begin
      FontStyle := FontStyle + [fsStrikeOut];
    end;

    TOKEN_S_OFF:
    begin
      FontStyle := FontStyle - [fsStrikeOut];
    end;

    TOKEN_EMOJI:
    begin
      Words.Add(TEmojiInfo.Create(Token.Value, FontStyle));
    end;

    TOKEN_SPACE:
    begin
      Words.Add(TSpaceInfo.Create(Token.Text, FontStyle));
    end;

    TOKEN_LINE_BREAK:
    begin
      Words.Add(TBreakInfo.Create(Token.Text, FontStyle));
    end;

  end;
end;

{*******************************************************}
{         Build Lines from List of Words (GDI)          }
{*******************************************************}
function BuildLines(var Words: TWordInfoList; var Lines: TLineInfoList; const EmojiSize: TSize;
  const R: TRect; const BuildCharacters: Boolean; const Canvas: TCanvas) : TRect;

  function GetSpaces(const Length: Integer) : WideString;
  begin
    FillChar(Result, Length, SpaceChar);
  end;

  function TextHeight(const Text: WideString) : Integer;
  begin
    Result := Canvas.TextHeight(Text);
  end;

  function TextWidth(const Text: WideString) : Integer;
  begin
    Result := Canvas.TextWidth(Text);
  end;

var
  OutputRectWidth  : Integer;
  OutputRectHeight : Integer;
  Word, I          : Integer;
  CurrentLine      : TLineInfo;
  LinkIndex        : Integer;
  Emoji            : TEmojiInfo;
begin
  // Initial Link index starts at zero
  LinkIndex := 0;
  // Clear list of Lines
  Lines.Clear;

  // Set output Rect
  Result := R;

  // Loop over words and measure the size
  for Word := 0 to Words.Count -1 do
  begin
    // Assign Font
    Canvas.Font.Style := Words.Items[Word].FFontStyle;

    // Emoji
    if (Words.Items[Word] is TEmojiInfo) then
    begin
      // Set word height / width
      Words.Items[Word].WordHeight := EmojiSize.Height;
      Words.Items[Word].WordWidth  := EmojiSize.Width;
      if BuildCharacters then
      begin
        Emoji := (Words.Items[Word] as TEmojiInfo);
        Words.Items[Word].Characters.Add(TCharInfo.Create(Emoji.Emoji, TextWidth(Emoji.Emoji), TextHeight(Emoji.Emoji)));
      end;
    end else

    // Link
    if (Words.Items[Word] is TLinkInfo) then
    begin
      // Set word height / width
      Words.Items[Word].WordHeight := TextHeight(Words.Items[Word].Text);
      Words.Items[Word].WordWidth  := TextWidth(Words.Items[Word].Text);
      (Words.Items[Word] as TLinkInfo).LinkIndex := LinkIndex;
      Inc(LinkIndex);
      if BuildCharacters then for I := 1 to Length(Words.Items[Word].Text) do
      Words.Items[Word].Characters.Add(TCharInfo.Create(Words.Items[Word].Text[I], TextWidth(Words.Items[Word].Text[I]), TextHeight(Words.Items[Word].Text[I])));
    end else

    // Space
    if (Words.Items[Word] is TSpaceInfo) then
    begin
      // Set word height / width
      Words.Items[Word].WordHeight := TextHeight(SpaceChar);
      Words.Items[Word].WordWidth  := 0;
      for I := 1 to Length(Words.Items[Word].Text) do
      begin
        if BuildCharacters then
        Words.Items[Word].Characters.Add(TCharInfo.Create(Words.Items[Word].Text[I], TextWidth(Words.Items[Word].Text[I]), TextHeight(Words.Items[Word].Text[I])));
        if Words.Items[Word].Text[I] = SpaceChar then
        begin
          Words.Items[Word].WordWidth := Words.Items[Word].WordWidth + TextWidth(SpaceChar);
        end else
        if Words.Items[Word].Text[I] = #9 then
        begin
          Words.Items[Word].WordWidth := Words.Items[Word].WordWidth + TextWidth(GetSpaces(TabSpaces));
        end;
      end;
    end else

    // LineBreak
    if (Words.Items[Word] is TBreakInfo) then
    begin
      // Set word height / width
      Words.Items[Word].WordHeight := TextHeight(SpaceChar);
      Words.Items[Word].WordWidth  := 0;
      //
      if BuildCharacters then Words.Items[Word].Characters.Add(TCharInfo.Create(#13#10, 0, TextHeight(SpaceChar)));
    end else

    // Text
    begin
      // Set word height / width
      Words.Items[Word].WordHeight := TextHeight(Words.Items[Word].Text);
      Words.Items[Word].WordWidth  := TextWidth(Words.Items[Word].Text);
      if BuildCharacters then for I := 1 to Length(Words.Items[Word].Text) do
      Words.Items[Word].Characters.Add(TCharInfo.Create(Words.Items[Word].Text[I], TextWidth(Words.Items[Word].Text[I]), TextHeight(Words.Items[Word].Text[I])));
    end;
  end;

  // Create Line and add to list of Lines
  if (Words.Count > 0) then
  begin
    CurrentLine := TLineInfo.Create;
    CurrentLine.LineWidth := 0;
    Lines.Add(CurrentLine);
  end;

  // Loop over words, and group per line
  for Word := 0 to Words.Count -1 do
  begin
    // If word type is LineBreak we want a new line
    if (Words.Items[Word].ClassType = TBreakInfo) then
    begin
      // Create new line
      CurrentLine := TLineInfo.Create;
      // Add current line to the List
      Lines.Add(CurrentLine);
      // Add word to this line ? (Do i need this? Its not drawn..)
      CurrentLine.Words.Add(Words.Items[Word]);
    end else
    begin
      // Check if word fits in the target Rect
      if (CurrentLine.LineWidth + Words.Items[Word].WordWidth) <= R.Width then
      begin
        // Add word to this line
        CurrentLine.Words.Add(Words.Items[Word]);
        // Update line width
        CurrentLine.LineWidth := CurrentLine.LineWidth + Words.Items[Word].WordWidth;
      end else
      // Word doesnt fit in this line
      begin
        // Create new line
        CurrentLine := TLineInfo.Create;
        // Add current line to the List
        Lines.Add(CurrentLine);
        // If the word type is not SPACE we want to add to the new line
        if (Words.Items[Word].ClassType <> TSpaceInfo) then
        begin
          // Add word to this line
          CurrentLine.Words.Add(Words.Items[Word]);
          // Update line width
          CurrentLine.LineWidth := CurrentLine.LineWidth + Words.Items[Word].WordWidth;
        end;
      end;
    end;
    // If the word is higher than the current line, update the line height
    if Words.Items[Word].WordHeight > CurrentLine.LineHeight then
    CurrentLine.LineHeight := Words.Items[Word].WordHeight;
  end;

  //
  OutputRectWidth  := 0;
  OutputRectHeight := 0;
  // Loop over lines and measure the size of the output rect
  for I := 0 to Lines.Count -1 do
  begin
    // Set word offset
    for Word := 0 to Lines.Items[I].Words.Count -1 do
    begin
      if Lines.Items[I].Words.Items[Word].WordHeight < Lines.Items[I].LineHeight then
      Lines.Items[I].Words.Items[Word].YOffset := (Lines.Items[I].LineHeight - Lines.Items[I].Words.Items[Word].WordHeight) div 2;
    end;

    // Update output rect width
    if Lines.Items[I].LineWidth > OutputRectWidth then
    OutputRectWidth := Lines.Items[I].LineWidth;
    // Update output rect height
    OutputRectHeight := OutputRectHeight + Lines.Items[I].LineHeight;
  end;

  // Update Rect size
  Result.Width  := OutputRectWidth;
  Result.Height := OutputRectHeight;
end;

{*******************************************************}
{                   Character Info                      }
{*******************************************************}
constructor TCharInfo.Create(const Character: WideString; const Width: Integer; const Height: Integer);
begin
  inherited Create;

  // Settings
  FCharacter  := Character;
  FRect       := TRect.Create(0, 0, 0, 0);
  FCharWidth  := Width;
  FCharHeight := Height;
end;

{*******************************************************}
{                      Word Info                        }
{*******************************************************}
constructor TWordInfo.Create(const Text: WideString; const FontStyle: TFontStyles);
begin
  inherited Create;

  // Settings
  FText      := Text;
  FRect      := TRect.Create(0, 0, 0, 0);
  FFontStyle := FontStyle;
  FYOffset   := 0;

  // Create list of characters
  FCharacters := TCharInfoList.Create(True);
end;

destructor TWordInfo.Destroy;
begin
  // Free list of characters
  FCharacters.Free;

  // Free
  inherited Destroy;
end;

constructor TLinkInfo.Create(const Text: WideString; const Link: WideString; const LinkType: TWordInfoLinkType);
begin
  inherited Create(Text, FontStyle);

  // Settings
  FText     := Text;
  FLink     := Link;
  FLinkType := LinkType;
end;

constructor TEmojiInfo.Create(const Text: WideString; const FontStyle: TFontStyles);
begin
  inherited Create(Text, FontStyle);

  // Set Emoji content
  FEmoji := Text;
  // Set Emoji Size
  FWordWidth  := 20;
  FWordHeight := 20;
end;

{*******************************************************}
{                      Line Info                        }
{*******************************************************}
constructor TLineInfo.Create;
begin
  inherited Create;

  // Create Words List
  FWords := TWordInfoList.Create(False);

  // Default Setting
  FLineWidth  := 0;
  FLineHeight := 0;
end;

destructor TLineInfo.Destroy;
begin
  // Free Words List
  FWords.Free;

  // Free
  inherited Destroy;
end;

{*******************************************************}
{              Chat Rich Text Base Control              }
{*******************************************************}
constructor TChatRichTextBaseControl.Create(AOwner: TComponent);
begin
  // Create
  inherited Create(AOwner);

  // Control Style
  ControlStyle := [csCaptureMouse, csClickEvents, csDoubleClicks];

  // Create Buffer
  FBuffer := TBitmap.Create;
end;

destructor TChatRichTextBaseControl.Destroy;
begin
  // Free Buffer
  FBuffer.Free;

  // Free
  inherited Destroy;
end;

procedure TChatRichTextBaseControl.SetEmojiList(const L: TEmojiList);
begin
  FEmojiList := L;
  if Assigned(FEmojiList) then FEmojiList.OnChange := OnEmojiListChange;
  PaintBuffer;
end;

procedure TChatRichTextBaseControl.OnEmojiListChange(Sender: TObject);
begin
  PaintBuffer;
end;

procedure TChatRichTextBaseControl.WMPaint(var Msg: TWMPaint);
begin
  GetUpdateRect(Handle, FUpdateRect, False);
  inherited;
end;

procedure TChatRichTextBaseControl.WMSize(var Message: TWMSize);
begin
  // Update Buffer size
  FBuffer.SetSize(Width, Height);
  // Repaint Buffer
  PaintBuffer;
  //
  inherited;
end;

procedure TChatRichTextBaseControl.WMEraseBkGnd(var Msg: TWMEraseBkgnd);
begin
  // Draw Buffer to control canvas
  BitBlt(Msg.DC, 0, 0, ClientWidth, ClientHeight, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  Msg.Result := -1;
end;

procedure TChatRichTextBaseControl.Paint;
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

procedure TChatRichTextBaseControl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FEmojiList) then
  begin
    // Remove Emoji List
    FEmojiList.OnChange := nil;
    FEmojiList := nil;
    // Repaint
    PaintBuffer;
  end;
end;

procedure TChatRichTextBaseControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
  end;
end;

procedure TChatRichTextBaseControl.Loaded;
begin
  PaintBuffer;
end;

procedure TChatRichTextBaseControl.Assign(Source: TPersistent);
begin
  if (Source <> nil) and (Source is TChatRichTextBaseControl) then
  begin
    EmojiList := (Source as TChatRichTextBaseControl).EmojiList;
  end else
    inherited;
end;

function TChatRichTextBaseControl.MeasureRichTextRect(var Words: TWordInfoList; var Lines: TLineInfoList; const R: TRect; const BuildCharacters: Boolean) : TRect;
var
  S : TSize;
begin
  // Emoji Size
  if Assigned(EmojiList) then
    S := TSize.Create(EmojiList.Width, EmojiList.Height)
  else
    S := TSize.Create(EmojiWidth, EmojiHeight);
  // Build lines and measure output rect
  Result := BuildLines(Words, Lines, S, R, BuildCharacters, FBuffer.Canvas);
end;

{*******************************************************}
{               Chat Rich Text Link Font                }
{*******************************************************}
procedure TChatRichTextLinkFont.SetColor(const C: TColor);
begin
  if Color <> C then
  begin
    FColor := C;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextLinkFont.SetStyle(const S: TFontStyles);
begin
  if Style <> S then
  begin
    FStyle := S;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TChatRichTextLinkFont.Assign(Source: TPersistent);
begin
  if (Source <> nil) and (Source is TChatRichTextLinkFont) then
  begin
    FColor := (Source as TChatRichTextLinkFont).Color;
    FStyle := (Source as TChatRichTextLinkFont).Style;
    if Assigned(FOnChange) then FOnChange(Self);
  end else
    inherited;
end;

end.
