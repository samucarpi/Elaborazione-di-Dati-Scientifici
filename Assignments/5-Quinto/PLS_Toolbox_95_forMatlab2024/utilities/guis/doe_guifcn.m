function varargout = doe_guifcn(varargin)
%DOE_GUIFCN Design of Experiments Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = analysis('options');
        %add guifcn specific options here
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if nargout == 0;
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
end

%----------------------------------------------------
function anova_Callback(h,eventdata,handles,varargin)

if ~checkdoe(handles,'ANOVA');
  return;
end

x = analysis('getobjdata','xblock',handles);
y = analysis('getobjdata','yblock',handles);

tbl = {};
for yi=y.include{2};
  res = anovadoe(x,y(:,yi));
  tbl{end+1} = res.table;
end
ibh = infobox(char(tbl),struct(...
  'visible','on',...
  'fontname','courier',...
  'figurename','ANOVA Results',...
  'openmode','reuse'));
analysis('adopt',handles,ibh,'modelspecific');

%-----------------------------------------------------------------
function   gui_updatetoolbar(h,eventdata,handles,varargin)

%get X block to decide if this is a DOE dataset
x = analysis('getobjdata','xblock',handles);

% is categorical if all(ismember(x.classid{2},'Categorical')) is true
if ~isempty(x) & isfield(x.userdata,'DOE') & all(contains(x.classid{2},{'Categorical', 'Interaction'}))
  %DOE DataSet
  
  %we'll need this info too...
  statmodl = getappdata(handles.analysis,'statmodl');
  y = analysis('getobjdata','yblock',handles);

  %Enable buttons that are special for DOE mlr
  set([handles.anova handles.doeeffects handles.plothalfnorm handles.make_doe_y],'visible','on')%,'separator','off')

  %anova button
  if ~isempty(y);  %y present and DOE data? enable anova
    en = 'on';
    eno = 'off';
  else
    en = 'off';
    eno = 'on';
  end
  
  set([handles.anova handles.doeeffects handles.plothalfnorm],'enable',en);
  set(handles.make_doe_y,'enable',eno);
  set(handles.make_doe_y,'separator','on');
  
else
  %not a DOE, disable buttons
  set([handles.anova handles.doeeffects handles.make_doe_y handles.plothalfnorm], 'Enable','off','visible','off','separator','off')
end

%-----------------------------------------------------------------
function doeeffectsplot_Callback(h,eventdata,handles,varargin)
%DOE effects plot.

if ~checkdoe(handles,'DOE Effects Plot');
  return;
end

x = analysis('getobjdata','xblock',handles);
y = analysis('getobjdata','yblock',handles);

%Give listdlg with all primary factors and 2-level interactions (i.e. do
%NOT offer 3rd order or higher interactions in list). Use labels from
%X-block columns in dialog.

mylst = str2cell(x.label{2});
myidx = intersect(find(ismember(x.classid{2},{'Numeric' 'Categorical' '2 Term Interaction'})),x.include{2});

% if length(myidx)>1
%   [listidx,OK] = listdlg('PromptString','Select column:',...
%     'SelectionMode','single',...
%     'InitialValue',1,...
%     'ListString',mylst(myidx));
%   if ~OK
%     return
%   end
%   icol = myidx(listidx);
% else
%   %only one - just show it
%   icol = myidx;
% end

alpha = inputdlg({['Two-sided critical region (alpha):']},'Specify (alpha)',1,{'0.05'});
if isempty(alpha)
  return
end
alpha = str2num(alpha{1});
%TODO: provide selection of alpha on plot itself??

options.display = 'off';

%Per Randy suggestion, open all plots.
for i = myidx
  newfig = doeeffectsplot(x, y, i, alpha,options);
end

analysis('adopt',handles,newfig,'modelspecific');

%-----------------------------------------------------------------
function plothalfnorm_Callback(h,eventdata,handles,varargin)
%Halfnorm plot.
if ~checkdoe(handles,'DOE Half-Normal Plot');
  return;
end

xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);

%Select Y-column to use for plot.
include = yblk.include{2};
ncols   = length(include);
if ncols>1
  lbls = yblk.label{2};
  for j=1:ncols;
    if isempty(lbls);
      str{j} = ['Column ' num2str(include(j))];
    else
      str{j} = [lbls(include(j),:) '  (' num2str(include(j)) ')'];
    end
  end
  [selection,ok] = listdlg('ListString',str,'SelectionMode','single','InitialValue',include(1),'PromptString','Select Y-Column to use:','Name','Half-Norm Y-Column');
else
  selection = include(1);
  ok = true;
end

if ok & ~isempty(selection)
  y = yblk(yblk.include{1},selection);
  newfig = halfnormplot(xblk, y, 'half-normal');
  analysis('adopt',handles,newfig,'modelspecific');
end

%-----------------------------------------------------------------
function makedoey_Callback(h,eventdata,handles,varargin)
%Make DOE Y-Block from DOE DSO.
doedso = analysis('getobjdata','xblock',handles);

if isempty(doedso)
  return
end

rsp = doedso.userdata.DOE.options.response_variables;

newy = dataset(nan(size(doedso,1),length(rsp)));
newy = copydsfields(doedso,newy,1);
newy.name = 'Responses';
newy.author = 'Analysis';
newy.label{2,1} = rsp';

analysis('loaddata_callback',handles.analysis, [], handles,'yblock', newy);
analysis('editblock',handles.analysis, [], handles,'yblock')
%-----------------------------------------------------------------
function ok = checkdoe(handles,method_name,varargin)
%Check for objects necessary for DOE.

x = analysis('getobjdata','xblock',handles);
y = analysis('getobjdata','yblock',handles);

ok = true;
if isempty(x) | ~isfield(x.userdata,'DOE')
  erdlgpls([method_name ' requires a DOE DataSet as the X-block'],[method_name ' Error']);
  ok = false;
  return;
end
if isempty(y);
  erdlgpls([method_name ' requires a response variable to be loaded in the Y-block'],[method_name ' Error']);
  ok = false;
  return;
end

