function [filename, pathname, filterindex] = evriuigetfile(varargin)
%EVRIUIGETFILE Overload getfile function for directory management.
%In PLS Mode - does nothing special over standard uigetfile. In solo,
%change pwd to whatever was selected. See uigetfile for more information.
%
% Also sorts output list of filenames into alphabetical order unless the
% setplspref option 'sortfiles' has been set to zero (false).
%
%I/O: [filename, pathname, filterindex] = evriuigetfile(filterspec, title, file);
%
%See also: EVRIUIGETDIR, EVRIUIPUTFILE, UIGETDIR, UIPUTFILE

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
% cmdlist = {'location'};
% if ~isempty(settings) & isfield(settings,'fromfile') & isempty(varargin{3}) & ~ismember(lower(varargin{3}),cmdlist)
%   varargin{3} = fileparts(settings.fromfile);
% end

if checkmlversion('<','7')
  %version 6.5 doesn't allow multiselect
  todel = [];
  for j=1:length(varargin); 
    if ischar(varargin{j}) & strcmpi(varargin{j},'multiselect'); 
      todel = [j j+1]; 
    end 
  end
  varargin(todel) = [];
end

[filename, pathname, filterindex] = uigetfile(varargin{:});

if iscell(filename) | filename
  frtn = 1;
else
  frtn = 0;
end

if frtn
  if iscell(filename) & length(filename)>1
    %unless user has set sortfiles to be zero (false), sort filenames
    sortflag = getplspref('evriuigetfile','sortfiles');
    if isempty(sortflag) | sortflag
      filename = sort(filename);
    end
  end
  
  if exist('isdeployed') & isdeployed
    cd(pathname)
  end
  settings = getappdata(0,'lddlgpls_settings');
  settings.fromfile = pathname;  %uncomment only for uigetfile
  setappdata(0,'lddlgpls_settings',settings);
end
