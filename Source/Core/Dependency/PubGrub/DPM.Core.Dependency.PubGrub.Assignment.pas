unit DPM.Core.Dependency.PubGrub.Assignment;

interface

uses
  System.SysUtils,
  DPM.Core.Dependency.Interfaces,
  DPM.Core.Dependency.Version,
  DPM.Core.Dependency.PubGrub.Types;

type
  /// <summary>
  /// Implementation of IAssignment representing a package version assignment
  /// </summary>
  TAssignment = class(TInterfacedObject, IAssignment)
  private
    FPackageId: string;
    FVersionRange: TVersionRange;
    FAssignmentType: TAssignmentType;
    FDecisionLevel: Integer;
    FCause: IIncompatibility;
    FIndex: Integer;
    
  protected
    function GetPackageId: string;
    function GetVersionRange: TVersionRange;
    function GetAssignmentType: TAssignmentType;
    function GetDecisionLevel: Integer;
    function GetCause: IIncompatibility;
    function GetIndex: Integer;
    
  public
    constructor Create(const APackageId: string; const AVersionRange: TVersionRange;
      const AAssignmentType: TAssignmentType; const ADecisionLevel: Integer;
      const AIndex: Integer; const ACause: IIncompatibility = nil);
      
    function ToString: string; override;
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: Integer; override;
    
    /// <summary>Creates a decision assignment</summary>
    class function CreateDecision(const PackageId: string; 
      const VersionRange: TVersionRange; const DecisionLevel: Integer;
      const Index: Integer): IAssignment; static;
    
    /// <summary>Creates a derivation assignment</summary>
    class function CreateDerivation(const PackageId: string;
      const VersionRange: TVersionRange; const DecisionLevel: Integer;
      const Index: Integer; const Cause: IIncompatibility): IAssignment; static;
      
    property PackageId: string read GetPackageId;
    property VersionRange: TVersionRange read GetVersionRange;
    property AssignmentType: TAssignmentType read GetAssignmentType;
    property DecisionLevel: Integer read GetDecisionLevel;
    property Cause: IIncompatibility read GetCause;
    property Index: Integer read GetIndex;
  end;

implementation

{ TAssignment }

constructor TAssignment.Create(const APackageId: string; 
  const AVersionRange: TVersionRange; const AAssignmentType: TAssignmentType;
  const ADecisionLevel: Integer; const AIndex: Integer; 
  const ACause: IIncompatibility);
begin
  inherited Create;
  
  if APackageId = '' then
    raise EArgumentException.Create('PackageId cannot be empty');
  if AVersionRange.IsEmpty then
    raise EArgumentException.Create('VersionRange cannot be empty');
  if ADecisionLevel < 0 then
    raise EArgumentException.Create('DecisionLevel cannot be negative');
  if AIndex < 0 then
    raise EArgumentException.Create('Index cannot be negative');
  if (AAssignmentType = atDerivation) and (ACause = nil) then
    raise EArgumentException.Create('Derivation assignments must have a cause');
  if (AAssignmentType = atDecision) and (ACause <> nil) then
    raise EArgumentException.Create('Decision assignments cannot have a cause');
    
  FPackageId := APackageId;
  FVersionRange := AVersionRange;
  FAssignmentType := AAssignmentType;
  FDecisionLevel := ADecisionLevel;
  FCause := ACause;
  FIndex := AIndex;
end;

function TAssignment.GetPackageId: string;
begin
  Result := FPackageId;
end;

function TAssignment.GetVersionRange: TVersionRange;
begin
  Result := FVersionRange;
end;

function TAssignment.GetAssignmentType: TAssignmentType;
begin
  Result := FAssignmentType;
end;

function TAssignment.GetDecisionLevel: Integer;
begin
  Result := FDecisionLevel;
end;

function TAssignment.GetCause: IIncompatibility;
begin
  Result := FCause;
end;

function TAssignment.GetIndex: Integer;
begin
  Result := FIndex;
end;

function TAssignment.ToString: string;
const
  ASSIGNMENT_TYPE_STR: array[TAssignmentType] of string = ('Decision', 'Derivation');
begin
  if FAssignmentType = atDecision then
    Result := Format('[%d] %s: %s %s (Level %d)', 
      [FIndex, ASSIGNMENT_TYPE_STR[FAssignmentType], FPackageId, 
       FVersionRange.ToString, FDecisionLevel])
  else
    Result := Format('[%d] %s: %s %s (Level %d, Cause: %s)', 
      [FIndex, ASSIGNMENT_TYPE_STR[FAssignmentType], FPackageId, 
       FVersionRange.ToString, FDecisionLevel, FCause.ToString]);
end;

function TAssignment.Equals(Obj: TObject): Boolean;
var
  Other: TAssignment;
begin
  Result := False;
  if not (Obj is TAssignment) then
    Exit;
    
  Other := TAssignment(Obj);
  Result := (FPackageId = Other.FPackageId) and
            (FAssignmentType = Other.FAssignmentType) and
            (FDecisionLevel = Other.FDecisionLevel) and
            (FIndex = Other.FIndex) and
            (FVersionRange = Other.FVersionRange);
            
  // Note: We don't compare FCause to avoid circular dependencies in equality
end;

function TAssignment.GetHashCode: Integer;
begin
  Result := FPackageId.GetHashCode;
  Result := Result xor (Integer(FAssignmentType) shl 8);
  Result := Result xor (FDecisionLevel shl 16);
  Result := Result xor (FIndex shl 24);
  Result := Result xor FVersionRange.ToString.GetHashCode;
end;

class function TAssignment.CreateDecision(const PackageId: string; 
  const VersionRange: TVersionRange; const DecisionLevel: Integer;
  const Index: Integer): IAssignment;
begin
  Result := TAssignment.Create(PackageId, VersionRange, atDecision, 
    DecisionLevel, Index, nil);
end;

class function TAssignment.CreateDerivation(const PackageId: string;
  const VersionRange: TVersionRange; const DecisionLevel: Integer;
  const Index: Integer; const Cause: IIncompatibility): IAssignment;
begin
  Result := TAssignment.Create(PackageId, VersionRange, atDerivation, 
    DecisionLevel, Index, Cause);
end;

end.