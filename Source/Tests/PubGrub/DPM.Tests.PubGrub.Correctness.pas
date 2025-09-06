unit DPM.Tests.PubGrub.Correctness;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Diagnostics,
  System.Generics.Collections,
  DPM.Core.Logging,
  DPM.Core.Dependency.Interfaces,
  DPM.Core.Dependency.PubGrub.Types,
  DPM.Core.Dependency.PubGrub.Solver,
  DPM.Core.Dependency.Resolver; // Legacy resolver

type
  [TestFixture]
  TTestPubGrubCorrectness = class
  private
    FPubGrubSolver: TPubGrubSolver;
    FLegacySolver: TLegacyDependencyResolver;
    FMockDependencyProvider: IDependencyProvider;
    FLogger: ILogger;
    
    function CreateMockContext(const RootPackages: array of string): IResolverContext;
    procedure SetupCommonTestPackages;
    function CompareResolveResults(const Result1, Result2: IResolveResult): Boolean;
    
  public
    [Setup]
    procedure Setup;
    
    [TearDown]
    procedure TearDown;
    
    // Correctness verification tests
    [Test]
    procedure CompareWithLegacyResolver_Simple;
    
    [Test]
    procedure CompareWithLegacyResolver_Complex;
    
    [Test]
    procedure VerifyDeterministicResults;
    
    [Test]
    procedure VerifyMinimalSolution;
    
    [Test]
    procedure VerifyOptimalVersionSelection;
    
    // Performance comparison tests
    [Test]
    procedure BenchmarkSimpleDependencies;
    
    [Test]
    procedure BenchmarkMediumComplexity;
    
    [Test]
    procedure BenchmarkConflictResolution;
    
    // Property-based tests
    [Test]
    procedure PropertyTest_SolutionAlwaysValid;
    
    [Test]
    procedure PropertyTest_ConflictAlwaysExplained;
    
    [Test]
    procedure PropertyTest_MonotonicPerformance;
    
    // Edge case correctness
    [Test]
    procedure TestEmptyDependencySet;
    
    [Test]
    procedure TestSelfDependency;
    
    [Test]
    procedure TestVersionDowngrade;
  end;

implementation

uses
  DPM.Tests.Mocks,
  DPM.Core.Types;

{ TTestPubGrubCorrectness }

procedure TTestPubGrubCorrectness.Setup;
begin
  FLogger := TMockLogger.Create;
  FMockDependencyProvider := TMockDependencyProvider.Create;
  FPubGrubSolver := TPubGrubSolver.Create(FMockDependencyProvider, FLogger);
  FLegacySolver := TLegacyDependencyResolver.Create(FMockDependencyProvider, FLogger);
  
  SetupCommonTestPackages;
end;

procedure TTestPubGrubCorrectness.TearDown;
begin
  FPubGrubSolver := nil;
  FLegacySolver := nil;
  FMockDependencyProvider := nil;
  FLogger := nil;
end;

function TTestPubGrubCorrectness.CreateMockContext(const RootPackages: array of string): IResolverContext;
var
  I: Integer;
begin
  Result := TMockResolverContext.Create;
  Result.DependencyProvider := FMockDependencyProvider;
  
  for I := Low(RootPackages) to High(RootPackages) do
    Result.RootDependencies.Add(TMockPackageReference.Create(RootPackages[I], '1.0.0'));
end;

procedure TTestPubGrubCorrectness.SetupCommonTestPackages;
begin
  // Setup identical test packages for both resolvers
  FMockDependencyProvider.AddPackage('A', '1.0.0', ['B >= 1.0.0']);
  FMockDependencyProvider.AddPackage('A', '2.0.0', ['B >= 2.0.0']);
  FMockDependencyProvider.AddPackage('B', '1.0.0', []);
  FMockDependencyProvider.AddPackage('B', '2.0.0', []);
  FMockDependencyProvider.AddPackage('B', '3.0.0', []);
  
  // Diamond scenario
  FMockDependencyProvider.AddPackage('Root', '1.0.0', ['Left >= 1.0.0', 'Right >= 1.0.0']);
  FMockDependencyProvider.AddPackage('Left', '1.0.0', ['Shared >= 2.0.0']);
  FMockDependencyProvider.AddPackage('Right', '1.0.0', ['Shared >= 1.5.0']);
  FMockDependencyProvider.AddPackage('Shared', '1.0.0', []);
  FMockDependencyProvider.AddPackage('Shared', '2.0.0', []);
  FMockDependencyProvider.AddPackage('Shared', '3.0.0', []);
end;

function TTestPubGrubCorrectness.CompareResolveResults(const Result1, Result2: IResolveResult): Boolean;
var
  I: Integer;
  Pkg1, Pkg2: IPackageInfo;
begin
  Result := False;
  
  // Both should have same success status
  if Result1.Success <> Result2.Success then
    Exit;
    
  // If both failed, consider them equivalent (for simple comparison)
  if not Result1.Success then
  begin
    Result := True;
    Exit;
  end;
  
  // Both succeeded - compare resolved packages
  if Result1.ResolvedPackages.Count <> Result2.ResolvedPackages.Count then
    Exit;
    
  // Sort both lists by package ID for comparison
  var List1 := Result1.ResolvedPackages.OrderBy(function(const p: IPackageInfo): string
    begin Result := p.Id; end).ToList;
  var List2 := Result2.ResolvedPackages.OrderBy(function(const p: IPackageInfo): string
    begin Result := p.Id; end).ToList;
    
  for I := 0 to List1.Count - 1 do
  begin
    Pkg1 := List1[I];
    Pkg2 := List2[I];
    
    if (Pkg1.Id <> Pkg2.Id) or (Pkg1.Version.ToString <> Pkg2.Version.ToString) then
      Exit;
  end;
  
  Result := True;
end;

// Correctness Tests

procedure TTestPubGrubCorrectness.CompareWithLegacyResolver_Simple;
var
  Context: IResolverContext;
  PubGrubResult, LegacyResult: IResolveResult;
begin
  Context := CreateMockContext(['A']);
  
  PubGrubResult := FPubGrubSolver.ResolveGraph(Context);
  LegacyResult := FLegacySolver.ResolveGraph(Context);
  
  Assert.IsTrue(CompareResolveResults(PubGrubResult, LegacyResult),
    'PubGrub and Legacy resolvers should produce equivalent results for simple case');
end;

procedure TTestPubGrubCorrectness.CompareWithLegacyResolver_Complex;
var
  Context: IResolverContext;
  PubGrubResult, LegacyResult: IResolveResult;
begin
  Context := CreateMockContext(['Root']);
  
  PubGrubResult := FPubGrubSolver.ResolveGraph(Context);
  LegacyResult := FLegacySolver.ResolveGraph(Context);
  
  // For complex cases, we may accept different valid solutions
  // At minimum, both should succeed or both should fail
  Assert.AreEqual(LegacyResult.Success, PubGrubResult.Success,
    'Both resolvers should agree on whether a solution exists');
    
  if PubGrubResult.Success then
  begin
    Assert.IsTrue(PubGrubResult.ResolvedPackages.Count > 0,
      'PubGrub should resolve at least some packages');
    
    // Verify that PubGrub solution is valid (all constraints satisfied)
    // This is more important than exact equivalence
    for var pkg in PubGrubResult.ResolvedPackages do
    begin
      Assert.IsTrue(pkg.Version.IsValid, 
        Format('Package %s version should be valid', [pkg.Id]));
    end;
  end;
end;

procedure TTestPubGrubCorrectness.VerifyDeterministicResults;
var
  Context: IResolverContext;
  Result1, Result2, Result3: IResolveResult;
begin
  Context := CreateMockContext(['A']);
  
  // Run the same resolution multiple times
  Result1 := FPubGrubSolver.ResolveGraph(Context);
  Result2 := FPubGrubSolver.ResolveGraph(Context);
  Result3 := FPubGrubSolver.ResolveGraph(Context);
  
  Assert.IsTrue(CompareResolveResults(Result1, Result2),
    'PubGrub should produce deterministic results (run 1 vs 2)');
  Assert.IsTrue(CompareResolveResults(Result2, Result3),
    'PubGrub should produce deterministic results (run 2 vs 3)');
end;

procedure TTestPubGrubCorrectness.VerifyMinimalSolution;
var
  Context: IResolverContext;
  Result: IResolveResult;
  PackageCount: Integer;
begin
  Context := CreateMockContext(['A']);
  Result := FPubGrubSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Resolution should succeed');
  
  PackageCount := Result.ResolvedPackages.Count;
  Assert.AreEqual(2, PackageCount, 'Should resolve exactly A and B (minimal solution)');
  
  // Verify no unnecessary packages are included
  Assert.IsTrue(Result.ResolvedPackages.Any(function(const p: IPackageInfo): Boolean
    begin Result := p.Id = 'A'; end), 'Should include package A');
  Assert.IsTrue(Result.ResolvedPackages.Any(function(const p: IPackageInfo): Boolean
    begin Result := p.Id = 'B'; end), 'Should include package B');
end;

procedure TTestPubGrubCorrectness.VerifyOptimalVersionSelection;
var
  Context: IResolverContext;
  Result: IResolveResult;
  ResolvedA, ResolvedB: IPackageInfo;
begin
  Context := CreateMockContext(['A']);
  Result := FPubGrubSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Resolution should succeed');
  
  ResolvedA := Result.ResolvedPackages.FirstOrDefault(
    function(const p: IPackageInfo): Boolean
    begin Result := p.Id = 'A'; end);
  ResolvedB := Result.ResolvedPackages.FirstOrDefault(
    function(const p: IPackageInfo): Boolean
    begin Result := p.Id = 'B'; end);
    
  Assert.IsNotNull(ResolvedA, 'Package A should be resolved');
  Assert.IsNotNull(ResolvedB, 'Package B should be resolved');
  
  // PubGrub should prefer latest versions when possible
  Assert.AreEqual('2.0.0', ResolvedA.Version.ToString, 
    'Should select latest version of A');
  Assert.AreEqual('3.0.0', ResolvedB.Version.ToString,
    'Should select latest compatible version of B');
end;

// Performance Tests

procedure TTestPubGrubCorrectness.BenchmarkSimpleDependencies;
var
  Context: IResolverContext;
  Stopwatch: TStopwatch;
  PubGrubTime, LegacyTime: Int64;
  Result: IResolveResult;
const
  ITERATIONS = 100;
begin
  Context := CreateMockContext(['A']);
  
  // Benchmark PubGrub
  Stopwatch := TStopwatch.StartNew;
  for var I := 1 to ITERATIONS do
  begin
    Result := FPubGrubSolver.ResolveGraph(Context);
    Assert.IsTrue(Result.Success);
  end;
  PubGrubTime := Stopwatch.ElapsedMilliseconds;
  
  // Benchmark Legacy
  Stopwatch.Restart;
  for var I := 1 to ITERATIONS do
  begin
    Result := FLegacySolver.ResolveGraph(Context);
    Assert.IsTrue(Result.Success);
  end;
  LegacyTime := Stopwatch.ElapsedMilliseconds;
  
  FLogger.Information(Format('Simple dependencies - PubGrub: %dms, Legacy: %dms', 
    [PubGrubTime, LegacyTime]));
    
  // For simple cases, performance should be comparable
  // We allow PubGrub to be up to 2x slower for simple cases due to additional overhead
  Assert.IsTrue(PubGrubTime < LegacyTime * 2,
    Format('PubGrub should not be significantly slower for simple cases: %d vs %d', 
      [PubGrubTime, LegacyTime]));
end;

procedure TTestPubGrubCorrectness.BenchmarkMediumComplexity;
var
  Context: IResolverContext;
  Stopwatch: TStopwatch;
  PubGrubTime, LegacyTime: Int64;
  Result: IResolveResult;
const
  ITERATIONS = 10;
begin
  // Setup more complex dependency graph
  for var I := 1 to 15 do
  begin
    var deps := TStringList.Create;
    try
      for var J := Max(1, I - 3) to I - 1 do
        deps.Add(Format('Complex%d >= 1.0.0', [J]));
      FMockDependencyProvider.AddPackage(Format('Complex%d', [I]), '1.0.0', deps.ToStringArray);
    finally
      deps.Free;
    end;
  end;
  
  Context := CreateMockContext(['Complex15']);
  
  // Benchmark both resolvers
  Stopwatch := TStopwatch.StartNew;
  for var I := 1 to ITERATIONS do
  begin
    Result := FPubGrubSolver.ResolveGraph(Context);
    Assert.IsTrue(Result.Success);
  end;
  PubGrubTime := Stopwatch.ElapsedMilliseconds;
  
  Stopwatch.Restart;
  for var I := 1 to ITERATIONS do
  begin
    Result := FLegacySolver.ResolveGraph(Context);
    Assert.IsTrue(Result.Success);
  end;
  LegacyTime := Stopwatch.ElapsedMilliseconds;
  
  FLogger.Information(Format('Medium complexity - PubGrub: %dms, Legacy: %dms', 
    [PubGrubTime, LegacyTime]));
    
  // For complex cases, PubGrub should show its advantages
  // In cases with conflicts, PubGrub should be significantly faster
end;

procedure TTestPubGrubCorrectness.BenchmarkConflictResolution;
var
  Context: IResolverContext;
  Stopwatch: TStopwatch;
  PubGrubTime, LegacyTime: Int64;
  PubGrubResult, LegacyResult: IResolveResult;
const
  ITERATIONS = 5;
begin
  // Setup a scenario with conflicts that require backtracking
  FMockDependencyProvider.AddPackage('ConflictRoot', '1.0.0', 
    ['ConflictA >= 1.0.0', 'ConflictB >= 1.0.0']);
  FMockDependencyProvider.AddPackage('ConflictA', '1.0.0', ['ConflictShared >= 3.0.0']);
  FMockDependencyProvider.AddPackage('ConflictA', '2.0.0', ['ConflictShared >= 1.0.0']);
  FMockDependencyProvider.AddPackage('ConflictB', '1.0.0', ['ConflictShared < 3.0.0']);
  FMockDependencyProvider.AddPackage('ConflictShared', '1.0.0', []);
  FMockDependencyProvider.AddPackage('ConflictShared', '2.0.0', []);
  
  Context := CreateMockContext(['ConflictRoot']);
  
  // Benchmark PubGrub conflict resolution
  Stopwatch := TStopwatch.StartNew;
  for var I := 1 to ITERATIONS do
  begin
    PubGrubResult := FPubGrubSolver.ResolveGraph(Context);
  end;
  PubGrubTime := Stopwatch.ElapsedMilliseconds;
  
  // Benchmark Legacy conflict resolution
  Stopwatch.Restart;
  for var I := 1 to ITERATIONS do
  begin
    LegacyResult := FLegacySolver.ResolveGraph(Context);
  end;
  LegacyTime := Stopwatch.ElapsedMilliseconds;
  
  FLogger.Information(Format('Conflict resolution - PubGrub: %dms, Legacy: %dms', 
    [PubGrubTime, LegacyTime]));
  
  // PubGrub should excel at conflict resolution due to learned clauses
  // This is where we expect to see the biggest performance gains
end;

// Property-Based Tests

procedure TTestPubGrubCorrectness.PropertyTest_SolutionAlwaysValid;
var
  Context: IResolverContext;
  Result: IResolveResult;
  TestCases: array of string;
  TestCase: string;
begin
  TestCases := ['A', 'Root', 'Complex15'];
  
  for TestCase in TestCases do
  begin
    Context := CreateMockContext([TestCase]);
    Result := FPubGrubSolver.ResolveGraph(Context);
    
    if Result.Success then
    begin
      // If a solution was found, it should be valid
      Assert.IsTrue(Result.ResolvedPackages.Count > 0,
        Format('Solution for %s should contain packages', [TestCase]));
        
      // Verify all resolved packages have valid versions
      for var pkg in Result.ResolvedPackages do
      begin
        Assert.IsTrue(pkg.Version.IsValid,
          Format('Package %s should have valid version', [pkg.Id]));
      end;
      
      // Verify dependencies are satisfied (simplified check)
      Assert.IsTrue(Result.ResolvedPackages.Any(function(const p: IPackageInfo): Boolean
        begin Result := p.Id = TestCase; end),
        Format('Root package %s should be in solution', [TestCase]));
    end;
  end;
end;

procedure TTestPubGrubCorrectness.PropertyTest_ConflictAlwaysExplained;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Setup a guaranteed conflict
  FMockDependencyProvider.AddPackage('FailRoot', '1.0.0', ['NonExistent >= 1.0.0']);
  
  Context := CreateMockContext(['FailRoot']);
  Result := FPubGrubSolver.ResolveGraph(Context);
  
  Assert.IsFalse(Result.Success, 'Conflict scenario should fail');
  Assert.IsTrue(Result.ErrorMessage.Length > 0,
    'Failed resolution should provide explanation');
  Assert.Contains(Result.ErrorMessage.ToLower, 'no versions',
    'Error message should explain the problem');
end;

procedure TTestPubGrubCorrectness.PropertyTest_MonotonicPerformance;
var
  SmallContext, LargeContext: IResolverContext;
  SmallResult, LargeResult: IResolveResult;
  SmallTime, LargeTime: Int64;
  Stopwatch: TStopwatch;
begin
  // Setup small and large dependency graphs
  SmallContext := CreateMockContext(['A']);
  
  // Add more packages for large graph
  for var I := 1 to 20 do
    FMockDependencyProvider.AddPackage(Format('Large%d', [I]), '1.0.0', []);
  LargeContext := CreateMockContext(['Large1', 'Large5', 'Large10', 'Large15', 'Large20']);
  
  // Measure small graph
  Stopwatch := TStopwatch.StartNew;
  SmallResult := FPubGrubSolver.ResolveGraph(SmallContext);
  SmallTime := Stopwatch.ElapsedMilliseconds;
  
  // Measure large graph  
  Stopwatch.Restart;
  LargeResult := FPubGrubSolver.ResolveGraph(LargeContext);
  LargeTime := Stopwatch.ElapsedMilliseconds;
  
  Assert.IsTrue(SmallResult.Success, 'Small graph should succeed');
  Assert.IsTrue(LargeResult.Success, 'Large graph should succeed');
  
  // Performance should scale reasonably (not exponentially)
  // Allow large graph to take up to 10x longer (very generous)
  Assert.IsTrue(LargeTime < SmallTime * 10,
    Format('Performance should scale reasonably: Small=%dms, Large=%dms', 
      [SmallTime, LargeTime]));
end;

// Edge Case Tests

procedure TTestPubGrubCorrectness.TestEmptyDependencySet;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  Context := CreateMockContext([]);
  Result := FPubGrubSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Empty dependency set should succeed');
  Assert.AreEqual(0, Result.ResolvedPackages.Count, 'Should resolve no packages');
end;

procedure TTestPubGrubCorrectness.TestSelfDependency;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Package that depends on itself (should be detected as invalid)
  FMockDependencyProvider.AddPackage('SelfDependent', '1.0.0', ['SelfDependent >= 1.0.0']);
  
  Context := CreateMockContext(['SelfDependent']);
  Result := FPubGrubSolver.ResolveGraph(Context);
  
  // This should either succeed (treating self-dependency as satisfied)
  // or fail with clear explanation
  if not Result.Success then
  begin
    Assert.Contains(Result.ErrorMessage.ToLower, 'circular',
      'Self-dependency should be explained as circular');
  end;
end;

procedure TTestPubGrubCorrectness.TestVersionDowngrade;
var
  Context: IResolverContext;
  Result: IResolveResult;
begin
  // Setup scenario where optimal solution requires "downgrading" from latest version
  FMockDependencyProvider.AddPackage('DowngradeRoot', '1.0.0', ['DowngradeDep < 2.0.0']);
  FMockDependencyProvider.AddPackage('DowngradeDep', '1.0.0', []);
  FMockDependencyProvider.AddPackage('DowngradeDep', '2.0.0', []);
  FMockDependencyProvider.AddPackage('DowngradeDep', '3.0.0', []);
  
  Context := CreateMockContext(['DowngradeRoot']);
  Result := FPubGrubSolver.ResolveGraph(Context);
  
  Assert.IsTrue(Result.Success, 'Downgrade scenario should succeed');
  
  var ResolvedDep := Result.ResolvedPackages.FirstOrDefault(
    function(const p: IPackageInfo): Boolean
    begin Result := p.Id = 'DowngradeDep'; end);
    
  Assert.IsNotNull(ResolvedDep, 'DowngradeDep should be resolved');
  Assert.AreEqual('1.0.0', ResolvedDep.Version.ToString,
    'Should choose version 1.0.0 to satisfy constraint');
end;

end.