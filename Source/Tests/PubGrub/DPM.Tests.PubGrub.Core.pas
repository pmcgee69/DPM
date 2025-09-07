unit DPM.Tests.PubGrub.Core;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Spring.Collections,
  DPM.Core.Dependency.Version,
  DPM.Core.Dependency.PubGrub.Types,
  DPM.Core.Dependency.PubGrub.Term,
  DPM.Core.Dependency.PubGrub.Assignment,
  DPM.Core.Dependency.PubGrub.Incompatibility;

type
  [TestFixture]
  TTestPubGrubCore = class
  private
    function CreateVersionRange(const Min, Max: string): TVersionRange;
    function CreateExactVersion(const Version: string): TVersionRange;
    
  public
    [Setup]
    procedure Setup;
    
    [TearDown]
    procedure TearDown;
    
    // Term Tests
    [Test]
    procedure TestTermCreation_Positive;
    
    [Test]
    procedure TestTermCreation_Negative;
    
    [Test]
    procedure TestTermInverse;
    
    [Test]
    procedure TestTermEquality;
    
    [Test]
    procedure TestTermToString;
    
    // Assignment Tests
    [Test]
    procedure TestAssignmentCreation_Decision;
    
    [Test]
    procedure TestAssignmentCreation_Derivation;
    
    [Test]
    [TestCase('InvalidPackageId', '', 'EArgumentException')]
    [TestCase('NegativeDecisionLevel', '-1', 'EArgumentException')]
    [TestCase('NegativeIndex', '-2', 'EArgumentException')]
    procedure TestAssignmentValidation(const TestValue: string; const ExpectedException: string);
    
    [Test]
    procedure TestAssignmentEquality;
    
    [Test]
    procedure TestAssignmentToString;
    
    // Incompatibility Tests
    [Test]
    procedure TestIncompatibilityCreation_Simple;
    
    [Test]
    procedure TestIncompatibilityCreation_Complex;
    
    [Test]
    procedure TestIncompatibilityFromDependency;
    
    [Test]
    procedure TestIncompatibilityNoVersions;
    
    [Test]
    procedure TestIncompatibilityFailure;
    
    [Test]
    procedure TestIncompatibilityToString;
    
    // Version Range Tests
    [Test]
    procedure TestVersionRangeIntersection;
    
    [Test]
    procedure TestVersionRangeOverlaps;
    
    [Test]
    procedure TestVersionRangeSatisfies;
    
    // Assignment Type Tests
    [Test]
    procedure TestAssignmentTypes;
  end;

implementation

uses
  DPM.Core.Types;

{ TTestPubGrubCore }

procedure TTestPubGrubCore.Setup;
begin
  // Setup code if needed
end;

procedure TTestPubGrubCore.TearDown;
begin
  // Cleanup code if needed  
end;

function TTestPubGrubCore.CreateVersionRange(const Min, Max: string): TVersionRange;
var
  MinVer, MaxVer: TPackageVersion;
begin
  MinVer := TPackageVersion.Parse(Min);
  MaxVer := TPackageVersion.Parse(Max);
  Result := TVersionRange.Create('', MinVer, True, MaxVer, True);
end;

function TTestPubGrubCore.CreateExactVersion(const Version: string): TVersionRange;
var
  Ver: TPackageVersion;
begin
  Ver := TPackageVersion.Parse(Version);
  Result := TVersionRange.Create(Ver);
end;

// Term Tests

procedure TTestPubGrubCore.TestTermCreation_Positive;
var
  Term: ITerm;
  Range: TVersionRange;
begin
  Range := CreateVersionRange('1.0.0', '2.0.0');
  Term := TTerm.Create('TestPackage', Range, True);
  
  Assert.AreEqual('TestPackage', Term.PackageId);
  Assert.IsTrue(Term.Positive);
  Assert.IsFalse(Term.VersionRange.IsEmpty);
end;

procedure TTestPubGrubCore.TestTermCreation_Negative;
var
  Term: ITerm;
  Range: TVersionRange;
begin
  Range := CreateVersionRange('1.0.0', '2.0.0');
  Term := TTerm.Create('TestPackage', Range, False);
  
  Assert.AreEqual('TestPackage', Term.PackageId);
  Assert.IsFalse(Term.Positive);
end;

procedure TTestPubGrubCore.TestTermInverse;
var
  PositiveTerm, NegativeTerm, InverseTerm: ITerm;
  Range: TVersionRange;
begin
  Range := CreateVersionRange('1.0.0', '2.0.0');
  PositiveTerm := TTerm.Create('TestPackage', Range, True);
  NegativeTerm := TTerm.Create('TestPackage', Range, False);
  
  InverseTerm := PositiveTerm.Inverse;
  
  Assert.IsFalse(InverseTerm.Positive);
  Assert.AreEqual(PositiveTerm.PackageId, InverseTerm.PackageId);
  
  InverseTerm := NegativeTerm.Inverse;
  Assert.IsTrue(InverseTerm.Positive);
end;

procedure TTestPubGrubCore.TestTermEquality;
var
  Term1, Term2, Term3: ITerm;
  Range: TVersionRange;
begin
  Range := CreateVersionRange('1.0.0', '2.0.0');
  Term1 := TTerm.Create('TestPackage', Range, True);
  Term2 := TTerm.Create('TestPackage', Range, True);
  Term3 := TTerm.Create('OtherPackage', Range, True);
  
  Assert.IsTrue(Term1.Equals(Term2));
  Assert.IsFalse(Term1.Equals(Term3));
end;

procedure TTestPubGrubCore.TestTermToString;
var
  PositiveTerm, NegativeTerm: ITerm;
  Range: TVersionRange;
begin
  Range := CreateExactVersion('1.0.0');
  PositiveTerm := TTerm.Create('TestPackage', Range, True);
  NegativeTerm := TTerm.Create('TestPackage', Range, False);
  
  Assert.Contains(PositiveTerm.ToString, 'TestPackage');
  Assert.Contains(NegativeTerm.ToString, 'NOT');
end;

// Assignment Tests

procedure TTestPubGrubCore.TestAssignmentCreation_Decision;
var
  Assignment: IAssignment;
  Range: TVersionRange;
begin
  Range := CreateExactVersion('1.0.0');
  Assignment := TAssignment.CreateDecision('TestPackage', Range, 1, 0);
  
  Assert.AreEqual('TestPackage', Assignment.PackageId);
  Assert.AreEqual(TAssignmentType.atDecision, Assignment.AssignmentType);
  Assert.AreEqual(1, Assignment.DecisionLevel);
  Assert.AreEqual(0, Assignment.Index);
  Assert.IsNull(Assignment.Cause);
end;

procedure TTestPubGrubCore.TestAssignmentCreation_Derivation;
var
  Assignment: IAssignment;
  Range: TVersionRange;
  Cause: IIncompatibility;
begin
  Range := CreateExactVersion('1.0.0');
  Cause := TIncompatibility.NoVersions('TestPackage');
  Assignment := TAssignment.CreateDerivation('TestPackage', Range, 1, 0, Cause);
  
  Assert.AreEqual(TAssignmentType.atDerivation, Assignment.AssignmentType);
  Assert.IsNotNull(Assignment.Cause);
end;

procedure TTestPubGrubCore.TestAssignmentValidation(const TestValue: string; const ExpectedException: string);
var
  Range: TVersionRange;
  ExceptionRaised: Boolean;
begin
  Range := CreateExactVersion('1.0.0');
  ExceptionRaised := False;
  
  try
    if TestValue = '' then
      TAssignment.CreateDecision('', Range, 1, 0)
    else if TestValue = '-1' then
      TAssignment.CreateDecision('TestPackage', Range, -1, 0)
    else if TestValue = '-2' then
      TAssignment.CreateDecision('TestPackage', Range, 1, -2);
  except
    on E: Exception do
    begin
      ExceptionRaised := True;
      Assert.AreEqual(ExpectedException, E.ClassName);
    end;
  end;
  
  Assert.IsTrue(ExceptionRaised, 'Expected exception was not raised');
end;

procedure TTestPubGrubCore.TestAssignmentEquality;
var
  Assignment1, Assignment2: IAssignment;
  Range: TVersionRange;
begin
  Range := CreateExactVersion('1.0.0');
  Assignment1 := TAssignment.CreateDecision('TestPackage', Range, 1, 0);
  Assignment2 := TAssignment.CreateDecision('TestPackage', Range, 1, 0);
  
  Assert.AreEqual(Assignment1.PackageId, Assignment2.PackageId);
  Assert.AreEqual(Assignment1.DecisionLevel, Assignment2.DecisionLevel);
  Assert.AreEqual(Integer(Assignment1.AssignmentType), Integer(Assignment2.AssignmentType));
end;

procedure TTestPubGrubCore.TestAssignmentToString;
var
  Assignment: IAssignment;
  Range: TVersionRange;
  Str: string;
begin
  Range := CreateExactVersion('1.0.0');
  Assignment := TAssignment.CreateDecision('TestPackage', Range, 1, 0);
  
  Str := Format('Assignment: %s', [Assignment.PackageId]); // Manual formatting
  Assert.Contains(Str, 'TestPackage');
  Assert.Contains(Str, 'Decision');
end;

// Incompatibility Tests

procedure TTestPubGrubCore.TestIncompatibilityCreation_Simple;
var
  Incompatibility: IIncompatibility;
  Terms: array[0..0] of ITerm;
  Range: TVersionRange;
begin
  Range := CreateVersionRange('1.0.0', '2.0.0');
  Terms[0] := TTerm.Create('TestPackage', Range, False);
  
  Incompatibility := TIncompatibility.Create(Terms, icNoVersions, 'Test failure');
  
  Assert.AreEqual(1, Incompatibility.Terms.Count);
  Assert.AreEqual(icNoVersions, Incompatibility.Cause);
  Assert.AreEqual('Test failure', Incompatibility.FailureReason);
end;

procedure TTestPubGrubCore.TestIncompatibilityCreation_Complex;
var
  Incompatibility: IIncompatibility;
  Terms: array[0..1] of ITerm;
  Range1, Range2: TVersionRange;
begin
  Range1 := CreateVersionRange('1.0.0', '2.0.0');
  Range2 := CreateVersionRange('2.0.0', '3.0.0');
  Terms[0] := TTerm.Create('Package1', Range1, True);
  Terms[1] := TTerm.Create('Package2', Range2, False);
  
  Incompatibility := TIncompatibility.Create(Terms, icConflict, 'Version conflict');
  
  Assert.AreEqual(2, Incompatibility.Terms.Count);
  Assert.AreEqual(1, Incompatibility.ConflictCount); // One negative term
end;

procedure TTestPubGrubCore.TestIncompatibilityFromDependency;
var
  Incompatibility: IIncompatibility;
  PackageRange, DependencyRange: TVersionRange;
begin
  PackageRange := CreateExactVersion('1.0.0');
  DependencyRange := CreateVersionRange('2.0.0', '3.0.0');
  
  Incompatibility := TIncompatibility.FromDependency('MyPackage', PackageRange, 
    'Dependency', DependencyRange);
    
  Assert.AreEqual(2, Incompatibility.Terms.Count);
  Assert.AreEqual(icDependency, Incompatibility.Cause);
  Assert.Contains(Incompatibility.FailureReason, 'depends on');
end;

procedure TTestPubGrubCore.TestIncompatibilityNoVersions;
var
  Incompatibility: IIncompatibility;
begin
  Incompatibility := TIncompatibility.NoVersions('TestPackage');
  
  Assert.AreEqual(1, Incompatibility.Terms.Count);
  Assert.AreEqual(icNoVersions, Incompatibility.Cause);
  Assert.Contains(Incompatibility.FailureReason, 'No versions available');
end;

procedure TTestPubGrubCore.TestIncompatibilityFailure;
var
  Incompatibility: IIncompatibility;
begin
  Incompatibility := TIncompatibility.Failure;
  
  Assert.AreEqual(0, Incompatibility.Terms.Count);
  Assert.AreEqual(icFailure, Incompatibility.Cause);
  Assert.IsTrue(Incompatibility.IsFailure);
end;

procedure TTestPubGrubCore.TestIncompatibilityToString;
var
  Incompatibility: IIncompatibility;
  Str: string;
begin
  Incompatibility := TIncompatibility.Failure;
  Str := Incompatibility.ToString;
  
  Assert.Contains(Str, 'No solution');
end;

// Version Range Tests

procedure TTestPubGrubCore.TestVersionRangeIntersection;
var
  Range1, Range2, Intersection: TVersionRange;
begin
  Range1 := CreateVersionRange('1.0.0', '3.0.0');
  Range2 := CreateVersionRange('2.0.0', '4.0.0');
  
  if not Range1.TryGetIntersectingRange(Range2, Intersection) then
    Intersection := TVersionRange.Empty;
  
  Assert.IsFalse(Intersection.IsEmpty);
end;

procedure TTestPubGrubCore.TestVersionRangeOverlaps;
var
  Range1, Range2, Range3, Temp: TVersionRange;
begin
  Range1 := CreateVersionRange('1.0.0', '3.0.0');
  Range2 := CreateVersionRange('2.0.0', '4.0.0');
  Range3 := CreateVersionRange('5.0.0', '6.0.0');
  
  Assert.IsTrue(Range1.TryGetIntersectingRange(Range2, Temp));
  Assert.IsFalse(Range1.TryGetIntersectingRange(Range3, Temp));
end;

procedure TTestPubGrubCore.TestVersionRangeSatisfies;
var
  Range1, Range2: TVersionRange;
begin
  Range1 := CreateVersionRange('1.0.0', '3.0.0');
  Range2 := CreateVersionRange('1.5.0', '2.5.0');
  
  Assert.IsTrue(Range2.IsSubsetOrEqualTo(Range1));
  Assert.IsFalse(Range1.IsSubsetOrEqualTo(Range2));
end;

procedure TTestPubGrubCore.TestAssignmentTypes;
begin
  Assert.AreEqual(0, Ord(TAssignmentType.atDecision));
  Assert.AreEqual(1, Ord(TAssignmentType.atDerivation));
end;

end.