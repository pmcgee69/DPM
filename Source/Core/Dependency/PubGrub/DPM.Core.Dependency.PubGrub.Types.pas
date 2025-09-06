unit DPM.Core.Dependency.PubGrub.Types;

interface

uses
  System.Generics.Collections,
  DPM.Core.Dependency.Interfaces,
  DPM.Core.Dependency.Version;

type
  // Forward declarations
  IAssignment = interface;
  IIncompatibility = interface;
  ITerm = interface;
  IPartialSolution = interface;
  
  /// <summary>
  /// Type of assignment in the partial solution
  /// </summary>
  TAssignmentType = (
    atDecision,    // Explicit choice made by solver
    atDerivation   // Derived through unit propagation
  );

  /// <summary>
  /// Reason why an incompatibility exists
  /// </summary>
  TIncompatibilityCause = (
    icRoot,               // Root requirement (direct dependency)
    icDependency,         // Package dependency constraint
    icConflict,           // Version conflict
    icNoVersions,         // No available versions satisfy constraint
    icUnavailable,        // Package not available in any source
    icDerived,            // Learned from conflict resolution
    icFailure             // Indicates no solution exists
  );

  /// <summary>
  /// A term in an incompatibility, representing a constraint on a package
  /// </summary>
  ITerm = interface
    ['{8B5E4F12-A3C7-4D1E-9F2A-1B3C8D4E5F67}']
    function GetPackageId: string;
    function GetVersionRange: IVersionRange; 
    function GetPositive: Boolean;
    function GetInverse: ITerm;
    
    /// <summary>Package identifier</summary>
    property PackageId: string read GetPackageId;
    /// <summary>Version constraint</summary>
    property VersionRange: IVersionRange read GetVersionRange;
    /// <summary>True = requires this constraint, False = conflicts with this constraint</summary>
    property Positive: Boolean read GetPositive;
    /// <summary>Returns the logical inverse of this term</summary>
    property Inverse: ITerm read GetInverse;
  end;

  /// <summary>
  /// An assignment of a version range to a package in the partial solution
  /// </summary>
  IAssignment = interface
    ['{7A4D3C2B-1E5F-4A8B-9C6D-2F7E8A9B0C1D}']
    function GetPackageId: string;
    function GetVersionRange: IVersionRange;
    function GetAssignmentType: TAssignmentType;
    function GetDecisionLevel: Integer;
    function GetCause: IIncompatibility;
    function GetIndex: Integer;
    
    /// <summary>Package identifier</summary>
    property PackageId: string read GetPackageId;
    /// <summary>Assigned version range</summary>
    property VersionRange: IVersionRange read GetVersionRange;
    /// <summary>How this assignment was made</summary>
    property AssignmentType: TAssignmentType read GetAssignmentType;
    /// <summary>Decision level (depth in search tree)</summary>
    property DecisionLevel: Integer read GetDecisionLevel;
    /// <summary>Incompatibility that caused this derivation (nil for decisions)</summary>
    property Cause: IIncompatibility read GetCause;
    /// <summary>Index in the partial solution</summary>
    property Index: Integer read GetIndex;
  end;

  /// <summary>
  /// An incompatibility represents a set of package version constraints
  /// that cannot all be satisfied simultaneously
  /// </summary>
  IIncompatibility = interface
    ['{6F8E2D1C-3B9A-4E7F-8C5D-1A2B3C4D5E6F}']
    function GetTerms: IList<ITerm>;
    function GetCause: TIncompatibilityCause;
    function GetFailureReason: string;
    function GetConflictCount: Integer;
    function IsFailure: Boolean;
    function ToString: string;
    
    /// <summary>List of terms that cannot be satisfied together</summary>
    property Terms: IList<ITerm> read GetTerms;
    /// <summary>Why this incompatibility exists</summary>
    property Cause: TIncompatibilityCause read GetCause;
    /// <summary>Human-readable failure explanation</summary>
    property FailureReason: string read GetFailureReason;
    /// <summary>Number of terms that could not be satisfied</summary>
    property ConflictCount: Integer read GetConflictCount;
  end;

  /// <summary>
  /// Manages the chronological sequence of package assignments
  /// </summary>
  IPartialSolution = interface
    ['{5C7B1F9E-2D4A-3E8C-9B6F-4A5B6C7D8E9F}']
    function GetAssignments: IList<IAssignment>;
    function GetDecisionLevel: Integer;
    
    procedure AddAssignment(const Assignment: IAssignment);
    function GetAssignment(const PackageId: string): IAssignment;
    function HasAssignment(const PackageId: string): Boolean;
    function Backtrack(const DecisionLevel: Integer): Boolean;
    function GetSatisfier(const Term: ITerm): IAssignment;
    function GetUnsatisfied(const Terms: IList<ITerm>): IList<ITerm>;
    procedure Clear;
    
    /// <summary>All assignments in chronological order</summary>
    property Assignments: IList<IAssignment> read GetAssignments;
    /// <summary>Current decision level (search depth)</summary>
    property DecisionLevel: Integer read GetDecisionLevel;
  end;

  /// <summary>
  /// Stores and efficiently queries incompatibilities
  /// </summary>  
  IIncompatibilityStore = interface
    ['{4B6A8D2F-1C5E-3A7B-8D9C-3E4F5A6B7C8D}']
    procedure Add(const Incompatibility: IIncompatibility);
    function GetForPackage(const PackageId: string): IEnumerable<IIncompatibility>;
    function FindConflicts(const Assignment: IAssignment): IList<IIncompatibility>;
    function Count: Integer;
    procedure Clear;
  end;

  /// <summary>
  /// Result of PubGrub conflict resolution
  /// </summary>
  TConflictResolution = record
    /// <summary>New incompatibility learned from the conflict</summary>
    Incompatibility: IIncompatibility;
    /// <summary>Decision level to backtrack to (-1 if unresolvable)</summary>
    BacktrackLevel: Integer;
    
    class function Create(const AIncompatibility: IIncompatibility; 
      const ABacktrackLevel: Integer): TConflictResolution; static;
    class function Failure(const AIncompatibility: IIncompatibility): TConflictResolution; static;
  end;

  /// <summary>
  /// PubGrub solver configuration options
  /// </summary>
  TPubGrubOptions = record
    /// <summary>Maximum number of backtrack operations before giving up</summary>
    MaxBacktracks: Integer;
    /// <summary>Maximum depth for conflict explanation</summary>
    ExplanationDepth: Integer;
    /// <summary>Enable detailed logging</summary>
    VerboseLogging: Boolean;
    /// <summary>Pre-process dependencies to detect obvious conflicts</summary>
    PreprocessConflicts: Boolean;
    
    class function Default: TPubGrubOptions; static;
  end;

implementation

{ TConflictResolution }

class function TConflictResolution.Create(const AIncompatibility: IIncompatibility; 
  const ABacktrackLevel: Integer): TConflictResolution;
begin
  Result.Incompatibility := AIncompatibility;
  Result.BacktrackLevel := ABacktrackLevel;
end;

class function TConflictResolution.Failure(const AIncompatibility: IIncompatibility): TConflictResolution;
begin
  Result.Incompatibility := AIncompatibility;
  Result.BacktrackLevel := -1;
end;

{ TPubGrubOptions }

class function TPubGrubOptions.Default: TPubGrubOptions;
begin
  Result.MaxBacktracks := 10000;
  Result.ExplanationDepth := 10;
  Result.VerboseLogging := False;
  Result.PreprocessConflicts := True;
end;

end.