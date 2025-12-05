function varargout = panelmanager(action,figdata,frameh)
%PANELMANAGER Manages basic tasks of adding contents of fig file to an existing ui frame.
%  This function aids in organizing of graphical elements for reuse in
%  figures. It will copy all controls stored in a seperate .fig file (content figure) to a
%  frame on a figure (content frame).
%
%  Input 'figdata' is a structure with two fields (.name and .file). The
%  'name' fields is the display name, the name displayed to a user for
%  selecting that panel. The 'file' field contians the m/fig file name of
%  the "content figure".
%  
%  NOTE: Field names on xxxgui.m figures/functions should be taged with
%  specific names, not default names. It's too easy to make mistakes when
%  pulling values in mfile.
%
%  EXAMPLE:
%     panelinfo.name = 'Function Settings';
%     panelinfo.file = 'gcluster';
%     panelmanager('add',panelinfo,handles.ssqframe)
%
%  Each control that is copied will have its userdata field value
%  containing the name of its original content figure (.file name).
%
%  Each control should be queried for its value or should act on the parent
%  figure's appdata.
%
%  Each content figure should have it's own .m file containing resize
%  behavior and update behavior.
%
%  The figure file name will be used to identify it's controls on
%  the content frame.
%
%  action
%   add - Add controls from content figure. Remove any duplicates from both ofigdata and figdata.
%   visible - Make panel visible and all others invisisble.
%   invisible - Make a panel invisible.
%   invisibleall - Make all panels invisible.
%   delete - Remove all objects for given panel/s.
%   resize - Call resize function of given panel.
%   update - Call update function of given panel.
%   findcontrols - Get handles of all controls for currently visible panels.
%
%  Callback needed in figure m-file:
%
%     panelupdate_Callback     - handles visibility, enable, and all other
%                                dynamic functionality. Should include
%                                initialization functionality.
%
%     panelresize_Callback     - reszie/reposition controls only.
%
%     panelinitialize_Callback - handels initialization code. Only called
%                                on add.
%     panelblur_Callback       - OPTIONAL. Called when a panel was visible
%                                but looses visibility or "focus" (thus, is
%                                "blurred")
%
%I/O: varargout = panelmanager(action,figdata,frameh);
%
%See also: CLUSTER

% Copyright © Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 8/24/2007

if ischar(action) && ismember(action,evriio([],'validtopics'));
  options = [];
  if nargout==0;
    clear varargout;
    evriio(mfilename,action,options);
  else
    varargout{1} = evriio(mfilename,action,options);
  end
  return;
end

% if nargout
%   [varargout{1:nargout}] = feval(varargin{:});
% else
%   feval(varargin{:});
% end

if nargin<1
  error('Need at least one input for panelmanager.')
end

if nargin==2
  %('action',frameh)  assumes empty figdata
  frameh = figdata;
  figdata = [];
end
if ~isempty(figdata) && (ischar(figdata) || iscell(figdata))
  %allow figdata to be just the file (easier calls)
  %e.g., panelmanager('visible','myfilename',...)
  %e.g., panelmanager('visible',{'oneframe' 'twoframe'},...)
  figdata = struct('file',figdata);
end
fparent = get(frameh,'parent');

%Remove any item that is missing its fig file or the fig file is empty
bad = [];
for i = 1:length(figdata)
  if ~isempty(figdata(i).file) & ~ismember(figdata(i).file,{'ssqtable'})
    if ~exist(figdata(i).file)
      bad(end+1) = i;
    else
      %Need to look up old struct "hgS_070000" variable. If not specified
      %then load will open a figure in newer versions of matlab. In old
      %matlab versions the other variable "hgM_070000" is ignored by load.
      warningstateOld = warning('query', 'MATLAB:load:variableNotFound');
      warning('off', warningstateOld.identifier);
      contents = load([figdata(i).file '.fig'],'-mat','hgS_050200');
      if isempty(fieldnames(contents))
        contents = load([figdata(i).file '.fig'],'-mat','hgS_070000');
      end
      warning(warningstateOld.state, warningstateOld.identifier)
      if isempty(fieldnames(contents))
        bad(end+1) = i;
      end
    end
  end
end
figdata(bad) = [];  %drop those marked as "bad"

%Remove ssq table becuase it's a special case for analysis and will break
%code below. Keep copy of orginal so can be used with rmpanel.
ofigdata = figdata;
if ~isempty(figdata);
  idx = ~ismember({figdata.file}, 'ssqtable');
  figdata = figdata(idx);
end
panelinfo = getappdata(fparent,'panelinfo');
if isempty(panelinfo)
  %initalize panelinfo for first ever call
  panelinfo = struct('visible','','panels',[]);
  setappdata(fparent,'panelinfo',panelinfo);
end

% ssqframe = findobj(fparent,'tag','ssqframe');
% 
% if ~isempty(ssqframe) & ~isempty(panelinfo.panels) & ismember('variableselectiongui',{panelinfo.panels.file})
%   set(ssqframe,'visible','on')
% end

switch action
  case 'add'
    %Remove any duplicates from both ofigdata and figdata. This can
    %happen if guideselect doesn't get run to destroy old copies.
    for i = 1:length(panelinfo.panels)
      idx = find(ismember({figdata.file},panelinfo.panels(i).file));
      if ~isempty(idx)
        figdata(idx) = [];
      end
      idx = find(ismember({ofigdata.file},panelinfo.panels(i).file));
      if ~isempty(idx)
        ofigdata(idx) = [];
      end
    end

    if isempty(figdata)
      if isempty(ofigdata)
        return;
      else
        %Must be ssq table or some other special case.
        panelinfo = struct('visible','','panels',[]);
        panelinfo.panels = ofigdata;
        setappdata(fparent,'panelinfo',panelinfo);
        return;
      end
    end  %nothing to add? return

    %Add figdata to parent appdata field.
    panelinfo.panels = [panelinfo.panels ofigdata];
    setappdata(fparent,'panelinfo',panelinfo);
    %Add controls.
    for i = 1:length(figdata)
      if ~isempty(figdata(i).file)
        if strcmp(figdata(i).file,'modeltable')
          maketable(fparent)
        else
          fig   = openfig([figdata(i).file '.fig'],'new','invisible');
        end
        fobjs = findobj(fig,'type','uicontrol');
        
        %****** Uncomment code below if uipanels are used in panels other
        %than variableselectiongui. It will be slow because of findobj but
        %will work. Commenting out now to speed things up.
        
        %Find uipanel objects and remove their children from fobjs since
        %they'll be copied with uipanel.
%         fpnls = findobj(fig,'type','uipanel');
%         fpnls_chd = findall(fpnls);%All children of panels.
%         
%         %All controls not on panels.
%         fobjs = fobjs(~ismember(fobjs,intersect(fobjs,fpnls_chd)));
%         
%         %Add panels.
%         fobjs = [fobjs; fpnls];
        %******
        
        %Special copy for variableselectiongui because it has "parent"
        %panel and all controls are copied as panel 
        %Maybe generalize this in future. 
        if ismember(figdata(i).file ,{'variableselectiongui' 'xgbgui' 'anndlgui'})
          fobjs = findobj(fig,'tag','uipanel_method');
          %Move objects way out to solve flickering problem with 14a and
          %older.
          set(fobjs,'position',[10000 10000 10 10]);
        end
        
        set(fobjs,'visible','off');
        newh  = evricopyobj(fobjs,fparent);
        %NOTE: UISTACK causes the entire figure to flash and repaint. It's
        %quite ugly so it is commented out below.
        if checkmlversion('<','7')
          %Have to use uistack with r13 because controls get sent to back.
          %Stack new controls to bottom.
          uistack(newh,'bottom');
          %Put frame below new controls.
          uistack(frameh,'bottom');
        end
        set(newh,'userdata',figdata(i).file,'visible','off');
        delete(fig);
        %If parent panel is an actual uipanel (not a frame) then try to title it.
        if strcmp(get(frameh,'Type'),'uipanel')
          %FIXME: Should find a way to be explicit about font size. Mac
          %needs 12 and Windows needs 10. Some uses may not need Title at
          %all e.g., SSQ Table.
          set(frameh,'Title',figdata(i).name,'FontSize',10)
          %Make frameh the new parent to child objects.
          %NOTE: The controls will use a relative position to frameh.
          set(newh,'Parent',frameh);
        end

        %Run any initialize code.
        safefeval(figdata(i).file,'panelinitialize_Callback',fparent,frameh);
      end
    end

  case 'getpanels'

    varargout = {panelinfo.panels};

  case 'visible'
    if isempty(figdata); 
      %no name provided? return currently visible panel
      varargout = {panelinfo.visible};
      return; 
    end
    if length(figdata)>1;
      error('Only one panel can be made visible at a time')
    end
    %% if another panel is visible right now, make it invisible
    if ~strcmp(panelinfo.visible,figdata(1).file)
      panelmanager('invisible',panelinfo.visible,frameh);
    end
    panelmanager('resize',figdata(1).file,frameh);
    if ~isempty(figdata(1).file);
      set(findobj(fparent,'userdata',figdata(1).file),'visible','on')
    end
    %% store which panel was made visible
    panelinfo.visible = figdata(1).file;
    setappdata(fparent,'panelinfo',panelinfo);
    toggleSSQFrame(fparent,figdata,panelinfo)
    %Resize here.
    panelmanager('resize',figdata,frameh)

  case 'invisibleall'
    panelmanager('invisible',struct('file',{panelinfo.panels.file}),frameh);

  case 'invisible'
    if isempty(figdata); return; end  %nothing to add? return
    for i = 1:length(figdata)
      if ~isempty(figdata(i).file)
        set(findobj(fparent,'userdata',figdata(i).file),'visible','off')
      end
      if strcmp(panelinfo.visible,figdata(i).file)
        %this panel was the currently visible panel
        try
          %try running the blur callback
          safefeval(figdata(i).file,'panelblur_Callback',fparent,frameh);
        catch
          %couldn't find or run a blur callback - just skip it
        end
        panelinfo.visible = '';   %% note this panel is invisible now
      end
    end
    toggleSSQFrame(fparent,figdata,panelinfo)
    setappdata(fparent,'panelinfo',panelinfo);

  case 'resize'
    %% get which panel is visible, resize ONLY that one
    if isempty(figdata) && ~isempty(panelinfo.visible)
      figdata = struct('file',panelinfo.visible);
    end
    for i = 1:length(figdata)
      safefeval(figdata.file,'panelresize_Callback',fparent,frameh);
    end
    %Update here.
    panelmanager('update',figdata,frameh)

  case 'update'
    if isempty(figdata) && ~isempty(panelinfo.visible)
      figdata = struct('file',panelinfo.visible);
    end
    for i = 1:length(figdata)
      safefeval(figdata(i).file,'panelupdate_Callback',fparent,frameh);
    end

  case 'delete'
    for i = 1:length(figdata)
      if ~isempty(figdata(i).file)
        delete(findobj(fparent,'userdata',figdata(i).file))
      end
      try
        delete(findobj(fparent,'tag','mtable'))
      end
      if strcmp(panelinfo.visible,figdata(i).file)
        panelinfo.visible = '';   %% note this panel is invisible now
      end
      
    end
    setappdata(fparent,'panelinfo',panelinfo);
    rmpanel(fparent,ofigdata);
    toggleSSQFrame(fparent,figdata,panelinfo)

  case 'ispanel'
    %Tests to see if 'figdata.file' is listed in 'getpanels'.
    curpanels = panelmanager('getpanels',frameh);
    mypanel = figdata(1).file;
    if ~isempty(curpanels) && ismember(mypanel,{curpanels.file})
      varargout = {true};
    else
      varargout = {false};
    end

  case 'currentpanel'
    %What's the current (visible) panel.
    if ~isempty(panelinfo.visible)
      idx = ismember({panelinfo.panels.file}, panelinfo.visible);
      varargout = {panelinfo.panels(idx).name};
    else
      varargout = {[]};
    end
  case 'findcontrols'
    %Get handles for all of the current panels controls.
    if ~isempty(panelinfo.visible) 
      idx = ismember({panelinfo.panels.file}, panelinfo.visible);
      if ~isempty(panelinfo.panels(idx).file)
        varargout = {findobj(fparent,'userdata',panelinfo.panels(idx).file)};
      else
        varargout = {[]};
      end        
    else
      varargout = {[]};
    end
    
  otherwise

end

%-------------------------------------------
function rmpanel(fparent,figdata)
%Remove items in figdata from panelinfo struction in parent figure. Uses
%.file field as key.

if isempty(figdata); return; end ; %no panels? just exit
parentinfo = getappdata(fparent,'panelinfo');
idx = ~ismember({parentinfo.panels.file}, {figdata.file});
parentinfo.panels = parentinfo(:).panels(idx);
setappdata(fparent,'panelinfo',parentinfo);

%-------------------------------------------
function maketable(fparent)

% [t,c] = uitable(fparent, rand(5), {'A', 'B', 'C', 'D', 'E'});
%
% set(c,'tag','mtable','units','pixels');

%-------------------------------------------
function  safefeval(fn,varargin)
%wrapper for feval which avoids error if fn doesn't exist

if ~isempty(fn)
  if nargout>0
    [varargin{1:nargout}] = feval(fn,varargin{:});
  else
    feval(fn,varargin{:});
  end
end

%-------------------------------------------
function toggleSSQFrame(fparent,figdata,panelinfo)
%Because uipanels can't be on top of frames the SSQ panel needs to be made
%invisible if uipanels are used. 

panelswithUIP = {'variableselectiongui'}; %Add panel to this list if uses UIPanel.

if isempty(figdata)
  return; 
end

ssqframe = findobj(fparent,'tag','ssqframe');
if isempty(ssqframe)
  return
end

if ismember(panelinfo.visible,panelswithUIP)
  %This panel needs ssq frame visible off.
  set(ssqframe,'visible','off')
else
  %Turn on ssq frame.
  set(ssqframe,'visible','on')
end






