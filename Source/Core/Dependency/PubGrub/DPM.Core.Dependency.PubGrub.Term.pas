unit DPM.Core.Dependency.PubGrub.Term;

interface

uses
  System.SysUtils,
  DPM.Core.Dependency.Interfaces,
  DPM.Core.Dependency.Version,
  DPM.Core.Dependency.PubGrub.Types;

type
  /// <summary>
  /// Implementation of ITerm representing a package version constraint
  /// </summary>
  TTerm = class(TInterfacedObject, ITerm)
  private
    FPackageId: string;
    FVersionRange: IVersionRange;
    FPositive: Boolean;
    
  protected
    function GetPackageId: string;
    function GetVersionRange: IVersionRange;
    function GetPositive: Boolean;
    function GetInverse: ITerm;
    
  public
    constructor Create(const APackageId: string; const AVersionRange: IVersionRange; 
      const APositive: Boolean = True);
    
    function ToString: string; override;
    function Equals(Obj: TObject): Boolean; override;
    function GetHashCode: Integer; override;
    
    /// <summary>Creates a positive term (requirement)</summary>
    class function Require(const PackageId: string; 
      const VersionRange: IVersionRange): ITerm; static;
    
    /// <summary>Creates a negative term (conflict)</summary>
    class function Conflict(const PackageId: string; 
      const VersionRange: IVersionRange): ITerm; static;
    
    /// <summary>Creates a term for exact version</summary>
    class function ExactVersion(const PackageId: string; 
      const Version: TPackageVersion): ITerm; static;
    
    property PackageId: string read GetPackageId;
    property VersionRange: IVersionRange read GetVersionRange;
    property Positive: Boolean read GetPositive;
    property Inverse: ITerm read GetInverse;
  end;

implementation

uses
  DPM.Core.Types;

{ TTerm }

constructor TTerm.Create(const APackageId: string; const AVersionRange: IVersionRange; 
  const APositive: Boolean);
begin
  inherited Create;
  if APackageId = '' then
    raise EArgumentException.Create('PackageId cannot be empty');
  if AVersionRange = nil then
    raise EArgumentNilException.Create('VersionRange cannot be nil');
    
  FPackageId := APackageId;
  FVersionRange := AVersionRange;
  FPositive := APositive;
end;

function TTerm.GetPackageId: string;
begin
  Result := FPackageId;
end;

function TTerm.GetVersionRange: IVersionRange;
begin
  Result := FVersionRange;
end;

function TTerm.GetPositive: Boolean;
begin
  Result := FPositive;
end;

function TTerm.GetInverse: ITerm;
begin
  Result := TTerm.Create(FPackageId, FVersionRange, not FPositive);
end;

function TTerm.ToString: string;
const
  POSITIVE_PREFIX: array[Boolean] of string = ('NOT ', '');
begin
  Result := Format('%s%s %s', [POSITIVE_PREFIX[FPositive], FPackageId, FVersionRange.ToString]);
end;

function TTerm.Equals(Obj: TObject): Boolean;
var
  Other: TTerm;
begin
  Result := False;
  if not (Obj is TTerm) then
    Exit;
    
  Other := TTerm(Obj);
  Result := (FPackageId = Other.FPackageId) and 
            (FPositive = Other.FPositive) and
            FVersionRange.Equals(Other.FVersionRange);
end;

function TTerm.GetHashCode: Integer;
begin
  // Simple hash combining package ID, positive flag, and version range
  Result := FPackageId.GetHashCode;
  Result := Result xor (Integer(FPositive) shl 1);
  Result := Result xor FVersionRange.GetHashCode;
end;

class function TTerm.Require(const PackageId: string; 
  const VersionRange: IVersionRange): ITerm;
begin
  Result := TTerm.Create(PackageId, VersionRange, True);
end;

class function TTerm.Conflict(const PackageId: string; 
  const VersionRange: IVersionRange): ITerm;
begin
  Result := TTerm.Create(PackageId, VersionRange, False);
end;

class function TTerm.ExactVersion(const PackageId: string; 
  const Version: TPackageVersion): ITerm;
var
  Range: IVersionRange;
begin
  Range := TVersionRange.CreateExact(Version);
  Result := TTerm.Create(PackageId, Range, True);
end;

end.