﻿unit gTrack;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,System.Net.HttpClient,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.ListView.Types, FMX.ListView,
  FMX.ListView.Adapters.Base, System.RegularExpressions,
  System.Net.URLClient,
  System.JSON,FMX.DialogService,
  FMX.ListView.Appearances, IdHTTP, IdTCPClient, IdGlobal, FMX.Edit, FMX.Layouts, IdSSLOpenSSL,FMX.VirtualKeyboard, FMX.Platform,
  FMX.Gestures;

type
  THeaderFooterForm = class(TForm)
    Header: TToolBar;
    HeaderLabel: TLabel;
    ListView1: TListView;
    SearchEdit: TEdit;
    Layout1: TLayout;
    GestureManager1: TGestureManager;
    LabelMessage: TLabel;
    TimerMessage: TTimer;
    procedure SearchEditChange(Sender: TObject);
    procedure ShowTemporaryMessage(const Msg: string);
//    procedure LoadButtonClick(Sender: TObject);
    procedure ListView1ItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure SearchEditClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardHidden(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
 //   procedure ListView1Gesture(Sender: TObject;
 //     const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure TimerMessageTimer(Sender: TObject);
    procedure SearchEditExit(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HeaderFooterForm: THeaderFooterForm;

implementation

{$R *.fmx}

function IsServerAvailable(const Host: string; Port: Integer): Boolean;
var
  TCPClient: TIdTCPClient;
begin
  Result := False;
  TCPClient := TIdTCPClient.Create(nil);
  try
    TCPClient.Host := Host;
    TCPClient.Port := Port;
    try
      TCPClient.ConnectTimeout := 3000; // Timp de așteptare 3 secunde
      TCPClient.Connect;
      Result := True;
    except
      on E: Exception do
      begin
        // Afișează mesaj de eroare folosind DialogService
        TDialogService.MessageDialog('Serverul nu este disponibil: ' + E.Message,
          TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0,
          procedure(const AResult: TModalResult)
          begin
            Application.Terminate;
          end);
      end;
    end;
  finally
    TCPClient.Free;
  end;
end;

function GetJSONValue(JSONObj: TJSONObject; const Key: string): string;
var
  JSONValue: TJSONValue;
begin
  JSONValue := JSONObj.GetValue(Key);
  if Assigned(JSONValue) then
    Result := JSONValue.Value
  else
    Result := 'N/A';
end;

 procedure THeaderFooterForm.FormCreate(Sender: TObject);
     var
  IdHTTPClient: TIdHTTP;
  response: string;
  jsonArray: TJSONArray;
  jsonValue: TJSONValue;
  searchText, url: string;
  listItem: TListViewItem;
begin
  searchText := Trim(SearchEdit.Text);
   url := ('http://95.65.99.175:4000/api/products?search');
  IdHTTPClient := TIdHTTP.Create(nil);
  try
    IdHTTPClient.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(IdHTTPClient);

    try
      response := IdHTTPClient.Get(url);

      // Procesarea răspunsului JSON
      jsonArray := TJSONObject.ParseJSONValue(response) as TJSONArray;
      if Assigned(jsonArray) then
      begin
        ListView1.Items.Clear;

        // Iterează prin array-ul JSON și adaugă elemente în ListView
        for jsonValue in jsonArray do
        begin
          listItem := ListView1.Items.Add;
          listItem.Text := jsonValue.GetValue<string>('a_marca_model') + '    ' + jsonValue.GetValue<string>('cod');
          listItem.Detail := Format('Cod: %s, Celulă: %s, Preț: %s',
            [jsonValue.GetValue<string>('cod'),
             jsonValue.GetValue<string>('nume_celula'),
             jsonValue.GetValue<string>('p_price')]);
        end;
      end
      else
        ShowMessage('Răspunsul de la API nu este valid!');

    except
      on E: Exception do
        ShowMessage('Eroare la conectarea la API: ' + E.Message);
    end;

  finally
    IdHTTPClient.Free;
  end;
 end;

//
procedure THeaderFooterForm.FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean;
  const Bounds: TRect);
var
  VKOffset: Single;
begin
  if KeyboardVisible then
  begin
    VKOffset := Bounds.Height;
    Layout1.Margins.Bottom := VKOffset;
    Application.ProcessMessages;
  end;
end;

procedure THeaderFooterForm.FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean;
  const Bounds: TRect);
begin
  Layout1.Margins.Bottom := 0;
  Application.ProcessMessages;
end;

procedure THeaderFooterForm.ShowTemporaryMessage(const Msg: string);
begin
  LabelMessage.Text := Msg;
  LabelMessage.Visible := True;

  TimerMessage.Enabled := True;
end;

//procedure THeaderFooterForm.ListView1Gesture(Sender: TObject;
//  const EventInfo: TGestureEventInfo; var Handled: Boolean);
//const
//  RefreshThreshold = 100;
//var
//  DraggingDown: Boolean;
//begin
//  if EventInfo.GestureID = igiPan then
//  begin
//    if ListView1.ScrollViewPos = 0 then
//    begin
//      // Verificăm dacă utilizatorul a tras suficient de mult în jos
//      DraggingDown := EventInfo.Location.Y > RefreshThreshold;
//
//      // Se face refresh doar dacă utilizatorul a tras și a eliberat gestul
//      if DraggingDown and (EventInfo.Flags * [TInteractiveGestureFlag.gfEnd] <> []) then
//      begin
//        ShowTemporaryMessage('Refresh...');
//        FormCreate(nil);
//        Handled := True;
//      end;
//    end;
//  end;
//end;

procedure THeaderFooterForm.ListView1ItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  ShowMessage(AItem.Detail);
end;

// bara cautare
procedure THeaderFooterForm.SearchEditChange(Sender: TObject);
var
  IdHTTPClient: TIdHTTP;
  response: string;
  jsonArray: TJSONArray;
  jsonValue: TJSONValue;
  searchText, url: string;
  listItem: TListViewItem;
begin
  searchText := Trim(SearchEdit.Text);
  url := Format('http://95.65.99.175:4000/api/products?search=%s', [searchText]);
  //url := Format('http://95.65.99.176:8080/api/products?search=%s', [searchText]);

  IdHTTPClient := TIdHTTP.Create(nil);
  try

    IdHTTPClient.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(IdHTTPClient);

    try
      response := IdHTTPClient.Get(url);

      // Procesarea răspunsului JSON
      jsonArray := TJSONObject.ParseJSONValue(response) as TJSONArray;
      if Assigned(jsonArray) then
      begin
        ListView1.Items.Clear;

        // Iterează prin array-ul JSON și adaugă elemente în ListView
        for jsonValue in jsonArray do
        begin
          listItem := ListView1.Items.Add;
          listItem.Text := jsonValue.GetValue<string>('a_marca_model') + '    '
           + jsonValue.GetValue<string>('cod');
          listItem.Detail := Format('Cod: %s, Celulă: %s, Preț: %s',
            [jsonValue.GetValue<string>('cod'),
             jsonValue.GetValue<string>('nume_celula'),
             jsonValue.GetValue<string>('p_price')]);
        end;
      end
      else
        ShowMessage('Răspunsul de la API nu este valid!');

    except
      on E: Exception do
        ShowMessage('Eroare la conectarea la API: ' + E.Message);
    end;

  finally
    IdHTTPClient.Free;
  end;
end;

procedure THeaderFooterForm.SearchEditClick(Sender: TObject);
begin
  SearchEdit.Text := '';
end;

procedure THeaderFooterForm.SearchEditExit(Sender: TObject);
var
  IdHTTPClient: TIdHTTP;
  response: string;
  jsonArray: TJSONArray;
  jsonValue: TJSONValue;
  searchText, url: string;
  listItem: TListViewItem;
begin
  searchText := Trim(SearchEdit.Text);

  // Verifică dacă bara de căutare este goală
  if searchText = '' then
    url := 'http://95.65.99.175:4000/api/products' // URL pentru toate produsele
  else
    url := Format('http://95.65.99.175:4000/api/products?search=%s', [searchText]);

  IdHTTPClient := TIdHTTP.Create(nil);
  try
    IdHTTPClient.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(IdHTTPClient);

    try
      response := IdHTTPClient.Get(url);

      // Procesarea răspunsului JSON
      jsonArray := TJSONObject.ParseJSONValue(response) as TJSONArray;
      if Assigned(jsonArray) then
      begin
        ListView1.Items.Clear;

        for jsonValue in jsonArray do
        begin
          listItem := ListView1.Items.Add;
          listItem.Text := jsonValue.GetValue<string>('a_marca_model') + '    '
            + jsonValue.GetValue<string>('cod');
          listItem.Detail := Format('Cod: %s, Celulă: %s, Preț: %s',
            [jsonValue.GetValue<string>('cod'),
             jsonValue.GetValue<string>('nume_celula'),
             jsonValue.GetValue<string>('p_price')]);
        end;
      end
      else
        ShowMessage('Răspunsul de la API nu este valid!');

    except
      on E: Exception do
        ShowMessage('Eroare la conectarea la API: ' + E.Message);
    end;

  finally
    IdHTTPClient.Free;
  end;
end;

procedure THeaderFooterForm.TimerMessageTimer(Sender: TObject);
begin
  LabelMessage.Visible := False;
  TimerMessage.Enabled := False;
end;

end.
