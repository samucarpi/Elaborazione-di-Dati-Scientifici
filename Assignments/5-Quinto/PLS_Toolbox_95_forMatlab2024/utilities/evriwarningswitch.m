function evriwarningswitch(myswitch)
%EVRIWARNINGSWITCH Manages warnings for EVRI products.
% Optional input 'myswitch' forces warnings 'on' or 'off'. If no inputs
% then turns warnings off.
%
%I/O: evriwarningswitch(myswitch)
%
%See also: GETPLSPREF

%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


if nargin<1
  myswitch = 'off';
end

%Try to put these in alphabetical order to make it easier to identify.
mywarnings = {'MATLAB:dispatcher:nameConflict' ...
  'MATLAB:Figure:SetPosition' ...
  'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame' ...
  'MATLAB:hg:EraseModeIgnored' ...
  'MATLAB:hg:JavaSetHGProperty' ...
  'MATLAB:hg:Root' ... %For get(0,'pointerwindow')
  'MATLAB:hg:UIControlSliderStepValueDifference' ...
  'MATLAB:modes:mode:InvalidPropertySet' ... %Plotgui
  'MATLAB:nearlySingularMatrix' ... %Parafac
  'MATLAB:uitab:MigratingFunction' ...
  'MATLAB:uitabgroup:MigratingFunction' ...
  'MATLAB:uitabgroup:OldVersion' ...
  'MATLAB:uitree:DeprecatedFunction' ...
  'MATLAB:uitreenode:DeprecatedFunction' ...
  'MATLAB:uitable:DeprecatedFunction' ...%17b uitable deprecated.
  'MATLAB:nargchk:deprecated' ... %16a warning.
  'MATLAB:callback:error' ... %15b Mac warning message when pressing number key on plotgui (in mplot) - Error in matlab.graphics.internal.SubplotListenersManager/removeFromListeners
  'MATLAB:load:classNotFound' ...%15a loading fig file in panel manager shows warning.
  'MATLAB:ui:javacomponent:FunctionToBeRemoved' ... %2019b remove in future release.
  'MATLAB:ui:javaframe:PropertyToBeRemoved' ...
  'MATLAB:pfileOlderThanMfile' ... %As of 2019 we're starting to p-code more proprietry code and should avoid obsolete warning when m-file happens to get a slightly older date.
  'MATLAB:ui:actxcontrol:FunctionToBeRemoved' ... %Warning of removal of actxlist and actxcontrol in 2019b (used in hjyreadr and piconnectgui).
  'MATLAB:ui:actxcontrollist:FunctionToBeRemoved' ... 
  'MATLAB:ui:javaframe:PropertyToBeRemoved' ... %ML 2020 warning when starting mccttool. 
  'MATLAB:handle_graphics:exceptions:SceneNode' ...%Bug in 2014b prerelease.
  'MATLAB:table:ModifiedAndSavedVarnames' ...%Warning from readtable when column names must be modified 
  'MATLAB:im2java:functionToBeRemoved'... %Warning from 2022b for icons in browse 
  'MATLAB:colon:operandsNotRealScalar'... %Warning from 2024a in browse in for loop being a vector (via size function) line 160.
  'MATLAB:Axes:NegativeLimitsInLogAxis'}; %Warning that shows up when plotting negative axis in log scale

for i = 1:length(mywarnings)
  warning(myswitch,mywarnings{i})
end

%From analysis.
if ismac
  %For some reason we always get "popupmenu control requires a
  %non-empty String" warnings so trun off. Likely from CV gui being
  %created and drawn before intialized
  warning(myswitch,'MATLAB:hg:uicontrol:ParameterValuesMustBeValid')
  warning(myswitch,'MATLAB:print:CustomResizeFcnInPrint')
end
