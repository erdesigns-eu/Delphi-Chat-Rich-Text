unit untChatRichTextEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ToolWin, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList;

type
  TfrmChatRichTextEditor = class(TForm)
    Panel1: TPanel;
    btnCancel: TButton;
    btnOK: TButton;
    ToolBar1: TToolBar;
    btnBold: TToolButton;
    btnItalic: TToolButton;
    ImageList: TImageList;
    btnUnderline: TToolButton;
    ToolButton4: TToolButton;
    btnLink: TToolButton;
    ToolButton6: TToolButton;
    btnEmoji: TToolButton;
    btnEntity: TToolButton;
    memText: TMemo;
    btnLineBreak: TToolButton;
    ToolButton2: TToolButton;
    procedure btnBoldClick(Sender: TObject);
    procedure btnItalicClick(Sender: TObject);
    procedure btnUnderlineClick(Sender: TObject);
    procedure btnLinkClick(Sender: TObject);
    procedure btnEmojiClick(Sender: TObject);
    procedure btnEntityClick(Sender: TObject);
    procedure btnLineBreakClick(Sender: TObject);
  private
    { Private declarations }
    procedure InsertTag(const TagStart: string; const TagEnd: string);
  public
    { Public declarations }
  end;

var
  frmChatRichTextEditor: TfrmChatRichTextEditor;

implementation

{$R *.dfm}

procedure TfrmChatRichTextEditor.InsertTag(const TagStart: string; const TagEnd: string);
var
  S    : string;
  I, L : Integer;
begin
  if memText.SelLength > 0 then
  begin
    I := memText.SelStart;
    L := memText.SelLength;
    S := memText.Text;
    S.Insert(memText.SelStart + memText.SelLength, TagEnd);
    S.Insert(memText.SelStart, TagStart);
    memText.Text := S;
    memText.SelStart  := I;
    memText.SelLength := L + Length(TagStart) + Length(TagEnd);
  end else
  begin
    S := memText.Text;
    memText.Text := S + TagStart + TagEnd;
    memText.SelStart := Length(memText.Text);
  end;
end;

procedure TfrmChatRichTextEditor.btnBoldClick(Sender: TObject);
begin
  InsertTag('<b>', '</b>');
end;

procedure TfrmChatRichTextEditor.btnItalicClick(Sender: TObject);
begin
  InsertTag('<i>', '</i>');
end;

procedure TfrmChatRichTextEditor.btnUnderlineClick(Sender: TObject);
begin
  InsertTag('<u>', '</u>');
end;

procedure TfrmChatRichTextEditor.btnLinkClick(Sender: TObject);
begin
  InsertTag('<a>', '</a>');
end;

procedure TfrmChatRichTextEditor.btnEmojiClick(Sender: TObject);
begin
  InsertTag('<e>', '</e>');
end;

procedure TfrmChatRichTextEditor.btnEntityClick(Sender: TObject);
begin
  memText.Text := memText.Text + '&amp;';
  memtext.SelStart := Length(memText.Text);
end;

procedure TfrmChatRichTextEditor.btnLineBreakClick(Sender: TObject);
begin
  InsertTag('<br>', '');
end;

end.
