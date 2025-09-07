unit DPM.Core.Dependency.PubGrub.IncompatibilityStore;

interface

uses
  System.SysUtils,
  Spring.Collections,
  DPM.Core.Dependency.Version,
  DPM.Core.Dependency.PubGrub.Types;

type
  /// <summary>
  /// Efficient storage and querying of incompatibilities indexed by package
  /// </summary>
  TIncompatibilityStore = class(TInterfacedObject, IIncompatibilityStore)
  private
    // Map from package ID to list of incompatibilities that mention that package
    FIncompatibilitiesByPackage: IDictionary<string, IList<IIncompatibility>>;
    // All incompatibilities for iteration
    FAllIncompatibilities: IList<IIncompatibility>;
    
  protected
    procedure IndexIncompatibility(const Incompatibility: IIncompatibility);
    
  public
    constructor Create;
    
    procedure Add(const Incompatibility: IIncompatibility);
    function GetForPackage(const PackageId: string): IEnumerable<IIncompatibility>;
    function FindConflicts(const Assignment: IAssignment): IList<IIncompatibility>;
    function Count: Integer;
    procedure Clear;
    
    /// <summary>Gets all incompatibilities</summary>
    function GetAll: IEnumerable<IIncompatibility>;
    
    /// <summary>Finds incompatibilities that would be satisfied by an assignment</summary>
    function FindSatisfied(const Assignment: IAssignment): IList<IIncompatibility>;
    
    /// <summary>Removes incompatibilities that are no longer relevant</summary>
    procedure Prune(const RelevantPackages: IList<string>);
  end;

implementation

{ TIncompatibilityStore }

constructor TIncompatibilityStore.Create;
begin
  inherited Create;
  FIncompatibilitiesByPackage := TCollections.CreateDictionary<string, IList<IIncompatibility>>;
  FAllIncompatibilities := TCollections.CreateList<IIncompatibility>;
end;

procedure TIncompatibilityStore.Add(const Incompatibility: IIncompatibility);
begin
  if Incompatibility = nil then
    raise EArgumentNilException.Create('Incompatibility cannot be nil');
    
  // Avoid duplicates
  if FAllIncompatibilities.Contains(Incompatibility) then
    Exit;
    
  FAllIncompatibilities.Add(Incompatibility);
  IndexIncompatibility(Incompatibility);
end;

procedure TIncompatibilityStore.IndexIncompatibility(const Incompatibility: IIncompatibility);
var
  Term: ITerm;
  PackageIncompatibilities: IList<IIncompatibility>;
begin
  // Index by each package mentioned in the incompatibility
  for Term in Incompatibility.Terms do
  begin
    if not FIncompatibilitiesByPackage.TryGetValue(Term.PackageId, PackageIncompatibilities) then
    begin
      PackageIncompatibilities := TCollections.CreateList<IIncompatibility>;
      FIncompatibilitiesByPackage.Add(Term.PackageId, PackageIncompatibilities);
    end;
    
    if not PackageIncompatibilities.Contains(Incompatibility) then
      PackageIncompatibilities.Add(Incompatibility);
  end;
end;

function TIncompatibilityStore.GetForPackage(const PackageId: string): IEnumerable<IIncompatibility>;
var
  PackageIncompatibilities: IList<IIncompatibility>;
begin
  if FIncompatibilitiesByPackage.TryGetValue(PackageId, PackageIncompatibilities) then
    Result := PackageIncompatibilities
  else
    Result := TCollections.CreateList<IIncompatibility>; // Empty list
end;

function TIncompatibilityStore.FindConflicts(const Assignment: IAssignment): IList<IIncompatibility>;
var
  Incompatibility: IIncompatibility;
  Term: ITerm;
  ConflictFound: Boolean;
  UnsatisfiedCount: Integer;
begin
  Result := TCollections.CreateList<IIncompatibility>;
  
  // Look at all incompatibilities that mention this package
  for Incompatibility in GetForPackage(Assignment.PackageId) do
  begin
    UnsatisfiedCount := 0;
    ConflictFound := False;
    
    // Check each term in the incompatibility
    for Term in Incompatibility.Terms do
    begin
      if Term.PackageId = Assignment.PackageId then
      begin
        // This term relates to our assignment
        if Term.Positive then
        begin
          // Positive term: assignment range must be subset of or equal to term range
          if not Assignment.VersionRange.IsSubsetOrEqualTo(Term.VersionRange) then
            Inc(UnsatisfiedCount);
        end
        else
        begin
          // Negative term: assignment must NOT overlap with the range
          var TempRange: TVersionRange;
          if Assignment.VersionRange.TryGetIntersectingRange(Term.VersionRange, TempRange) then
          begin
            ConflictFound := True;
            Break;
          end;
        end;
      end
      else
      begin
        // Term for different package - assume unsatisfied for now
        // (This would need to check against partial solution in real implementation)
        Inc(UnsatisfiedCount);
      end;
    end;
    
    // Add to conflicts if this incompatibility is violated
    if ConflictFound or (UnsatisfiedCount = 0) then
      Result.Add(Incompatibility);
  end;
end;

function TIncompatibilityStore.FindSatisfied(const Assignment: IAssignment): IList<IIncompatibility>;
var
  Incompatibility: IIncompatibility;
  Term: ITerm;
  SatisfiedTerms: Integer;
begin
  Result := TCollections.CreateList<IIncompatibility>;
  
  // Look at all incompatibilities that mention this package
  for Incompatibility in GetForPackage(Assignment.PackageId) do
  begin
    SatisfiedTerms := 0;
    
    // Check each term in the incompatibility
    for Term in Incompatibility.Terms do
    begin
      if Term.PackageId = Assignment.PackageId then
      begin
        // This term relates to our assignment
        if Term.Positive then
        begin
          // Positive term: assignment satisfies if its range is subset of or equal to term range
          if Assignment.VersionRange.IsSubsetOrEqualTo(Term.VersionRange) then
            Inc(SatisfiedTerms);
        end
        else
        begin
          // Negative term: assignment satisfies if it doesn't overlap
          var TempRange: TVersionRange;
          if not Assignment.VersionRange.TryGetIntersectingRange(Term.VersionRange, TempRange) then
            Inc(SatisfiedTerms);
        end;
      end;
    end;
    
    // If we satisfied at least one term, the incompatibility is satisfied
    // (In PubGrub, incompatibilities are disjunctions - any one term being true satisfies it)
    if SatisfiedTerms > 0 then
      Result.Add(Incompatibility);
  end;
end;

function TIncompatibilityStore.Count: Integer;
begin
  Result := FAllIncompatibilities.Count;
end;

procedure TIncompatibilityStore.Clear;
begin
  FAllIncompatibilities.Clear;
  FIncompatibilitiesByPackage.Clear;
end;

function TIncompatibilityStore.GetAll: IEnumerable<IIncompatibility>;
begin
  Result := FAllIncompatibilities;
end;

procedure TIncompatibilityStore.Prune(const RelevantPackages: IList<string>);
var
  NewAllIncompatibilities: IList<IIncompatibility>;
  Incompatibility: IIncompatibility;
  Term: ITerm;
  IsRelevant: Boolean;
begin
  if RelevantPackages = nil then
    Exit;
    
  // Rebuild incompatibility list with only relevant ones
  NewAllIncompatibilities := TCollections.CreateList<IIncompatibility>;
  
  for Incompatibility in FAllIncompatibilities do
  begin
    IsRelevant := False;
    
    // Check if any term in the incompatibility relates to a relevant package
    for Term in Incompatibility.Terms do
    begin
      if RelevantPackages.Contains(Term.PackageId) then
      begin
        IsRelevant := True;
        Break;
      end;
    end;
    
    if IsRelevant then
      NewAllIncompatibilities.Add(Incompatibility);
  end;
  
  // Rebuild indexes
  FAllIncompatibilities := NewAllIncompatibilities;
  FIncompatibilitiesByPackage.Clear;
  
  for Incompatibility in FAllIncompatibilities do
    IndexIncompatibility(Incompatibility);
end;

end.