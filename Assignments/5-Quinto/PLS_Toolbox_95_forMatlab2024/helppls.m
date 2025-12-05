function helppls(varargin)
%HELPPLS Context related help on the PLS_Toolbox.
% With no inputs, helppls goes to the main help page. With an input, the
% given HTML help page is opened.
%
%I/O: helppls
%I/O: helppls pagename.html
%
%See also: help pls_toolbox, <functionname> help

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

try
  if nargin==0 | isempty(varargin{1})
    page = 'main_page.html';
  else
    page = varargin{1};
  end
  
  if isempty(findstr(lower(page),'.html'));
    %add HTML if not there
    [page,section] = strtok(page,'#');
    if exist('isdeployed') & isdeployed
      %Have section in page URL causes error in Solo for some reason.
      page = [page '.html'];
    else
      page = [page '.html' section];
    end
  end
  
  hmain = fileparts(mfilename('fullpath'));
  hmain = fullfile(hmain,'help',page);
  web(hmain)
catch
  error('Can''t dispaly help pages. Please contact helpdesk@eigenvector.com.')
end
