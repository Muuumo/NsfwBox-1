unit NsfwBox.Providers.DataBase;

interface
uses
  SysUtils, Classes, XSuperObject, XSuperJSON, DbHelper, System.JSON,
  NsfwBox.Interfaces, NsfwBox.Provider.Pseudo, NsfwBox.Provider.NsfwXxx,
  NsfwBox.Provider.R34App, NsfwBox.Provider.R34JsonApi, NsfwBox.Consts,
  NsfwBox.Helper, Math, system.Generics.Collections, NsfwBox.Logging,
  NsfwBox.Provider.BooruScraper, BooruScraper.Interfaces, BooruScraper.BaseTypes,
  BooruScraper.Serialize.Json, BooruScraper.Serialize.XSuperObject,
  ZExceptions, ZPlainSqLiteDriver,
  Variants, Data.DB;

type

  TNBoxProvidersDb = class(TDbHelper)
    protected
      procedure CreateBase; override;
      function AddProviderFromFields(aFields: TFields;
        aOut: TNBoxProviders): TNBoxProviderInfoCustom;
    public
      procedure UpsertProvider(aProvider: TNBoxProviderInfoCustom);
      procedure UpsertUserCustomProviders(aProviders: TNBoxProviders);
      procedure LoadProvidersTo(aProviders: TNBoxProviders);
  end;

implementation

{ TNBoxBookmarksDb }

function TNBoxProvidersDb.AddProviderFromFields(aFields: TFields;
  aOut: TNBoxProviders): TNBoxProviderInfoCustom;
var
  lParentPvr: Integer;
  lId: integer;
  lTitleName: string;
  lHost: string;
begin
  lParentPvr := aFields.FieldByName('parent_id').AsInteger;
  lId := aFields.FieldByName('id').AsInteger;
  lTitleName := aFields.FieldByName('title_name').AsString;
  lHost := aFields.FieldByName('host').AsString;

  if lParentPvr = PVR_BOORUSCRAPER then
  begin
    Result := aOut.AddCustomBooru(
      lTitleName,
      TBooruScraperClientType(aFields.FieldByName('client_type').AsInteger),
      TBooruScraperParserType(aFields.FieldByName('parser_type').AsInteger),
      lHost,
      lId);
  end else
  begin
    Result := aOut.AddCustom(lTitleName, aOut.ById(lParentPvr), lHost, lId);
  end;
end;

procedure TNBoxProvidersDb.LoadProvidersTo(aProviders: TNBoxProviders);
begin
   try
    Query.SQL.AddStrings([
      'SELECT * FROM providers;'
    ]);

    Query.ExecSQL;
    Query.Open;
    while not Query.Eof do
    begin
      AddProviderFromFields(Query.Fields, aProviders);
      Query.Next;
    end;
  finally
    Query.SQL.Clear;
  end;
end;

procedure TNBoxProvidersDb.UpsertProvider(aProvider: TNBoxProviderInfoCustom);

  procedure SetProviderParams;
  var
    lClientType, lParserType: variant;
  begin
    if (aProvider is TNBoxProviderInfoCustomBooruScraper) then
    begin
      var lBooruPvr := TNBoxProviderInfoCustomBooruScraper(aProvider);
      lClientType := Ord(lBooruPvr.ClientType);
      lParserType := Ord(lBooruPvr.ParserType);
    end else
    begin
      lClientType := Null;
      lParserType := Null;
    end;

    Query.Params.ParamValues['client_type'] := lClientType;
    Query.Params.ParamValues['parser_type'] := lParserType;
  end;

begin
  try
    Query.SQL.AddStrings([
      'INSERT INTO providers (id, parent_id, title_name, host, is_inactive, data,',
      '  client_type, parser_type',
      ')',
      'VALUES (:id, :parent_id, :title_name, :host, :is_inactive, :data,',
      '  :client_type, :parser_type',
      ')',
      'ON CONFLICT(id) DO UPDATE SET',
      '  parent_id = :parent_id,',
      '  title_name = :title_name,',
      '  host = :host,',
      '  is_inactive = :is_inactive,',
      '  data = :data,',
      '  client_type = :client_type,',
      '  parser_type = :parser_type,',
      '  modified_at = :modified_at',
      ';'
    ]);

    with Query.Params do
    begin
      ParamValues['id'] := aProvider.Id;
      ParamValues['parent_id'] := aProvider.RootProviderId;
      ParamValues['title_name'] := aProvider.TitleName;
      ParamValues['host'] := aProvider.Host;
      ParamValues['is_inactive'] := BoolTo(aProvider.IsInactive);
      ParamValues['data'] := '{}';
      ParamValues['modified_at'] := Now;

      SetProviderParams;
    end;

    Query.ExecSQL;
  finally
    Query.SQL.Clear;
  end;
end;

procedure TNBoxProvidersDb.CreateBase;
begin
  try
    SqlProc.Script.AddStrings([
      'CREATE TABLE IF NOT EXISTS providers (',
      '  id         INTEGER PRIMARY KEY AUTOINCREMENT,',
      '  parent_id  INTEGER,',
      '  title_name VARCHAR(255),',
      '  host       TEXT,',
      '  is_inactive BOOLEAN DEFAULT 0,',
      '  data       JSON DEFAULT "{}",', { reserved }

      { provider settings }
      '  client_type INTEGER DEFAULT NULL,',
      '  parser_type INTEGER DEFAULT NULL,',

      { metadata }
      '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,',
      '  modified_at DATETIME DEFAULT CURRENT_TIMESTAMP',
      ');'
    ]);
    SqlProc.Execute;
  finally
    SqlProc.Script.Clear;
  end;
end;

procedure TNBoxProvidersDb.UpsertUserCustomProviders(
  aProviders: TNBoxProviders);
var
  I: integer;
  lPvr: TNBoxProviderInfo;
begin
  for I := 0 to aProviders.Count - 1 do
  begin
    lPvr := aProviders.items[I];
    if lPvr.IsCustom and (not lPvr.IsPredefined) then
      UpsertProvider(TNBoxProviderInfoCustom(lPvr));
  end;
end;

end.
