function pls_toolboxhelp(varargin)
%PLS_TOOLBOXHELP Utility for INFO.XML.
%  PLS_TOOLBOXHELP is a single-entry point for access to various manuals
%  and website materials via a keyword:
%    man = Chemometrics Tutorial (PDF)
%    ref = Function reference manual
%    dso = DataSet object manual
%    calt = Calibration Transfer Getting Started guide
%    faq    = FAQ (online)
%    movies = Eigenguide Movies (online)
%    web    = Eigenvector main website (online)
%
%I/O: pls_toolboxhelp

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%jms -stopped using browser (matlab's browser supports load of PDFs)
%rsk 06/08/04 Add keyword so can change file names in one place.
%jms -reactivate using browser for Matlab version 6.1

if nargin<1;
  helpname = 'PLS_Manual.pdf';
else
  %Use keywords 
  switch lower(varargin{1})
    case 'man'
      helpname = 'PLS_Manual.pdf';
    case 'ref'
      helpname = 'pls_toolbox_topics.html';
    case 'dso'
      helpname = 'dataset_object.html';
    case 'calt'
      helpname = 'CalibrationTransferGettingStarted.pdf';
    case 'faq'
      web('http://software.eigenvector.com/faq','-browser');
      return
    case 'movies'
      web('http://www.eigenvector.com/eigenguide.php','-browser');
      return
    case 'web'
      web('http://www.eigenvector.com/','-browser');
      return
    otherwise
      helpname = varargin{1};
  end
  
end
if exist([which(helpname)])~=2
  erdlgpls(['"' helpname '" not found on the MATLAB path.'],'Help')
else
  if checkmlversion('<','6.5') || (exist('isdeployed') && isdeployed)
    web(strrep(which(helpname),[filesep filesep],filesep),'-browser');
  else
    web(which(helpname))%,'-browser');
  end
end 
