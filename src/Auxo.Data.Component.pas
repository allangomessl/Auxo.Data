unit Auxo.Data.Component;

interface

uses
  System.Classes, System.Generics.Collections, Auxo.Access.Core, Auxo.Data.Core, Auxo.Core.Observer;

type
  TAuxoField = class(TCollectionItem)
  private
    FName: string;
    FErrors: TDictionary<string, string>;
    FWarnings: TDictionary<string, string>;
    procedure SetName(const Value: string);
  protected
    function GetDisplayName: string; override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Name: string read FName write SetName;
  end;

  TAuxoFields = class(TOwnedCollection)
  private
    function GetItemByName(AName: string): TAuxoField;
    procedure SetItemByName(AName: string; const AValue: TAuxoField);
    function GetItemByIndex(AIndex: Integer): TAuxoField;
    procedure SetItemByIndex(AIndex: Integer; const AValue: TAuxoField);
    procedure CheckDuplicate(Item: TAuxoField; Value: string);
  public
    function Add: TAuxoField; reintroduce; overload;
    function Add(AName: string): TAuxoField; reintroduce; overload;
    procedure Remove(AName: string);
    function Exists(const AName: String): Boolean;
    function Find(const AName: String; out Item: TAuxoField): Boolean; overload;
    function Find(const AName: String; out Index: Integer): Boolean; overload;
    property Items[AName: string]: TAuxoField read GetItemByName write SetItemByName; default;
    property Items[AIndex: Integer]: TAuxoField read GetItemByIndex write SetItemByIndex; default;
  end;

  ISourceSuport = interface(ISubject)
    function GetMembers: TAuxoFields;
    procedure SetMembers(const Value: TAuxoFields);
    function GetAccess: IRecord;
    property Members: TAuxoFields read GetMembers write SetMembers;
    property Access: IRecord read GetAccess;
    function ClassType: TClass;
  end;

  TAuxoSource = class(TComponent, ISourceSuport, ISubject)
  public
    const INS_ACTION: TGUID = '{A7F8DFE0-7CB7-46DB-AF68-1037D7E175B5}';
    const LOAD_ACTION: TGUID = '{9BA607C9-473D-4321-AE6B-EECB48001F35}';
    const POST_ACTION: TGUID = '{D25413EB-554F-4E4C-B516-32B93D803F72}';
    const DELETE_ACTION: TGUID = '{31CEAA73-1064-4FA2-83BB-D8ED5F131BAB}';
  private
    FObservers: TObservers;
    FMembers: TAuxoFields;
    FAccess: IRecord;
    FRepository: IRepository;
    function GetItemByName(AName: string): TAuxoField;
    procedure SetItemByName(AName: string; const AValue: TAuxoField);
    function GetItemByIndex(AIndex: Integer): TAuxoField;
    procedure SetItemByIndex(AIndex: Integer; const AValue: TAuxoField);
    procedure Notify(Action: TGUID);
    procedure RegisterObserver(Observer: IObserver; Actions: array of TGUID);
    procedure UnregisterObserver(Observer: IObserver);
    function GetMembers: TAuxoFields;
    procedure SetMembers(const Value: TAuxoFields);
    function GetAccess: IRecord;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property Items[AName: string]: TAuxoField read GetItemByName write SetItemByName; default;
    property Items[AIndex: Integer]: TAuxoField read GetItemByIndex write SetItemByIndex; default;
    property Access: IRecord read GetAccess;
    procedure New;
    procedure Load(AId: Variant);
    procedure Post;
    procedure Delete;
  published
    property Members: TAuxoFields read GetMembers write SetMembers;
    property Repository: IRepository read FRepository write FRepository;
  end;


implementation

uses
  System.SysUtils;

{ TAuxoField }

procedure TAuxoField.AfterConstruction;
begin
  inherited;
  FErrors := TDictionary<string, string>.Create;
  FWarnings := TDictionary<string, string>.Create;
end;

procedure TAuxoField.Assign(Source: TPersistent);
begin
  if Source is TAuxoField then
  begin
    FName := TAuxoField(Source).FName;
    FErrors := TAuxoField(Source).FErrors;
    FWarnings := TAuxoField(Source).FWarnings;
  end;
end;

procedure TAuxoField.BeforeDestruction;
begin
  inherited;
  FErrors.Free;
  FWarnings.Free;
end;

function TAuxoField.GetDisplayName: string;
begin
  Result := Name;
end;

procedure TAuxoField.SetName(const Value: string);
begin
  TAuxoFields(Collection).CheckDuplicate(Self, Value);
  FName := Value;
end;

{ TAuxoSource }

procedure TAuxoSource.AfterConstruction;
begin
  inherited;
  FMembers := TAuxoFields.Create(Self, TAuxoField);
  FObservers := TObservers.Create;
end;

procedure TAuxoSource.New;
begin
//  FAccess := (FRepository as IDataProvider).New;
  FObservers.Notify(Self, INS_ACTION);
end;

procedure TAuxoSource.BeforeDestruction;
begin
  inherited;
  FMembers.Free;
  FObservers.Free;
end;

procedure TAuxoSource.Delete;
begin
  FObservers.Notify(Self, DELETE_ACTION);
//  (FRepository as IDataProvider).Delete(FAccess['Id']);
end;

function TAuxoSource.GetAccess: IRecord;
begin
  Result := FAccess;
end;

function TAuxoSource.GetItemByIndex(AIndex: Integer): TAuxoField;
begin
  Result := TAuxoField(FMembers.Items[AIndex]);
end;

function TAuxoSource.GetItemByName(AName: string): TAuxoField;
begin
  FMembers.Find(AName, Result);
end;

function TAuxoSource.GetMembers: TAuxoFields;
begin
  Result := FMembers;
end;

procedure TAuxoSource.Load(AId: Variant);
begin
//  FAccess := (FRepository as IDataProvider).Get(AId);
  FObservers.Notify(Self, LOAD_ACTION);
end;

procedure TAuxoSource.Notify(Action: TGUID);
begin
  FObservers.Notify(Self, Action);
end;

procedure TAuxoSource.Post;
begin
  FObservers.Notify(Self, POST_ACTION);
//  (FRepository as IDataProvider).Insert(FAccess, nil);
end;

procedure TAuxoSource.RegisterObserver(Observer: IObserver; Actions: array of TGUID);
begin
  FObservers.Register(Observer, Actions);
end;

procedure TAuxoSource.SetItemByIndex(AIndex: Integer; const AValue: TAuxoField);
begin
  FMembers.Items[AIndex] := AValue;
end;

procedure TAuxoSource.SetItemByName(AName: string; const AValue: TAuxoField);
var
  Index: Integer;
begin
  if FMembers.Find(AName, Index) then
    FMembers.Items[Index] := AValue;
end;

procedure TAuxoSource.SetMembers(const Value: TAuxoFields);
begin
  FMembers := Value;
end;

procedure TAuxoSource.UnregisterObserver(Observer: IObserver);
begin
  FObservers.Unregister(Observer);
end;

{ TAuxoFields }

function TAuxoFields.Add(AName: string): TAuxoField;
begin
  Result := Add;
  Result.Name := AName;
end;

procedure TAuxoFields.CheckDuplicate(Item: TAuxoField; Value: string);
var
  IRepository: Integer;
begin
  for IRepository := 0 to Count-1 do
  begin
    if Items[IRepository] <> Item then
    begin
      if Items[IRepository].Name = Value then
        raise Exception.Create('Name already defined for this source');
    end;
  end;
end;

function TAuxoFields.Exists(const AName: String): Boolean;
var
  IRepository: Integer;
begin
  Result := Find(AName, IRepository);
end;

function TAuxoFields.Find(const AName: String; out Item: TAuxoField): Boolean;
var
  IRepository: Integer;
begin
  Item := nil;
  if Find(AName, IRepository) then
    Item := Items[IRepository];
  Exit(Assigned(Item));
end;

function TAuxoFields.Add: TAuxoField;
begin
  Result :=  TAuxoField(inherited Add);
end;

function TAuxoFields.Find(const AName: String; out Index: Integer): Boolean;
var
 IRepository: Integer;
 Item: TAuxoField;
 Name: String;
begin
  Result := False;
  Name := AName;
  for IRepository := 0 to Count - 1 do
  begin
    Item := Items[IRepository];
    if Item.Name = Name then
    begin
      Index := IRepository;
      Exit(True);
    end;
  end;
end;

function TAuxoFields.GetItemByIndex(AIndex: Integer): TAuxoField;
begin
  Result := TAuxoField(inherited Items[AIndex]);
end;

function TAuxoFields.GetItemByName(AName: string): TAuxoField;
begin
  Find(AName, Result);
end;

procedure TAuxoFields.Remove(AName: string);
var
  Index: Integer;
begin
  if Find(AName, Index) then
    Delete(Index);
end;

procedure TAuxoFields.SetItemByIndex(AIndex: Integer; const AValue: TAuxoField);
begin
  inherited Items[AIndex] := AValue;
end;

procedure TAuxoFields.SetItemByName(AName: string; const AValue: TAuxoField);
var
  Index: Integer;
begin
  if Find(AName, Index) then
    inherited Items[Index] := AValue;
end;

end.
