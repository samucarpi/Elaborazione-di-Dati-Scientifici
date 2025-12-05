function [filename, pathname, filterindex] = evriuiputfile(varargin)
%EVRIUIPUTFILE Overload putfile function for directory management.
%In PLS Mode - does nothing.
%In solo, change pwd to whatever was selected. 
%
%I/O: [filename, pathname, filterindex] = evriuiputfile(filterspec, title, file);
%
%See also: EVRIUIGETDIR, EVRIUIPUTFILE, UIGETDIR, UIGETFILE

%Copyright Eigenvector Research, Inc 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 09/12/06

settings = getappdata(0,'lddlgpls_settings');

% if nargin ==0
%   varargin{1} = '';
% end
% 
% cmdlist = {'location' 'multiselect'};
% if ~isempty(settings) & isfield(settings,'tofile') & isempty(varargin{3}) & ~ismember(lower(varargin{3}),cmdlist)
%   varargin{3} = fileparts(settings.tofile);
% end

[filename, pathname, filterindex] = uiputfile(varargin{:});

if filename
  if exist('isdeployed') & isdeployed
    cd(pathname)
  end
  settings = getappdata(0,'lddlgpls_settings');
  settings.tofile = pathname;  %uncomment only for uiputfile
  setappdata(0,'lddlgpls_settings',settings);
end
