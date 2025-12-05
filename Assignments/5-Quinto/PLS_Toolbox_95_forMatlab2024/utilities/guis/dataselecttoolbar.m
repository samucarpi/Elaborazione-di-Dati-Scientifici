function dataselecttoolbar(fig,show)
%DATASELECTORTOOLBAR Show/Hide toolbar with additional select functionality
% Shows or hides the Data Selector toolbar which has additional selection
% functionality for PlotGUI figures. When called with only one input (the
% figure handle), the toolbar is toggled on or off. When called with a
% second input (show), the toolbar is shown (1) or hidden (0). If called
% with no inputs, the toolbar on current figure is toggled.
%
%I/O: dataselecttoolbar(fig)      %toggles toolbar
%I/O: dataselecttoolbar(fig,1)    %shows toolbar
%I/O: dataselecttoolbar(fig,0)    %hides toolbar

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  show = [];
end
if nargin<1 | isempty(fig)
  fig = gcbf;
end
if isempty(fig)
  fig = gcf;
end

if ~ishandle(fig)
  return;
end
if ~isplotgui(fig)
  show = 0;
end

tbh = findobj(fig,'tag',mytag);
tbexists = ~isempty(tbh);
if isempty(show)
  show = ~tbexists;
end
if ~show
  if tbexists
    closetoolbar(tbh);
  end
else
  if ~tbexists
    
    noinclude = getappdata(fig,'noinclude');
    if ~noinclude
      btnlist = {
        'selectx'      'selectonly' @makeselection 'enable' 'Select and Include Only Selected' 'off' 'push' ;
        'selectxplus'  'selectadd'  @makeselection 'enable' 'Select and Include' 'off' 'push' ;
        'selectxminus' 'selectsub'  @makeselection 'enable' 'Select and Exclude' 'off' 'push'
        };
      sep = 'on';
    else
      btnlist = {};
      sep = 'off';
    end
    
    btnlist = [btnlist; {
      'search'       'pgsearch'   'plotgui_searchbar(gcbf);' 'enable' 'Make Selection by Search'  sep   'push'
      'close'        'donebtn'    @closetoolbar  'enable' 'Close Data Selection toolbar' 'on' 'push'
      }];
    
    tbh = toolbar(fig,'',btnlist,mytag);
    viewexcluded = getappdata(fig,'viewexcludeddata');
    setappdata(tbh,'viewexcluded',viewexcluded)
    setappdata(tbh,'selectionmode',getappdata(fig,'selectionmode'));
    plotgui('update','figure',fig,'viewexcludeddata',1); %REMOVED:  ,'selectionmode','xs')
  end
end

%--------------------------------
function out = mytag 

out = 'dataselecttoolbar';

%-----------------------------------------
function closetoolbar(varargin)

%get toolbar harndle and figure handle
tbh = varargin{1};
if ~strcmp(get(tbh,'tag'),mytag)
  %assume it was a child
  tbh = get(tbh,'parent');
end
fig = get(tbh,'parent');

%note status of viewexcluded that we saved
viewexcluded = getappdata(tbh,'viewexcluded');
selectionmode = getappdata(tbh,'selectionmode');
delete(findobj(tbh,'tag',mytag));  %and delete toolbar

if isplotgui(fig);
  %return viewexcluded and selectionmode to their original states
  plotgui('update','figure',fig,'viewexcludeddata',viewexcluded,'selectionmode',selectionmode)
end

%----------------------------------------
function out = isplotgui(fig) 
out = strcmpi(char(getappdata(fig,'figuretype')),'plotgui');

%----------------------------------------
function makeselection(varargin)

tag = get(varargin{1},'tag');
fig = gcbf;
plotgui('makeselection',fig);
sel = plotgui('getselection',fig);
if all(cellfun('isempty',sel))
  sel = {};
end
call = [];
switch tag
  case 'selectonly'
    call = 'EditExcludeUnselected';
    if isempty(sel); return; end
  case 'selectadd' 
    call = 'EditIncludeSelection';
  case 'selectsub' 
    call = 'EditExcludeSelection';
end
if ~getappdata(fig,'noinclude') & ~isempty(call)
  plotgui('menuselection',call);
end
