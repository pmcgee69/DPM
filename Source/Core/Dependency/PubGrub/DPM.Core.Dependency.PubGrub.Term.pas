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
    FVersionRange: TVersionRange;
    FPositive: Boolean;
    
  protected
    function GetPackageId: string;
    function GetVersionRange: TVersionRange;
    function GetPositive: Boolean;
    function GetInverse: ITerm;
    
  public
    constructor Create(const APackageId: string; const AVersionRange: TVersionRange; 
      const APositive: Boolean = True);
    
    function ToString: string; override;
    function Equals(Obj: TObject): Boolean; overload; override;
    function Equals(const Other: ITerm): Boolean; overload;
    function GetHashCode: Integer; override;
    
    /// <summary>Creates a positive term (requirement)</summary>
    class function Require(const PackageId: string; 
      const VersionRange: TVersionRange): ITerm; static;
    
    /// <summary>Creates a negative term (conflict)</summary>
    class function Conflict(const PackageId: string; 
      const VersionRange: TVersionRange): ITerm; static;
    
    /// <summary>Creates a term for exact version</summary>
    class function ExactVersion(const PackageId: string; 
      const VersionString: string): ITerm; static;
    
    property PackageId: string read GetPackageId;
    property VersionRange: TVersionRange read GetVersionRange;
    property Positive: Boolean read GetPositive;
    property Inverse: ITerm read GetInverse;
  end;

implementation

uses
  DPM.Core.Types;

{ TTerm }

constructor TTerm.Create(const APackageId: string; const AVersionRange: TVersionRange; 
  const APositive: Boolean);
begin
  inherited Create;
  if APackageId = '' then
    raise EArgumentException.Create('PackageId cannot be empty');
  if AVersionRange.IsEmpty then
    raise EArgumentException.Create('VersionRange cannot be empty');
    
  FPackageId := APackageId;
  FVersionRange := AVersionRange;
  FPositive := APositive;
end;

function TTerm.GetPackageId: string;
begin
  Result := FPackageId;
end;

function TTerm.GetVersionRange: TVersionRange;
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
            (FVersionRange = Other.FVersionRange);
end;

function TTerm.Equals(const Other: ITerm): Boolean;
begin
  Result := (FPackageId = Other.PackageId) and 
            (FPositive = Other.Positive) and
            (FVersionRange = Other.VersionRange);
end;

function TTerm.GetHashCode: Integer;
begin
  // Simple hash combining package ID, positive flag, and version range
  Result := FPackageId.GetHashCode;
  Result := Result xor (Integer(FPositive) shl 1);
  Result := Result xor FVersionRange.ToString.GetHashCode;
end;

class function TTerm.Require(const PackageId: string; 
  const VersionRange: TVersionRange): ITerm;
begin
  Result := TTerm.Create(PackageId, VersionRange, True);
end;

class function TTerm.Conflict(const PackageId: string; 
  const VersionRange: TVersionRange): ITerm;
begin
  Result := TTerm.Create(PackageId, VersionRange, False);
end;

class function TTerm.ExactVersion(const PackageId: string; 
  const VersionString: string): ITerm;
var
  Version: TPackageVersion;
  Range: TVersionRange;
begin
  if not TPackageVersion.TryParse(VersionString, Version) then
    raise Exception.CreateFmt('Invalid version string: %s', [VersionString]);
  Range := TVersionRange.Create(Version);
  Result := TTerm.Create(PackageId, Range, True);
end;

end.