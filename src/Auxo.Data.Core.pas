unit Auxo.Data.Core;

interface

uses
  System.Generics.Collections, System.Classes, Auxo.Access.Core, Auxo.Core.Observer, Auxo.Query, System.Variants, System.SysUtils;

const
  IDataProvider_ID = '{13BDB707-9013-4148-BAEB-1DBC7AF57D09}';
  IDataProvider_GUID: TGUID = IDataProvider_ID;

const
  BindToControls: TGUID = '{9CC11F4C-9CB0-40DD-A326-B4F51FEF28A3}';
  BindToSource: TGUID = '{A6A2F20D-0405-411A-95DC-FE7B98827B0C}';

type
  TReadMethod = (Get, Count, Load);
  TReadMethods = set of TReadMethod;
  TMasterMode = (FilterRecords, SourceMaster);


  TMasterParameter = record
  public
    MasterMode: TMasterMode;
    KeyField: string;
    KeyValue: Variant;
  end;

  TRepositoryParameters = record
  public
    Query: IQuery;
    Source: string;
    KeyField: string;
    KeyValue: Variant;
    Master: TMasterParameter;
    AsyncMethods: TReadMethods;
  end;

  IRepository = interface
  [IDataProvider_ID]
    procedure Get(Parameters: TRepositoryParameters; ACallback: TProc<IRecord>);
    procedure Count(Parameters: TRepositoryParameters; ACallback: TProc<Integer>);
    procedure Load(Parameters: TRepositoryParameters; ACallback: TProc<IRecordList>); overload;
    procedure Load(Parameters: TRepositoryParameters; ACallback: TProc<IRecord>); overload;
    function New(Parameters: TRepositoryParameters): IRecord;
    function Insert(Parameters: TRepositoryParameters; var ARecord: IRecord): Boolean;
    function Update(Parameters: TRepositoryParameters; var ARecord: IRecord): Boolean;
    function Delete(Parameters: TRepositoryParameters): Boolean;
  end;

implementation


end.


