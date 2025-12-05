function xmat = xclgetdata(filename,datarange,formt)
%XCLGETDATA Extracts matrix from an Excel spreadsheet.
%  Inputs are (filename) a text string containing the
%  file name of the OPEN Excel spreadsheet and (datarange)
%  a text string containing the range in the spreadsheet
%  that contains the data matrix in row/column format.
%
%  Optional text string input (formt) can be 'numeric' {default}
%  that indicates that numeric data is to be read in, or
%  'string' indicating that text data is to be read in.
%
%  The output (xmat) is the MATLAB matrix.
%
%Note: This function only works on a PC and the spreadsheet
%  must be open in Office 97 or higher.
%Note: This function is based on DDE.
%
%Example: to get a table of data from the range C2 to T25
%  from sheet2 the open workbook 'book1.xls':
%     data = xclgetdata('book1.xls\Sheet2','r2c3:r25c20')
%
%I/O: xmat = xclgetdata(filename,datarange,formt);
%
%See also: AREADR, MTFREADR, SPCREADR, TEXTREADR, XCLPUTDATA, XLSREADR

%Copyright Eigenvector Research, Inc. 1999
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 1/99
%nbg 11/00 added XCLREADR
%nbg 1/01 changed 'See Also' to 'See also'
%nbg 3/04 added formt and 'string' capability

if nargin == 0; filename = 'io'; end
if ismember(filename,evriio([],'validtopics'));
  varargin{1} = filename;
  options = [];
  if nargout==0; clear xmat; evriio(mfilename,varargin{1},options); else; xmat = evriio(mfilename,varargin{1},options); end
  return; 
end
if nargin<3
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
xmat  = ddereq(chan,datarange,formt);
rc    = ddeterm(chan);
