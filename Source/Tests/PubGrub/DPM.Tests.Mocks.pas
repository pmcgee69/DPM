unit DPM.Tests.Mocks;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Classes,
  Spring.Collections,
  VSoft.CancellationToken,
  DPM.Core.Types,
  DPM.Core.Logging,
  DPM.Core.Package.Interfaces,
  DPM.Core.Repository.Interfaces,
  DPM.Core.Configuration.Interfaces,
  DPM.Core.Dependency.Interfaces,
  DPM.Core.Dependency.Version,
  DPM.Core.Options.Search,
  DPM.Core.Options.Push,
  JsonDataObjects;

type
  /// <summary>
  /// Mock logger for testing
  /// </summary>
  TMockLogger = class(TInterfacedObject, ILogger)
  private
    FMessages: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Debug(const data: string);
    procedure Verbose(const data: string; const important: Boolean = False);
    procedure Information(const data: string; const important: Boolean = False);
    procedure Warning(const data: string; const important: Boolean = False);
    procedure Error(const data: string);
    procedure Success(const data: string; const important: Boolean = False);
    
    procedure Clear;
    procedure NewLine;
    function GetVerbosity: TVerbosity;
    procedure SetVerbosity(const Value: TVerbosity);
    
    function GetMessages: TList<string>;
    property Messages: TList<string> read GetMessages;
  end;

  /// <summary>
  /// Mock package repository for testing
  /// </summary>
  TMockPackageRepository = class(TInterfacedObject, IPackageRepository)
  private
    FPackages: TDictionary<string, IList<IPackageInfo>>;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure AddPackage(const PackageId, Version: string; const Dependencies: array of string);
    
    // IPackageRepository interface methods
    function GetRepositoryType: TSourceType;
    function GetName: string;
    function GetSource: string;
    procedure Configure(const source: ISourceConfig);
    function GetEnabled: Boolean;
    procedure SetEnabled(const value: Boolean);
    
    // Core methods matching current IPackageRepository interface
    function FindLatestVersion(const cancellationToken: ICancellationToken; const id: string; const compilerVersion: TCompilerVersion; const version: TPackageVersion; const platform: TDPMPlatform; const includePrerelease: Boolean): IPackageInfo;
    function DownloadPackage(const cancellationToken: ICancellationToken; const packageInfo: IPackageInfo; const localFolder: string; var fileName: string): Boolean;
    function GetPackageVersions(const cancellationToken: ICancellationToken; const id: string; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform; const preRelease: Boolean): IList<TPackageVersion>;
    function GetPackageVersionsWithDependencies(const cancellationToken: ICancellationToken; const id: string; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform; const versionRange: TVersionRange; const preRelease: Boolean): IList<IPackageInfo>;
    function GetPackageInfo(const cancellationToken: ICancellationToken; const packageId: IPackageIdentity): IPackageInfo;
    
    // Additional required interface methods
    function GetPackageIcon(const cancellationToken: ICancellationToken; const packageId: string; const packageVersion: string; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform): IPackageIcon;
    function GetPackageMetaData(const cancellationToken: ICancellationToken; const packageId: string; const packageVersion: string; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform): IPackageSearchResultItem;
    function GetPackageFeed(const cancellationToken: ICancellationToken; const options: TSearchOptions; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform): IPackageSearchResult;
    function GetPackageFeedByIds(const cancellationToken: ICancellationToken; const ids: IList<IPackageIdentity>; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform): IPackageSearchResult;
    function Push(const cancellationToken: ICancellationToken; const pushOptions: TPushOptions): Boolean;
    function List(const cancellationToken: ICancellationToken; const options: TSearchOptions): IList<IPackageListItem>;
  end;

  /// <summary>
  /// Mock configuration for testing
  /// </summary>
  TMockConfiguration = class(TInterfacedObject, IConfiguration)
  public
    // IConfiguration interface methods
    function GetUsePubGrub: Boolean;
    procedure SetUsePubGrub(const Value: Boolean);
    function GetPubGrubMaxBacktracks: Integer;
    procedure SetPubGrubMaxBacktracks(const Value: Integer);
    function GetPubGrubConflictExplanationDepth: Integer;
    procedure SetPubGrubConflictExplanationDepth(const Value: Integer);
    function GetPackageCacheLocation: string;
    procedure SetPackageCacheLocation(const Value: string);
    function GetIsDefaultPackageCacheLocation: Boolean;
    procedure AddDefaultSources;
    function GetSourceByName(const sourceName: string): ISourceConfig;
    function GetSources: IList<ISourceConfig>;
    function GetFileName: string;
    procedure SetFileName(const Value: string);
    // IConfigNode methods
    function LoadFromJson(const jsonObj: TJsonObject): Boolean;
    function SaveToJson(const parentObj: TJsonObject): Boolean;
  end;

implementation

{ TMockLogger }

constructor TMockLogger.Create;
begin
  inherited;
  FMessages := TList<string>.Create;
end;

destructor TMockLogger.Destroy;
begin
  FMessages.Free;
  inherited;
end;

procedure TMockLogger.Debug(const data: string);
begin
  FMessages.Add('DEBUG: ' + data);
end;

procedure TMockLogger.Verbose(const data: string; const important: Boolean);
begin
  FMessages.Add('VERBOSE: ' + data);
end;

procedure TMockLogger.Information(const data: string; const important: Boolean);
begin
  FMessages.Add('INFO: ' + data);
end;

procedure TMockLogger.Warning(const data: string; const important: Boolean);
begin
  FMessages.Add('WARNING: ' + data);
end;

procedure TMockLogger.Error(const data: string);
begin
  FMessages.Add('ERROR: ' + data);
end;

procedure TMockLogger.Success(const data: string; const important: Boolean);
begin
  FMessages.Add('SUCCESS: ' + data);
end;

procedure TMockLogger.Clear;
begin
  FMessages.Clear;
end;

procedure TMockLogger.NewLine;
begin
  FMessages.Add('');
end;

function TMockLogger.GetVerbosity: TVerbosity;
begin
  Result := TVerbosity.Normal; // Default
end;

procedure TMockLogger.SetVerbosity(const Value: TVerbosity);
begin
  // Placeholder
end;

function TMockLogger.GetMessages: TList<string>;
begin
  Result := FMessages;
end;

{ TMockPackageRepository }

constructor TMockPackageRepository.Create;
begin
  inherited;
  FPackages := TDictionary<string, IList<IPackageInfo>>.Create;
end;

destructor TMockPackageRepository.Destroy;
begin
  FPackages.Free;
  inherited;
end;

procedure TMockPackageRepository.AddPackage(const PackageId, Version: string; const Dependencies: array of string);
var
  packageList: IList<IPackageInfo>;
begin
  // Simple implementation for testing - just ensure the package ID exists in our dictionary
  if not FPackages.ContainsKey(PackageId) then
  begin
    packageList := TCollections.CreateList<IPackageInfo>;
    FPackages.Add(PackageId, packageList);
  end;
  // For now, just register that this package/version exists
  // Full IPackageInfo mock implementation would be needed for complete functionality
end;


function TMockPackageRepository.GetPackageInfo(const cancellationToken: ICancellationToken; const packageId: IPackageIdentity): IPackageInfo;
begin
  // Placeholder - would return mock package info
  Result := nil;
end;

function TMockPackageRepository.GetRepositoryType: TSourceType;
begin
  Result := TSourceType.Folder; // Default for testing
end;

function TMockPackageRepository.GetName: string;
begin
  Result := 'MockRepository';
end;

function TMockPackageRepository.GetSource: string;
begin
  Result := 'Mock Source';
end;

procedure TMockPackageRepository.Configure(const source: ISourceConfig);
begin
  // Placeholder
end;

function TMockPackageRepository.GetEnabled: Boolean;
begin
  Result := True; // Default enabled
end;

procedure TMockPackageRepository.SetEnabled(const value: Boolean);
begin
  // Placeholder
end;

function TMockPackageRepository.FindLatestVersion(const cancellationToken: ICancellationToken; const id: string; const compilerVersion: TCompilerVersion; const version: TPackageVersion; const platform: TDPMPlatform; const includePrerelease: Boolean): IPackageInfo;
begin
  Result := nil; // Placeholder
end;

function TMockPackageRepository.DownloadPackage(const cancellationToken: ICancellationToken; const packageInfo: IPackageInfo; const localFolder: string; var fileName: string): Boolean;
begin
  fileName := '';
  Result := False; // Placeholder
end;

function TMockPackageRepository.GetPackageVersions(const cancellationToken: ICancellationToken; const id: string; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform; const preRelease: Boolean): IList<TPackageVersion>;
begin
  Result := TCollections.CreateList<TPackageVersion>; // Return empty list
end;

function TMockPackageRepository.GetPackageVersionsWithDependencies(const cancellationToken: ICancellationToken; const id: string; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform; const versionRange: TVersionRange; const preRelease: Boolean): IList<IPackageInfo>;
begin
  Result := TCollections.CreateList<IPackageInfo>; // Return empty list for now
end;


function TMockPackageRepository.GetPackageIcon(const cancellationToken: ICancellationToken; const packageId: string; const packageVersion: string; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform): IPackageIcon;
begin
  Result := nil; // Placeholder
end;

function TMockPackageRepository.GetPackageMetaData(const cancellationToken: ICancellationToken; const packageId: string; const packageVersion: string; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform): IPackageSearchResultItem;
begin
  Result := nil; // Placeholder
end;

function TMockPackageRepository.GetPackageFeed(const cancellationToken: ICancellationToken; const options: TSearchOptions; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform): IPackageSearchResult;
begin
  Result := nil; // Placeholder
end;

function TMockPackageRepository.GetPackageFeedByIds(const cancellationToken: ICancellationToken; const ids: IList<IPackageIdentity>; const compilerVersion: TCompilerVersion; const platform: TDPMPlatform): IPackageSearchResult;
begin
  Result := nil; // Placeholder
end;

function TMockPackageRepository.Push(const cancellationToken: ICancellationToken; const pushOptions: TPushOptions): Boolean;
begin
  Result := False; // Placeholder
end;

function TMockPackageRepository.List(const cancellationToken: ICancellationToken; const options: TSearchOptions): IList<IPackageListItem>;
begin
  Result := nil; // Placeholder
end;

{ TMockConfiguration }

function TMockConfiguration.GetUsePubGrub: Boolean;
begin
  Result := True; // Default to PubGrub for testing
end;

procedure TMockConfiguration.SetUsePubGrub(const Value: Boolean);
begin
  // Placeholder
end;

function TMockConfiguration.GetPubGrubMaxBacktracks: Integer;
begin
  Result := 1000; // Test default
end;

procedure TMockConfiguration.SetPubGrubMaxBacktracks(const Value: Integer);
begin
  // Placeholder
end;

function TMockConfiguration.GetPubGrubConflictExplanationDepth: Integer;
begin
  Result := 5; // Test default
end;

procedure TMockConfiguration.SetPubGrubConflictExplanationDepth(const Value: Integer);
begin
  // Placeholder
end;

function TMockConfiguration.GetPackageCacheLocation: string;
begin
  Result := 'C:\MockCache'; // Placeholder
end;

procedure TMockConfiguration.SetPackageCacheLocation(const Value: string);
begin
  // Placeholder
end;

function TMockConfiguration.GetIsDefaultPackageCacheLocation: Boolean;
begin
  Result := True; // Placeholder
end;

procedure TMockConfiguration.AddDefaultSources;
begin
  // Placeholder
end;

function TMockConfiguration.GetSourceByName(const sourceName: string): ISourceConfig;
begin
  Result := nil; // Placeholder
end;

function TMockConfiguration.GetSources: IList<ISourceConfig>;
begin
  Result := nil; // Placeholder
end;

function TMockConfiguration.GetFileName: string;
begin
  Result := 'MockConfig.json'; // Placeholder
end;

procedure TMockConfiguration.SetFileName(const Value: string);
begin
  // Placeholder
end;

function TMockConfiguration.LoadFromJson(const jsonObj: TJsonObject): Boolean;
begin
  Result := True; // Placeholder
end;

function TMockConfiguration.SaveToJson(const parentObj: TJsonObject): Boolean;
begin
  Result := True; // Placeholder
end;

end.