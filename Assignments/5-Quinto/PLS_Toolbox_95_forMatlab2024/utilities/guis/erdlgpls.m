function varargout = erdlgpls(txtstring,namestring,varargin)
%ERDLGPLS Error dialog.
%  ERDLGPLS creates an error dialog box with the
%  name (namestring) and an error message provided
%  by (txtstring). ERDLGPLS is called by DECOMPOSE and REGRESSION.
%
%I/O: erdlgpls(txtstring,namestring);
%
%See also: EVRIHELPDLG, EVRIMSGBOX, EVRIQUESTDLG, EVRIWARNDLG, LDDLGPLS, SVDLGPLS

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 4/97 

if nargin == 0; txtstring = 'io'; end
varargin{1} = txtstring;
if ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics'));
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<2
  namestring = '';
end

if inevriautomation
  %if in automation THROW error, don't give warning
  if iscell(txtstring); txtstring = sprintf('%s\n',txtstring{:}); end
  %first check if lasterror contains same info
  le = lasterror;   %get complete last error info
  letxt = lasterr;  %get plain-text version (which may match txtstring)
  if ~isempty(strfind(txtstring,letxt));
    rethrow(le);
  end
  %otherwise, just throw txtstring as error
  error(txtstring);
end


le = lasterror;
teststring = txtstring;
if iscell(teststring); teststring = [teststring{:}]; end
if ~isempty(findstr(teststring,le.message))
  %lasterror appears to match text string to some extent, give option to
  %report this error
  answer = questdlg(txtstring,namestring,'OK','Request Help','OK');
  if strcmp(answer,'Request Help')
    evrireporterror
    return
  end
else
  h = msgbox(txtstring,namestring,'error','modal');
  
  if ishandle(h);
    uiwait(h);   %if it's still here, wait for it to close
  end
end

%(can't return handle anymore because box was "modal" and will be gone by the time we're done)
%drawnow;
%if nargout > 0; varargout = {h}; end
