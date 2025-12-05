function [pathname] = evriuigetdir(varargin)
%EVRIUIGETDIR Overload putfile function for directory management.
%In PLS Mode - does nothing.
%In solo, change pwd to whatever was selected. 
%
%I/O: [pathname] = evriuigetdir(start_dir, title);
%
%See also: EVRIUIGETFILE, EVRIUIPUTFILE, UIGETFILE, UIPUTFILE

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
% if ~isempty(settings) & isfield(settings,'fromfile') & isempty(varargin{1})
%   varargin{1} = fileparts(settings.fromfile);
% end

[pathname] = uigetdir(varargin{:});

if pathname
  if exist('isdeployed') & isdeployed
    cd(pathname)
  end
  settings.fromfile = pathname;  %uncomment only for uigetfile
  setappdata(0,'lddlgpls_settings',settings);
end

