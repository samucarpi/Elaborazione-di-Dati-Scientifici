function opts = reconopts(options,defaults,filterunused)
%RECONOPTS Reconcile options structure with defaults.
% Assures that input options strucutre (options) has all the necessary
% fields by checking against the default options structure for a given
% function name indicated in the string (mfilename). Any fields missing
% from (options) will be set to the default value retrieved for
% (mfilename).
%
% The optional input (filterunused) is a flag indicating how to handle
% options which do not appear in the defaults list ("unexpected options").
% It can be any of the following, the default is [2]:
%     [0]   = allow unexpected options (pass through without filtering)
%     [1]   = silently filter out unexpected options (cull all)
%     [2]   = throw error if unexpected options are found
%     {...} = cell array of strings giving the names of options which
%             should be permitted without filtering. Any other unexpected
%             options will throw an error. Example: {'junk_option' 'a'}
% The action taken when an unexpected option is passed can be modified by
% setting the 'missingaction' preference for reconopts using the setplspref
% command:
%     setplspref('reconopts','missingaction','action')
% where 'action' can be any of the following:
%     'error'   : throw an error
%     'warning' : display a warning message
%     'display' : display a message in the command window (does not trigger
%                 warning flag)
%     'none'    : do nothing - similar to resetting all filterunused
%                 values to 0 (no errors ever thrown or display given.)
% The default value is 'none'.
%
%I/O: options = reconopts(options,mfilename,filterunused);
%
%Example: The following fills in missing pls options
%   options.plots = 'off';
%   options = reconopts(options,'pls');
%
%See also: MAKESUBOPS

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 5/16/02
%JMS 7/22/02 -added support for empty "options" input
%RSK 02/16/05 -add support for nested structures.
%JMS 9/26/05 -added "filterunused" flag as extra input

%The old format of input (options,default) is still supported for
%compatibility. 

% NOTE: HIDDEN FEATURE:
% If options contains a field named "norecon" with ANY VALUE,
%  then the default options are NOT retrieved and no reconcilliation is
%  done. This can speed up loops in which the default options have already
%  been retrieved and have been verified.

persistent storeddefaults

if nargin==0
  %no inputs = clear stored defaults
  storeddefaults = [];
  return;
end
if ischar(options);
  doptions = [];
  if nargout==0; clear opts; evriio(mfilename,options,doptions); else; opts = evriio(mfilename,options,doptions); end
  return; 
end

if nargin <2;
  error('Input DEFAULTS is missing');
end

%list of options which, if present do NOT throw error (if filterunused==2)
allowedextras = {'rawmodel'};
if nargin<3;
  %no flag passed, use this as default
  filterunused = 2;
  recursive = filterunused;  %what to use on a recursive call
else
  %filterunused specified
  recursive = filterunused;   %what to use on a recursive call
  if iscell(filterunused)
    %cell? it is the options which are OK if found
    allowedextras = filterunused;
    filterunused = 2;
  end
end


if isfield(options,'norecon');  %add a field named "norecon" to avoid reconopts from processing defaults
  opts = options;
  return
end

if isa(defaults,'char');
  fn = defaults;
  if isfield(storeddefaults,fn);
    defaults = storeddefaults.(fn);
  else
    defaults = feval(fn,'options');
    storeddefaults.(fn) = defaults;
  end  
else
  if ~isempty(defaults) & (prod(size(defaults))>1 | ~isa(defaults,'struct'));
    error('Input DEFAULTS must be a structure with a single record')
  end
end

if isempty(options);
  opts = defaults;
  return
end

if prod(size(options))~=1 | ~isa(options,'struct')
  error('Input OPTIONS must be a structure with a single record')
end

optsfields = fieldnames(options);

for k = optsfields';
  %Recursive call if k for both options and default are single-record structures
  if (   isstruct(options.(k{:})) ...
      && isfield(defaults,k{:}) ...
      && isstruct(defaults.(k{:})) ...
      && ~strcmp(k{:},'definitions') ...
      && length(defaults.(k{:}))==1 ...
      && length(options.(k{:}))==1 )
    cstrct = reconopts(options.(k{:}),defaults.(k{:}),recursive);
    defaults.(k{:}) = cstrct;
  elseif ~isstruct(options.(k{:})) & isfield(defaults,k{:}) & isstruct(defaults.(k{:}))
    error(['Expecting structure data type for field ''' k{:} '''. Check options assignment.']);
  else
    switch filterunused
      case 0
        %pass all
      case 1
        %filter out bad options
        if ~isfield(defaults,k{:})
          continue;
        end
      case 2
        %throw error for bad options
        if ~isfield(defaults,k{:}) & ~ismember(k{:},allowedextras)
          if ~isfield(defaults,'functionname')
            if isfield(options,'functionname');
              defaults.functionname = options.functionname;
            else
              defaults.functionname = '???';
            end
          end
          logfolder = getplspref('reconopts','logfolder');
          if ~isempty(logfolder) & exist(logfolder,'file')
            stk = dbstack;
            stk = stk(2);
            fid = fopen(fullfile(logfolder,'badoptions.txt'),'a');
            fprintf(fid,'%s : %s OPTION "%s" NOT EXPECTED IN   %s / %s @ %i\n',datestr(now,31),defaults.functionname,k{:},stk.file,stk.name,stk.line);
            fclose(fid);
          end
          message = ['Invalid option "' k{:} '" passed to function: ' defaults.functionname];
          %decide how to act on this issue
          switch char(getplspref('reconopts','missingaction'))
            %put '' into case statement that should be default
            case {'error'}
              error(message);
            case {'warn' 'warning'}
              warning('EVRI:ReconoptsMissing',message);
            case {'disp' 'display'}
              disp(message);
            case {'none' ''}
              %do nothing
          end
        end
    end
    defaults.(k{:}) = options.(k{:});
  end
end
opts = defaults;

