unit DPM.Core.Dependency.PubGrub.PartialSolution;

interface

uses
  System.SysUtils,
  Spring.Collections,
  DPM.Core.Dependency.Interfaces,
  DPM.Core.Dependency.Version,
  DPM.Core.Dependency.PubGrub.Types;

type
  /// <summary>
  /// Manages the chronological sequence of package version assignments
  /// </summary>
  TPartialSolution = class(TInterfacedObject, IPartialSolution)
  private
    FAssignments: IList<IAssignment>;
    FPackageAssignments: IDictionary<string, IAssignment>;
    FDecisionLevel: Integer;
    FNextIndex: Integer;
    
  protected
    function GetAssignments: IList<IAssignment>;
    function GetDecisionLevel: Integer;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure AddAssignment(const Assignment: IAssignment);
    function GetAssignment(const PackageId: string): IAssignment;
    function HasAssignment(const PackageId: string): Boolean;
    function Backtrack(const DecisionLevel: Integer): Boolean;
    function GetSatisfier(const Term: ITerm): IAssignment;
    function GetUnsatisfied(const Terms: IList<ITerm>): IList<ITerm>;
    procedure Clear;
    
    /// <summary>Creates and adds a decision assignment</summary>
    function AddDecision(const PackageId: string; 
      const VersionRange: TVersionRange): IAssignment;
    
    /// <summary>Creates and adds a derivation assignment</summary>
    function AddDerivation(const PackageId: string; 
      const VersionRange: TVersionRange; 
      const Cause: IIncompatibility): IAssignment;
    
    /// <summary>Increments the decision level for new decisions</summary>
    procedure IncrementDecisionLevel;
    
    /// <summary>Gets assignments at a specific decision level</summary>
    function GetAssignmentsAtLevel(const Level: Integer): IList<IAssignment>;
    
    /// <summary>Checks if a term is satisfied by current assignments</summary>
    function IsSatisfied(const Term: ITerm): Boolean;
    
    /// <summary>Gets the intersection of current assignment with term's range</summary>
    function GetIntersection(const PackageId: string; 
      const VersionRange: TVersionRange): TVersionRange;
      
    property Assignments: IList<IAssignment> read GetAssignments;
    property DecisionLevel: Integer read GetDecisionLevel;
  end;

implementation

uses
  DPM.Core.Dependency.PubGrub.Assignment;

{ TPartialSolution }

constructor TPartialSolution.Create;
begin
  inherited Create;
  FAssignments := TCollections.CreateList<IAssignment>;
  FPackageAssignments := TCollections.CreateDictionary<string, IAssignment>;
  FDecisionLevel := 0;
  FNextIndex := 0;
end;

destructor TPartialSolution.Destroy;
begin
  // Interfaces will be automatically released
  inherited;
end;

function TPartialSolution.GetAssignments: IList<IAssignment>;
begin
  Result := FAssignments;
end;

function TPartialSolution.GetDecisionLevel: Integer;
begin
  Result := FDecisionLevel;
end;

procedure TPartialSolution.AddAssignment(const Assignment: IAssignment);
begin
  if Assignment = nil then
    raise EArgumentNilException.Create('Assignment cannot be nil');
    
  // Check for duplicate package assignment
  if FPackageAssignments.ContainsKey(Assignment.PackageId) then
    raise EInvalidOpException.CreateFmt(
      'Package %s is already assigned', [Assignment.PackageId]);
      
  FAssignments.Add(Assignment);
  FPackageAssignments.Add(Assignment.PackageId, Assignment);
  Inc(FNextIndex);
end;

function TPartialSolution.GetAssignment(const PackageId: string): IAssignment;
begin
  if not FPackageAssignments.TryGetValue(PackageId, Result) then
    Result := nil;
end;

function TPartialSolution.HasAssignment(const PackageId: string): Boolean;
begin
  Result := FPackageAssignments.ContainsKey(PackageId);
end;

function TPartialSolution.Backtrack(const DecisionLevel: Integer): Boolean;
var
  I: Integer;
  Assignment: IAssignment;
  NewAssignments: IList<IAssignment>;
  NewPackageAssignments: IDictionary<string, IAssignment>;
begin
  Result := False;
  if DecisionLevel < 0 then
    Exit;
    
  // Find assignments to keep (those at lower decision levels)
  NewAssignments := TCollections.CreateList<IAssignment>;
  NewPackageAssignments := TCollections.CreateDictionary<string, IAssignment>;
  
  for I := 0 to FAssignments.Count - 1 do
  begin
    Assignment := FAssignments[I];
    if Assignment.DecisionLevel <= DecisionLevel then
    begin
      NewAssignments.Add(Assignment);
      NewPackageAssignments.Add(Assignment.PackageId, Assignment);
    end;
  end;
  
  // Update state
  FAssignments := NewAssignments;
  FPackageAssignments := NewPackageAssignments;
  FDecisionLevel := DecisionLevel;
  FNextIndex := FAssignments.Count;
  
  Result := True;
end;

function TPartialSolution.GetSatisfier(const Term: ITerm): IAssignment;
var
  Assignment: IAssignment;
begin
  Result := nil;
  
  if not FPackageAssignments.TryGetValue(Term.PackageId, Assignment) then
    Exit; // No assignment for this package
    
  // Check if the assignment satisfies the term
  if Term.Positive then
  begin
    // Positive term: assignment range must be subset of or equal to term range
    if Assignment.VersionRange.IsSubsetOrEqualTo(Term.VersionRange) then
      Result := Assignment;
  end
  else
  begin
    // Negative term: assignment must NOT overlap with the range
    var TempRange: TVersionRange;
    if not Assignment.VersionRange.TryGetIntersectingRange(Term.VersionRange, TempRange) then
      Result := Assignment;
  end;
end;

function TPartialSolution.GetUnsatisfied(const Terms: IList<ITerm>): IList<ITerm>;
var
  Term: ITerm;
begin
  Result := TCollections.CreateList<ITerm>;
  
  for Term in Terms do
  begin
    if GetSatisfier(Term) = nil then
      Result.Add(Term);
  end;
end;

procedure TPartialSolution.Clear;
begin
  FAssignments.Clear;
  FPackageAssignments.Clear;
  FDecisionLevel := 0;
  FNextIndex := 0;
end;

function TPartialSolution.AddDecision(const PackageId: string; 
  const VersionRange: TVersionRange): IAssignment;
begin
  IncrementDecisionLevel;
  Result := TAssignment.CreateDecision(PackageId, VersionRange, 
    FDecisionLevel, FNextIndex);
  AddAssignment(Result);
end;

function TPartialSolution.AddDerivation(const PackageId: string; 
  const VersionRange: TVersionRange; 
  const Cause: IIncompatibility): IAssignment;
begin
  Result := TAssignment.CreateDerivation(PackageId, VersionRange, 
    FDecisionLevel, FNextIndex, Cause);
  AddAssignment(Result);
end;

procedure TPartialSolution.IncrementDecisionLevel;
begin
  Inc(FDecisionLevel);
end;

function TPartialSolution.GetAssignmentsAtLevel(const Level: Integer): IList<IAssignment>;
var
  Assignment: IAssignment;
begin
  Result := TCollections.CreateList<IAssignment>;
  
  for Assignment in FAssignments do
  begin
    if Assignment.DecisionLevel = Level then
      Result.Add(Assignment);
  end;
end;

function TPartialSolution.IsSatisfied(const Term: ITerm): Boolean;
begin
  Result := GetSatisfier(Term) <> nil;
end;

function TPartialSolution.GetIntersection(const PackageId: string; 
  const VersionRange: TVersionRange): TVersionRange;
var
  Assignment: IAssignment;
begin
  Result := VersionRange;
  
  if FPackageAssignments.TryGetValue(PackageId, Assignment) then
  begin
    // Return intersection of current assignment and the requested range
    if not Assignment.VersionRange.TryGetIntersectingRange(VersionRange, Result) then
      Result := TVersionRange.Empty;
  end;
end;

end.