function varargout = preprocessiterator(inpp,varargin)
%PREPROCESSITERATOR - Create array of preprocessing combinations.
% For given input preprocessing structure (inpp), create combinations of
% preprocessing based on PP methods that can be iterated over using simple
% min/steps/max values. If iteration list is not provided a window will
% appear allowing user to specify  iterations.
%
% Supported Preprocessing Methods:
%   Derivative (SavGol)
%   Normalize
%   GLS Weighting
%   EPO Filter
%   Baseline (Automatic Whittaker Filter)
%   Detrend
%   Gap Segment Derivative
%   Autoscale
%   Poisson (Sqrt Mean) Scaling
%
% Iterator Matrix example (cell array):
%  Rel_Index  PP_Name         Param_Name    Param_Var   Data_Type         Min  Step  Max  Use_Log
%  1          'derivative'     'Width'       'width'     'int(1:inf)'      15    3     23   0
%  1          'derivative'     'Derivative'  'deriv'     'int(1:inf)'      1     1     1    0
%  1          'derivative'     'Order'       'order'     'int(1:inf)'      1     1     1    0
%  2          'Normalize'      'Norm Type'   'normtype'  'int(1:inf)'      2     1     2    0
%  1          'GLS Weighting'  'Alpha'       'a'         'float(0:inf)'    1     4     100  1
%
%   Rel_Index   - Relative index of method. In the example above the second
%                 Normalize step is used.
%   PP_Name     - Name of preprocess method.
%   Param_nName - Name of .userdata parameter.
%   Param_Var   - Name of .userdata field.
%   Data_Type   - Allowed values for Min and Max.
%   Min         - First value.
%   Step        - Size of interval of each step.
%   Max         - Last value.
%   Use_Log     - Use a log scale to create values.
%
% NOTE: If the original preprocess structure contains 2 Normalize steps,
% the second Normalize will be iterated over.
%
% NOTE: See getdefaults() sub function for list of methods and parameters
% that can be iterated.
%
%I/O: pplist = preprocessiterator(inpp);%Shows gui for iterator settings.
%I/O: pplist = preprocessiterator(inpp,imatrix);%Command line call.
%
%See also: PREPROCESS, PREPROUSER

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>0;
  
  if ischar(inpp) & ismember(inpp,evriio([],'validtopics'))
    %EVRIIO
    options = [];
    if nargout==0
      evriio(mfilename,inpp,options)
    else
      varargout{1} = evriio(mfilename,inpp,options);
    end
    return;
  else
    if ischar(inpp)
      if nargout == 0;
        feval(inpp,varargin{:}); % FEVAL switchyard
      else
        %Not used yet.
        [varargout{1:nargout}] = feval(inpp,varargin{:}); % FEVAL switchyard
      end
    else
      if nargin==2
        %Go straight to list constructor.
        varargout{:} = getlist(inpp,varargin{1});
      elseif nargin==1
        %Show gui.
        varargout{:} = getlist(inpp,[]);
      end
    end
  end
  
end

%--------------------------------------------------
function pplist = getlist(inpp,imatrix)
%Get combined preprocess list.

pplist = [];

default_imatrix = getdefaults;

if isempty(imatrix)
  %Get matrix from GUI.
  %Get list of incoming preprocessing that can be iterated over.
  %imatrix = default_imatrix(ismember(default_imatrix(:,2),{inpp.keyword}),:);
  imatrix = '';
  for i = 1:length(inpp)
    thispp_count = ismember({inpp.keyword},inpp(i).keyword);%Get relative count of this pp method.
    if ismember(inpp(i).keyword,default_imatrix(:,2))
      thisimat = default_imatrix(ismember(default_imatrix(:,2),inpp(i).keyword),:);
      thisimat(:,1) = repmat({sum(thispp_count(1:i))},size(thisimat,1),1);%Get relative count of this pp method.
      %Add initial values.
      for j = 1:size(thisimat,1)
        %Add initial data for each parameter.
        thisimat{j,6} = inpp(i).userdata.(thisimat{j,4});
        thisimat{j,8} = inpp(i).userdata.(thisimat{j,4});
      end
      imatrix = [imatrix; thisimat];
    end
  end
else
  %Make sure imatrix only has inpp methods.
  imatrix = imatrix(ismember(imatrix(:,2),{inpp.keyword}),:);
end

if ~isempty(imatrix) && all([imatrix{:,7}]==1)%imatrix{:,7} is all ones if using default imatrix and not passing via command line.
  imatrix = getppgui(imatrix);%Call GUI for settings.
else
  %No iterator pp methods found so set to -1 so we can tell it was not a
  %user cancel of the gui.
  pplist = -1;
end

if isempty(imatrix)
  return
end

%Assemble lists and indexes.
ppname = {};%Unique PP and pram name.
ppvals = {};%Actual value of parameter.
validx = {};%Index into ppvals.
%Index of PP params that have more than one value and should be fed to DOE.
%We do this to avoid high number of factors that cause factdes to create a
%huge design matrix.
doeuse = [];

%Build all combos.
for i = 1:size(imatrix,1)
  %Get a unique column name that has pp indx, method and parameter.
  ppname{i} = [num2str(imatrix{i,1}) '_' imatrix{i,2} '_' imatrix{i,4}];
  
  mmstep = round((imatrix{i,8}-imatrix{i,6})/imatrix{i,7})+1;
  if mmstep<=1
    if imatrix{i,9}
      ppvals{i} = log10(imatrix{i,8});
    else
      ppvals{i} = imatrix{i,8};
    end
  else
    %Get numeric values for parameters.
    switch imatrix{i,5}(1:3)
      case 'int'
        thisval = round(linspace(imatrix{i,6},imatrix{i,8},mmstep));
        if (strcmpi(imatrix{i,2},'derivative') & strcmpi(imatrix{i,3},'width')) | ...
            (strcmpi(imatrix{i,2},'gapsegment') & strcmpi(imatrix{i,3},'gap'))
          %Needs to be odd.
          thisval(~mod(thisval,2)) = thisval(~mod(thisval,2))-1;
        end
        ppvals{i} = thisval;
      case 'flo'
        if imatrix{i,9}
          %Use log.
          ppvals{i} = linspace(log10(imatrix{i,6}),log10(imatrix{i,8}),mmstep);
          ppvals{i} = 10.^ppvals{i};
        else
          ppvals{i} = linspace(imatrix{i,6},imatrix{i,8},mmstep);
        end
      otherwise
        error('No data type info')
    end
  end
  
  doeuse(i) = 0;
  %Insert 1 if empty so DOE doesn't fail.
  if ~isempty(ppvals{i})
    validx{i} = 1:length(ppvals{i});
    if length(ppvals{i})>1
      doeuse(i) = 1;
    end
  else
    validx{i} = 1;
  end
end

if any(doeuse)
  %Get DOE with indexes (validx) into the pp value (ppvals) vectors.
  [doe,msg] = doegen('full',ppname(logical(doeuse)),validx(logical(doeuse)));
else
  doe=1;%Spoof for single row, size==1.
end

%Cell array of final pp structures.
pplist = {};

for i = 1:size(doe,1);
  %For each row in doe make a pp structure.
  thispp = inpp;
  for j = 1:length(ppname)
    upos = strfind(ppname{j},'_');
    thisname = ppname{j};
    myidx    = str2num(thisname(1:upos(1)-1));
    ppmeth   = thisname(upos(1)+1:upos(2)-1);
    pppram   = thisname(upos(2)+1:end);
    
    ppidx = find(ismember({thispp.keyword},ppmeth));
    ppidx = ppidx(myidx);
    thisval = ppvals{j};
    if ~isempty(thisval) && doeuse(j)==1
      jidx = sum(doeuse(1:j));
      thisval = thisval(doe.data(i,jidx));
    end
    thispp(ppidx).userdata.(pppram) = thisval;
    % special case for whittaker and baseline (currently baseline not used):
    if strcmp(ppmeth,'whittaker') & strcmp(pppram, 'lambda')
      % whittaker: set metabasis equal to lambda setting
      thispp(ppidx).userdata.metabasis = thisval;
    elseif strcmp(ppmeth,'baseline') & strcmp(pppram, 'order')
      % baseline: set metabasis equal to order setting
      thispp(ppidx).userdata.metabasis = thisval;
    end
    try
      %Try setting description.
      thispp(ppidx) = feval(thispp(ppidx).settingsgui,'setdescription',thispp(ppidx));
    end
  end
  pplist = [pplist; {thispp}];
end

%--------------------------------------------------
function out = getdefaults
%Get default list of preprocessing iteration methods.
% Rel_IDX PP_Name Param_Name Para_Var Data_Type Min Step Max Use_Log

out = {1 'derivative'     'Width'       'width'     'int(1:inf)'   1 1 1 0;
  1 'derivative'     'Derivative'  'deriv'     'int(1:inf)'   1 1 1 0;...
  1 'derivative'     'Order'       'order'     'int(1:inf)'   1 1 1 0;...
  1 'smooth'         'Width'       'width'     'int(1:inf)'   1 1 1 0;
  1 'smooth'         'Order'       'order'     'int(1:inf)'   1 1 1 0;...
  1 'Normalize'      'Norm Type'   'normtype'  'int(1:inf)'   1 1 1 0;...
  1 'GLS Weighting'  'Alpha'       'a'         'float(0:inf)' 1 1 1 1;...
  1 'EPO'            'PCs'         'a'         'int(-inf:-1)'   1 1 1 0;...
  1 'declutter GLS Weighting'  'Alpha'       'a'         'float(0:inf)' 1 1 1 1;...
  1 'declutter EPO'            'PCs'         'a'         'int(-inf:-1)'   1 1 1 0;...
  1 'whittaker'      'Asymmetry'   'p'         'float(0:inf)' 1 1 1 0;...
  1 'whittaker'      'Smoothness (Lambda)' 'lambda'    'float(0:inf)' 1 1 1 1;...
  1 'Detrend'        'Order'       'order'     'int(1:inf)'   1 1 1 0;...
  1 'gapsegment'     'Order'       'order'     'int(1:inf)'   1 1 1 0;...
  1 'gapsegment'     'Gap'         'gap'       'int(1:inf)'   1 1 1 0;...
  1 'gapsegment'     'Segment'     'segment'   'int(1:inf)'   1 1 1 0;...
  1 'Autoscale'      'Offset'      'offset'    'float(0:inf)'   1 1 1 0;...
  1 'sqmnsc'         'Offset'      'offset'    'float(0:inf)' 1 1 1 0};

% s = preprocess('default','derivative','normalize','GLS Weighting','EPO',...
%                'whittaker','detrend','gapsegment','autoscale','sqmnsc');

%--------------------------------------------------------------
function datachange_callback(varargin)
%Data chane callback, check value for (Float/Int).
fig = varargin{1};
m   = varargin{2};
ev  = varargin{3};
jt  = varargin{4};

if ~isempty(getappdata(fig,'silentedit'));
  %Resetting a value so don't need to check.
  setappdata(fig,'silentedit',[])%Clear again just in case error occurs.
  return
end

mRow = get(ev,'FirstRow');
mCol = get(ev,'Column');
if mCol==6
  %Don't validate log check box.
  return
end

newData = m.getValueAt(mRow,mCol);
newValidData = newData;

method  = m.getValueAt(mRow,0);
idx     = m.getValueAt(mRow,1);
param   = m.getValueAt(mRow,2);

imat = getappdata(fig,'imatrix');

pprows   = ismember(imat(:,2),method);%Rows for pp method.
idxrows  = [imat{:,1}]'==idx;%Rows for index.
pramrows = ismember(imat(:,3),param);%Rows for param.
myrow    = pprows+idxrows+pramrows>2;%Editing this row.

if sum(myrow)>1 | sum(myrow)<1
  error('Error finding parameter in data table.')
end
% 
if mCol >= 3 & mCol <= 5
  %Check min, max, and step for correct data type.
  %For columns 3 and 5 we need to check data type.
  if ~prefobjcb('isvalid',newData,struct('valid',imat{myrow,5}),[])
    %Roll back.
    newValidData = imat{myrow,mCol+3};%There's a 3 column offset between table data and actual imat.
  end
end

%Was getting errors from latency I think. Drawnow here seems to fix.
drawnow

setappdata(fig,'silentedit',1);
if newValidData~=newData
  %Need to roll back changes.
  setappdata(fig,'silentedit',1);
  m.setValueAt(newValidData,mRow,mCol)
  setappdata(fig,'silentedit',[])
else
  %Set appdata of new imat.
  imat{myrow,mCol+3} = newValidData;
  setappdata(fig,'imatrix',imat)
  %Update count.
  count = round((imat{myrow,8}-imat{myrow,6})/imat{myrow,7})+1;
  m.setValueAt(count,mRow,7)
end

%--------------------------------------------------
function out = getppgui(imatrix)
%GUI for setting parameters.

out = [];
columntypes = {'double','label','label','doulbe','double','double','logical','double'};
columneditable = logical([0 0 0 1 1 1 1 0]);%Editable does not work correctly for double (5/15/14). Need to fix treeTable when possible.
headers = {'Method','Index','Name','Min','Step','Max','Log','Count'};  % 5 columns by default
f = figure('tag','ppiterator','toolbar','none','menu','none','units','pixels',...
  'name','Preprocess Parameters','NumberTitle','off');
fpos = get(f,'position');
dpanel = uipanel(f,'tag','table_panel',...
  'units','pixels',...
  'BackgroundColor',[1 1 1],...
  'title','',...
  'position',[4 38 fpos(3)-8 fpos(4)-38],...
  'fontsize',getdefaultfontsize);
data = imatrix(:,[2 1 3 6:end]);
%Make count column.
ccol = ([data{:,6}]'-[data{:,4}]')+1/1;
data = [data num2cell(ccol)];
data(:,end-1) = num2cell(logical([data{:,end-1}])');
drawnow
tt = treeTable('Container',dpanel,'data',data,'headers',headers,'columntypes',columntypes,'ColumnEditable',columneditable);
%Add custom callback to do error checking.
cb = schema.prop(tt,'DataChangeCallbackCustom','mxArray');
set(tt,'DataChangeCallbackCustom',{@datachange_callback,f})

setappdata(f,'treeTable',tt);
setappdata(f,'imatrix',imatrix);

uicontrol('parent', f,...
  'tag', 'okbtn',...
  'style', 'pushbutton', ...
  'string', 'OK', ...
  'units', 'pixels', ...
  'position',[100 4 110 30],...
  'fontsize',getdefaultfontsize,...
  'tooltipstring','OK',...
  'callback','preprocessiterator(''button_callback'',gcbo,[],guidata(gcbf),''ok'')');

%Cancel
uicontrol('parent', f,...
  'tag', 'cancelbtn',...
  'style', 'pushbutton', ...
  'string', 'Cancel', ...
  'units', 'pixels', ...
  'position',[206 4 110 30],...
  'fontsize',getdefaultfontsize,...
  'tooltipstring','Cance and close window.',...
  'callback','preprocessiterator(''button_callback'',gcbo,[],guihandles(gcbf))');

set(f,'ResizeFcn','preprocessiterator(''resize_callback'',gcbo,[],guihandles(gcbf),''ok'')');
resize_callback(f,[],guihandles(f),{})

%Center columns so looks little better.

uiwait(f);
out = [];
if ishandle(f) & isempty(getappdata(f,'usercancel'))
  %Add datatype back into column 3.
  %TODO: Fix this output.
  out = getappdata(f,'imatrix');
end
delete(f)
%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%Resize callback.

%Get initial positions.
figpos = get(handles.ppiterator,'position');
set(handles.table_panel,'position',[2 38 figpos(3)-4 figpos(4)-38])

set(handles.okbtn,'position',[figpos(3)-208 4 100 30])
set(handles.cancelbtn,'position',[figpos(3)-104 4 100 30])

%--------------------------------------------------------------
function button_callback(h,eventdata,handles,varargin)
%Button callback.
handles = guihandles(h);

switch get(h,'tag')
  case 'okbtn'
    %Data is maintained in datachange_callback so just resume.
    
  case 'cancelbtn'
    setappdata(handles.ppiterator,'usercancel',1)
end

uiresume(handles.ppiterator);

%--------------------------------------------------
function test
%Simple runtime test scenarios.

inpp = preprocess('default','mean center','derivative','normalize', 'mean center','sqmnsc','normalize','log10','whittaker');
imat = {1 'derivative'     'Width'       'width'     'int(1:inf)'   1 1 1 0;
  1 'derivative'     'Derivative'  'deriv'     'int(1:inf)'   1 1 1 0;...
  1 'derivative'     'Order'       'order'     'int(1:inf)'   1 3 3 0;...
  1 'Normalize'      'Norm Type'   'normtype'  'int(1:inf)'   1 1 1 0;...
  1 'Normalize'      'Norm Type'   'normtype'  'int(1:inf)'   1 1 1 0};
t = preprocessiterator(inpp,imat);


%Test everything.
inpp = preprocess('default','derivative','normalize','GLS Weighting','EPO',...
  'whittaker','detrend','gapsegment','autoscale','sqmnsc');

imat = {1 'derivative'     'Width'       'width'     'int(1:inf)'   1 1 1 0;
  1 'derivative'     'Derivative'  'deriv'     'int(1:inf)'   1 1 1 0;...
  1 'derivative'     'Order'       'order'     'int(1:inf)'   1 1 1 0;...
  1 'Normalize'      'Norm Type'   'normtype'  'int(1:inf)'   1 1 1 0;...
  1 'GLS Weighting'  'Alpha'       'a'         'float(0:inf)' 1 1 1 1;...
  1 'EPO'            'PCs'         'a'         'int(1:inf)'   1 1 1 0;...
  1 'whittaker'      'Asymmetry'   'p'         'float(0:inf)' 1 1 1 0;...
  1 'whittaker'      'Smoothness (Lambda)' 'lambda'    'float(0:inf)' 1 1 1 1;...
  1 'Detrend'        'Order'       'order'     'int(1:inf)'   1 1 1 0;...
  1 'gapsegment'     'Order'       'order'     'int(1:inf)'   1 1 1 0;...
  1 'gapsegment'     'Gap'         'gap'       'int(1:inf)'   1 1 1 0;...
  1 'gapsegment'     'Segment'     'segment'   'int(1:inf)'   1 1 1 0;...
  1 'Autoscale'      'Offset'      'offset'    'int(1:inf)'   1 1 1 0;...
  1 'sqmnsc'         'Offset'      'offset'    'float(0:inf)' 1 1 1 0};
%Should open gui
t = preprocessiterator(inpp,imat);

imat = {1 'GLS Weighting'  'Alpha'       'a'         'float(0:inf)' 1 1 1 1};
t = preprocessiterator(inpp,imat);
