function summ = summary(varargin)
%SUMMARY Summary statistics for a data vector.
%  The input is a data matrix (x) (numeric or DataSet object) and the
%  output is a DataSet object array with the following statistics reported
%  as rows for each column of x:
%    mean  = mean,
%    std   = standard deviation,
%    min   = minimum,
%    max   = maximum,
%    p10   = 10th percentile,
%    p25   = 25th percentile,
%    p50   = 50th percentile,
%    p75   = 75th percentile,
%    p90   = 90th percentile,
%    skew  = skewness,
%    kurt  = kurtosis.
%
%  If input x is a multi-dimensional array, the output contains the above
%  statistics for each multi-dimensional column of the array (the result
%  will have the same dimensions on modes 2-n where n = number of modes in
%  x) If summary is called without setting a return value it prints a
%  summary table of up to 20 columns (default), or up to number specified
%  by second input parameter, out to the command window.
%
%I/O: summ = summary(x);     % returns struct
%I/O:        summary(x);     % prints summary text, for up to 20 columns
%I/O: text = summary(x, n);  % returns summary as text, for up to n cols
%I/O:        summary(x, n);  % prints summary text, for up to n columns
%
%See also: MEANS, PCTILE1, PCTILE2

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin<1
  varargin{1} = 'io';
end

if nargin <= 1 & ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics')) %Help, Demo, Options
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

if ~isdataset(varargin{1})
  %if it isn't a dataset... make it one (pretty much the only way we could
  %even get into this function is because it isn't a dataset - so we'll
  %ALWAYS be doing this next line)
  varargin{1} = dataset(varargin{1});
end
%now, call the dataset version of summary
if nargout==0;
  summary(varargin{:});
else
  summ = summary(varargin{:});
end
