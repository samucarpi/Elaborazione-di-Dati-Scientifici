function varargout = batchmaturity_guifcn(varargin)
%BATCHMATURITY_GUIFCN Batchmaturity Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2012
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
        usepca = {'updatefigures'};
        if ~ismember(char(varargin{1}),usepca)
          if nargout == 0;
            feval(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
          end
        else
          if nargout == 0;
            pca_guifcn(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = pca_guifcn(varargin{:}); % FEVAL switchyard
          end
        end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
end

%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin);
%create toolbar

[atb abtns] = toolbar(handles.analysis,getappdata(handles.analysis,'curanal'),'');
handles  = guidata(handles.analysis);

%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons

%change pc edit box to text box.
set(handles.pcsedit,'style','text')

mytbl = getappdata(handles.analysis,'ssqtable');

mytbl = ssqsetup(mytbl,{'Eigenvalue<br>of Cov(X)' '% Variance<br>This PC' '% Variance<br>Cumulative' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;PC',{'%4.2e' '%6.2f' '%6.2f' ''},1);

tableheader = 'Percent Variance Captured by PCA Model';
set(handles.tableheader,'string',tableheader,'HorizontalAlignment','center');
%Add table header.
setappdata(handles.analysis,'tableheader',tableheader);

% Need to hack options into analysis before call to add panel because 
% panel depends on options being there.
getoptions(handles);

%Add panel.
panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';

panelinfo(2).name = 'Batch Maturity';
panelinfo(2).file = 'batchmaturitygui';

panelmanager('add',panelinfo,handles.ssqframe)

%Turn off CV.
setappdata(handles.analysis,'enable_crossvalgui','off');

%Check for option enabled objects.
options = pca_guifcn('options');

%Auto select button visibility.
setappdata(handles.analysis,'autoselect_visible',0)

%general updating
analysis('updatestatusboxes',handles)
updatefigures(handles.analysis)
updatessqtable(handles)

analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
%Change pcsedit back to defualt style.
set(handles.pcsedit,'style','edit')
set([handles.tableheader handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','on')
set(handles.pcseditlabel,'string','Number PCs:') %change pc edit label.
set(handles.tableheader,'string', { '' },'horizontalalignment','left')
setappdata(handles.analysis,'autoselect_visible',0)

%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');

setappdata(handles.analysis,'enable_crossvalgui','on');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

closefigures(handles);

%--------------------------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
%Edit PCs so set panel PCs box to new value and call pca function.
val = get(handles.pcsedit,'string');
val = str2double(val);
default = getappdata(handles.pcsedit,'default');
if ~isfinite(val) || val<1  %not valid? reset
  set(handles.pcsedit,'string',default);
  return
end
if val==default;
  return
end
val = round(val);

setappdata(handles.pcsedit,'default',val);
switch getappdata(handles.analysis,'statmodl')
  case 'calold'
    setappdata(handles.analysis,'statmodl','calnew');
end
analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)  %set buttons

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)

pca_guifcn('gui_updatetoolbar',h,eventdata,handles,varargin);
if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
end

%-------------------------------------------------
function updatessqtable(handles,pc)

pca_guifcn('updatessqtable',handles);

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes OR y
%out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
%out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

if analysis('isloaded','xblock',handles.analysis);
  if analysis('isloaded','yblock',handles.analysis)
    %if y-block is loaded, we're using it
    out = true;
  else
    %if no y-block, then whether or not we need one is based on if classes
    %exist in the x-block
    x = analysis('getobjdata','xblock',handles);
    xprofile = analysis('varprofile',x);
    out = ~xprofile.class;
  end
else
  %no x? can't decide, assume not
  out = false;
end

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures

pca_guifcn('closefigures',handles);

%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);
% Callback of the uicontrol handles.calcmodel.

handles = guihandles(handles.analysis);%Update handles.

statmodl = lower(getappdata(handles.analysis,'statmodl'));
mytbl    = getappdata(handles.analysis,'ssqtable');

if strcmp(statmodl,'calnew') & ~analysis('isloaded','rawmodel',handles)
  statmodl = 'none';
end

if strcmp(statmodl,'none') | strcmp(statmodl,'calnew');
  x = analysis('getobjdata','xblock',handles);
  if isempty(x.includ{1});
    erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
    return
  end
  if isempty(x.includ{2});
    erdlgpls('All x-block variables excluded. Can not calibrate','Calibrate Error');
    return
  end

  if mdcheck(x.data);
    ans = evriquestdlg({'Missing Data Found - Replacing with "best guess"','Results may be affected by this action.'},'Warning: Replacing Missing Data','OK','Cancel','OK');
    if ~strcmp(ans,'OK'); return; end
    try
      if strcmpi(getfield(modelcache('options'),'cache'),'on')
        modelcache([],x);
        evritip('missingdatacache','Original data (with missing values) has been stored in the model cache.',1)
      end
    catch
    end
    [flag,missmap,x] = mdcheck(x,struct('toomuch','ask'));
    analysis('setobjdata','xblock',handles,x);
  end

  %Deal with y block if present.
  y = analysis('getobjdata','yblock',handles);
  if ~isempty(y);

    nans = any(isnan(y.data(y.include{1},y.include{2})),2);
    if any(nans);
      evrimsgbox({'Missing Data Found in Y-block - Excluding all samples with missing y-block values.'},'Warning: Excluding Missing Data Samples','warn','modal');
      y.include{1} = intersect(y.include{1},y.include{1}(find(~nans)));
      analysis('setobjdata','yblock',handles,y);   %and save back to object
    end
    if isempty(y.includ{2});
      erdlgpls('All y-block columns excluded. Can not calibrate','Calibrate Error');
      return
    end
    isect = intersect(y.include{1},x.include{1}); %intersect samples includ from x- and y-blocks
    if length(x.include{1})~=length(isect) | length(y.include{1})~=length(isect);  %did either change?
      y.include{1} = isect;
      analysis('setobjdata','yblock',handles,y);   %and save back to object
      x.include{1} = isect;
      analysis('setobjdata','xblock',handles,x);   %and save back to object
    end

    if all(all(y.data(y.includ{1},:) == y.data(y.includ{1}(1),1)));
      erdlgpls('All included samples are in the same class - can not do discriminant analysis','Calibrate Error');
      return
    end
  else
    %no y-block, just make empty
    y = [];

  end
  preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};

  options = batchmaturity_guifcn('options');
  
  %PCs come from normal pcsedit.
  maxpc   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors]);
  pc      = getappdata(handles.pcsedit,'default');
  
  %Make sure pc is valid.
  if isempty(pc) | pc>maxpc | pc<1;
    pc = 1;
  end
  
  %LVs come from panel. 
  lvs         = str2num(get(handles.bmlvedit,'String'));

  try
    opts               = getoptions(handles);
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;
    
    %No rawmodel code in BM so just do two normal "expensive" calls.
    opts.rawmodel = 1;
    rawmodl    = batchmaturity(x,y,maxpc,lvs,opts);
    opts.rawmodel = 0;
    modl       = batchmaturity(x,y,pc,lvs,opts);
    
    modl.submodelpca.detail.ssq(pc+1:size(rawmodl.submodelpca.detail.ssq,1),:) = rawmodl.submodelpca.detail.ssq(pc+1:end,:);   %copy complete SSQ table

  catch
    erdlgpls({'Error using Batchmaturity method',lasterr},'Calibrate Error');
    return
  end

  %UPDATE GUI STATUS
  setappdata(handles.analysis,'statmodl','calold');
  analysis('setobjdata','model',handles,modl);
  analysis('setobjdata','rawmodel',handles,rawmodl);

  handles = guidata(handles.analysis);
  pca_guifcn('updatessqtable',handles,pc);

  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 1);

  figure(handles.analysis)
end

if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action
  if ~isempty(y)
    evritip('noyinbm','Validation Y-Block not supported for Batch Maturity. Y data will be ignored.',1);
    y = [];
  end
  
  try
    opts               = getoptions(handles);
    opts.display       = 'off';
    opts.plots         = 'none';

    test = batchmaturity(x,modl,opts);

  catch
    erdlgpls({'Error using applying model',lasterr,'Model not applied to validation data.'},'Apply Model Error');
    test = [];
  end
  analysis('setobjdata','prediction',handles,test);

else
  analysis('setobjdata','prediction',handles,[]);
end

analysis('toolbarupdate',handles)
analysis('updatestatusboxes',handles);

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

updatefigures(handles.analysis);     %update any open figures

%--------------------------------------------------------------------
function plotscores_Callback(h,eventdata,handles,varargin)

pca_guifcn('plotscores_Callback',h,eventdata,handles,{'automonotonic' 1});

%--------------------------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.
handles = guihandles(handles.analysis);%Update handles.
pca_guifcn('ssqtable_Callback',h, eventdata, handles, varargin)

%Update number of PCs in case it's changed.
val = get(handles.pcsedit,'string');
set(handles.bmpcedit,'String',str2double(val));

%----------------------------------------------------
function  optionschange(h)
%Update options on panel.
handles = guihandles(h);
batchmaturitygui('panelupdate_Callback',handles.analysis, []); 

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures
handles = guidata(h);
eventdata = [];%Dummy var.
varargin = [];%Dummy var.

if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
end

pca_guifcn('updatefigures',h)

% --------------------------------------------------------------------
function opts = getoptions(handles)
%Returns options strucutre

%See if there are old/curent options (loaded in analysis under
%enable_method.
opts = analysis('getoptshistory',handles,lower(getappdata(handles.analysis,'curanal')));
if isempty(opts)
  opts = batchmaturity('options');
end
setappdata(handles.analysis, 'analysisoptions',opts);

opts.display       = 'off';
opts.plots         = 'none';



