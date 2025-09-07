unit DPM.Tests.PubGrub.Scenarios;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Spring.Collections,
  VSoft.CancellationToken,
  DPM.Core.Types,
  DPM.Core.Logging,
  DPM.Core.Package.Interfaces,
  DPM.Core.Repository.Interfaces,
  DPM.Core.Configuration.Interfaces,
  DPM.Core.Dependency.Interfaces,
  DPM.Core.Dependency.Version,
  DPM.Core.Dependency.Reference,
  DPM.Core.Dependency.PubGrub.Types,
  DPM.Core.Dependency.PubGrub.Solver,
  DPM.Core.Options.Search;

type
  [TestFixture]
  TTestPubGrubScenarios = class
  private
    FMockRepository: IPackageRepository;
    FLogger: ILogger;
    FConfig: IConfiguration;
    FSolver: IDependencyResolver;
    FCancellationToken: ICancellationToken;
    
    function CreatePackageReference(const PackageId, VersionRange: string): IPackageReference;
    procedure SetupMockPackages;
    
  public
    [Setup]
    procedure Setup;
    
    [TearDown]
    procedure TearDown;
    
    // Basic scenarios
    [Test]
    procedure TestSimpleDependency;
    
    [Test]
    procedure TestDiamondDependency;
    
    [Test]
    procedure TestConflictingConstraints;
    
    [Test]
    procedure TestDeepDependencyChain;
    
    [Test]
    procedure TestCircularDependencyDetection;
    
    [Test]
    procedure TestOptionalDependencies;
    
    [Test]
    procedure TestPrereleasePrecedence;
    
    // Complex scenarios
    [Test]
    procedure TestMultipleConflicts;
    
    [Test]
    procedure TestBacktrackingScenario;
    
    [Test]
    procedure TestNoSolutionScenario;
    
    // Performance scenarios
    [Test]
    procedure TestMediumComplexityGraph;
    
    // Real-world inspired scenarios
    [Test]
    procedure TestDelphi_Spring4D_Scenario;
    
    [Test]
    procedure TestDelphi_DevExpress_Scenario;
  end;

implementation

uses
  DPM.Tests.Mocks,
  DPM.Core.Types;

{ TTestPubGrubScenarios }

procedure TTestPubGrubScenarios.Setup;
begin
  FLogger := TMockLogger.Create;
  FMockRepository := TMockPackageRepository.Create;
  FConfig := TMockConfiguration.Create;
  FSolver := TPubGrubSolver.Create(FMockRepository, FLogger);
  FCancellationToken := TCancellationTokenFactory.Create.CreateToken;
  
  // Initialize solver
  FSolver.Initialize(FConfig);
  
  SetupMockPackages;
end;

procedure TTestPubGrubScenarios.TearDown;
begin
  FSolver := nil;
  FMockRepository := nil;
  FLogger := nil;
  FConfig := nil;
  FCancellationToken := nil;
end;

function TTestPubGrubScenarios.CreatePackageReference(const PackageId, VersionRange: string): IPackageReference;
var
  Range: TVersionRange;
  Version: TPackageVersion;
begin
  Range := TVersionRange.Parse(VersionRange);
  // For mock testing, use the minimum version from range
  Version := Range.MinVersion;
  Result := TPackageReference.Create(nil, PackageId, Version, 
    TDPMPlatform.Win32, TCompilerVersion.RS10_4, Range, False);
end;

procedure TTestPubGrubScenarios.SetupMockPackages;
begin
  // Setup mock package repository with known packages and dependencies
  // This would configure the mock repository with test packages
  
  // Example: Package A 1.0.0 depends on B >= 1.0.0
  TMockPackageRepository(FMockRepository).AddPackage('A', '1.0.0', ['B >= 1.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('B', '1.0.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('B', '1.1.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('B', '2.0.0', []);
  
  // Diamond dependency scenario
  TMockPackageRepository(FMockRepository).AddPackage('Root', '1.0.0', ['Left >= 1.0.0', 'Right >= 1.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('Left', '1.0.0', ['Shared >= 2.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('Right', '1.0.0', ['Shared >= 2.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('Shared', '2.0.0', []);
  
  // Conflict scenario
  TMockPackageRepository(FMockRepository).AddPackage('ConflictRoot', '1.0.0', ['ConflictA >= 1.0.0', 'ConflictB >= 1.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('ConflictA', '1.0.0', ['ConflictShared >= 2.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('ConflictB', '1.0.0', ['ConflictShared < 2.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('ConflictShared', '1.0.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('ConflictShared', '2.0.0', []);
end;

// Test Implementations

procedure TTestPubGrubScenarios.TestSimpleDependency;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('A', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Simple dependency resolution should succeed');
  Assert.AreEqual(2, Result.ResolvedPackages.Count, 'Should resolve A and B');
end;

procedure TTestPubGrubScenarios.TestDiamondDependency;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('Root', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Diamond dependency resolution should succeed');
  Assert.AreEqual(4, Result.ResolvedPackages.Count, 'Should resolve Root, Left, Right, and Shared');
  
  // Verify that the shared dependency has a compatible version
  var SharedPackage := Result.ResolvedPackages.FirstOrDefault(
    function(const pkg: IPackageInfo): Boolean
    begin
      Result := pkg.Id = 'Shared';
    end);
    
  Assert.IsNotNull(SharedPackage, 'Shared package should be resolved');
  Assert.AreEqual('2.0.0', SharedPackage.Version.ToString, 'Should choose version 2.0.0');
end;

procedure TTestPubGrubScenarios.TestConflictingConstraints;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('ConflictRoot', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsFalse(Result.Success, 'Conflicting constraints should fail');
  Assert.Contains(Result.ErrorMessage, 'conflict', 'Error message should mention conflict');
end;

procedure TTestPubGrubScenarios.TestDeepDependencyChain;
var
  Context: IResolverContext;
  Result: IResolveResult;
  I: Integer;
begin
  // Setup deep chain: Level0 -> Level1 -> ... -> Level10
  for I := 0 to 9 do
  begin
    if I = 9 then
      TMockPackageRepository(FMockRepository).AddPackage(Format('Level%d', [I]), '1.0.0', [])
    else
      TMockPackageRepository(FMockRepository).AddPackage(Format('Level%d', [I]), '1.0.0', 
        [Format('Level%d >= 1.0.0', [I + 1])]);
  end;
  
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('Level0', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Deep dependency chain should succeed');
  Assert.AreEqual(10, Result.ResolvedPackages.Count, 'Should resolve all 10 levels');
end;

procedure TTestPubGrubScenarios.TestCircularDependencyDetection;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Setup circular dependency: CircA -> CircB -> CircA
  TMockPackageRepository(FMockRepository).AddPackage('CircA', '1.0.0', ['CircB >= 1.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('CircB', '1.0.0', ['CircA >= 1.0.0']);
  
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('CircA', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsFalse(Result.Success, 'Circular dependency should fail');
  Assert.Contains(Result.ErrorMessage, 'circular', 'Error should mention circular dependency');
end;

procedure TTestPubGrubScenarios.TestOptionalDependencies;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Setup package with optional dependency based on platform
  TMockPackageRepository(FMockRepository).AddPackage('OptionalRoot', '1.0.0', 
    ['RequiredDep >= 1.0.0'], ['OptionalDep >= 1.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('RequiredDep', '1.0.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('OptionalDep', '1.0.0', []);
  
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('OptionalRoot', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Optional dependency resolution should succeed');
  // Optional dependencies handling would depend on specific implementation
end;

procedure TTestPubGrubScenarios.TestPrereleasePrecedence;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Setup packages with prerelease versions
  TMockPackageRepository(FMockRepository).AddPackage('PrereleaseTest', '1.0.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('PrereleaseTest', '1.1.0-alpha', []);
  TMockPackageRepository(FMockRepository).AddPackage('PrereleaseTest', '1.1.0', []);
  
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('PrereleaseTest', '>= 1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Prerelease resolution should succeed');
  
  var ResolvedPackage := Result.ResolvedPackages.First;
  Assert.AreEqual('1.1.0', ResolvedPackage.Version.ToString, 
    'Should prefer stable version over prerelease');
end;

procedure TTestPubGrubScenarios.TestMultipleConflicts;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Setup scenario with multiple conflicting constraints
  TMockPackageRepository(FMockRepository).AddPackage('MultiConflictRoot', '1.0.0', 
    ['Dep1 >= 1.0.0', 'Dep2 >= 1.0.0', 'Dep3 >= 1.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('Dep1', '1.0.0', ['SharedDep >= 3.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('Dep2', '1.0.0', ['SharedDep >= 2.0.0, < 3.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('Dep3', '1.0.0', ['SharedDep < 2.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('SharedDep', '1.0.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('SharedDep', '2.0.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('SharedDep', '3.0.0', []);
  
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('MultiConflictRoot', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsFalse(Result.Success, 'Multiple conflicts should fail');
  Assert.IsTrue(Result.ErrorMessage.Length > 0, 'Should provide error explanation');
end;

procedure TTestPubGrubScenarios.TestBacktrackingScenario;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Setup scenario that requires backtracking to find solution
  TMockPackageRepository(FMockRepository).AddPackage('BacktrackRoot', '1.0.0', ['BacktrackA >= 1.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('BacktrackA', '1.0.0', ['BacktrackB >= 2.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('BacktrackA', '2.0.0', ['BacktrackB >= 1.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('BacktrackB', '1.0.0', []);
  // BacktrackB 2.0.0 intentionally missing to force backtracking
  
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('BacktrackRoot', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Backtracking scenario should succeed');
  
  var ResolvedA := Result.ResolvedPackages.FirstOrDefault(
    function(const pkg: IPackageInfo): Boolean
    begin
      Result := pkg.Id = 'BacktrackA';
    end);
    
  Assert.AreEqual('2.0.0', ResolvedA.Version.ToString, 
    'Should backtrack to version 2.0.0 of BacktrackA');
end;

procedure TTestPubGrubScenarios.TestNoSolutionScenario;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Request a package that doesn't exist
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('NonExistentPackage', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsFalse(Result.Success, 'Non-existent package should fail');
  Assert.Contains(Result.ErrorMessage, 'No versions available', 
    'Should explain that no versions are available');
end;

procedure TTestPubGrubScenarios.TestMediumComplexityGraph;
var
  Context: IResolverContext;
  Result: IResolveResult;
  I, J: Integer;
begin
  // Create a medium complexity dependency graph (20 packages, multiple levels)
  for I := 1 to 20 do
  begin
    var Dependencies := TStringList.Create;
    try
      // Each package depends on 2-3 others (if they exist)
      for J := 1 to Min(3, I - 1) do
        Dependencies.Add(Format('Package%d >= 1.0.0', [I - J]));
        
      TMockPackageRepository(FMockRepository).AddPackage(Format('Package%d', [I]), '1.0.0', 
        Dependencies.ToStringArray);
    finally
      Dependencies.Free;
    end;
  end;
  
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('Package20', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Medium complexity graph should succeed');
  Assert.IsTrue(Result.ResolvedPackages.Count > 10, 'Should resolve many packages');
end;

procedure TTestPubGrubScenarios.TestDelphi_Spring4D_Scenario;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Simulate a realistic Delphi scenario with Spring4D
  TMockPackageRepository(FMockRepository).AddPackage('MyApp', '1.0.0', 
    ['Spring4D >= 2.0.0', 'DUnitX >= 17.0.0']);
  TMockPackageRepository(FMockRepository).AddPackage('Spring4D', '2.0.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('Spring4D', '2.1.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('DUnitX', '17.0.0', []);
  TMockPackageRepository(FMockRepository).AddPackage('DUnitX', '17.1.0', []);
  
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('MyApp', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Delphi Spring4D scenario should succeed');
  Assert.AreEqual(3, Result.ResolvedPackages.Count, 'Should resolve MyApp, Spring4D, and DUnitX');
end;

procedure TTestPubGrubScenarios.TestDelphi_DevExpress_Scenario;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Simulate DevExpress components with version constraints
  TMockPackageRepository(FMockRepository).AddPackage('MyBusinessApp', '1.0.0', 
    ['DevExpress.VCL >= 22.1.0', 'DevExpress.Data >= 22.1.0']);
  TMockPackageRepository(FMockRepository).AddPackage('DevExpress.VCL', '22.1.0', ['DevExpress.Core = 22.1.0']);
  TMockPackageRepository(FMockRepository).AddPackage('DevExpress.Data', '22.1.0', ['DevExpress.Core = 22.1.0']);
  TMockPackageRepository(FMockRepository).AddPackage('DevExpress.Core', '22.1.0', []);
  
  Context := CreateMockContext;
  Context.RootDependencies.Add(CreatePackageReference('MyBusinessApp', '1.0.0'));
  
  Result := FSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'DevExpress scenario should succeed');
  Assert.AreEqual(4, Result.ResolvedPackages.Count, 
    'Should resolve app plus three DevExpress packages');
end;

end.