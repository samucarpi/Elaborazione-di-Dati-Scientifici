function varargout = svdlgpls(varargin)
%SVDLGPLS Dialog to save variable to workspace or MAT file.
%  The input (varin) is a variable to be passed
%  out from a function to the workspace or MAT file. The
%  dialog box allows the user to select a location
%  (base workspace or MAT file) and a name for (varin).
% Optional inputs (message) and (defaultname) set the
%  message to display in the dialog box and the default
%  name for saving, respectively.
% Optional outputs give information about the variable 
%  name (name) and file location (location)
%  used to save the variable. Location will be empty if
%  saved to the base workspace.
%
%I/O: [name,location]=svdlgpls(varin,message,defaultname);
%
%See also: LDDLGPLS

%Copyright Eigenvector Research, Inc 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 1/8/01 Initial 3.0 coding to match old svdlgpls
%jms 2/26/02 updated for new initializing of lddlgpls figure
%  -cleaned up initial code & made "all-classes" the only available validclass
%jms 9/10/03 -added better test for bad variable name characters

if strcmp(getappdata(0,'debug'),'on');
  dbstop if all error
end

if nargin < 1;
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,'io',options); else; varargout{1} = evriio(mfilename,'io',options); end
  return
end
if nargin < 2 | isempty(varargin{2});
  varargin{2} = 'Save Item As';
end
if nargin < 3;
  varargin{3} = '';   %default variable name for save
end

savetofile = [];
if nargin < 4;
  options = [];
elseif isstr(varargin{4});
  savetofile = varargin{4};
  options = [];
else
  options = varargin{4};
end

if nargin==1 & ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics'));
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

options = reconopts(options,'svdlgpls');

sz           = size(varargin{1});
if any(sz==0); 
  validdims  = [1:100];        %empty variable, match any size var
else
  validdims  = length(sz);
end
%validclasses = class(varargin{1});
validclasses = '*';                   %show all classes so we don't overwrite an existing variable of a different class

fig     = openfig('lddlgpls','reuse');
handles = guihandles(fig);                % Generate a structure of handles to pass to callbacks, and store it. 
handles = lddlgpls('initgui',handles,lddlgpls('options'),[],[]);
guidata(fig, handles);
set(handles.text3,'string','Items')
set(handles.text5,'string','Item:')

%Fix for mac and ML 2008.
ismac=~isempty(findstr(computer,'MAC'));
if ismac && checkmlversion('==','7.6')
  set(findobj(fig,'style','edit'),'horizontalAlignment','center');
end

setappdata(handles.lddlg,'mode','save'); 
set(handles.loadbtn,'string','Save');
set(handles.lddlg,'name','Save');

setappdata(handles.lddlg,'value',varargin{1});
set(handles.description,'string',varargin{2});
setappdata(handles.lddlg,'validclasses',validclasses);
setappdata(handles.lddlg,'validdims',validdims);

setappdata(handles.lddlg,'defaultext','.mat');
%call any add-on functions
fns = evriaddon('lddlgpls_initialize');
for j=1:length(fns)
  feval(fns{j},handles.lddlg);
end

%resize to last used size (in this session)
figsize = getappdata(0,'lddlgpls_size');
if ~isempty(figsize);
  set(handles.lddlg,'position',figsize)
end

lddlgpls('resize',handles.lddlg, [], handles)  

%store and set default variable name
varname  = varargin{3};
varname((varname<'0') | (varname>'9' & varname<'A') | (varname>'Z' & varname<'a' & varname~='_')) = [];
varargin{3} = varname;
setappdata(handles.lddlg,'defaultname',varargin{3});
set(handles.editvarname,'string',varargin{3});
lddlgpls('editvarname_Callback',fig, [], handles)

%decide WHERE we should save this (depends on what the user did last time
%and what the caller requested)
settings = lddlgpls('getsettings',[],[],[]);
if isempty(savetofile)
  %caller didn't request anything, do what the user did last time
  savetofile = settings.tofile;
elseif strcmp(savetofile,'workspace')
  %caller requested workspace, do it
  settings.toworkspace = 1;
elseif strcmp(savetofile,'file')
  %caller requested file, try where the user saved last
  savetofile = settings.tofile;
  settings.toworkspace = 0;
  if isempty(savetofile)
    %if they did workspace, switch to present working folder
    savetofile = pwd;
  end
end
if settings.toworkspace
  lddlgpls('sourcebtn_Callback',fig,[],handles,'');     %update controls for initial base workspace mode
else
  lddlgpls('sourcebtn_Callback',fig,[],handles,savetofile);     %update controls for to file mode
end
setappdata(handles.sourcename,'lastfile',savetofile);

set(fig,'windowstyle','modal');
uiwait(fig);      %wait for figure to return

if ishandle(fig);   %figure still exists?
  settings.figsize = get(fig,'position');  %save current fig size and position
  varargout = {get(handles.editvarname,'string') get(handles.editfilename,'string')};
  mydir = getappdata(handles.lddlg,'pwd');
  %if isstr(mydir); cd(mydir); end  %change to this folder
  %save the folder and filename for next time svdlgpls is called to test if save to base or file
  if ~isempty(varargout{2});
    settings.tofile = fullfile(mydir,varargout{2});
    settings.toworkspace = 0;
    if exist('isdeployed') & isdeployed
      %if deployed, change the current working directory to this folder
      cd(mydir);
    end
  else   %unless they saved to the base workspace, in which case, store flag to return here
    settings.toworkspace = 1;
  end;
  setappdata(0,'lddlgpls_settings',settings);
  delete(fig);  
else
  varargout = {[] []};    %figure closed, empty response returned
end

if nargout == 0;
  clear varargout
end

