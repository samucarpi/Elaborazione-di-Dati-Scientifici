function varargout = setplspref(mfile,options,value)
%SETPLSPREF Set overriding options (preferences) for PLS_Toolbox functions.
% Sets user-defined "overriding default options" for a PLS_Toolbox
% function. These preferences will, for a given function, override any
% factory-default options of the same name. Any option which is defined in
% the factory-defaults but not specified in the user-defined default
% options will remain at the factory-default setting.
%
% Inputs are: (mfile) the function name for which preferences are being
% set. The subsequent inputs can be one of three forms:
%  Form 1: (options) a structure to use as the overriding default options for
%     the given function. Any previous overriding options are erased.
%  Form 2: a string (option) and a value (value) to set a particular option to
%     the specified value. Any other overriding options are left alone and
%     only that one option is changed.
%  Form 3: a string (option) without a value resets the speicified option
%     to the factory default.
%
% If the keyword 'factory' can be used to reset all or some of the options
% back to the factory default values: When given as the mfile name
% (mfile) then all preferences for all functions will be reset; when given
% as the options structure (options), then all options for the named
% function will be reset. When given as the value for a specified option,
% only that option's default is reset.
%
%Examples:
%  options = []; options.plots = 'none'; setplspref('pca',options)
%  setplspref('pca','plots','none');
%  setplspref('pca','factory');
%
%I/O: setplspref(mfile,options)
%I/O: setplspref(mfile,option,value)
%I/O: setplspref(mfile,'factory')  %reset preferences for specified file
%I/O: setplspref('factory')   %reset all preferences to factory settings
%
%See also: GETPLSPREF

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 10/04/02
%JMS 12/02 -added additional 'factory' support and specific preference
%  support
%jms 5/04 -added top-level structure support (e.g info=getplspref; setplspref(info))

%TODO: Remove optionsdef before saving.

if nargin == 0; mfile = 'io'; end
if ischar(mfile) & ismember(mfile,evriio([],'validtopics'));
  varargin{1} = mfile;
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

groupname = 'PLS_Toolbox';

if ~isappdata(0,'PLS_Prefs')
  getplspref('');  %assure we've called getplspref ONCE this session
end

%if mfile is a structure, cycle through fields (assume they are m-file names)
if isa(mfile,'struct');
  for file = fieldnames(mfile)';
    setplspref(file{:},getfield(mfile,(file{:})));
  end
  return
end

%factory default reset
if strcmp(mfile,'factory');
  if ispref(groupname);
    ans = evriquestdlg('Reset all Options Preferences back to Factory Defaults?','Reset Preferences','Yes','Cancel','Cancel');
    if strcmp(ans,'Yes');
      rmpref(groupname);
      setappdata(0,'PLS_Prefs',[]);
      reconopts;  %assure reconopts reloads defaults
      disp('All preferences reset to Factory Defaults');
    end
  else
    disp('No preferences are currently set');
  end
  return
end

if nargin < 2;
  error('Insufficient inputs')
end

if isempty(options) | (isa(options,'char') & strcmp(options,'factory'))
  if ispref(groupname,mfile);
    rmpref(groupname,mfile);
  end
else
  switch class(options)
    case 'struct'
      if length(options)>1;
        error('Input OPTIONS must be a structure with a single record or empty []')
      end
      %Need to remove @optiondefs from options. Function handles cause
      %problems with older versions of ML.
      %TODO: Do we need to check for/remove all function handles?
      if isfield(options,'definitions')
        options = rmfield(options,'definitions');
      end
      setpref(groupname,mfile,options);
    case 'char'
      if nargin<3
        error('Input VALUE is required when modifying a specific option')
      end
      opts = getplspref(mfile);
      if ischar(value) & strcmp(value,'factory')
        if isfield(opts,options);
          opts = rmfield(opts,options);
        end
      else
        if isempty(opts)
          opts = [];
        end
        opts = setfield(opts,options,value);
      end
      setpref(groupname,mfile,opts);
  end
end

%read prefs into memory for faster access
setappdata(0,'PLS_Prefs',getpref('PLS_Toolbox'));

reconopts;  %assure reconopts reloads defaults

