function success = evrihelp(mfile,browser)
%EVRIHELP Provide help on a given topic for a given mfile.
% Input (mfile) is the name of the m-file on which help is desired
%  optional input (browser) indicates that the given file should be forced
%  to be opened in the system browser rather than the Matlab web browser.
% Output (success) returns 1 (one) if help was found, 0 (zero) if not.
%I/O: success = evrihelp(mfile,browser)

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; mfile = 'io'; end
if ischar(mfile) && ismember(mfile,evriio([],'validtopics'));
  varargin{1} = mfile;
  options = [];
  if nargout==0; clear success; evriio(mfilename,varargin{1},options); else; success = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<2; browser = 0;end
if browser;
  browser = {'-browser'};
else
  browser = {};
end
helpfolder = [fileparts(fileparts(which(mfilename))) filesep 'help' filesep];
helpfile = [mfile '.html'];
if exist([helpfolder helpfile],'file')
  web([helpfolder helpfile],browser{:})
  success = 1;
else
  if nargout==0
    if ~exist(helpfolder)
      disp(['Help folder not found. Not installed?']);
    else
      %no local copy? get web version
      disp(['No local extended help for the topic ',mfile,' is available; checking on-line documentation...'])
      web(['http://wiki.eigenvector.com/index.php?title=' mfile],browser{:});
    end
  end
  success = 0;
end

if nargout == 0;
  clear success
end
