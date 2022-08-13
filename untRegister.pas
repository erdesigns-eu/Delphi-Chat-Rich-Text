{*******************************************************}
{                                                       }
{                  untRegister.pas                      }
{               Author: Ernst Reidinga                  }
{                                                       }
{     Register components and property editors for      }
{     the ERDesigns Chat Component Pack.                }
{                                                       }
{*******************************************************}

unit untRegister;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  DesignIntf,
  DesignEditors,
  untEmojiListEditor,
  untEmojiList,
  untChatRichTextEditor,
  untChatRichText,
  untChatRichTextLabel,
  untChatBalloon,
  untChatBalloonPreview,
  untChatRichTextEdit;

{*******************************************************}
{              Emoji List Component Editor              }
{*******************************************************}
type
  TEmojiListComponentEditor = class(TComponentEditor)
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): String; override;
    procedure Executeverb(Index: Integer); override;
  end;

{*******************************************************}
{        Chat Rich Text Label Component Editor          }
{*******************************************************}
type
  TChatRichTextLabelComponentEditor = class(TComponentEditor)
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): String; override;
    procedure Executeverb(Index: Integer); override;
  end;

{*******************************************************}
{             Chat Balloon Component Editor             }
{*******************************************************}
type
  TChatBalloonComponentEditor = class(TComponentEditor)
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): String; override;
    procedure Executeverb(Index: Integer); override;
  end;

{*******************************************************}
{              Emoji Items Property Editor              }
{*******************************************************}
type
  TEmojiItemsEditor = class(TClassProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

{*******************************************************}
{        Chat Rich Text String Property Editor          }
{*******************************************************}
type
  TChatRichTextStringEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

procedure Register;

implementation

{*******************************************************}
{              Emoji List Component Editor              }
{*******************************************************}
function TEmojiListComponentEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TEmojiListComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0 : Result := 'EmojiList Editor';
  end;
end;

procedure TEmojiListComponentEditor.ExecuteVerb(Index: Integer);
begin
  with TfrmEmojiListEditor.Create(nil) do
  try
    // Dialog Caption
    Caption := Format('%s', [
      (GetComponent as TComponent).Name
    ]);

    // Set EmojiList
    EmojiList := (GetComponent as TEmojiList);

    // Load Emojis
    LoadItems((GetComponent as TEmojiList).Items);
    // Load Categories
    LoadCategories((GetComponent as TEmojiList).Categories);

    // Show Dialog
    ShowModal;
  finally
    Free;
  end;
end;

{*******************************************************}
{        Chat Rich Text Label Component Editor          }
{*******************************************************}
function TChatRichTextLabelComponentEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TChatRichTextLabelComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0 : Result := 'Edit Rich Text';
  end;
end;

procedure TChatRichTextLabelComponentEditor.ExecuteVerb(Index: Integer);
begin
  with TfrmChatRichTextEditor.Create(nil) do
  try
    // Dialog Caption
    Caption := Format('%s', [
      (GetComponent as TComponent).Name
    ]);

    // Load text
    memText.Text := (GetComponent as TChatRichTextLabel).Text;

    if ShowModal = mrOK then
    begin
      (GetComponent as TChatRichTextLabel).Text := memText.Text;
    end;
  finally
    Free;
  end;
end;

{*******************************************************}
{             Chat Balloon Component Editor             }
{*******************************************************}
function TChatBalloonComponentEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TChatBalloonComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Preview..';
  end;
end;

procedure TChatBalloonComponentEditor.ExecuteVerb(Index: Integer);
begin
  with TfrmChatBalloonPreview.Create(nil) do
  try
    // Dialog Caption
    Caption := Format('%s - Preview', [
      (GetComponent as TComponent).Name
    ]);

    // Set Balloon
    ChatBalloon := GetComponent as TChatBalloonBase;

    // Show dialog
    ShowModal;
  finally
    Free;
  end;
end;

{*******************************************************}
{              Emoji Items Property Editor              }
{*******************************************************}
function TEmojiItemsEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

procedure TEmojiItemsEditor.Edit;
begin
  with TfrmEmojiListEditor.Create(nil) do
  try
    // Dialog Caption
    Caption := Format('%s', [
      (GetComponent(0) as TComponent).Name
    ]);

    // Set EmojiList
    EmojiList := (GetComponent(0) as TEmojiList);

    // Load Emojis
    LoadItems((GetComponent(0) as TEmojiList).Items);
    // Load Categories
    LoadCategories((GetComponent(0) as TEmojiList).Categories);

    // Show Dialog
    ShowModal;
  finally
    Free;
  end;
end;

{*******************************************************}
{        Chat Rich Text String Property Editor          }
{*******************************************************}
function TChatRichTextStringEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paReadOnly, paDialog];
end;

procedure TChatRichTextStringEditor.Edit;
begin
  with TfrmChatRichTextEditor.Create(nil) do
  try
    // Dialog Caption
    Caption := Format('%s', [
      (GetComponent(0) as TComponent).Name
    ]);

    // Load text
    memText.Text := GetStrValue;

    if ShowModal = mrOK then
    begin
      SetValue(memText.Text);
    end;
  finally
    Free;
  end;
end;

{*******************************************************}
{           Register Components and Editors             }
{*******************************************************}
procedure Register;
begin
  // Register Component Editors
  RegisterComponentEditor(TEmojiList, TEmojiListComponentEditor);
  RegisterComponentEditor(TChatRichTextLabel, TChatRichTextLabelComponentEditor);
  RegisterComponentEditor(TChatBalloonBase, TChatBalloonComponentEditor);
  // Register Property Editors
  RegisterPropertyEditor(TypeInfo(TEmojiCollection), nil, '', TEmojiItemsEditor);

  // ToDo replace this with a property editor for the new TChatRichTextString type
  //
  //RegisterPropertyEditor(TypeInfo(TChatRichTextString), nil, '', TChatRichTextStringEditor);
  //
  //

  // Register Components
  RegisterComponents('ERDesigns', [
    TEmojiList,
    TChatRichTextLabel,
    TSimpleChatBalloon,
    TChatRichTextEdit
  ]);
end;

end.
