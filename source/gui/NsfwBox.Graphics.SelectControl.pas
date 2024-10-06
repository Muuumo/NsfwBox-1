unit NsfwBox.Graphics.SelectControl;

interface
uses
  SysUtils, Types, System.UITypes, Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics,
  FMX.ColumnsView, System.Threading, System.Generics.Collections, Net.HttpClient,
  Net.HttpClientComponent, Fmx.Layouts, NsfwXxx.Types, Fmx.ActnList, FMX.Memo,
  NetHttp.R34AppApi,
  { Alcinoe }
  Alcinoe.FMX.Objects, Alcinoe.FMX.Graphics,
  { NsfwBox }
  NsfwBox.Interfaces, NsfwBox.ContentScraper, NsfwBox.Provider.Pseudo,
  NsfwBox.Provider.NsfwXxx, NsfwBox.Graphics, NsfwBox.Consts,
  NsfwBox.Graphics.Rectangle, NsfwBox.Provider.R34App, NsfwBox.Provider.R34JsonApi,
  NsfwBox.Provider.GivemepornClub, NsfwBox.Styling, NsfwBox.Provider.Bookmarks,
  NsfwBox.Helper, CoomerParty.Scraper, NsfwBox.Provider.CoomerParty,
  NsfwBox.Provider.Randomizer, NsfwBox.Provider.motherless, Motherless.types,
  Fapello.Types, NsfwBox.Provider.Fapello, NsfwBox.Logging,
  NsfwBox.Provider.BepisDb, BooruScraper.Client.BepisDb;

type

  INBoxSelectControls = Interface
    ['{3D11AE0C-F101-48DF-974A-92E832906EC5}']
    { Protected / private }
    procedure SetSelectedControl(const value: TControl);
    function GetSelectedControl: TControl;
    procedure SetOnSelected(const value: TNotifyEvent);
    function GetOnSelected: TNotifyEvent;
    { Public }
    property SelectedControl: TControl read GetSelectedControl write SetSelectedControl;
    property OnSelected: TNotifyEvent read GetOnSelected write SetOnSelected;
    procedure SelectFirst;
    procedure FreeControls;
  End;

  INBoxSelectMenu = Interface(IControl)
    ['{218067DC-26F7-41C3-8E74-9533F2333C95}']
    { Protected / private }
    function GetMenu: INBoxSelectControls;
    { Public }
    property Menu: INBoxSelectControls read GetMenu;
  End;

  TNBoxSelectControlsAbs<T> = Class;

  TNBoxSelectControlsAbs<T> = Class(TComponent, INBoxSelectControls)
    public type
      TControlContainer = Record
        Control: TControl;
        Value: T;
        constructor Create(AControl: TControl; AValue: T); overload;
        constructor Create(AControl: TControl); overload;
      End;
    protected
      FSelectedContainer: TControlContainer;
      FOnSelected: TNotifyEvent;
      procedure SetOnSelected(const value: TNotifyEvent);
      function GetOnSelected: TNotifyEvent;
      function IsEqual(const AValue, AValue2: T): boolean; virtual; abstract;
      procedure DoOnSelected; virtual;
      function IndexOfValue(const AValue: T): integer;
      function IndexOfControl(const AControl: TControl): integer;
      procedure SetSelected(const value: T);
      function GetSelected: T;
      procedure SetSelectedControl(const value: TControl);
      function GetSelectedControl: TControl;
      procedure OnControlTap(Sender: TObject; const Point: TPointF);
    public
      Items: TList<TControlContainer>;
      function GetControlByValue(const AValue: T): TControl;
      procedure AddControl(AControl: TControl; const AValue: T);
      procedure SelectFirst;
      procedure FreeControls;
      property Selected: T read GetSelected write SetSelected;
      property SelectedControl: TControl read GetSelectedControl write SetSelectedControl;
      property OnSelected: TNotifyEvent read GetOnSelected write SetOnSelected;
      constructor Create(AOwner: TComponent); override;
  End;

  TNBoxSelectControlsObj<T: class> = Class(TNBoxSelectControlsAbs<T>)
    protected
      function IsEqual(const AValue, AValue2: T): boolean; override;
  End;

  TNBoxSelectControlsIObj<T: IInterface> = Class(TNBoxSelectControlsAbs<T>)
    protected
      function IsEqual(const AValue, AValue2: T): boolean; override;
  End;

  TNBoxSelectControlsInt = Class(TNBoxSelectControlsAbs<Int64>)
    protected
      function IsEqual(const AValue, AValue2: Int64): boolean; override;
  End;

  TNBoxSelectControlsStr = Class(TNBoxSelectControlsAbs<String>)
    protected
      function IsEqual(const AValue, AValue2: String): boolean; override;
  End;

  TNBoxSelectMenuAbs<ValueType; MenuType: TNBoxSelectControlsAbs<ValueType>> = Class(TVertScrollBox, INBoxSelectMenu)
    protected
      FMenu: MenuType;
      function GetMenu: INBoxSelectControls;
    public
      property Menu: MenuType read FMenu;
      constructor Create(AOwner: TComponent); override;
  End;

  TNBoxSelectMenu<ValueType; MenuType: TNBoxSelectControlsAbs<ValueType>> = Class(TNBoxSelectMenuAbs<ValueType, MenuType>)
    protected
      procedure SetSelected(const value: ValueType);
      function GetSelected: ValueType;
    public
      function AddBtn(ABtnClass: TRectButtonClass;
        AText: string; AValue: ValueType): TRectButton; overload; virtual;
      function AddBtn(AText: string;
       AValue: ValueType;
       AImageFilename: string = ''
      ): TRectButton; overload; virtual;
      property Selected: ValueType read GetSelected write SetSelected;
  End;

  TNBoxSelectMenuInt = Class(TNBoxSelectMenu<Int64, TNBoxSelectControlsInt>);
  TNBoxSelectMenuStr = Class(TNBoxSelectMenu<String, TNBoxSelectControlsStr>);
  TNBoxSelectMenuTag = Class(TNBoxSelectMenu<INBoxItemTag, TNBoxSelectControlsIObj<INBoxItemTag>>);

  TTNBoxSelectMenuList = TList<INBoxSelectMenu>;

implementation
uses
  Unit1;

{ TNBoxSelectControls<T> }

procedure TNBoxSelectControlsAbs<T>.AddControl(AControl: TControl; const AValue: T);
begin
  with (AControl as TControl) do
  begin
    OnTap := Self.OnControlTap;
    {$IFDEF MSWINDOWS} OnClick := Form1.ClickTapRef; {$ENDIF}
  end;
  Items.Add(TControlContainer.Create(AControl, AValue));
end;

constructor TNBoxSelectControlsAbs<T>.Create(AOwner: TComponent);
begin
  Inherited;
  FSelectedContainer.Control := Nil;
  Items := TList<TControlContainer>.Create;
end;

procedure TNBoxSelectControlsAbs<T>.DoOnSelected;
begin
  if Assigned(FOnSelected) then
    FOnSelected(Self);
end;

function TNBoxSelectControlsAbs<T>.GetControlByValue(const AValue: T): TControl;
var
  LIndex: integer;
begin
  LIndex := IndexOfValue(AValue);
  if not LIndex < 0 then
    Result := Items[LIndex].Control
  else
    Result := Nil;
end;

function TNBoxSelectControlsAbs<T>.GetOnSelected: TNotifyEvent;
begin
  Result := FOnSelected;
end;

function TNBoxSelectControlsAbs<T>.GetSelected: T;
begin
  if Assigned(FSelectedContainer.Control) then
    Result := FSelectedContainer.Value;
end;

function TNBoxSelectControlsAbs<T>.GetSelectedControl: TControl;
begin
  Result := FSelectedContainer.Control;
end;

function TNBoxSelectControlsAbs<T>.IndexOfControl(
  const AControl: TControl): integer;
var
  I: integer;
begin
  if Assigned(AControl) then
  begin
    For I := 0 to Items.Count - 1 do
      if (AControl = Items[I].Control) then Exit(I);
  end;
  Result := -1; { Not found. }
end;

function TNBoxSelectControlsAbs<T>.IndexOfValue(const AValue: T): integer;
var
  I: integer;
begin
  For I := 0 to Items.Count - 1 do
    if IsEqual(AValue, Items[I].Value) then Exit(I);
  Result := -1; { Not found. }
end;

procedure TNBoxSelectControlsAbs<T>.OnControlTap(Sender: TObject;
  const Point: TPointF);
begin
  SelectedControl := Sender as TControl;
end;

procedure TNBoxSelectControlsAbs<T>.SelectFirst;
begin
  if Items.Count > 0 then begin
    FSelectedContainer := Items.First;
    DoOnSelected;
  end;
end;

procedure TNBoxSelectControlsAbs<T>.FreeControls;
var
  I: integer;
begin
  FSelectedContainer := TControlContainer.Create(Nil);
  For I := 1 to Items.Count do
  begin
    Items[0].Control.Free;
    Items.Delete(0);
  end;
end;

procedure TNBoxSelectControlsAbs<T>.SetOnSelected(const value: TNotifyEvent);
begin
  FOnSelected := Value;
end;

procedure TNBoxSelectControlsAbs<T>.SetSelected(const value: T);
var
  LIndex: integer;
begin
  LIndex := Self.IndexOfValue(value);
  if not LIndex < 0 then
    SelectedControl := Items[LIndex].Control;
end;

procedure TNBoxSelectControlsAbs<T>.SetSelectedControl(const value: TControl);
var
  LIndex: Integer;
begin
  LIndex := IndexOfControl(value);
  if not LIndex < 0 then
    FSelectedContainer := Items[LIndex];
  DoOnSelected;
end;

{ TNBoxSelectControlsObj<T> }

function TNBoxSelectControlsObj<T>.IsEqual(const AValue, AValue2: T): boolean;
begin
  Result := AValue = AValue2;
end;

{ TNBoxSelectControlsIObj<T> }

function TNBoxSelectControlsIObj<T>.IsEqual(const AValue, AValue2: T): boolean;
begin
  Result := (AValue as TObject) = (AValue2 as TObject);
end;

{ TNBoxSelectControlsInt }

function TNBoxSelectControlsInt.IsEqual(const AValue, AValue2: Int64): boolean;
begin
  Result := AValue = AValue2;
end;

{ TNBoxSelectControlsAbs<T>.TControlContainer }

constructor TNBoxSelectControlsAbs<T>.TControlContainer.Create(
  AControl: TControl; AValue: T);
begin
  Control := AControl;
  Value := AValue;
end;

constructor TNBoxSelectControlsAbs<T>.TControlContainer.Create(
  AControl: TControl);
begin
  Control := AControl;
end;


{ TNBoxSelectMenuAbs<ValueType, MenuType> }

constructor TNBoxSelectMenuAbs<ValueType, MenuType>.Create(AOwner: TComponent);
begin
  inherited;
  FMenu := MenuType.Create(Self);
end;

function TNBoxSelectMenuAbs<ValueType, MenuType>.GetMenu: INBoxSelectControls;
begin
  Result := FMenu;
end;

{ TNBoxSelectMenu<ValueType, MenuType> }

function TNBoxSelectMenu<ValueType, MenuType>.AddBtn(AText: string;
  AValue: ValueType; AImageFilename: string): TRectButton;
begin
  Result := AddBtn(TRectButton, AText, AValue);
  with Result do
  begin
    if not AImageFilename.IsEmpty then
      Image.ImageURL := AImageFilename;
  end;
end;

function TNBoxSelectMenu<ValueType, MenuType>.GetSelected: ValueType;
begin
  Result := Menu.Selected;
end;

procedure TNBoxSelectMenu<ValueType, MenuType>.SetSelected(
  const value: ValueType);
begin
  Menu.Selected := value;
end;

function TNBoxSelectMenu<ValueType, MenuType>.AddBtn(
  ABtnClass: TRectButtonClass; AText: string; AValue: ValueType): TRectButton;
begin
  Result := Form1.CreateDefButtonC(Self, ABtnClass, DEFAULT_IMAGE_CLASS);
  with Result do
  begin
    Parent := Self;
    Align := TAlignLayout.Top;
    Position.Y := 0;
    Text.Text := AText;
  end;
  Menu.AddControl(Result, AValue);
end;

{ TNBoxSelectControlsStr }

function TNBoxSelectControlsStr.IsEqual(const AValue, AValue2: String): boolean;
begin
  Result := (AValue = AValue2);
end;

end.
