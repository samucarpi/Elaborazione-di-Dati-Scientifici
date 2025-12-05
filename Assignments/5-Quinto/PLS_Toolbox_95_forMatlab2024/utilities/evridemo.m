function varargout = evridemo(mfile)
%EVRIDEMO Start demo for a given mfile.
%  Input (mfile) is the name of the m-file for which demo is desired
%
%I/O: evridemo(mfile)

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
% JMS 5/13/03 -generalized so demos outside of dems folder can be run

if nargin == 0; mfile = 'io'; end
if ischar(mfile) & ismember(mfile,evriio([],'validtopics'));
  varargin{1} = mfile;
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if checkmlversion('>=','7')
  commandwindow
end

disp([' Also use: '])
disp(['        ' mfile ' io             %for short I/O for this function'])
disp(['        ' mfile ' help           %for extended help on this function'])

%Are there options for this function?
try
  opts = feval(mfile,'options');
catch
  opts = [];
end
if ~isempty(opts);
  disp(['        ' mfile ' options        %for help on options for this function'])
  disp([' opts = ' mfile '(''options'')     %for default options structure'])
end
disp([' ']);

% demofolder = [fileparts(fileparts(which(mfilename))) filesep 'dems' filesep];
demofile = [mfile 'demo.m'];
if exist(demofile)==2
  saferun(which(demofile));
  
  hlp = help(mfile);
  s = [''];
  sas  = findstr(hlp,'See also:');
  for i2 = sas;
    i3  = i2+min(find(hlp(i2:end)==10))-2;
    s = char(s,[' ' hlp(i2:i3)]);
  end
  disp(s);
  
else
%   if ~exist(demofolder)
%     disp(['Demos folder not found. Not loaded?']);
%   else
    disp(['No Demo of the ',mfile,' function is available.'])
%   end
end

%-------------------------------
function saferun(ans)
run(ans);
