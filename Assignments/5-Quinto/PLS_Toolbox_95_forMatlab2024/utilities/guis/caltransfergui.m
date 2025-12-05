function varargout = caltransfergui(varargin)
% CALTRANSFERGUI M-file for caltransfergui.fig
%      CALTRANSFERGUI, by itself, creates a new CALTRANSFERGUI or raises the existing
%      singleton*.
%
%      H = CALTRANSFERGUI returns the handle to a new CALTRANSFERGUI or the handle to
%      the existing singleton*.
%?
%      CALTRANSFERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALTRANSFERGUI.M with the given input arguments.
%
%      CALTRANSFERGUI('Property','Value',...) creates a new CALTRANSFERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before caltransfergui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to caltransfergui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% TODO: ---- FEATURES FOR Mode Centric and or Existing GUI FOR 8.3 RELEASE ----
% TODO: Add menu enabling code. [this might be done]
% TODO: Add drag drop.
% TODO: Add uitable for cache table.
% TODO: Maybe use modelcache for caching instead of native.
% TODO: Test all buttons and menu items to make sure the behave as
%       expected.
% TODO: Add tabs in table section for new functionality.
% TODO: Add resize and maybe "all-code" build of GUI to make easier to
%       manage.
% TODO: Diff value in table not implemented yet. 
% TODO: Add demo data nir_data to help menu. 

if nargin == 0  % LAUNCH GUI

  h=waitbar(1,['Starting Calibration Transfer...']);
  drawnow
  fig = openfig(mfilename,'new');
  positionmanager(fig,'caltransfergui');%Position gui from last known position.
  figbrowser('addmenu',fig); %add figbrowser link
  %set(fig,'closerequestfcn',['try;' get(fig,'closerequestfcn') ';catch;delete(gcbf);end'])
  set(fig,'Resize','on');%Need to allow resize in case of high DPI screen.
  
  handles = guihandles(fig);	%structure of handles to pass to callbacks
  guidata(fig, handles);      %store it.
  gui_init(fig)            %add additional fields
  set(fig,'visible','on')

  if nargout > 0
    varargout{1} = fig;
  end

  close(h)

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
  if strcmp(getappdata(0,'debug'),'on');
    dbstop if all error
  end

  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if nargin==1
          %           %try auto-starting with given method enabled
          %           methods = transfertypes;
          %           methods = lower(methods(:,1:2));
          %           if ismember(char(varargin{1}),methods);         %check for valid tag or symbol
          %             h = caltransfergui;
          %             try
          %               enable_method(h,[],guidata(h),varargin{1})
          %             catch
          %               erdlgpls('Unable to intialize for given method','Analysis')
          %             end
          %           else
          %             erdlgpls('Unrecognized Analysis Method Name','Analysis')
          %           end
          %           if nargout>0;
          %             varargout = {h};
          %           end
        elseif nargout == 0;
          %normal calls with a function
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
  catch
    if ~isempty(gcbf);
      set(gcbf,'pointer','arrow');  %no "handles" exist here so try setting callback figure
    end
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end

end

%--------------------------------------------------------------------
function gui_init(h)
%Initialize the the gui.
%NOTE: Dynmaic field naming is used heavily in the code so naming of
%appdata fields and controls is important.
handles = guidata(h);

%Status variables.
%setappdata(handles.caltransfergui,'statdata','none'); %'none','new','cal','test'
%setappdata(handles.caltransfergui,'statmodl','none'); %'none','calold','calnew','loaded'

%Set figure to appropriate position.
set(h,'units','pixels');
set(0,'units','pixels');

%Set figure color.
set(h,'color',[0.7000 0.8000 0.8500]);

%Preprocess variables.
%setappdata(handles.caltransfergui,'x1pp',[]); %x1 preprocessing structure.
%setappdata(handles.caltransfergui,'x2pp',[]); %x2 preprocessing structure.
setappdata(handles.caltransfergui,'x1ppfig',[]); %pp figure handle.
setappdata(handles.caltransfergui,'x2ppfig',[]); %pp figure handle.
setappdata(handles.caltransfergui,'x1editfig',[]); %pp figure handle.
setappdata(handles.caltransfergui,'x2editfig',[]); %pp figure handle.

%Options.
setappdata(handles.caltransfergui,'options',caltransfer('options'));

%Set callbacks for data browsers
setappdata(handles.caltransfergui,'includchangecallback','caltransfergui(''dataincludchange'',datasource)')

%Structure array of cached data (will include all data above plus anything
%else needed to reload and edit a model).
setappdata(handles.caltransfergui,'ctmcache',[]);

%Plotting selection, this contains a cell array of strings describing the
%current plotting selection. The strings must match what's in the
%'plotcombos' function.
setappdata(handles.caltransfergui,'plotselection',{''});

%Intialize dropdown model menu.
select_setup(handles.ctm_select)

%Set up parameter area.
setctrls(curmethod(handles),handles)

%Clear modle cache area.
set(handles.cachetable,'String','');

%If stand-alone, change help labels to "Solo" (or whatever is appropriate)
if exist('isdeployed') & isdeployed;
  [ver,prodname] = evrirelease;
  ch = get(findobj(handles.caltransfergui,'label','&Help'),'children');
  set(ch,{'label'},strrep(get(ch,'label'),'PLS_Toolbox',prodname))
end

%Set new pp callback. 
%TODO: Change fig file to update callback.
set(handles.x1pp,'Callback','caltransfergui(''pp_Callback'',gcbo,[],guidata(gcbo))')
set(handles.x2pp,'Callback','caltransfergui(''pp_Callback'',gcbo,[],guidata(gcbo))')

%Add export menu items.
xptmenu = findobj(handles.caltransfergui,'tag','menu_exportctm');
set(xptmenu,'enable','off','visible','on');
uimenu(xptmenu,'label','Predictor &M-File','tag','exportmodel_mfile','callback','caltransfergui(''ctm_export_Callback'',gcbo,[],guidata(gcbf));');
uimenu(xptmenu,'label','Predictor &XML','tag','exportmodel_xml','callback','caltransfergui(''ctm_export_Callback'',gcbo,[],guidata(gcbf));');
uimenu(xptmenu,'label','Predictor &Python','tag','exportmodel_python','callback','caltransfergui(''ctm_export_Callback'',gcbo,[],guidata(gcbf));');

drawnow 

updateeanblestatus(handles)
%--------------------------------------------------------------------
function ctm_calc_Callback(h,eventdata,handles,varargin)
%Calculate model.
%After model is calculated/applied then automatically enter item into cache
%table and save everything into appdata structure.

ctm   = getobjdata('ctm',handles);
x1    = getobjdata('datasetx1',handles);
x2    = getobjdata('datasetx2',handles);
x1t   = getobjdata('datasetx1t',handles);
x2t   = getobjdata('datasetx2t',handles);

mtype = curmethod(handles);
opts = makeoptions(mtype,handles);

%Test for different pp in x1 and x2.
pp1 = opts.preprocessing{1};
pp2 = opts.preprocessing{2};
pperr = 0;

if length(pp1)~=length(pp2)
  %Imediate warning, no need to loop.
  pperr = 1;
else
  for i = 1:length(pp1)
    %Loop through keywords.
    if ~strcmp(pp1(i).keyword,pp2(i).keyword)
      pperr = 1;
    end
  end
end

if pperr
    button = evriquestdlg(['You have selected different preprocessing for '...
      'Instruments 1 and 2. This may lead to unusual results. Do you with to continue?'],...
    'Different Preprocessing','Continue','Cancel','Continue');
  if strcmpi(button,'Cancel')
    return
  end
end

try
  if ~isempty(x1)
    %Calibrate mode.
    [ctm,x1t,x2t] = caltransfer(x1,x2,mtype,opts);

    %Add model name.
    %NOTE: This may need to go into modelstruct.
    ctm.detail.modelname = get(handles.ctm_name,'String');

    setobjdata('ctm',handles,ctm);
    setobjdata('datasetx1t',handles,x1t);
    setobjdata('datasetx2t',handles,x2t);
  else
    %Apply mode.
    x2t = caltransfer(x2,ctm,opts);
    setobjdata('datasetx2t',handles,x2t);
  end
catch
  erdlgpls({'Error calling caltransfer function, following error received: ', ' ', lasterr},'Calibration Transfer Error');
  return
end

% updatestatusboxes(handles);

%Cache items to end of structure.
ctmcache = getappdata(handles.caltransfergui,'ctmcache');
ctmcache(end+1).x1 = x1;
ctmcache(end).x2 = x2;
ctmcache(end).x1t = x1t;
ctmcache(end).x2t = x2t;
ctmcache(end).opts = opts;
ctmcache(end).ctm = ctm;
setappdata(handles.caltransfergui,'ctmcache',ctmcache);
setappdata(handles.caltransfergui,'options',opts);

%Disable calc button and model name to indicate "current model"
set(handles.ctm_calc,'enable','off')
set(handles.ctm_name,'enable','off')
set(handles.ctm_select,'enable','off')

%Update cachetable.
updateall(handles)

set(handles.cachetable,'value',length(ctmcache));

% --------------------------------------------------------------------
function dataincludechange(id)
%Input h is the handle of the figure.
%Need to clear transferred data if orginal data is changed.
handles = guidata(id.source);

clearmodelXT(handles);

updateall(handles);

% --------------------------------------------------------------------
function  datachangecallback(id)
%Input h is the handle of the figure.
%Need to clear transferred data if orginal data is changed.
handles = guidata(id.source);

clearmodelXT(handles);

updateall(handles);

%---------------------------------------------------------------------
function  drop(h, eventdata, handles, varargin)

%first check for a model
clr = logical(zeros(1,length(varargin)));
for j = 1:length(varargin);
  if ismodel(varargin{j})
    if any(clr);
      evrimsgbox({'Only one model may be loaded at a time.','Additional models ignored.'},'Load Model','warn','modal');
      break;
    end
    ctm_load_Callback(h, eventdata, handles, varargin{j}); %load non-silently
    handles = guidata(h);
    clr(j) = 1;
  end
end
varargin(clr) = [];  %clear models from varargin

if isempty(varargin);
  return
end

%now, assume anything else is data and try to load it
if length(varargin)==2;
  x1load_Callback(handles.caltransfergui, [], handles, varargin{1});
  x2load_Callback(handles.caltransfergui, [], handles, varargin{:});
else
  x1 = getobjdata('datasetx1',handles);
  x2 = getobjdata('datasetx2',handles);
  if isempty(x1)
    block = 'Instrument 1';
  else
    if (~isempty(x1) & ~isempty(x2) & all(size(varargin{1})>1))
      block = 'Instrument 1';
    else
      block = 'Instrument 2';
    end
    block = evriquestdlg('Load this data as Instrument 1 or Instrument 2?','Load data','Instrument 1','Instrument 2','Cancel',block);
  end
  switch block
    case 'Instrument 1'
      %try load as x-block
      x1load_Callback(handles.caltransfergui, [], handles, varargin{:});
    case 'Instrument 2'
      %try load as y-block
      x2load_Callback(handles.caltransfergui, [], handles, varargin{:});
  end
end


%-----------------------------------------------------------------
function  importdata_Callback(h,eventdata,handles,varargin)
%File menu import.

[data,name,source] = autoimport;
if isempty(data);  %canceled out of import?
  return;
end

if strcmp(varargin{1},'x')
  loaddata(handles,'datasetx1',data, name, source);
else
  loaddata(handles,'datasetx2', data, name, source);
end

%--------------------------------------------------------------------
function x1load_Callback(hObject, eventdata, handles, varargin)
%Load X1 data.

loaddata(handles,'datasetx1',varargin{:})

%--------------------------------------------------------------------
function x2load_Callback(hObject, eventdata, handles,varargin)

loaddata(handles,'datasetx2',varargin{:})

%--------------------------------------------------------------------
function pp_Callback(hObject, eventdata, handles, varargin)
%Preprocessing.

opts    = getappdata(handles.caltransfergui,'options');
pptag = get(hObject,'tag');

if strcmp(pptag,'x1pp')
  myblock = 'x1';
  curpp   = opts.preprocessing{1}; %Get current preprocessing.
else
  myblock = 'x2';
  curpp   = opts.preprocessing{2}; %Get current preprocessing.
end

blockid = getobj(['dataset' myblock],handles);

%PP GUI checks appdata of parent for current pp if 'curpp' is empty going
%into call below so update it here to avoid unexpected behavior.
setappdata(handles.caltransfergui,'preprocessing',curpp)

[pp ppchange]= preprocess('setup',handles.caltransfergui,'Name',['Preprocessing Instrument ' myblock(2)], ...
  'addtoparent',handles.caltransfergui, curpp, blockid);

if ppchange
  switch myblock
    case 'x1'
      opts.preprocessing{1} = pp;
      if comparevars(curpp,opts.preprocessing{2})
        %If old x1pp is same as x2pp then "push" x1pp to x2pp. User must
        %manually change x2pp to make it different.
        opts.preprocessing{2} = pp;
      end
    case 'x2'
      opts.preprocessing{2} = pp;
  end
  setappdata(handles.caltransfergui,'options',opts);
  %Must clear model if change pp.
  clearmodelXT(handles)
end
updateall(handles);

% %--------------------------------------------------------------------
% function x1pp_Callback(hObject, eventdata, handles, varargin)
% %X1 preprocessing.
% 
% opts = getappdata(handles.caltransfergui,'options');
% x1 = getobjdata('datasetx1',handles);
% if isempty(x1)
%   return
% end
% curpp = opts.preprocessing{1}; %Get current preprocessing.
% 
% %PP GUI checks appdata of parent for current pp if 'curpp' is empty going
% %into call below so update it here to avoid unexpected behavior.
% setappdata(handles.caltransfergui,'preprocessing',curpp)
% 
% [x1pp ppchange]= preprocess('setup',handles.caltransfergui,x1,'Name','Preprocessing Instrument 1','addtoparent',handles.caltransfergui,curpp);
% 
% if ppchange
%   opts.preprocessing{1} = x1pp;
%   if comparevars(curpp,opts.preprocessing{2})
%     %If old x1pp is same as x2pp then "push" x1pp to x2pp. User must
%     %manually change x2pp to make it different.
%     opts.preprocessing{2} = x1pp;
%   end
%   setappdata(handles.caltransfergui,'options',opts);
%   %Must clear model if change pp.
%   clearmodelXT(handles)
% end
% updateall(handles);
% %--------------------------------------------------------------------
% function x2pp_Callback(hObject, eventdata, handles, varargin)
% %X2 preprocessing.
% opts = getappdata(handles.caltransfergui,'options');
% x2 = getappdata(handles.caltransfergui,'datasetx2');
% if isempty(x2)
%   return
% end
% curpp = opts.preprocessing{2}; %Get current preprocessing.
% 
% %PP GUI checks appdata of parent for current pp if 'curpp' is empty going
% %into call below so update it here to avoid unexpected behavior.
% setappdata(handles.caltransfergui,'preprocessing',curpp)
% 
% [x2pp ppchange]= preprocess('setup',handles.caltransfergui,x2,'Name','Preprocessing Instrument 2','addtoparent',handles.caltransfergui,curpp);
% 
% if ppchange
%   opts.preprocessing{2} = x2pp;
%   setappdata(handles.caltransfergui,'options',opts);
%   %Must clear model if change pp.
%   clearmodelXT(handles)
% end
% updateall(handles);
%--------------------------------------------------------------------
function x1clear_Callback(hObject, eventdata, handles)

setobjdata('datasetx1',handles,[]);
clearpp(handles,'x1')
updateall(handles);

%--------------------------------------------------------------------
function x2clear_Callback(hObject, eventdata, handles)

setobjdata('datasetx2',handles,[]);
clearpp(handles,'x2');
updateall(handles);

%--------------------------------------------------------------------
function modelclear_Callback(hObject, eventdata, handles)

setobjdata('ctm',handles,[]);
updatestatusboxes(handles);

%--------------------------------------------------------------------
function x1tclear_Callback(hObject, eventdata, handles)

setobjdata('datasetx1t',handles,[]);
% updatestatusboxes(handles);
updateall(handles);

%--------------------------------------------------------------------
function x2tclear_Callback(hObject, eventdata, handles)

setobjdata('datasetx2t',handles,[]);
% updatestatusboxes(handles);
updateall(handles);

%--------------------------------------------------------------------
function ctm_select_Callback(hObject, eventdata, handles)
%Model select dropdown callback.
mtype = curmethod(handles);

%Add default name to modelname box.
name = ['CTM_' upper(mtype) '-' datestr(now,30)];
set(handles.ctm_name,'String',name);

%Enable method if possible.
setctrls(mtype,handles)

%--------------------------------------------------------------------
function ctm_save_Callback(hObject, eventdata, handles)
%Save model to workspace.
modl = getobjdata('ctm',handles);
if ~isempty(modl)
  %Save model
  targname = get(handles.ctm_name,'String');
  [what,where] = svdlgpls(modl,'Save Model',targname);
end

%--------------------------------------------------------------------
function ctm_export_Callback(hObject, eventdata, handles)
%Save model to workspace.
modl = getobjdata('ctm',handles);

if ~isempty(modl)
  switch get(hObject,'tag')
    case 'exportmodel_mfile'
      method = 'matlab';
    case 'exportmodel_xml'
      method = 'xml';
    case 'exportmodel_python'
      method = 'python';
  end
  %Export model.
  if ~exist('exportmodel','file');
    switch evriquestdlg('Exporting Predictors requires Model_Exporter (not installed on this system).','Model_Exporter Not Found','OK','More Information','OK');
      case 'More Information'
        web('http://www.eigenvector.com/software/model_exporter.htm','-browser');
    end
    return
  end
  exportmodel(modl,method);
end

%--------------------------------------------------------------------
function ctm_clear_Callback(hObject, eventdata, handles)
%Clear model.
clearmodelXT(handles)
updateall(handles);
%--------------------------------------------------------------------
function filemenu_Callback(hObject, eventdata, handles)
%File menu click.


%--------------------------------------------------------------------
function clearmodelXT(handles)
%Clears model, X1T, and X2T then updates status boxes.

setobjdata('datasetx1t',handles,[]);
setobjdata('datasetx2t',handles,[]);
setobjdata('ctm',handles,[]);

updatestatusboxes(handles);

%--------------------------------------------------------------------
function clearall_Callback(hObject, eventdata, handles)
%Clears model, X1T, and X2T then updates status boxes.
setobjdata('datasetx1',handles,[]);
setobjdata('datasetx2',handles,[]);
setobjdata('datasetx1t',handles,[]);
setobjdata('datasetx2t',handles,[]);
setobjdata('ctm',handles,[]);
clearpp(handles,'all')

updateall(handles)

%--------------------------------------------------------------------
function clearpp(handles,keyword)
%Clear preprocessing, keyword can be x1, x2, all.
opts = getappdata(handles.caltransfergui,'options');

switch keyword
  case 'x1'
    opts.preprocessing{1} = preprocess('none');
  case 'x2'
    opts.preprocessing{2} = preprocess('none');
  case 'all'
    opts.preprocessing{1} = preprocess('none');
    opts.preprocessing{2} = preprocess('none');
end
setappdata(handles.caltransfergui,'options',opts);

%--------------------------------------------------------------------
function loaddata(handles,ctrl,varargin)
%Generic load data function, (ctrl) is the calling control. Can be
%'datasetx1', 'datasetx2', and 'datasetctmy'.
% Test for existing data, overwrite warning if data exits. Test for
% existing model, clears if exists.
%
% If varargin is empty, user is prompted for data to load, if it isn't
% empty, it is assumed to be one of the following:
%    ..., data)
%    ..., data, name)  %where name is used for DSO name if empty
% Where data is either a matrix or a DSO.
%

model = getobjdata('ctm',handles);
tdata.datasetx1 = getobjdata('datasetx1',handles);
tdata.datasetx2 = getobjdata('datasetx2',handles);
tdata.datasetctmy = getobjdata('datasetctmy',handles);

if ~isempty(tdata.(ctrl))
  if ~isempty(model)
    button = evriquestdlg('There is existing data and a model. Do you wish to clear the model and overwrite the data?',...
      'Continue Load Data','Yes','No','Yes');
    if strcmp(button,'Yes')
      %cleardata_cleanup(h, eventdata, handles, [])
    elseif strcmp(button,'No')
      return
    end
  else
    button = evriquestdlg('There is existing data. Do you wish to overwrite the data?',...
      'Continue Load Data','Yes','No','Yes');
    if strcmp(button,'Yes')
      %cleardata_cleanup(h, eventdata, handles, [])
    elseif strcmp(button,'No')
      return
    end
  end
end

%lddlgpls cell settings.
dlgsetting = {'double' 'dataset'};

h = handles.caltransfergui;
%Load Data Into the GUI
finfo = [];
if isempty(varargin)
  [rawdata,name,location,rdir] = lddlgpls(dlgsetting,'Select Data');
  %Save file/var info for display in status box.
  finfo.varname  = name;
  finfo.filename = location;
  rdir = [fliplr(strtok(fliplr(rdir),filesep))]; %Get parent directory of file.
  finfo.dir      = rdir;
  if isempty(rawdata)
    return
  end
  if ~isempty(finfo) && isa(rawdata,'dataset') && (isempty(rawdata.userdata)||isstruct(rawdata.userdata))
    rawdata.userdata.fileinfo = finfo;
  end
else
  rawdata = varargin{1};
  if length(varargin)>1;
    name = varargin{2};
  else
    name = '';
  end
  if length(varargin)>2;
    location = varargin{3};
  else
    location = '';
  end
end

if ~isempty(rawdata)
  if ~isa(rawdata,'dataset')
    %Put double data into a dataset.
    rawdata             = dataset(rawdata);
    rawdata.name        = name;
    rawdata.author      = '';
    if ~isempty(finfo) && (isempty(rawdata.userdata)||isstruct(rawdata.userdata))
      rawdata.userdata.fileinfo = finfo;
    end
  end

  if isempty(rawdata.data)
    erdlgpls('Variable empty. Data not loaded.','Error on Load.')
    rawdata = [];
    %elseif ~isempty(x2) && size(x2,1)~=size(rawdata.data,1);
    %NOTE: No size checks, missing variables can be handled by all methods.
    %Missing samples are handled by some methods otherwise patricular
    %method will give error.
    %evriwarndlg('Number of samples must match in Orginal and Target. Target is being cleared.','Block size mismatch.')
  end

  %Store new data.
  setobjdata(ctrl,handles,rawdata,getdataprops);

  %Clear preprocessing for block.
  setappdata(handles.caltransfergui,[ctrl 'pp'],[]);

  if ~isempty(rawdata)
    %Clear model, x1t and x2t.
    clearmodelXT(handles)
  end
end

updateall(handles)

%--------------------------------------------------------------------
function out = transfertypes()
%Based on analysistypes.m.
out = {...
  'ds'       'Direct Standardization'                         'stdgen'   'off';
  'pds'      'Piecewise Direct Standardization'               'stdgen'   'off';
  'dwpds'    'Double Window Piecewise Direct Standardization' 'stdgen'   'off';
  'glsw'     'Generalized Least-Squares Weighting'            'glsw'     'off';
  'osc'      'Orthogonal Signal Correction'                   'osccalc'  'off';
  'alignmat' 'Matrix Alignment'                               'alignmat' 'off';
  'sst'      'Spectral Space Transformation'                  'sstcal'   'off';
  };

%--------------------------------------------------------------------
function select_setup(h)
%Populate dropdown menu.
%Input h is dropdown control handle.

mt = transfertypes;
lst = '';
for i = 1:size(mt,1)
  lst = [lst; {[upper(mt{i,1}) ' - ' mt{i,2}]}];
end

set(h,'string',lst)

%--------------------------------------------------------------------
function mtype = curmethod(handles)
%Get currently selected method.

mystr = get(handles.ctm_select,'String');
mystr = mystr{get(handles.ctm_select,'value')};
mtype = lower(mystr(1:findstr(mystr,' - ')-1));

%--------------------------------------------------------------------
function setmethod(newmethod,handles)
%Set method in dropdown control.
transt = transfertypes;
set(handles.ctm_select,'value',find(ismember(transt(:,1),newmethod)))

%--------------------------------------------------------------------
function setctrls(mtype,handles)
%Set list of controls to display. Input mtype is model type.
%Input 'mtype' is model type.
x1    = getobjdata('datasetx1',handles);
x2    = getobjdata('datasetx2',handles);

opts = getappdata(handles.caltransfergui,'options');

cenbl = 'on'; %Control enable.
% if ~isempty(x1) && ~isempty(x2)
%   cenbl = 'on';
% end

%Generic control list.
pref = {'p1_' 'p2_' 'p3_' 'p4_' 'p5_'};

%Turn all visibility off.
for i = pref
  set(handles.([i{:} 'label' ]),'visible','off');
  set(handles.([i{:} 'value' ]),'visible','off');
end

%Deal with p5 buttons.
set(handles.p5_load,'visible','off');
set(handles.p5_edit,'visible','off');
set(handles.p5_clear,'visible','off');

%This lists must be same length.
ctrlist = ''; %Control list.
vlist = ''; %Option value list.

switch mtype
  case 'ds'

  case 'pds'
    ctrlist = {'Window'};
    vlist = {'win'};
  case 'dwpds'
    ctrlist = {'Window 1' 'Window 2'};
    vlist = {'win' 'win'};
  case 'glsw'
    ctrlist = {'Singular Value Scale'};
    vlist = {'a'};
  case 'osc'
    ctrlist = {'Number of Components' 'Iterations' 'Tolerance'};
    vlist = {'ncomp' 'iter' 'tol' 'y'};
    set(handles.p5_value,'visible','on','enable',cenbl);
    set(handles.p5_label,'visible','on','enable',cenbl);
    set(handles.p5_load,'visible','on','enable',cenbl);
    set(handles.p5_edit,'visible','on','enable',cenbl);
    set(handles.p5_clear,'visible','on','enable',cenbl);
  case 'alignmat'
    ctrlist = {'Number of Components'};
    vlist = {'ncomp'};
  case 'sst'
    ctrlist = {'Num. Comp.'};
    vlist = {'ncomp'};
  case 'clear'
    return
  otherwise
    return
end

%Turn on labels and values and replace String as needed.
wincount = 1; %Window count for seperate controls on each element.
for i = 1:length(ctrlist)
  h = handles.([pref{i} 'label']);
  set(h,'String',ctrlist{i});
  set(h,'visible','on','enable',cenbl);

  val = opts.(mtype).(vlist{i});
  if strcmp(mtype,'dwpds') && strcmp(vlist{i},'win') && length(val)==2
    val = val(wincount);
    wincount = wincount+1;
  elseif isnumeric(val) && max(size(val))<=2
    val = num2str(val);
  elseif isnumeric(val)
    val = ['Size: ' size(val,1) 'x' size(val,2)];
  end
  set(handles.([pref{i} 'value' ]),'visible','on','enable',cenbl,'String',val);
end

%--------------------------------------------------------------------
function updateall(handles)

updatestatusboxes(handles);
updatecachetable(handles);
updatemodeldisplay(handles);
updatediffbars(handles);
updateeanblestatus(handles);

%--------------------------------------------------------------------
function plotsmenu_Callback(hObject,eventdata,handles,varargin)
%Enable and execute plotting.
%Plotting descriptions are from 'plotcombos':
%   'Instrument 1' 
%   'Instrument 2' 
%   'Instrument 1 Transferred' 
%   'Instrument 2 Transferred' 
%   'Pre-Transfer Difference' 
%   'Post-Transfer Difference' 
%   'Change in Instrument 1' 
%   'Change in Instrument 2'

guifig = handles.caltransfergui;

tdata{1}    = getobjdata('datasetx1',handles);
tdata{2}    = getobjdata('datasetx2',handles);
tdata{3}    = getobjdata('datasetx1t',handles);
tdata{4}    = getobjdata('datasetx2t',handles);

combodesc = plotcombos;

nadesc = '';%Non applicable descriptions.
if isempty(tdata{1})
  nadesc = [nadesc {'Instrument 1' 'Change in Instrument 1'}];
end

if isempty(tdata{2})
  nadesc = [nadesc {'Instrument 2' 'Change in Instrument 2'}];
end

if isempty(tdata{3})
  nadesc = [nadesc {'Instrument 1 Transferred' 'Change in Instrument 1'}];
end

if isempty(tdata{4})
  nadesc = [nadesc {'Instrument 2 Transferred' 'Change in Instrument 2'}];
end

%Remove any mismatched data size plots from list.
if (isempty(tdata{1}) || isempty(tdata{2})) || any(size(tdata{1})~=size(tdata{2}))
  nadesc = [nadesc {'Pre-Transfer Difference'}];
end
  
if (isempty(tdata{3}) || isempty(tdata{4})) || any(size(tdata{3})~=size(tdata{4}))
  nadesc = [nadesc {'Post-Transfer Difference'}];
end

combodesc = setdiff(combodesc,nadesc);

show  = getappdata(handles.caltransfergui,'plotselection');
show = find(ismember(combodesc,show));
[s,OK] = listdlg('PromptString','Select one or more plots to view:',...
                'SelectionMode','multiple',...
                'ListString',combodesc,...
                'InitialValue', show);
if OK
  show = false(1,length(combodesc));
  show(s) = true;
  setappdata(handles.caltransfergui,'plotselection',combodesc(show));
  updateplots(handles,0);
end
              
%--------------------------------------------------------------------
function [combodesc,combos] = plotcombos;
%list of plots and how to title them
combodesc = {'Instrument 1' 'Instrument 2' 'Instrument 1 Transferred' 'Instrument 2 Transferred' 'Pre-Transfer Difference' 'Post-Transfer Difference' 'Change in Instrument 1' 'Change in Instrument 2'};
combos = {1 2 3 4 [1 2] [3 4] [3 1] [4 2]};

%--------------------------------------------------------------------
function updateplots(handles,updatecall)
%Update plots. If 'updatecall' set to 1 then only update figure if it
%alreay exists (ishandle = 1).

guifig = handles.caltransfergui;
fig = getappdata(guifig,'plotfigure');

if nargin<2
  updatecall = 0;
end

if updatecall && (isempty(fig) || ~ishandle(fig))
  %No figure to update so return.
  return
end
  
tdata{1}    = getobjdata('datasetx1',handles);
tdata{2}    = getobjdata('datasetx2',handles);
tdata{3}    = getobjdata('datasetx1t',handles);
tdata{4}    = getobjdata('datasetx2t',handles);

%mapping for single and combination data
[combodesc,combos] = plotcombos;

%determine which should/can be used 
show  = getappdata(guifig,'plotselection');
show = ismember(combodesc,show);
if isempty(show);
  show = false(1,length(combos));
end

%determine which of those data items are empty
empty = cellfun('isempty',tdata);
for j=5:length(combos);
  %calculate "empty" for combination data
  empty(j) = any(empty(combos{j}));
end

%Mark data size mismatches as "empty" becuase a difference can't be
%calculated (causing an error).
if any(size(tdata{1})~=size(tdata{2}))
  empty(5) = 1;
end
  
if any(size(tdata{3})~=size(tdata{4}))
  empty(6) = 1;
end

use   = show & ~empty;

%get last plot information
datesused = getappdata(guifig,'plottedtimestamps');
lastplotted = getappdata(guifig,'lastplotted');  %what we selected before
fig = getappdata(guifig,'plotfigure');

%whether or not we're going to redo, check if the ones we need are all empty
if ~any(use);
  if ishandle(fig);
    positionmanager(fig,'caltransfergui_plot','set');
    close(fig);
  end
  return
end

%check date on the combined dataset and the dates on the relevent data
%dsos. If the data DSOs are different, update plots
dates = [];
for j = find(use);
  for ji = combos{j};
    ds = tdata{ji};
    if ~isempty(ds) & isdataset(ds)
      dates(end+1) = datenum(ds.moddate);
    end
  end
end
if length(dates)~=length(datesused) || any(dates~=datesused) || any(lastplotted~=use)
  redo = true;
else
  %no dates at all or no date > last combined DSO
  redo = false;
end

if redo
  %assemble parts based on use and combo
  ds = [];
  cls = [];
  fullname = '';
  for j=find(use);
    %SK added try/catch to allow for mismatched data sizes and other
    %problems that might occur. Should allow valid plots to path through. 
    %TODO: Make this code interrogate sizing more robustly.
    if length(combos{j})==1
      thisdata = tdata{combos{j}};
    else
      try
        thisdata = tdata{combos{j}(1)}-tdata{combos{j}(2)};
      catch
        continue
      end
    end
    try
      ds  = [ds;thisdata];
    catch
      continue
    end
    cls = [cls ones(1,size(thisdata,1))*j];  %add class for this set
    fullname = [fullname combodesc{j} ', '];
  end
  fullname = fullname(1:end-2);  %drop ending ,
  
  %add classes to assembled DSO
  clsset = size(ds.class,2)+1;
  ds.class{1,clsset} = cls;
  ds.classname{1,clsset} = 'Data Source';
  ds.classlookup{1,clsset} = [mat2cell(1:length(combodesc),1,ones(1,length(combodesc)));combodesc]';
  ds.name = fullname;
  ds.title{1} = fullname;
  ds.title{2} = fullname;
  
  %setappdata(guifig,'dataset',ds);
  %Add/update plot dataset.
  myid = setobjdata('plotdata',handles,ds);
  
  setappdata(guifig,'plottedtimestamps',dates);
  setappdata(guifig,'lastplotted',use);  %what we selected before
  
  if isempty(fig) | ~ishandle(fig)
    fig = figure;
    positionmanager(fig,'caltransfergui_plot','move');
    setappdata(guifig,'plotfigure',fig);
    viewclasses = ~all(cls==cls(1));
    addsettings = {'plotby',0,'axismenuvalues',{1 1},...
      'viewclasses',viewclasses,'viewclassset',clsset,...
      'viewexcludeddata',1};
  else
    if sum(lastplotted)<2 & sum(use)>=2
      addsettings = {'viewclasses',1,'viewclassset',clsset};
    else
      addsettings = {};
    end
  end
  plotgui('update',myid,'noinclude',1,'noload',1,'figure',fig,addsettings{:})
end

%--------------------------------------------------------------------
function updatestatusboxes(handles)
%Updates (only) listboxes based on data stored in appdata fields.

model = getobjdata('ctm',handles);
tdata.datasetx1    = getobjdata('datasetx1',handles);
tdata.datasetx2    = getobjdata('datasetx2',handles);
tdata.datasetx1t   = getobjdata('datasetx1t',handles);
tdata.datasetx2t   = getobjdata('datasetx2t',handles);

%update plots (if there)
updateplots(handles,1)

opts = getappdata(handles.caltransfergui,'options');
x1pp = opts.preprocessing{1};
x2pp = opts.preprocessing{2};

dname = {'datasetx1' 'datasetx2' 'datasetx1t' 'datasetx2t'};%AppData names.

for i = dname
  ctrlstr = '';
  if ~isempty(tdata.(i{:}))
    nstr = tdata.(i{:}).name;
    sstr = size(tdata.(i{:}).data);
    sstr = [num2str(sstr(1)) 'x' num2str(sstr(2))];
    ctrlstr = [ctrlstr;{['Name : ' nstr]}];
    ctrlstr = [ctrlstr;{['Size : ' sstr]}];
    if ~isempty(tdata.(i{:}).userdata) && isfield(tdata.(i{:}).userdata,'fileinfo')
      ctrlstr = [ctrlstr;{['Directory : ' tdata.(i{:}).userdata.fileinfo.dir]}];
      ctrlstr = [ctrlstr;{['File Name : ' tdata.(i{:}).userdata.fileinfo.filename]}];
    end

    if strcmp(i{:},'datasetx1')
      xppstr = '';
      if ~isempty(x1pp)
        for j = 1:length(x1pp)
          xppstr = [xppstr x1pp(j).description ', '];
        end
        xppstr = xppstr(1:end-2);
      end
      ctrlstr = [ctrlstr;{['Preprocessing : ' xppstr]}];
    elseif strcmp(i{:},'datasetx2')
      xppstr = '';
      if ~isempty(x2pp)
        for j = 1:length(x2pp)
          xppstr = [xppstr x2pp(j).description ', '];
        end
        xppstr = xppstr(1:end-2);
      end
      ctrlstr = [ctrlstr;{['Preprocessing : ' xppstr]}];
    end

    set(handles.([i{:} 'status']),'String', ctrlstr);
  else
    if strfind(i{:},'t')
      set(handles.([i{:} 'status']),'String','Data : None Transferred')
    else
      set(handles.([i{:} 'status']),'String','Data : None Loaded')
    end
  end

end

% %Enable/disable method parameters.
% setctrls(curmethod(handles),handles);

%--------------------------------------------------------------------
function updatecachetable(handles)
%Update model cache table. Uses appdata 'ctmcache' to create list.
%Calculation code adds a model to the cache then calls here.

ctmcache = getappdata(handles.caltransfergui,'ctmcache');
cachectrls = {'cache_load' 'cache_save' 'cache_clear' 'cachetable'};

if isempty(ctmcache)
  enbl = 'off';
else
  enbl = 'on';
end

for k = cachectrls
  set(handles.(k{:}),'enable',enbl)
end

cstr = '';

nmodels = length(ctmcache);%Number of models.

%Cache model and update cachetable.
for j = 1:nmodels

  %Model name (30 char max + 4 char divide).
  mblk = repmat(' ',1,34); %Create padded char array.
  mname = ctmcache(j).ctm.detail.modelname;
  mlen = length(mname);

  if mlen>30
    mname = [mname(1:12) '...' mname(end-14:end)];
  end
  mname = char(mblk,mname); %Use char to pad model name.
  mname = mname(2,:);

  %Dataset name/s.
  if ~isempty(ctmcache(j).x1)
    %Can be empty if in apply mode.
    dat(1).name = ctmcache(j).x1.name;
  else
    dat(1).name = 'n/a';
  end
  dat(2).name = ctmcache(j).x2.name;
  nmstr = '';

  for i = 1:length(dat)
    tempstr = repmat(' ',1,26);
    if length(dat(i).name)>24
      tstr = char(tempstr, [dat(i).name(1:6) '...' dat(i).name(end-16:end)]);
    else
      tstr = char(tempstr,dat(i).name);
    end
    nmstr = [nmstr tstr(2,:)];
  end

  %Difference str
  mdiff = 'n/a';

  cstr = [cstr;{[mname nmstr mdiff]}];
end

%Set value of table.
cval = get(handles.cachetable,'value');
clen = length(cstr);

if cval>clen
  set(handles.cachetable,'value',clen);
elseif cval ==0;
  set(handles.cachetable,'value',1);
end

%Add new string to current list.
set(handles.cachetable,'String',cstr)

%--------------------------------------------------------------------
function updatemodeldisplay(handles)
%Update Model info based on stored information. This is called after a
%model is loaded from external (using Load) button.

ctm  = getobjdata('ctm',handles);
opts = getappdata(handles.caltransfergui,'options');

if ~isempty(ctm)
  %Set model name based on stored name.
  set(handles.ctm_name,'String',ctm.detail.modelname);

  %Set model type based on model transfer method.
  setmethod(ctm.transfermethod,handles);

  %Set options.
  setctrls(ctm.transfermethod,handles);
else
  %Set model name based on stored name.
  %ctm_select_Callback([], [], handles)
end

%--------------------------------------------------------------------
function updateeanblestatus(handles)
%Update button enable/disable based on loaded data/model.
% Conditions:
%   1) No Data Loaded:
%        Load raw data and load model enabled.
%   2) Only X1 loaded:
%        Load X2 enabled, load model disabled.
%   3) X1 and X2 loaded:
%        Enable calculate model. Disable load model?
%   4) Model Caclulated (appdata for ctm ~empty):
%        Load and Caclualte disabled. Need to clear model, change settings,
%        or change model type to recalculate.
%   5)
%
%  Model status is determined implicitly by its existance (with transferred
%  data). To change status, clear model.

handles = guihandles(handles.caltransfergui);

model = isloaded('ctm',handles);
x1    = isloaded('datasetx1',handles);
x2    = isloaded('datasetx2',handles);
x1t   = isloaded('datasetx1t',handles);
x2t   = isloaded('datasetx2t',handles);
cache = ~isempty(getappdata(handles.caltransfergui,'ctmcache'));

opts  = ~isempty(getappdata(handles.caltransfergui,'options'));

%Disable all buttons on figure.
btns = findobj(handles.caltransfergui,'style','pushbutton');
set(btns,'enable','off');

%Disable all menus.
mnus = findobj(handles.caltransfergui,'type','uimenu');
set(mnus,'enable','off');

%Disable parameter controls.
pctrls = {'p1_value' 'p2_value' 'p3_value' 'p4_value' 'p5_value' 'p5_load',...
  'p5_edit' 'p5_clear' 'ctm_name' 'ctm_select',...
  'datasetx1status' 'datasetx2status' 'datasetx1tstatus' 'datasetx2tstatus'};

for i = 1:length(pctrls)
  set(handles.(pctrls{i}),'enable','off')
end

%Deal with always enable menus.
enmenus = {'figbrowsermenu' 'menu_help'};
for i = enmenus
  set(handles.(i{:}),'enable','on')
  set(get(handles.(i{:}),'children'),'enable','on')
end

%List of controls to enable, always enable close button.
enablelist = {'close' 'menu_file' 'menu_edit' 'menu_preprocess' 'menu_view'...
              'menu_load' 'menu_import' 'menu_save' 'menu_clear' 'menu_close'...
              'menu_importx1' 'menu_importx2' 'menu_clearall'};
%Data status.
if x1
  enablelist = [enablelist {'x1load' 'x1pp' 'x1edit' 'x1clear' 'menu_editx1'...
                            'menu_loadx1' 'menu_ppx1' 'menu_clearx1'}];
  set(handles.datasetx1status,'enable','inactive')
else
  enablelist = [enablelist {'x1load' 'x1edit' 'menu_loadx1'}];
end

if x2
  enablelist = [enablelist {'x2load' 'x2pp' 'x2edit' 'x2clear' 'menu_editx2' ...
                            'menu_ppx2' 'menu_loadx2' 'menu_clearx2'}];
  set(handles.datasetx2status,'enable','inactive')
else
  enablelist = [enablelist {'x2load' 'x2edit' 'menu_loadx2'}];
end

if x1t
  enablelist = [enablelist {'x1tsave' 'x1tclear' 'menu_savex1t' 'menu_clearx1'}];
  set(handles.datasetx1tstatus,'enable','inactive')
end

if x2t
  enablelist = [enablelist {'x2tsave' 'x2tclear' 'menu_savex2t' 'menu_clearx2'}];
  set(handles.datasetx2tstatus,'enable','inactive')
end

%Model
if (x2t && model)
  %Model is current.
  enablelist = [enablelist {'ctm_calc' 'ctm_load' 'ctm_save' 'ctm_clear' 'menu_clearctm'...
    'exportmodel_mfile' 'exportmodel_xml' 'exportmodel_python' 'menu_savectm' 'menu_exportctm'}];
  
  enablelist = [enablelist {'ctm_load' 'ctm_calc' 'ctm_name' 'ctm_select'}];
  enablelist = [enablelist {'p1_value' 'p2_value' 'p3_value' 'p4_value'}];
  enablelist = [enablelist {'p5_value' 'p5_load' 'p5_edit' 'p5_clear'}];
  %Enable model.
  %ctm_select_Callback([], [], handles);
elseif (model && x2 && ~x2t)
  %There's model that hasn't been applied.
  enablelist = [enablelist {'ctm_calc' 'ctm_clear' 'menu_clearctm' 'ctm_select'}];
elseif ~model && (x1 && x2)
  %Data but no model.
  enablelist = [enablelist {'ctm_load' 'ctm_calc' 'ctm_name' 'ctm_select'}];
  enablelist = [enablelist {'p1_value' 'p2_value' 'p3_value' 'p4_value'}];
  enablelist = [enablelist {'p5_value' 'p5_load' 'p5_edit' 'p5_clear'}];
  %Enable model.
  ctm_select_Callback([], [], handles);
else
  %Else condition is to allow loading of model.
  enablelist = [enablelist {'ctm_load' 'ctm_select'}];
end

if ~exist('exportmodel','file');
  set(handles.menu_exportctm,'visible','off')
else
  set(handles.menu_exportctm,'visible','on')
end

%Cache Table
if cache
  enablelist = [enablelist {'cache_load' 'cache_save' 'cache_clear'}];
end

%Enable plotting if there's anything loaded.
if x1 || x2 || x1t || x2t
  enablelist = [enablelist {'chooseplots' 'ViewPlots'}];
end

for i = 1:length(enablelist)
  set(handles.(enablelist{i}),'enable','on')
end

%set(handles.chooseplots,'enable','on')
%--------------------------------------------------------------------
function  updatediffbars(handles)
%Update diff bars.
x1    = getobjdata('datasetx1',handles);
x2    = getobjdata('datasetx2',handles);
x1t   = getobjdata('datasetx1t',handles);
x2t   = getobjdata('datasetx2t',handles);

%prediffbar
axes(handles.prediffbar);
cla(handles.prediffbar);

diffval_cal = 1;
if (~isempty(x1) && ~isempty(x2)) && all(size(x1)==size(x2))
  [diffval_cal,diffvalstr_cal] = calcdifference(x1,x2);
  patch([0;1;1;0],[0,0,1,1],'y','EdgeColor','r')
  text('position',[0.1 0.5 0],'String',['Difference: ' diffvalstr_cal])
elseif ~isempty(x1) && ~isempty(x2)
  %There's data but the sizes don't match.
  patch([0;0;0;0],[0,0,1,1],'w','EdgeColor','w')
  text('position',[0.1 0.5 0],'String','N/A Data Size Mismatch')
end

%postdiffbar
axes(handles.postdiffbar);
cla(handles.postdiffbar);
if (~isempty(x1t) && ~isempty(x2t)) && all(size(x1t)==size(x2t))
  [diffval_val,diffvalstr_val] = calcdifference(x1t,x2t);
  %Get percent change from diffval_cal
  mydiffpercent = diffval_val/diffval_cal;
  mydiffpercent = min(mydiffpercent,1);
  patch([0;mydiffpercent;mydiffpercent;0],[0,0,1,1],'y','EdgeColor','r')
  text('position',[0.1 0.5 0],'String',['Difference: ' diffvalstr_val])
elseif ~isempty(x1t) && ~isempty(x2t)
  patch([0;0;0;0],[0,0,1,1],'w','EdgeColor','w')
  text('position',[0.1 0.5 0],'String','N/A Data Size Mismatch')
end

%--------------------------------------------------------------------
function opts = makeoptions(mtype,handles)
%Create options from appdata and interface.

opts = getappdata(handles.caltransfergui,'options');

switch mtype
  case 'ds'

  case 'pds'
    opts.pds.win = str2num(get(handles.p1_value,'String'));
  case 'dwpds'
    w1 = str2num(get(handles.p1_value,'String'));
    w2 = str2num(get(handles.p2_value,'String'));
    opts.dwpds.win = [w1 w2];
  case 'glsw'
    opts.glsw.a = str2num(get(handles.p1_value,'String'));
  case 'osc'
    opts.osc.y = getobjdata('datasetctmy',handles); %Required input.
    opts.osc.ncomp = str2num(get(handles.p1_value,'String')); %Required input.
    opts.osc.iter = str2num(get(handles.p2_value,'String')); %Default from function.
    opts.osc.tol = str2num(get(handles.p3_value,'String')); %Default from function.
  case 'sst'
    opts.sst.ncomp = str2num(get(handles.p1_value, 'String'));
    
  case 'alignmat'
    opts.alignmat.ncomp = str2num(get(handles.p1_value,'String')); %Required input.
    opts.alignmat.iter = str2num(get(handles.p2_value,'String')); %Default from function.
    opts.alignmat.tol = str2num(get(handles.p3_value,'String'));
    opts.alignmat.y = getobjdata('datasetctmy',handles); %Required input.

  case 'clear'
    return
  otherwise
    return
end

%--------------------------------------------------------------------
function p3_value_Callback(hObject, eventdata, handles)


%--------------------------------------------------------------------
function p4_value_Callback(hObject, eventdata, handles)
%

%--------------------------------------------------------------------
function p5_value_Callback(hObject, eventdata, handles)


%--------------------------------------------------------------------
function p5_load_Callback(hObject, eventdata, handles, varargin)
%Load data to P5.
loaddata(handles,'datasetctmy',varargin{:})

ysize = size(getobjdata('datasetctmy',handles));
set(handles.p5_value,'String',['Size : ' num2str(ysize(1)) 'x' num2str(ysize(2))]);

%--------------------------------------------------------------------
function p5_edit_Callback(hObject, eventdata, handles)
%Edit data to P5.
%Set dataset extention (datasetext) so editds can find data.

%setappdata(handles.caltransfergui,'datasetext','ctmy')
myid = getobj('datasetctmy',handles);
editds(myid);

%--------------------------------------------------------------------
function p5_clear_Callback(hObject, eventdata, handles)
%Clear data to P5.
setobjdata('datasetctmy',handles,[]);
set(handles.p5_value,'String','');

%--------------------------------------------------------------------
function x1edit_Callback(hObject, eventdata, handles)
%Edit X1 with editds.
%Set dataset extention (datasetext) so editds can find data.

myid = getobj('datasetx1',handles);

curfig = getappdata(handles.caltransfergui,'x1editfig');
if isempty(curfig) || ~ishandle(curfig)
  curfig = editds(myid);
  setappdata(handles.caltransfergui,'x1editfig',curfig);
end

updateall(handles)

figure(curfig); %Make figure come to front.

%--------------------------------------------------------------------
function x2edit_Callback(hObject, eventdata, handles)
%Edit X2 with editds.
%Set dataset extention (datasetext) so editds can find data.

myid = getobj('datasetx2',handles);

curfig = getappdata(handles.caltransfergui,'x2editfig');
if isempty(curfig) || ~ishandle(curfig)
  curfig = editds(myid);
  setappdata(handles.caltransfergui,'x2editfig',curfig);
end

updateall(handles)

figure(curfig); %Make figure come to front.
%--------------------------------------------------------------------
function cache_load_Callback(hObject, eventdata, handles)
%Load cache.

if hObject==handles.cachetable && ~strcmp(get(gcbf,'selectiontype'),'open')
  return
end

mselect = get(handles.cachetable,'value');
mcache = getappdata(handles.caltransfergui,'ctmcache');
mcache = mcache(mselect);

clearall_Callback([], [], handles)

if ~isempty(mcache)
  setobjdata('datasetx1',handles,mcache.x1);
  setobjdata('datasetx2',handles,mcache.x2);
  setobjdata('datasetx1t',handles,mcache.x1t);
  setobjdata('datasetx2t',handles,mcache.x2t);
  setobjdata('ctm',handles,mcache.ctm);
  setappdata(handles.caltransfergui,'options',mcache.opts);
end
%TODO: load preprocessing?

updateall(handles)
%--------------------------------------------------------------------
function cache_save_Callback(hObject, eventdata, handles)
%Save entire structure.
mselect = get(handles.cachetable,'value');
mcache = getappdata(handles.caltransfergui,'ctmcache');
mcache = mcache(mselect);

targname = mcache.ctm.detail.modelname;
[what,where] = svdlgpls(mcache,'Save All Cached CALTRANSFER Data',['cache_' targname]);

%--------------------------------------------------------------------
function cache_clear_Callback(hObject, eventdata, handles)
%Clear selected entry.

mselect = get(handles.cachetable,'value');
mcache = getappdata(handles.caltransfergui,'ctmcache');

mcache = mcache([1:mselect-1,mselect+1:end]);
setappdata(handles.caltransfergui,'ctmcache',mcache);

%Update cachetable.
updatecachetable(handles)

%--------------------------------------------------------------------
function ctm_load_Callback(hObject, eventdata, handles, varargin)
%Load a model.
%There is no checking for replacing/deleting a model becuase they are save
%automatically or loaded from saved structure.

if length(varargin)==0;
  [modl,name,location] = lddlgpls('struct','Select Model');
else
  modl = varargin{1};
end

if isempty(modl);  return; end

if ~ismodel(modl) || ~strcmpi(modl.modeltype,'caltransfer')
  erdlgpls({'Error loading calibration transfer model. Model needs to be standard model structer and .modeltype = caltransfer.'},'Calibration Transfer Error')
  return
end

%setappdata(handles.caltransfergui,'ctm',modl); %CalTransferModel structure.
setobjdata('ctm',handles,modl);
updateall(handles);

%--------------------------------------------------------------------
function x1tsave_Callback(hObject, eventdata, handles)
%Save transferred data.
x1t   = getobjdata('datasetx1t',handles);
[what,where] = svdlgpls(x1t,'Save Instrument 1 Transferred Data',[x1t.name '_transferred']);

%--------------------------------------------------------------------
function x2tsave_Callback(hObject, eventdata, handles)
%Save transferred data.
x2t   = getobjdata('datasetx2t',handles);
[what,where] = svdlgpls(x2t,'Save Instrument 2 Transferred Data',[x2t.name '_transferred']);

%--------------------------------------------------------------------
function close_Callback(hObject, eventdata, handles)
%Close gui.

mcache = getappdata(handles.caltransfergui,'ctmcache');
if ~isempty(mcache)
  ans=evriquestdlg('Model(s) and Data are still present in the Cache. What do you want to do?', ...
    'Cached Data','Quit Without Saving','Cancel','Quit Without Saving');
  switch ans
    case {'Cancel'}
      return
  end
end

%store position
positionmanager(handles.caltransfergui,'caltransfergui','set')

%Close any open figures.
chfigs = {'preprocess' 'x1editfig' 'x2editfig' 'children'};

for i = chfigs
  try
    h = getappdata(handles.caltransfergui,i{:});
    h(~ishandle(h)) = [];
    delete(h);
  end
end

delete(handles.caltransfergui);



% --- Executes on button press in plotsbutton.
function plotsbutton_Callback(hObject, eventdata, handles)
% hObject    handle to plotsbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --------------------------------------------------------------------
function [myid,myitem] = getobj(item,handles)
%Get current item, 'myid' is sourceID.

myitem = item;%Legacy code from Analysis, just return item.

if ~isstruct(handles)
  handles = guidata(handles);
end

%Get a list of objects for given item type.
queryprops.itemType = item;
queryprops.itemIsCurrent = 1;
myid = searchshareddata(handles.caltransfergui,'query',queryprops);

if length(myid)>1
  error(['There appears to be more than one current ' myitem ' registered to the analysis GUI.']);
elseif isempty(myid)
  myid = [];
elseif length(myid)>1
  myid = myid{1};
end

% --------------------------------------------------------------------
function out = isloaded(item,handles)
%Determine if item is currently loaded.

if ~isstruct(handles)
  handles = guidata(handles);
end

out = ~isempty(getobjdata(item,handles));

% --------------------------------------------------------------------
function out = getobjdata(item,handles)
%Get a data object. 
%  Inputs:
%    item       - is the type of object (e.g., "xblock" or "yblock").
%    handles    - handles structure or figure handle.

if ~isstruct(handles)
  handles = guidata(handles);
end

myid = getobj(item,handles);

out = getshareddata(myid);

% --------------------------------------------------------------------
function myid = setobjdata(item,handles,obj,myprops,userdata)
%Update or add a data object to the figure.
%  Inputs:
%    item    - is the type of object (e.g., "xblock" or "yblock").
%    handles - handles structure.
%    obj     - data object (e.g., DSO, model, or prediction).
%  OPTIONAL INPUTS:
%    myprops  - properties to set with the object
%    userdata - userdata to set with the link in analysis

%If adding for first time (i.e., there's no data for current "item" then
%set the currentitem flag for that item). NOTE: this functionality is not
%currently in use but should allow for multiple versions of the same "item"
%to be loaded at one time.
%
% Use the following properties to define behavior.
%   itemType      - How the item is assigned in the gui (e.g., "xblock" or
%                   "model", etc).
%   itemIsCurrent - (boolean) if there are multiple items of the same type loaded,
%                   which item is currently being used (has focus).
%   itemReadOnly  - (boolean) can the current item be modified.

if ~isstruct(handles)
  handles = guidata(handles);
end

[myid myitem] = getobj(item,handles);

if nargin<4
  myprops = [];
end
if nargin<5;
  userdata = [];
end

if isempty(myid)
  if~isempty(obj)
    %Adding for the first time.
    myprops.itemType = myitem;
    myprops.itemIsCurrent = 1;
    myprops.itemReadOnly = 0;
    myid = setshareddata(handles.caltransfergui,obj,myprops);
    linkshareddata(myid,'add',handles.caltransfergui,'caltransfergui',userdata);
  else
    %Don't add an empty data object.
  end
else
  if ~isempty(obj)
    %Update shareddata.
    if ~isempty(myprops)
      %update properties (quietly - without propogating callbacks)
      updatepropshareddata(myid,'update',myprops,'quiet');
    end
    setshareddata(myid,obj);
  else
    %Set to empty = clear shareddata.
    removeshareddata(myid,'standard');
  end
end

% --------------------------------------------------------------------
function dataprops = getdataprops
%define data callback properties

dataprops = [];
dataprops.datachangecallback = 'datachangecallback(myobj.id)';
dataprops.includechangecallback = 'dataincludechange(myobj.id)';

%-----------------------------------------------
function updateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object. 
%The myobj variable comes in with the following structure.
%
%   id           - unique id of object.
%   object       - shared data (object).
%   properties   - structure of "properties" to associate with shared data.

if isempty(keyword); keyword = 'Modify'; end

if isshareddata(h)
  
  %connection link
  if strcmp(keyword,'delete') & isfield(userdata,'isdependent') & userdata.isdependent
    removeshareddata(h);
  end

elseif ishandle(h)

  %subscriber link
  cb = '';
  switch char(keyword)
  
    case {'class' 'include' 'axisscale'}

      if isempty(cb) & isfield(myobj.properties,'datachangecallback')
        cb = myobj.properties.datachangecallback;
      end
      
    case 'delete'

    otherwise
      if isfield(myobj.properties,'datachangecallback')
        cb = myobj.properties.datachangecallback;
      end
      
  end
  if ~isempty(cb)
    try
      eval(cb);
    catch
      disp(encode(lasterror))
      erdlgpls(sprintf('Error executing callback for keyword ''%s'' on object ''%s''',keyword,myobj.properties.itemType),'Callback Error');
    end
  end

end

%-----------------------------------------------
function propupdateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object. 
%The myobj variable comes in with the following structure.
%
%   id       - unique id of object.
%   myobj    - shared data (object).
%   keyword  - keyword for what was updated (may be empty if nothing specified
%   userdata - additional data associated with the link by user

if nargin<4;
  userdata = [];
end

id = myobj.id;
if ~isempty(keyword)
  switch keyword
    case {'selection'}
      %Selection updated

      myobj.properties.selection = plotgui('validateselection',myobj.properties.selection,myobj.object);
      
      if ishandle(h)  %'subscriber'
        %call related to analysis' link to this object (subscriber)

        %In the future, we may put "callback" actions here
        
      else  %'connection'        
        %call related to linking to another object (connection)
        try
          last_timestamp = searchshareddata(h,'getval','timestamp');
        catch
          %any error in finding object, just skip it
          return
        end
        timestamp      = myobj.properties.timestamp;
        if last_timestamp~=timestamp
          %figure out what kind of selection mapping we need
          if ~isfield(userdata,'linkmap')
            if ~isstruct(userdata)
              userdata = [];
            end
            userdata.linkmap = ':';
          end
          newselection = myobj.properties.selection;
          if ~isnumeric(userdata.linkmap)
            %not numeric? pass entire selection as is
            myselection = newselection;
          else
            %matrix mapping mode to mode, pass only those modes
            myselection = h.properties.selection;
            oldselection = myselection;
            myselection(1,userdata.linkmap(:,1)) = newselection(userdata.linkmap(:,2));
            if comparevars(oldselection,myselection)
              %no change actually made? skip!
              return
            end
          end
          
          %create properties structure and update connection
          props = [];
          props.selection = myselection;
          props.timestamp = timestamp;
          updatepropshareddata(h,'update',props,'selection')
        end
      end
  end
end
