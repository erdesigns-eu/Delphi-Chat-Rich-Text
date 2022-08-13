{*******************************************************}
{                                                       }
{                   untEmojiList.pas                    }
{                Author: Ernst Reidinga                 }
{                                                       }
{               List with Emoji Pictures                }
{                                                       }
{*******************************************************}

unit untEmojiList;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Vcl.Graphics,
  Vcl.Direct2D;

{*******************************************************}
{                      Emoji Class                      }
{*******************************************************}
type
  TEmoji = class(TCollectionItem)
  private
    // Events
    FOnChange    : TNotifyEvent;

    // Properties
    FPicture     : TPicture;
    FDisplayName : string;
    FShortCode   : string;
    FFilename    : string;
    FCategory    : Integer;

    // Property Setters
    procedure SetPicture(const P: TPicture);
    procedure SetDisplayName(const S: string);
    procedure SetShortCode(const S: string);
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    // Properties
    property Filename: string read FFilename write FFilename;
  published
    // Evenst
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    // Properties
    property Picture: TPicture read FPicture write SetPicture;
    property DisplayName: string read FDisplayName write SetDisplayName;
    property ShortCode: string read FShortCode write SetShortCode;
    property Category: Integer read FCategory write FCategory;
  end;

{*******************************************************}
{                   Emoji Collection                    }
{*******************************************************}
type
  TEmojiCollection = class(TOwnedCollection)
  private
    FOnChange : TNotifyEvent;

    procedure ItemChanged(Sender: TObject);

    function GetItem(Index: Integer): TEmoji;
    procedure SetItem(Index: Integer; Value: TEmoji);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    function Add: TEmoji;
    procedure Assign(Source: TPersistent); override;

    property Items[Index: Integer]: TEmoji read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

{*******************************************************}
{                Emoji List Component                   }
{*******************************************************}
type
  TEmojiList = class(TComponent)
  private
    // Events
    FOnChange : TNotifyEvent;

    // Properties
    FItems      : TEmojiCollection;
    FWidth      : Integer;
    FHeight     : Integer;
    FFallBack   : TEmoji;
    FCategories : TStrings;

    // Property Setters
    procedure SetItems(const L: TEmojiCollection);
    procedure SetWidth(const I: Integer);
    procedure SetHeight(const I: Integer);
    procedure SetFallback(const P: TPicture);
    procedure SetCategories(const S: TStrings);

    // Property Getters
    function GetFallback : TPicture;
    function GetCount : Integer;

    // Events
    procedure OnItemsChange(Sender: TObject);
    procedure OnFallbackChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    function Add(const Emoji: TEmoji) : Integer; overload;
    function Add(const Picture: TPicture; const DisplayName: string;
      const ShortCode: string; const Filename: string) : Integer; overload;

    function GetEmoji(const ShortCode: string) : TEmoji;
    function GetEmojiGraphic(const ShortCode: string) : TGraphic;

    procedure DrawEmoji(const ShortCode: string; const Canvas: TCanvas; const X: Integer; const Y: Integer); overload;
    procedure DrawEmoji(const ShortCode: string; const Canvas: TDirect2DCanvas; const X: Integer; const Y: Integer); overload;
    procedure DrawEmoji(const Emoji: TEmoji; const Canvas: TCanvas; const X: Integer; const Y: Integer); overload;
    procedure DrawEmoji(const Emoji: TEmoji; const Canvas: TDirect2DCanvas; const X: Integer; const Y: Integer); overload;

    procedure Delete(const Index: Integer);
    procedure Clear;

    // Emoji Count
    property Count: Integer read GetCount;
  published
    // Events
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    // Emoji's
    property Items: TEmojiCollection read FItems write SetItems;

    // Emoji Size
    property Width: Integer read FWidth write SetWidth default 18;
    property Height: Integer read FHeight write SetHeight default 18;

    // Fallback Emoji
    property FallbackEmoji: TPicture read GetFallBack write SetFallback;

    // Categories
    property Categories: TStrings read FCategories write SetCategories;
  end;

implementation

{*******************************************************}
{                      Emoji Class                      }
{*******************************************************}
constructor TEmoji.Create(Collection: TCollection);
begin
  // Create
  inherited Create(Collection);

  // Default category
  FCategory := -1;

  // Create Picture
  FPicture := TPicture.Create;
end;

destructor TEmoji.Destroy;
begin
  // Free Picture
  FPicture.Free;

  // Free
  inherited Destroy;
end;

procedure TEmoji.SetPicture(const P: TPicture);
begin
  FPicture.Assign(P);
  if Assigned(OnChange) then OnChange(Self);
end;

procedure TEmoji.SetDisplayName(const S: string);
begin
  if DisplayName <> S then
  begin
    FDisplayName := S;
    if Assigned(OnChange) then OnChange(Self);
  end;
end;

procedure TEmoji.SetShortCode(const S: string);
begin
  if ShortCode <> S then
  begin
    FShortCode := S;
    if Assigned(OnChange) then OnChange(Self);
  end;
end;

procedure TEmoji.Assign(Source: TPersistent);
begin
  if (Source <> nil) and (Source is TEmoji) then
  begin
    FPicture.Assign((Source as TEmoji).Picture);
    FDisplayName := (Source as TEmoji).DisplayName;
    FShortCode   := (Source as TEmoji).ShortCode;
    FFilename    := (Source as TEmoji).Filename;
    FCategory    := (Source as TEmoji).Category;
  end;
  if Assigned(OnChange) then OnChange(Self);
end;

{*******************************************************}
{                   Emoji Collection                    }
{*******************************************************}
procedure TEmojiCollection.ItemChanged(Sender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

function TEmojiCollection.GetItem(Index: Integer): TEmoji;
begin
  Result := inherited GetItem(Index) as TEmoji;
end;

procedure TEmojiCollection.SetItem(Index: Integer; Value: TEmoji);
begin
  inherited SetItem(Index, Value);
  ItemChanged(Self);
end;

procedure TEmojiCollection.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FOnChange) then FOnChange(Self);
end;

function TEmojiCollection.Add: TEmoji;
begin
  Result := TEmoji(inherited Add);
end;

procedure TEmojiCollection.Assign(Source: TPersistent);
var
  LI   : TEmojiCollection;
  Loop : Integer;
begin
  if (Source is TEmojiCollection)  then
  begin
    LI := TEmojiCollection(Source);
    Clear;
    for Loop := 0 to LI.Count - 1 do Add.Assign(LI.Items[Loop]);
  end else
    inherited;
end;

{*******************************************************}
{                Emoji List Component                   }
{*******************************************************}
constructor TEmojiList.Create(AOwner: TComponent);
const
  FBName = 'Fallback';
begin
  // Create
  inherited Create(AOwner);

  // Create Emoji Collection
  FItems := TEmojiCollection.Create(Self, TEmoji);
  FItems.OnChange := OnItemsChange;

  // Create Fallbak emoji
  FFallBack := TEmoji.Create(nil);
  FFallBack.DisplayName := FBName;
  FFallBack.ShortCode   := FBName;
  FFallBack.OnChange := OnFallbackChange;

  // Create categories list
  FCategories := TStringList.Create;

  // Set Default settings
  FWidth  := 18;
  FHeight := 18;
end;

destructor TEmojiList.Destroy;
begin
  // Free Emoji Object List
  FItems.Free;

  // Free Fallback emoji picture
  FFallback.Free;

  // Free Categories
  FCategories.Free;

  // Free
  inherited Destroy;
end;

procedure TEmojiList.SetItems(const L: TEmojiCollection);
begin
  FItems := L;
end;

procedure TEmojiList.SetWidth(const I: Integer);
begin
  if (Width <> I) and (I >= 5) then
  begin
    FWidth := I;
    if Assigned(OnChange) then OnChange(Self);
  end;
end;

procedure TEmojiList.SetHeight(const I: Integer);
begin
  if (Height <> I) and (I >= 5) then
  begin
    FHeight := I;
    if Assigned(OnChange) then OnChange(Self);
  end;
end;

procedure TEmojiList.SetFallback(const P: TPicture);
begin
  FFallBack.Picture.Assign(P);
  if Assigned(OnChange) then OnChange(Self);
end;

procedure TEmojiList.SetCategories(const S: TStrings);
begin
  FCategories.Assign(S);
end;

function TEmojiList.GetFallback: TPicture;
begin
  Result := FFallback.Picture;
end;

function TEmojiList.GetCount: Integer;
begin
  Result := Items.Count;
end;

procedure TEmojiList.OnItemsChange(Sender: TObject);
begin
  if Assigned(OnChange) then OnChange(Self);
end;

procedure TEmojiList.OnFallbackChange(Sender: TObject);
begin
  if Assigned(OnChange) then OnChange(Self);
end;

procedure TEmojiList.Assign(Source: TPersistent);
var
  I : Integer;
  E : TEmoji;
begin
  if (Source <> nil) and (Source is TEmojiList) then
  begin
    // Clear current items
    FItems.Clear;
    // Copy items from source
    for I := 0 to (Source as TEmojiList).Count -1 do
    begin
      E := FItems.Add;
      E.Assign((Source as TEmojiList).Items.Items[I]);
    end;
    //
    FWidth  := (Source as TEmojiList).Width;
    FHeight := (Source as TEmojiList).Height;
    FFallback.Assign((Source as TEmojiList).FallBackEmoji);
    FCategories.Assign((Source as TEmojiList).Categories);
    //
    if Assigned(OnChange) then OnChange(Self);
  end else
    inherited;
end;

function TEmojiList.Add(const Emoji: TEmoji) : Integer;
var
  E : TEmoji;
begin
  try
    E := FItems.Add;
    E.Assign(Emoji);
    Result := E.Index;
  finally
    Emoji.Free;
  end;
  if Assigned(OnChange) then OnChange(Self);
end;

function TEmojiList.Add(const Picture: TPicture; const DisplayName: string;
  const ShortCode: string; const Filename: string): Integer;
var
  Emoji : TEmoji;
begin
  Emoji := FItems.Add;
  Emoji.Picture.Assign(Picture);
  Emoji.DisplayName := DisplayName;
  Emoji.ShortCode   := ShortCode;
  Emoji.Filename    := Filename;
  Result := Emoji.Index;
  if Assigned(OnChange) then OnChange(Self);
end;

procedure TEmojiList.Delete(const Index: Integer);
begin
  FItems.Delete(Index);
  if Assigned(OnChange) then OnChange(Self);
end;

procedure TEmojiList.Clear;
begin
  FItems.Clear;
  if Assigned(OnChange) then OnChange(Self);
end;

function TEmojiList.GetEmoji(const ShortCode: string) : TEmoji;
var
  I : Integer;
begin
  Result := FFallback;
  for I := 0 to Count -1 do
  if AnsiCompareText(ShortCode, Items.Items[I].ShortCode) = 0 then
  begin
    Result := Items.Items[I];
    Break;
  end;
end;

function TEmojiList.GetEmojiGraphic(const ShortCode: string) : TGraphic;
var
  E : TEmoji;
begin
  E := GetEmoji(ShortCode);
  if Assigned(E) then Result := E.Picture.Graphic else Result := nil;
end;

procedure TEmojiList.DrawEmoji(const ShortCode: string; const Canvas: TCanvas; const X: Integer; const Y: Integer);
var
  E : TEmoji;
begin
  E := GetEmoji(Trim(ShortCode));
  if Assigned(E) then if Assigned(E) then DrawEmoji(E, Canvas, X, Y);
end;

procedure TEmojiList.DrawEmoji(const ShortCode: string; const Canvas: TDirect2DCanvas; const X: Integer; const Y: Integer);
var
  E : TEmoji;
begin
  E := GetEmoji(Trim(ShortCode));
  if Assigned(E) then DrawEmoji(E, Canvas, X, Y);
end;

procedure TEmojiList.DrawEmoji(const Emoji: TEmoji; const Canvas: TCanvas; const X: Integer; const Y: Integer);
var
  R : TRect;
begin
  if Assigned(Emoji) then
  begin
    R := TRect.Create(X, Y, X + Width, Y + Height);
    Canvas.StretchDraw(R, Emoji.Picture.Graphic);
  end;
end;

procedure TEmojiList.DrawEmoji(const Emoji: TEmoji; const Canvas: TDirect2DCanvas; const X: Integer; const Y: Integer);
var
  R : TRect;
begin
  if Assigned(Emoji) then
  begin
    R := TRect.Create(X, Y, X + Width, Y + Height);
    Canvas.StretchDraw(R, Emoji.Picture.Graphic);
  end;
end;

end.
