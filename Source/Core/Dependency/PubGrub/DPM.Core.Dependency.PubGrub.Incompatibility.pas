unit DPM.Core.Dependency.PubGrub.Incompatibility;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Classes,
  DPM.Core.Dependency.PubGrub.Types;

type
  /// <summary>
  /// Implementation of IIncompatibility representing conflicting constraints
  /// </summary>
  TIncompatibility = class(TInterfacedObject, IIncompatibility)
  private
    FTerms: IList<ITerm>;
    FCause: TIncompatibilityCause;
    FFailureReason: string;
    FConflictCount: Integer;
    
  protected
    function GetTerms: IList<ITerm>;
    function GetCause: TIncompatibilityCause;
    function GetFailureReason: string;
    function GetConflictCount: Integer;
    
    procedure UpdateConflictCount;
    
  public
    constructor Create(const ATerms: array of ITerm; const ACause: TIncompatibilityCause;
      const AFailureReason: string = '');
    constructor CreateFromList(const ATerms: IList<ITerm>; const ACause: TIncompatibilityCause;
      const AFailureReason: string = '');
      
    function IsFailure: Boolean;
    function ToString: string; override;
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: Integer; override;
    
    /// <summary>Creates an incompatibility from package dependency</summary>
    class function FromDependency(const PackageId: string;
      const PackageVersion: IVersionRange; const DependencyId: string;
      const DependencyRange: IVersionRange): IIncompatibility; static;
    
    /// <summary>Creates an incompatibility indicating no versions available</summary>
    class function NoVersions(const PackageId: string): IIncompatibility; static;
    
    /// <summary>Creates a failure incompatibility (no solution exists)</summary>
    class function Failure: IIncompatibility; static;
    
    /// <summary>Creates an incompatibility from version conflict</summary>
    class function FromConflict(const PackageId: string;
      const Range1, Range2: IVersionRange): IIncompatibility; static;
      
    property Terms: IList<ITerm> read GetTerms;
    property Cause: TIncompatibilityCause read GetCause;
    property FailureReason: string read GetFailureReason;
    property ConflictCount: Integer read GetConflictCount;
  end;

implementation

uses
  System.StrUtils,
  DPM.Core.Dependency.PubGrub.Term,
  DPM.Core.Dependency.Version;

{ TIncompatibility }

constructor TIncompatibility.Create(const ATerms: array of ITerm; 
  const ACause: TIncompatibilityCause; const AFailureReason: string);
var
  I: Integer;
begin
  inherited Create;
  
  FTerms := TCollections.CreateList<ITerm>;
  for I := Low(ATerms) to High(ATerms) do
  begin
    if ATerms[I] = nil then
      raise EArgumentNilException.Create('Term cannot be nil');
    FTerms.Add(ATerms[I]);
  end;
  
  FCause := ACause;
  FFailureReason := AFailureReason;
  UpdateConflictCount;
end;

constructor TIncompatibility.CreateFromList(const ATerms: IList<ITerm>; 
  const ACause: TIncompatibilityCause; const AFailureReason: string);
var
  Term: ITerm;
begin
  inherited Create;
  
  if ATerms = nil then
    raise EArgumentNilException.Create('Terms list cannot be nil');
    
  FTerms := TCollections.CreateList<ITerm>;
  for Term in ATerms do
  begin
    if Term = nil then
      raise EArgumentNilException.Create('Term cannot be nil');
    FTerms.Add(Term);
  end;
  
  FCause := ACause;
  FFailureReason := AFailureReason;
  UpdateConflictCount;
end;

function TIncompatibility.GetTerms: IList<ITerm>;
begin
  Result := FTerms;
end;

function TIncompatibility.GetCause: TIncompatibilityCause;
begin
  Result := FCause;
end;

function TIncompatibility.GetFailureReason: string;
begin
  Result := FFailureReason;
end;

function TIncompatibility.GetConflictCount: Integer;
begin
  Result := FConflictCount;
end;

procedure TIncompatibility.UpdateConflictCount;
var
  Term: ITerm;
begin
  FConflictCount := 0;
  for Term in FTerms do
    if not Term.Positive then
      Inc(FConflictCount);
end;

function TIncompatibility.IsFailure: Boolean;
begin
  Result := FCause = icFailure;
end;

function TIncompatibility.ToString: string;
var
  TermStrings: TStringList;
  Term: ITerm;
begin
  TermStrings := TStringList.Create;
  try
    for Term in FTerms do
      TermStrings.Add(Term.ToString);
    
    if FTerms.Count = 0 then
      Result := 'No solution'
    else if FTerms.Count = 1 then
      Result := TermStrings[0]
    else
      Result := Format('[%s]', [String.Join(', ', TermStrings.ToStringArray)]);
      
    if FFailureReason <> '' then
      Result := Result + ': ' + FFailureReason;
  finally
    TermStrings.Free;
  end;
end;

function TIncompatibility.Equals(Obj: TObject): Boolean;
var
  Other: TIncompatibility;
  I: Integer;
begin
  Result := False;
  if not (Obj is TIncompatibility) then
    Exit;
    
  Other := TIncompatibility(Obj);
  if (FTerms.Count <> Other.FTerms.Count) or (FCause <> Other.FCause) then
    Exit;
    
  // Compare terms (order-independent)
  for I := 0 to FTerms.Count - 1 do
  begin
    if not Other.FTerms.Contains(FTerms[I]) then
      Exit;
  end;
  
  Result := True;
end;

function TIncompatibility.GetHashCode: Integer;
var
  Term: ITerm;
begin
  Result := Integer(FCause);
  for Term in FTerms do
    Result := Result xor Term.GetHashCode;
end;

class function TIncompatibility.FromDependency(const PackageId: string;
  const PackageVersion: IVersionRange; const DependencyId: string;
  const DependencyRange: IVersionRange): IIncompatibility;
var
  Terms: array[0..1] of ITerm;
begin
  Terms[0] := TTerm.Conflict(PackageId, PackageVersion);  // NOT package version
  Terms[1] := TTerm.Require(DependencyId, DependencyRange); // requires dependency
  
  Result := TIncompatibility.Create(Terms, icDependency,
    Format('%s %s depends on %s %s', 
      [PackageId, PackageVersion.ToString, DependencyId, DependencyRange.ToString]));
end;

class function TIncompatibility.NoVersions(const PackageId: string): IIncompatibility;
var
  Terms: array[0..0] of ITerm;
  AllVersions: IVersionRange;
begin
  AllVersions := TVersionRange.CreateAny;
  Terms[0] := TTerm.Conflict(PackageId, AllVersions);
  
  Result := TIncompatibility.Create(Terms, icNoVersions,
    Format('No versions available for package %s', [PackageId]));
end;

class function TIncompatibility.Failure: IIncompatibility;
begin
  Result := TIncompatibility.Create([], icFailure, 'No solution exists');
end;

class function TIncompatibility.FromConflict(const PackageId: string;
  const Range1, Range2: IVersionRange): IIncompatibility;
var
  Terms: array[0..1] of ITerm;
begin
  Terms[0] := TTerm.Conflict(PackageId, Range1);
  Terms[1] := TTerm.Conflict(PackageId, Range2);
  
  Result := TIncompatibility.Create(Terms, icConflict,
    Format('%s versions %s and %s are incompatible', 
      [PackageId, Range1.ToString, Range2.ToString]));
end;

end.