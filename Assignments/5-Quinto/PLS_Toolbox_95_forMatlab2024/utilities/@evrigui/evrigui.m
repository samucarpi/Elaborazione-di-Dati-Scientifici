function obj = evrigui(varargin)
%EVRIGUI Create EVRIGUI object as access to Eigenvector GUI.
% Opens a GUI from PLS_Toolbox of a given type and provides an EVRIGUI
% interface object to that GUI. Can also attach to an existing GUI if given
% the handle of that GUI.
%
% Input is either a string identifying the GUI type (see 'types' below) or
% a handle of an existing GUI to attach to. To avoid opening a new GUI of a
% given type, add the keyword '-reuse' to the inputs. This will locate and
% attach to an existing GUI of the specified type. If none is found, a new
% one will be opened.
%
% To list the valid types of GUIs which can be attached to, use the keyword
% 'types':
%     evrigui('types')
%
%I/O: obj = evrigui('guitype')
%I/O: obj = evrigui('guitype',...)     %pass additional options to GUI
%I/O: obj = evrigui('guitype','-reuse',...)  %attach to existing GUI
%I/O: obj = evrigui(handle)
%
%See also: ANALYSIS, BROWSE

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

obj = struct('type','','handle',[],'interface',[],'evriguiversion',1.0);

if nargin<1 | isempty(varargin{1})
  obj = class(obj,'evrigui');
  return;
end

%run through possible types and see if we can find creation functions
validtypes = {};
for type = {'analysis' 'browse' 'preprocess' 'editds' 'plotgui' 'trendtool'};
  if exist(['evrigui_' type{:}])
    validtypes{end+1} = type{:};
  end
end

%---------------------------------------------------------------
if ishandle(varargin{1})
  %Got a handle, see if we can tell what kind of GUI this is
  handle = varargin{1};
  tag = lower(get(handle,'tag'));
  switch tag
    case validtypes
      varargin{1} = tag;
    otherwise
      varargin{1} = 'unknown';
  end
elseif ~ischar(varargin{1})  
  error('GUI handle or type expected')
else
  handle = [];
end

if ischar(varargin{1}) & strcmpi(varargin{1},'types')
  if nargout == 0
    disp('Valid EVRIGUI Types:');
    disp(sprintf('  %s\n',validtypes{:}));
    clear obj
  else
    obj = validtypes;
  end
  return
end

if ~exist(['evrigui_' varargin{1}])
  error('GUI Type not valid. Use "evrigui types" command to list valid types');
end

%---------------------------------------------------------------
%create object given successful GUI creation
obj.type   = varargin{1};
obj.handle = handle;
try
  obj.interface = feval(['evrigui_' obj.type]);
catch
  disp(lasterr)
  error('Unable to create interface to GUI of type "%s"',obj.type)
end
obj = class(obj,'evrigui');

if isempty(handle);
  %check for instruction to reuse existing figure (attach to existing)
  strs = cellfun('isclass', varargin, 'char');
  if ismember('-reuse',varargin(strs))
    h = findobj(allchild(0),'tag',expectedtag(obj.interface,obj));
    if ~isempty(h);
      %could we find an existing handle? return it
      handle = h(1);
    end
    varargin(ismember(varargin,'-reuse')) = [];
  end
  
  if isempty(handle);
  %create GUI using method of interface object and get handle info
    handle = create(obj.interface,obj,varargin{2:end});
  end
  obj.handle = handle;
  
end

%NEW GUI TYPES:
% Create a new EVRIGUI_TYPE folder:
%     @EVRIGUI_TYPE   (where "type" is replaced with GUI type name)
%
% The following methods are REQUIRED for a new GUI type and need to be
% created custom for the GUI type (see EVRIGUI_ANALYSIS for example
% templates)
%
%    .create       : creates new GUI and passes back handle
%    .expectedtag  : gives text expected for tag on the given GUI type
%
% The following methods are REQUIRED for a new GUI type but can be copied
% from an existing EVRIGUI_TYPE object (generic code)
%
%    .evrigui_type    (where "type" is replaced to match folder name)
%    .subsref      
%    .disp
%    .display
%    .encodexml
%    .validmethod
%
% All methods for GUI types must have the following I/O:
%    out = method(obj,parent,varargin)
% obj will be the EVRIGUI_TYPE object and parent will be the parent EVRIGUI
% object. varargin will be any additional inputs.

