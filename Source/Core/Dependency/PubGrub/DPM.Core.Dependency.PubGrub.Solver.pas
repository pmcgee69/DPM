unit DPM.Core.Dependency.PubGrub.Solver;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DPM.Core.Logging,
  DPM.Core.Dependency.Interfaces,
  DPM.Core.Dependency.Version,
  DPM.Core.Dependency.PubGrub.Types;

type
  /// <summary>
  /// Main PubGrub dependency resolution algorithm implementation
  /// Based on conflict-driven clause learning (CDCL) from SAT solving
  /// </summary>
  TPubGrubSolver = class(TInterfacedObject, IDependencyResolver)
  private
    FPartialSolution: IPartialSolution;
    FIncompatibilityStore: IIncompatibilityStore;
    FDependencyProvider: IDependencyProvider;
    FLogger: ILogger;
    FOptions: TPubGrubOptions;
    FBacktrackCount: Integer;
    FSolveStartTime: TDateTime;
    
    // Core PubGrub algorithm methods
    function UnitPropagate(const PackageId: string): Boolean;
    function ChoosePackageVersion: IAssignment;
    function Conflict(const Incompatibility: IIncompatibility): TConflictResolution;
    function Resolve(const Incompatibility: IIncompatibility): IIncompatibility;
    
    // Helper methods
    procedure AddIncompatibility(const Incompatibility: IIncompatibility);
    procedure AddRootIncompatibilities(const RootDependencies: IList<IPackageReference>);
    procedure AddPackageDependencyIncompatibilities(const PackageId: string; const Version: TPackageVersion);
    function GetCandidateVersions(const PackageId: string; const Constraint: IVersionRange): IList<TPackageVersion>;
    function FindMostConstrainedPackage: string;
    
    // Conflict analysis
    function AnalyzeConflict(const Incompatibility: IIncompatibility): TConflictResolution;
    function FindDecisionLevel(const Incompatibility: IIncompatibility): Integer;
    function ExplainFailure(const Incompatibility: IIncompatibility): string;
    
    // Logging and debugging
    procedure LogDecision(const Assignment: IAssignment);
    procedure LogDerivation(const Assignment: IAssignment);
    procedure LogBacktrack(const Level: Integer);
    procedure LogConflict(const Incompatibility: IIncompatibility);
    
  public
    constructor Create(const ADependencyProvider: IDependencyProvider; const ALogger: ILogger);
    constructor CreateWithOptions(const ADependencyProvider: IDependencyProvider; 
      const ALogger: ILogger; const AOptions: TPubGrubOptions);
      
    function ResolveGraph(const Context: IResolverContext): IResolveResult;
    function GetResolverType: TResolverType;
    
    property Options: TPubGrubOptions read FOptions write FOptions;
  end;

implementation

uses
  System.DateUtils,
  System.Math,
  DPM.Core.Dependency.PubGrub.PartialSolution,
  DPM.Core.Dependency.PubGrub.IncompatibilityStore,
  DPM.Core.Dependency.PubGrub.Incompatibility,
  DPM.Core.Dependency.PubGrub.Term,
  DPM.Core.Dependency.PubGrub.Assignment,
  DPM.Core.Dependency.Resolution;

{ TPubGrubSolver }

constructor TPubGrubSolver.Create(const ADependencyProvider: IDependencyProvider; const ALogger: ILogger);
begin
  CreateWithOptions(ADependencyProvider, ALogger, TPubGrubOptions.Default);
end;

constructor TPubGrubSolver.CreateWithOptions(const ADependencyProvider: IDependencyProvider; 
  const ALogger: ILogger; const AOptions: TPubGrubOptions);
begin
  inherited Create;
  
  if ADependencyProvider = nil then
    raise EArgumentNilException.Create('DependencyProvider cannot be nil');
  if ALogger = nil then
    raise EArgumentNilException.Create('Logger cannot be nil');
    
  FDependencyProvider := ADependencyProvider;
  FLogger := ALogger;
  FOptions := AOptions;
  
  FPartialSolution := TPartialSolution.Create;
  FIncompatibilityStore := TIncompatibilityStore.Create;
  FBacktrackCount := 0;
end;

function TPubGrubSolver.GetResolverType: TResolverType;
begin
  Result := rtPubGrub;
end;

function TPubGrubSolver.ResolveGraph(const Context: IResolverContext): IResolveResult;
var
  NextAssignment: IAssignment;
  ConflictingIncompatibility: IIncompatibility;
  Resolution: TConflictResolution;
begin
  FSolveStartTime := Now;
  FBacktrackCount := 0;
  
  try
    FLogger.Information('PubGrub solver starting dependency resolution');
    
    // Initialize with root dependencies
    AddRootIncompatibilities(Context.RootDependencies);
    
    // Main solving loop
    while True do
    begin
      // Unit propagation - derive what we can
      if not UnitPropagate('') then
      begin
        // No more unit propagation possible, make a decision
        NextAssignment := ChoosePackageVersion;
        
        if NextAssignment = nil then
        begin
          // No more decisions needed - we have a solution!
          FLogger.Information('PubGrub solver found solution');
          Result := CreateSuccessResult;
          Exit;
        end;
        
        LogDecision(NextAssignment);
        FPartialSolution.AddAssignment(NextAssignment);
        
        // Add dependencies for the chosen version
        AddPackageDependencyIncompatibilities(NextAssignment.PackageId, 
          NextAssignment.VersionRange.MinVersion);
      end
      else
      begin
        // Unit propagation found a conflict
        ConflictingIncompatibility := FindConflictingIncompatibility;
        if ConflictingIncompatibility = nil then
          Continue; // No conflict after all, continue
          
        LogConflict(ConflictingIncompatibility);
        
        // Analyze the conflict and determine what to do
        Resolution := Conflict(ConflictingIncompatibility);
        
        if Resolution.BacktrackLevel < 0 then
        begin
          // Unresolvable conflict - no solution exists
          FLogger.Error('PubGrub solver: No solution exists');
          Result := CreateFailureResult(ExplainFailure(Resolution.Incompatibility));
          Exit;
        end;
        
        // Backtrack and learn from the conflict
        LogBacktrack(Resolution.BacktrackLevel);
        FPartialSolution.Backtrack(Resolution.BacktrackLevel);
        AddIncompatibility(Resolution.Incompatibility);
        
        Inc(FBacktrackCount);
        if FBacktrackCount > FOptions.MaxBacktracks then
        begin
          FLogger.Error('PubGrub solver: Maximum backtrack limit exceeded');
          Result := CreateFailureResult('Dependency resolution too complex - exceeded backtrack limit');
          Exit;
        end;
      end;
    end;
    
  except
    on E: Exception do
    begin
      FLogger.Error('PubGrub solver error: ' + E.Message);
      Result := CreateFailureResult('Internal solver error: ' + E.Message);
    end;
  end;
end;

function TPubGrubSolver.UnitPropagate(const PackageId: string): Boolean;
var
  Incompatibility: IIncompatibility;
  UnsatisfiedTerms: IList<ITerm>;
  Term: ITerm;
  NewAssignment: IAssignment;
  IntersectedRange: IVersionRange;
begin
  Result := False;
  
  // Check all incompatibilities for unit propagation opportunities
  for Incompatibility in FIncompatibilityStore.GetAll do
  begin
    UnsatisfiedTerms := FPartialSolution.GetUnsatisfied(Incompatibility.Terms);
    
    if UnsatisfiedTerms.Count = 0 then
    begin
      // All terms are satisfied - this is a conflict
      Result := True;
      Exit;
    end
    else if UnsatisfiedTerms.Count = 1 then
    begin
      // Unit clause - we can derive an assignment
      Term := UnsatisfiedTerms[0];
      
      if Term.Positive then
      begin
        // Positive term: we must assign this package to satisfy the range
        IntersectedRange := FPartialSolution.GetIntersection(Term.PackageId, Term.VersionRange);
        
        if (IntersectedRange <> nil) and not IntersectedRange.IsEmpty then
        begin
          NewAssignment := FPartialSolution.AddDerivation(Term.PackageId, 
            IntersectedRange, Incompatibility);
          LogDerivation(NewAssignment);
          Result := True;
        end;
      end
      else
      begin
        // Negative term: we must ensure this package doesn't satisfy the range
        // This is more complex and may require constraint propagation
        // For now, we'll handle it in conflict analysis
      end;
    end;
  end;
end;

function TPubGrubSolver.ChoosePackageVersion: IAssignment;
var
  PackageId: string;
  CurrentAssignment: IAssignment;
  AvailableVersions: IList<TPackageVersion>;
  ChosenVersion: TPackageVersion;
  VersionRange: IVersionRange;
begin
  Result := nil;
  
  // Find the most constrained unassigned package
  PackageId := FindMostConstrainedPackage;
  if PackageId = '' then
    Exit; // All packages are assigned
    
  // Get current constraints for this package
  CurrentAssignment := FPartialSolution.GetAssignment(PackageId);
  if CurrentAssignment <> nil then
    Exit; // Already assigned
    
  // Get available versions that satisfy all constraints
  VersionRange := GetConstraintsForPackage(PackageId);
  AvailableVersions := GetCandidateVersions(PackageId, VersionRange);
  
  if AvailableVersions.Count = 0 then
  begin
    // No valid versions - add incompatibility for no versions
    AddIncompatibility(TIncompatibility.NoVersions(PackageId));
    Exit;
  end;
  
  // Choose the highest version (pub algorithm preference)
  ChosenVersion := AvailableVersions.Last;
  VersionRange := TVersionRange.CreateExact(ChosenVersion);
  
  Result := FPartialSolution.AddDecision(PackageId, VersionRange);
end;

function TPubGrubSolver.Conflict(const Incompatibility: IIncompatibility): TConflictResolution;
begin
  // Analyze the conflict and learn a new incompatibility
  Result := AnalyzeConflict(Incompatibility);
end;

function TPubGrubSolver.AnalyzeConflict(const Incompatibility: IIncompatibility): TConflictResolution;
var
  LearnedIncompatibility: IIncompatibility;
  BacktrackLevel: Integer;
begin
  // This is simplified conflict analysis - real PubGrub does more sophisticated learning
  LearnedIncompatibility := Resolve(Incompatibility);
  
  if LearnedIncompatibility.IsFailure then
  begin
    Result := TConflictResolution.Failure(LearnedIncompatibility);
    Exit;
  end;
  
  BacktrackLevel := FindDecisionLevel(LearnedIncompatibility);
  Result := TConflictResolution.Create(LearnedIncompatibility, BacktrackLevel);
end;

function TPubGrubSolver.Resolve(const Incompatibility: IIncompatibility): IIncompatibility;
begin
  // Simplified resolution - in real PubGrub this would do proper resolution
  // For now, just return the incompatibility or create a failure
  if Incompatibility.Terms.Count = 0 then
    Result := TIncompatibility.Failure
  else
    Result := Incompatibility;
end;

// Helper method implementations would go here...
// Due to space constraints, I'm showing the core structure

procedure TPubGrubSolver.AddIncompatibility(const Incompatibility: IIncompatibility);
begin
  FIncompatibilityStore.Add(Incompatibility);
  
  if FOptions.VerboseLogging then
    FLogger.Debug('Added incompatibility: ' + Incompatibility.ToString);
end;

// Logging methods
procedure TPubGrubSolver.LogDecision(const Assignment: IAssignment);
begin
  if FOptions.VerboseLogging then
    FLogger.Debug('Decision: ' + Assignment.ToString);
end;

procedure TPubGrubSolver.LogDerivation(const Assignment: IAssignment);
begin
  if FOptions.VerboseLogging then
    FLogger.Debug('Derivation: ' + Assignment.ToString);
end;

procedure TPubGrubSolver.LogBacktrack(const Level: Integer);
begin
  if FOptions.VerboseLogging then
    FLogger.Debug(Format('Backtracking to level %d', [Level]));
end;

procedure TPubGrubSolver.LogConflict(const Incompatibility: IIncompatibility);
begin
  FLogger.Warning('Conflict: ' + Incompatibility.ToString);
end;

// Placeholder implementations for methods that would need full implementation
function TPubGrubSolver.FindMostConstrainedPackage: string;
begin
  Result := ''; // Placeholder
end;

function TPubGrubSolver.GetCandidateVersions(const PackageId: string; const Constraint: IVersionRange): IList<TPackageVersion>;
begin
  Result := TCollections.CreateList<TPackageVersion>; // Placeholder
end;

function TPubGrubSolver.FindDecisionLevel(const Incompatibility: IIncompatibility): Integer;
begin
  Result := FPartialSolution.DecisionLevel - 1; // Simplified
end;

function TPubGrubSolver.ExplainFailure(const Incompatibility: IIncompatibility): string;
begin
  Result := 'No solution exists: ' + Incompatibility.ToString;
end;

// Additional helper methods would be implemented here...

end.