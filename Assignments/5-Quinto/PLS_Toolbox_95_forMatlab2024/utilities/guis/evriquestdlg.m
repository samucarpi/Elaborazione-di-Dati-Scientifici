function varargout = evriquestdlg(varargin)
%EVRIQUESTDLG Overload standard question dialog for automation management.
% Operation of this function is nearly identical to the standard Matlab
% QUESTDLG except that this function will intercept calls through an
% automation interface and return the default value (if available) without
% bringing up the actual dialog box.
%
% For I/O options, see the QUESTDLG function.
%
%See also: ERDLGPLS, EVRIHELPDLG, EVRIMSGBOX, EVRIWARNDLG

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%check if we're currently processing an automation call
if inevriautomation
  %locate default option among inputs
  strs = cellfun('isclass',varargin,'char');
  strs(1:2) = false;  %NEVER consider first two as options
  if nargin<3
    %No buttons named? using standard buttons, Yes will be default always.
    default = 'Yes';
  elseif nargin==3 & ischar(varargin{3})
    %Only a default option given? Choose it
    default = varargin{3};
  elseif ischar(varargin{end}) & sum(ismember(varargin(strs),varargin{end}))==2
    %last value is a string which matches another button name string?
    default = varargin{end};
  elseif isstruct(varargin{end}) & isfield(varargin{end},'default')
    %last value is a structure with a "default" field?
    default = varargin{end}.default;
  elseif any(strs);
    %No other option - choose first string
    default = varargin(min(find(strs)));
  else
    error('Unable to automatically answer question: %s',varargin{1});
  end
%   disp(['*** ' varargin{1} ' Answering: ' default])
  varargout = {default};
  return
end

if nargout>0
  [varargout{1:nargout}] = questdlg(varargin{:});
else
  questdlg(varargin{:});
end
