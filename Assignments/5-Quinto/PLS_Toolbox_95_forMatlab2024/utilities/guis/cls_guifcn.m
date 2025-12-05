function varargout = cls_guifcn(varargin);
%CLS_GUIFCN Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%jms/rsk 04/04 Initial coding.
%rsk 05/04/04 Disable maxpc checking in calc
%       -Change ssq table behavior.
%jms 5/7/04 Re-added test for "bad" preprocessing

%If function not found here then call from pca_guifcn.
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
        usepca = {'biplot_Callback','loadsdatabuttoncall','loadsincludchange','loadsinfobuttoncall',...
          'loadsinfobuttoncall_add','ploteigen_Callback','plotloads_Callback','scoresclasschange','scoresdatabuttoncall',...
          'scoresincludchange','scoresqconbuttoncall','scorestconbuttoncall','varcapbuttoncall'};
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
[atb abtns] = toolbar(handles.analysis, 'cls','');
handles  = guidata(handles.analysis);

%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons

%change pc edit label.
set(handles.pcseditlabel,'string','Number of Components:')


mytbl = getappdata(handles.analysis,'ssqtable');

mytbl = ssqsetup(mytbl,{'Fit<br>(%Model)' 'Fit<br>(%X)' 'Fit<br>Cumulative (%X)'},...
  '<b>&nbsp;&nbsp;&nbsp;PC',{'%6.2f' '%6.2f' '%6.2f'},0);

% %change ssq table labels
% if ispc
%   set(handles.tableheader,'string',...
%     { '          Percent Variance Captured by CLS Model           ',...
%       'Component       Fit               Fit           Cumulative  ',...
%       ' Number      (%Model)         (%X)           Fit (%X)    ' } )
%   format       = '%3.0f       %6.2f   %6.2f    %6.2f';
% else
%   set(handles.tableheader,'string',...
%     { '          Percent Variance Captured by CLS Model           ',...
%       'Component   Fit           Fit          Cumulative  ',...
%       'Number    (%Model)         (%X)         Fit (%X)    ' } )
%   format       = '%5.0f       %6.2f   %6.2f    %6.2f';
% end
% setappdata(handles.analysis,'tableformat',format);

set(handles.tableheader,'string','Percent Variance Captured by CLS Model','HorizontalAlignment','center')

panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';
panelmanager('add',panelinfo,handles.ssqframe)

%turn off crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','on');

%general updating
analysis('updatestatusboxes',handles)
updatefigures(handles.analysis)
updatessqtable(handles)
set(handles.pcsedit,'enable','off')

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
closefigures(handles);
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)
setappdata(handles.analysis,'enable_crossvalgui','on');
%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)
pca_guifcn('gui_updatetoolbar',h,eventdata,handles,varargin);

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes OR y
% out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
% out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

out = true;

%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);

statmodltest = lower(getappdata(handles.analysis,'statmodl'));

switch statmodltest
  case {'none', 'calnew'}
    %prepare X-block for analysis
    x = analysis('getobjdata','xblock',handles);
    y = analysis('getobjdata','yblock',handles);

    if isempty(x.includ{1});
      erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
      return
    end
    
    preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};    
    
    ppdesc = {};
    if ~isempty(preprocessing{1})
      ppdesc = {preprocessing{1}.description};
    end
    if ~isempty(preprocessing{2}) & ~isempty(y)
      ppdesc = {ppdesc{:} preprocessing{2}.description};
    end
    if ~isempty(ppdesc) & any(ismember(ppdesc,{ 'Autoscale' 'Center' 'Mean Center' 'Median Center' 'SNV' 'Detrend' }));
      switch evriquestdlg({'One or more of your selected preprocessing methods includes a centering step (e.g. Autoscale, Mean Centering, Detrend) and is likely to produce a poor CLS model.',...
          ' ','Are you sure you want to calculate the model now?'},'Preprocessing Warning','Yes','No','Yes');
        case 'No'
          return
      end
    end
    
    opts = getappdata(handles.analysis,'analysisoptions');
    if isempty(opts)
      opts = cls('options');
    end
    
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;
    
    if isempty(y) || (isdataset(y) && isempty(y.data))
      %y-block is empty, do special tests for diagy mode
      if getappdata(handles.analysis,'clsxaspure');
        answer = 'Yes';
      else
        answer = evriquestdlg('No y-block is currently loaded. CLS will use the X-block as a set of pure component spectra. Continue?','No Y-block','Yes','Yes, always','Cancel','Yes');
      end
      switch answer
        case 'Cancel'
          return
        case 'Yes, always'
          setappdata(handles.analysis,'clsxaspure',1);
      end
      
      if length(x.include{2})<length(x.include{1})
        erdlgpls({'You have more components than you do variables. A CLS model will not work in these conditions. Suggestions:' 'a) Verify that all samples in your X-block are pure component samples or' 'b) Remove some components or' 'c) Collect additional variables' },'Too few variables')
        return
      end
      
      %remove preprocessing (doesn't really work with empty y-block)
      opts.preprocessing{2} = [];
      
    else
      %y-block isn't empty...
      %check if number of components>number of VARIABLES
      if length(x.include{2})<length(y.include{2})
        erdlgpls({'You have more components than you do variables. A CLS model will not work in these conditions. Suggestions:' 'a) Remove some y-block columns (i.e. components) or' 'b) Add additional x-block variables'},'Too few variables')
        return
      end

      %check if number of components>number of SAMPLES
      if length(x.include{1})<length(y.include{2})
        erdlgpls({'You have more components than you do samples. A CLS model will not work in these conditions. Suggestions:' 'a) Remove some y-block columns (i.e. components) or' 'b) Add additional samples.'},'Too few samples')
        return
      end
    end
    
    %calculate model
    modl    = cls(x,y,opts);
    pc      = size(modl.loads{2},2);   %may have been reduced from what we asked for
      
    if ~isempty(y) || (isdataset(y) && ~isempty(y.data));
      cvmode = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
      if ~strcmp(cvmode,'none');
        modl = crossvalidate(handles.analysis,modl);
      end
    end

    %UPDATE GUI STATUS
    %set status windows
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    
    updatessqtable(handles,pc);
    
end

if analysis('isloaded','validation_xblock',handles)
  %apply model to new data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action
  
  opts = getappdata(handles.analysis,'analysisoptions');
  if isempty(opts)
    opts               = cls('options');
  end
  opts.display       = 'off';
  opts.plots         = 'none';

  try
    test = cls(x,y,modl,opts);
  catch
    erdlgpls({'Error applying model to validation data.',lasterr,'Model not applied.'},'Apply Model Error');
    test = [];
  end

  analysis('setobjdata','prediction',handles,test)

else
  %no test data? clear prediction
  analysis('setobjdata','prediction',handles,[]);  
end

analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)  %set buttons

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

%update plots
updatefigures(handles.analysis);     %update any open figures
figure(handles.analysis)

%----------------------------------------------------
function [modl,success] = crossvalidate(h,modl,perm)
%CrossValidationGUI CrossValidateButton CallBack

handles  = guidata(h);
success = 0;

if nargin<3
  perm = 0;
end

x        = analysis('getobjdata','xblock',handles);
y        = analysis('getobjdata','yblock',handles);
mc       = modl.detail.preprocessing;

[cv,lv,split,iter,cvi] = crossvalgui('getsettings',getappdata(h,'crossvalgui'));

m  = length(x.includ{1});
n  = length(x.includ{2});
lv = 1;

opts = [];
opts.preprocessing = mc;
opts.display = 'off';
opts.plots = 'none';

opts.testx = analysis('getobjdata','validation_xblock',handles);
opts.testy = analysis('getobjdata','validation_yblock',handles);
if isempty(opts.testx) | isempty(opts.testy)
  opts.testx = [];
  opts.testy = [];
end

if perm>0
  opts.permutation = 'yes';
  opts.npermutation = perm;
end

try
  modl = crossval(x,y,modl,cvi,lv,opts);
catch
  erdlgpls({'Unable to perform cross-valiation - Aborted';lasterr},'Cross-Validation Error');
  return
end
if perm>0
  success = lv;
else
  success = 1;
end

%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.
% ssqtable value and pcsedit string updated by updatessqtable.


%----------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.pcsedit.
% Selects number of PCs in the editable text box.
% ssqtable value and pcsedit string updated by updatessqtable.


%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures

pca_guifcn('updatefigures',h);

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures

pca_guifcn('closefigures',handles);

%-------------------------------------------------
function updatessqtable(handles,pc)
%Don't use raw model technique in Parafac.
%SSQ info in modl.detail.ssq.percomponent.data

options = mcr_guifcn('options');
modl = analysis('getobjdata','model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');
% s     = [];
% format = getappdata(handles.analysis,'tableformat');

%Empty if no model.
if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  %No model, update everything and return.
  %set(handles.ssqtable,'String',s,'max',2,'min',0,'Value',[],'Enable','inactive')
  clear(mytbl);%Clear data.
  set(handles.pcsedit,'String','','Enable','inactive')
  return
end

%Create vector and display string.
pcs = [];
if ~strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  pcs = size(modl.loads{2,1},2);
  newtbl = modl.detail.ssq;
  newtbl = newtbl(1:pcs,:);
  newtbl = num2cell(newtbl);
  newtbl = newtbl(:,2:4);%Get rid of PC number.

  clbls = mytbl.column_labels;
  clfmt = mytbl.column_format;
  clbls = clbls(1:3);
  clfmt = clfmt(1:3);

  %add RMSECV
  myfmt = '%0.5g';
  if ~isempty(modl.detail.rmsecv)
    val = modl.detail.rmsecv;
    m = min(size(newtbl,1),length(val));
    %move last column over by one
    newtbl(:,end+1) = newtbl(:,end);
    %add new column before that one
    newtbl(1:m,end) = num2cell(val(1:m));
    %add header
    lbl = 'RMSECV';
    clbls{size(newtbl,2)} = ['<html>' lbl '</html>'];
    if iscell(myfmt)
      clfmt{size(newtbl,2)} = myfmt{addind};
    else
      clfmt{size(newtbl,2)} = myfmt;
    end
  end

  %Update table data.
  mytbl.data = newtbl;
  mytbl.column_labels = clbls;
  mytbl.column_format = clfmt;

  %Make selection the current PC.
  setselection(mytbl,'rows',pcs)
  
  
%   for jj = 1:pcs
%     s{jj}   = [sprintf(format,modl.detail.ssq(jj,:))];
%   end
end
%set(handles.ssqtable,'String',s,'max',2,'min',0,'Value',[],'Enable','inactive')
set(handles.pcsedit,'String',int2str(pcs),'Enable','inactive')
if ~isempty(getappdata(handles.pcsedit,'default'));
  setappdata(handles.pcsedit,'default',pcs);
end

%------------------------------------------------
function ind = locateincache(cache,lookfor)

ncomp = [];
for j=1:length(cache);
  ncomp(j) = size(cache{j}.loads{2,1},2);
end

ind = find(ncomp==lookfor);


%----------------------------------------------------
function  optionschange(h)
