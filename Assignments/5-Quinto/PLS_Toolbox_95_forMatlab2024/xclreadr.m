function out = xclreadr(varargin)
%XCLREADR Reads an ASCII or .XLS file in as a DataSet Object.
% Wrapper for TEXTREADR.
%
%I/O: out = xclreadr(file,delim,options);
%
%See also: AREADR, DATASET, SPCREADR, TEXTREADR, XCLGETDATA, XCLPUTDATA, XLSREADR

% Copyright © Eigenvector Research, Inc. 1998
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified BMW 11/2000
% 8/02 bmw converted output to dataset object
% 8/02 jms added error checking for missing delimiter, strange line
% lengths, etc.
% 11/03 jms -close file if errors occur
%   -automatic detection of delimiter
%   -added ability to read from microsoft XLS files using xlsread
% 2/04 jms -moved xls read code into separate file
%   -fixed one-column-of-data bug
%   -added row/col lables options
% 3/2/04 jms -fixed zero-input bug
% 6/5/04 bmw -added conversion for time and date variables
% 2/3/04 jms -added headerrows option to read off non-delimited rows on top

if nargout==0
  textreadr(varargin{:});
else
  out = textreadr(varargin{:});
end
