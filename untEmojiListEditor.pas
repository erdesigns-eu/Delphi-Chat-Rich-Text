unit untEmojiListEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.Generics.Collections, untEmojiList, System.ImageList, Vcl.ImgList,
  Vcl.ExtDlgs, Vcl.ComCtrls, Vcl.ToolWin, untChatRichText, untChatRichTextLabel;

type
  TCollectionHack = class(TPersistent)
  private
    FItems: TList;
  end;

  TfrmEmojiListEditor = class(TForm)
    Panel1: TPanel;
    btnCancel: TButton;
    btnOK: TButton;
    ImageList1: TImageList;
    Splitter: TSplitter;
    GroupBox1: TGroupBox;
    lvItems: TListView;
    GroupBox2: TGroupBox;
    pnlPreview: TPanel;
    lblDisplayName: TLabel;
    edtDisplayName: TEdit;
    Label1: TLabel;
    edtShortCode: TEdit;
    pbPreview: TPaintBox;
    ToolBar: TToolBar;
    btnAdd: TToolButton;
    btnDelete: TToolButton;
    ToolButton3: TToolButton;
    btnReplace: TToolButton;
    ToolButton5: TToolButton;
    btnDown: TToolButton;
    btnUp: TToolButton;
    OpenPictureDialog: TOpenPictureDialog;
    imgPreview: TImage;
    ToolButton1: TToolButton;
    btnClear: TToolButton;
    btnSave: TToolButton;
    ToolButton4: TToolButton;
    SavePictureDialog: TSavePictureDialog;
    Label2: TLabel;
    cbCategories: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbPreviewPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure lvItemsData(Sender: TObject; Item: TListItem);
    procedure lvItemsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure edtDisplayNameChange(Sender: TObject);
    procedure edtShortCodeChange(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnReplaceClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure cbCategoriesChange(Sender: TObject);
  private
    { Private declarations }
    FBuffer       : TBitmap;
    FRedrawBuffer : Boolean;
    FEditorItems  : TEmojiCollection;
    FEmojiList    : TEmojiList;
  public
    { Public declarations }
    procedure LoadItems(const Items: TEmojiCollection);
    procedure SaveItems(const Items: TEmojiCollection);
    procedure LoadCategories(const Lines: TStrings);

    property Items: TEmojiCollection read FEditorItems;
    property EmojiList: TEmojiList read FEmojiList write FEmojiList;
  end;

var
  frmEmojiListEditor: TfrmEmojiListEditor;

implementation

{$R *.dfm}

uses Math;

procedure TfrmEmojiListEditor.FormCreate(Sender: TObject);
begin
  FBuffer       := TBitmap.Create;
  FEditorItems  := TEmojiCollection.Create(Self, TEmoji);
  FRedrawBuffer := True;
end;

procedure TfrmEmojiListEditor.LoadItems(const Items: TEmojiCollection);
begin
  FEditorItems.Assign(Items);
  // Load items in list
  lvItems.Items.Count := FEditorItems.Count;
  // Select added item
  if (lvItems.Items.Count > 0) then
  lvItems.Selected := lvItems.Items[0];
end;

procedure TfrmEmojiListEditor.SaveItems(const Items: TEmojiCollection);
begin
  Items.Assign(FEditorItems);
end;

procedure TfrmEmojiListEditor.LoadCategories(const Lines: TStrings);
begin
  cbCategories.Clear;
  cbCategories.Items.Assign(Lines);
  cbCategories.Enabled := cbCategories.Items.Count > 0;
end;

procedure TfrmEmojiListEditor.pbPreviewPaint(Sender: TObject);
const
  GridSize = 10;
  GridCol1 = clBtnFace;
  GridCol2 = clWhite;

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

begin
  with pbPreview.Canvas do
  begin
    if FRedrawBuffer then
    begin
      FRedrawBuffer := False;
      DrawBackground;
    end;
    Draw(0, 0, FBuffer);
  end;
end;

procedure TfrmEmojiListEditor.FormResize(Sender: TObject);
begin
  FRedrawBuffer := True;
end;

procedure TfrmEmojiListEditor.btnAddClick(Sender: TObject);
var
  I : Integer;
  E : TEmoji;
begin
  // Load from file(s)
  OpenPictureDialog.Options := OpenPictureDialog.Options + [ofAllowMultiSelect];
  if OpenPictureDialog.Execute(Handle) then
  begin
    for I := 0 to OpenPictureDialog.Files.count -1 do
    begin
      E := FEditorItems.Add;
      if FileExists(OpenPictureDialog.Files[I]) then
      E.Picture.LoadFromFile(OpenPictureDialog.Files[I]);
      E.DisplayName := ChangeFileExt(ExtractFilename(OpenPictureDialog.Files[I]), '');
      E.Filename    := ExtractFilename(OpenPictureDialog.Files[I]);
      E.Category    := -1;
    end;
  end;
  // Load items in list
  lvItems.Items.Count := FEditorItems.Count;
  // Select added item
  if (lvItems.Items.Count > 0) then
  lvItems.Selected := lvItems.Items[lvItems.Items.Count -1];
  // Set focus
  lvItems.SetFocus;
end;

procedure TfrmEmojiListEditor.btnDeleteClick(Sender: TObject);
begin
  if Assigned(lvItems.Selected) then
  begin
    // Delete selected
    FEditorItems.Delete(lvItems.Selected.Index);
    // Load items in list
    lvItems.Items.Count := FEditorItems.Count;
    //
    if lvItems.Items.Count = 0 then
    lvItemsSelectItem(lvItems, nil, False);
  end;
end;

procedure TfrmEmojiListEditor.btnReplaceClick(Sender: TObject);
begin
  if Assigned(lvItems.Selected) then
  begin
    OpenPictureDialog.Options := OpenPictureDialog.Options - [ofAllowMultiSelect];
    if OpenPictureDialog.Execute(Handle) and (FileExists(OpenPictureDialog.Filename)) then
    begin
      FEditorItems.Items[lvItems.Selected.Index].Picture.LoadFromFile(OpenPictureDialog.Filename);
      imgPreview.Picture.Assign(FEditorItems.Items[lvItems.Selected.Index].Picture);
    end;
  end;
end;

procedure TfrmEmojiListEditor.btnDownClick(Sender: TObject);
var
  TempList: TList;
begin
  if Assigned(lvItems.Selected) then
  begin
    TempList := TCollectionHack(FEditorItems).FItems;
    TempList.Exchange(lvItems.Selected.Index, lvItems.Selected.Index +1);
    lvItems.Items.Count := FEditorItems.Count;
    lvItems.Selected := lvItems.Items[lvItems.Selected.Index +1];
  end;
end;

procedure TfrmEmojiListEditor.btnUpClick(Sender: TObject);
var
  TempList: TList;
begin
  if Assigned(lvItems.Selected) then
  begin
    TempList := TCollectionHack(FEditorItems).FItems;
    TempList.Exchange(lvItems.Selected.Index, lvItems.Selected.Index -1);
    lvItems.Items.Count := FEditorItems.Count;
    lvItems.Selected := lvItems.Items[lvItems.Selected.Index -1];
  end;
end;

procedure TfrmEmojiListEditor.btnClearClick(Sender: TObject);
begin
  FEditorItems.Clear;
  lvItems.Items.Count := 0;
  lvItemsSelectItem(lvItems, nil, false);
end;

procedure TfrmEmojiListEditor.btnSaveClick(Sender: TObject);
begin
  if Assigned(lvItems.Selected) then
  begin
    SavePictureDialog.FileName   := FEditorItems.Items[lvItems.Selected.Index].Filename;
    SavePictureDialog.DefaultExt := ExtractFileExt(FEditorItems.Items[lvItems.Selected.Index].Filename);
    if SavePictureDialog.Execute(Handle) then
    begin
      FEditorItems.Items[lvItems.Selected.Index].Picture.SaveToFile(SavePictureDialog.FileName);
    end;
  end;
end;

procedure TfrmEmojiListEditor.lvItemsData(Sender: TObject; Item: TListItem);
begin
  if FEditorItems.Count > Item.Index then
  begin
    Item.Caption := FEditorItems.Items[Item.Index].DisplayName;
    Item.SubItems.Add(FEditorItems.Items[Item.Index].ShortCode);
  end;
end;

procedure TfrmEmojiListEditor.lvItemsSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  if Assigned(Item) then
  begin
    imgPreview.Picture.Assign(FEditorItems.Items[Item.Index].Picture);
    edtDisplayName.Text := FEditorItems.Items[Item.Index].DisplayName;
    edtShortCode.Text   := FEditorItems.Items[Item.Index].ShortCode;
    cbCategories.ItemIndex := FEditorItems.Items[lvItems.Selected.Index].Category;

    btnDelete.Enabled  := True;
    btnReplace.Enabled := True;
    btnSave.Enabled    := True;
    btnDown.Enabled    := Item.Index < (lvItems.Items.Count -1);
    btnUp.Enabled      := Item.Index > 0;
  end else
  begin
    imgPreview.Picture  := nil;
    edtDisplayName.Text := '';
    edtShortCode.Text   := '';
    cbCategories.ItemIndex := -1;

    btnDelete.Enabled  := False;
    btnReplace.Enabled := False;
    btnDown.Enabled    := False;
    btnUp.Enabled      := False;
    btnSave.Enabled    := False;
  end;
  FRedrawBuffer := True;
  pbPreview.Invalidate;
end;

procedure TfrmEmojiListEditor.edtDisplayNameChange(Sender: TObject);
begin
  if Assigned(lvItems.Selected) then
  begin
    lvItems.Items.BeginUpdate;
    lvItems.Selected.Caption := edtDisplayName.Text;
    lvItems.Items.EndUpdate;
    FEditorItems.Items[lvItems.Selected.Index].DisplayName := edtDisplayName.Text;
  end;
end;

procedure TfrmEmojiListEditor.edtShortCodeChange(Sender: TObject);
begin
  if Assigned(lvItems.Selected) then
  begin
    lvItems.Items.BeginUpdate;
    lvItems.Selected.SubItems[0] := edtShortCode.Text;
    lvItems.Items.EndUpdate;
    FEditorItems.Items[lvItems.Selected.Index].ShortCode := edtShortCode.Text;
  end;
end;

procedure TfrmEmojiListEditor.cbCategoriesChange(Sender: TObject);
begin
  if Assigned(lvItems.Selected) then
  begin
    lvItems.Items.BeginUpdate;
    lvItems.Items.EndUpdate;
    FEditorItems.Items[lvItems.Selected.Index].Category := cbCategories.ItemIndex;
  end;
end;

procedure TfrmEmojiListEditor.FormDestroy(Sender: TObject);
begin
  FBuffer.Free;
  FEditorItems.Free;
end;

procedure TfrmEmojiListEditor.btnOKClick(Sender: TObject);
begin
  if Assigned(FEmojiList) then SaveItems(FEmojiList.Items);
  Close;
end;

procedure TfrmEmojiListEditor.btnCancelClick(Sender: TObject);
begin
  Close;
end;

end.
