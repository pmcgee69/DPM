{***************************************************************************}
{                                                                           }
{           Delphi Package Manager - DPM                                    }
{                                                                           }
{           Copyright � 2019 Vincent Parrett and contributors               }
{                                                                           }
{           vincent@finalbuilder.com                                        }
{           https://www.finalbuilder.com                                    }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit DPM.IDE.EditorView;

interface

uses
  ToolsAPI,
  DesignIntf,
  VCL.Forms,
  Spring.Container,
  DPM.IDE.ProjectTreeManager,
  DPM.IDE.BaseEditViewFrame;

type
  IDPMEditorView = interface
    ['{1DF76A55-76AC-4789-A35A-CA025583356A}']
    procedure Reloaded;
    procedure ThemeChanged;
  end;

  TDPMEditorView = class(TInterfacedObject, INTACustomEditorView, INTACustomEditorView150, IDPMEditorView)
  private
    FContainer : TContainer;
    FProject : IOTAProject;
    FProjectGroup : IOTAProjectGroup;
    FIsProjectGroup : boolean;
    FFrame : TDPMBaseEditViewFrame;
    FImageIndex : integer;
    FCaption : string;
    FProjectTreeManager : IDPMProjectTreeManager;
    FIdentifier : string;
  protected
    //IDPMEditorView
    procedure Reloaded;
    procedure ThemeChanged;

    function CloneEditorView : INTACustomEditorView;
    procedure CloseAllCalled(var ShouldClose : Boolean);
    procedure DeselectView;
    function EditAction(Action : TEditAction) : Boolean;
    procedure FrameCreated(AFrame : TCustomFrame);
    function GetCanCloneView : Boolean;
    function GetCaption : string;
    function GetEditState : TEditState;
    function GetEditorWindowCaption : string;
    function GetFrameClass : TCustomFrameClass;
    function GetViewIdentifier : string;
    procedure SelectView;

    //INTACustomEditorView150
    function GetImageIndex : Integer;
    function GetTabHintText : string;
    procedure Close(var Allowed : Boolean);
  public
    constructor Create(const container : TContainer; const project : IOTAProject; const imageIndex : integer; const projectTreeManager : IDPMProjectTreeManager);
    destructor Destroy;override;
  end;

implementation

uses
  System.SysUtils,
  DPM.IDE.EditorViewFrame,
  DPM.IDE.GroupEditorViewFrame;

{ TDPMEditorView }

function TDPMEditorView.CloneEditorView : INTACustomEditorView;
begin
  result := nil;
end;

procedure TDPMEditorView.Close(var Allowed : Boolean);
begin
  Allowed := true;
  FFrame.Closing;
  FFrame := nil;
end;

procedure TDPMEditorView.CloseAllCalled(var ShouldClose : Boolean);
begin
  //doesn't seem to get called???
  ShouldClose := true;
  FFrame.Closing;
end;

constructor TDPMEditorView.Create(const container : TContainer; const project : IOTAProject; const imageIndex : integer; const projectTreeManager : IDPMProjectTreeManager);
begin
  FContainer := container;
  FProject := project;
  FImageIndex := imageIndex;
  FProjectTreeManager := projectTreeManager;
  FProjectGroup := nil;
  FIsProjectGroup := Supports(FProject, IOTAProjectGroup, FProjectGroup);
  if FIsProjectGroup then
    FCaption := 'DPM : ProjectGroup'
  else
    FCaption := 'DPM : ' + ChangeFileExt(ExtractFileName(FProject.FileName), '');

  if FProjectGroup <> nil then
    FIdentifier := 'DPM_GROUP_VIEW_' + ChangeFileExt(ExtractFileName(FProjectGroup.FileName), '')
  else
     FIdentifier := 'DPM_VIEW_' + ChangeFileExt(ExtractFileName(FProject.FileName), '');
   FIdentifier := StringReplace(FIdentifier, '.', '_', [rfReplaceAll]);

end;

procedure TDPMEditorView.DeselectView;
begin
  if FFrame <> nil then
    FFrame.ViewDeselected;
end;

destructor TDPMEditorView.Destroy;
begin

  inherited;
end;

function TDPMEditorView.EditAction(Action : TEditAction) : Boolean;
begin
  result := false;
end;

procedure TDPMEditorView.FrameCreated(AFrame : TCustomFrame);
begin
  FFrame := TDPMBaseEditViewFrame(AFrame);
  FFrame.Name := GetViewIdentifier;
  FFrame.Configure(FProject, FContainer, FProjectTreeManager);
end;

function TDPMEditorView.GetCanCloneView : Boolean;
begin
  result := false;
end;

function TDPMEditorView.GetCaption : string;
begin
  result := FCaption;
end;

function TDPMEditorView.GetEditorWindowCaption : string;
begin
  result := 'DPM Packages';
end;

function TDPMEditorView.GetEditState : TEditState;
begin
  result := [];
end;

function TDPMEditorView.GetFrameClass : TCustomFrameClass;
begin
  if FIsProjectGroup then
    result := TDPMGroupEditViewFrame
  else
    result := TDPMEditViewFrame;
end;

function TDPMEditorView.GetImageIndex : Integer;
begin
  result := FImageIndex;
end;

function TDPMEditorView.GetTabHintText : string;
begin
  result := GetCaption;
end;

function TDPMEditorView.GetViewIdentifier : string;
begin
  result := FIdentifier;
end;

procedure TDPMEditorView.Reloaded;
begin
  if FFrame <> nil then
    FFrame.ProjectReloaded;
end;

procedure TDPMEditorView.SelectView;
begin
  //Note : For some reason this is getting called twice in XE7 for each selection.
  //TODO : Check if it's the same in other IDE versions
  if FFrame <> nil then
    FFrame.ViewSelected;
end;

procedure TDPMEditorView.ThemeChanged;
begin
  if FFrame <> nil then
    FFrame.ThemeChanged;
end;

end.

