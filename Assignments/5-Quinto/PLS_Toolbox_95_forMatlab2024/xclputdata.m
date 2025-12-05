function varargout = xclputdata(filename,datarange,xmat,formt)
%XCLPUTDATA Write matrix to an Excel spreadsheet.
%  Inputs are (filename) a text string containing the
%  file name of the OPEN Excel spreadsheet, (datarange)
%  a text string containing the range in the spreadsheet
%  to place the data matrix in row/column format, and (xmat)
%  a MATLAB matrix to be placed into the Excel spreadsheet. 
%  The size of Excel data range (datarange) must match the
%  dimensions of the matrix (xmat).
%
%  Optional text string input (formt) can be 'numeric' {default}
%  that indicates that numeric data is passed, or
%  'string' indicating that text data is to be passed.
%
%Note: This function only works on a PC and the spreadsheet
%  must be open. For Mac see XLSETRANGE.
%Note: This function is based on DDE.
%
%Example: for a 3 by 5 MATLAB matrix mydat
%     xclputdata('book1.xls','r2c2:r4c6',mydat)
%
%I/O: xclputdata(filename,datarange,xmat,formt);
%
%See also: AREADR, MTFREADR, SPCREADR, TEXTREADR, XCLGETDATA

%Copyright Eigenvector Research, Inc. 1999
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 1/99, 10/00 fixed help
%nbg 1/01 changed 'See Also' to 'See also'
%nbg 3/04 added formt and 'string' capability

if nargin == 0; filename = 'io'; end
if ismember(filename,evriio([],'validtopics'));
  varargin{1} = filename;
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<4
  formt = [1 0]; %numeric data
else
  switch lower(formt)
  case {'n','nu','num','nume','numer','numeri','numeric'}
    formt = [1 0];
  case {'s','st','str','stri','strin','string'}
    formt = [1 1];
  otherwise
    error('Input (formt) not recognized - must be ''numeric'' or ''string''.')
  end
end

chan  = ddeinit('excel',filename);
ddepoke(chan,datarange,xmat,formt);
rc    = ddeterm(chan);
