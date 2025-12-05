function [n,ok] = datenumplus(varargin)
%DATENUMPLUS String to serial date number with additional format support.
% Can be used in place of calls to standard datenum function in older
% Matlab versions and still maintain support for unusual date formats (such
% as YYYY-MM-DD format)
% If only one output is requested, any failure to convert a string will
% throw an error. If the second output (ok) is requested, then any failure
% to convert will NOT throw an error, but will instead return 0 (zero) for
% the OK flag. If the string was converted successfully, ok will be
% returned as 1 (one).
%
% The inputs and outputs are identical to the datenum function with the
% exception of the "ok" flag here. 
% In later Matlab versions, has identical behavior to datenum. In earlier
% Matlab versions, when called without a format string, this function will
% attempt to convert "uninterpretable strings" using some common string
% formats which were not formerly supported.
%
%I/O: [n,ok] = datenumplus(d)    %auto-identify date format
%
%See also: DATENUM

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

try
  n = datenum(varargin{:});
catch
  %error = bad date format
  le = lasterror;  %store error so we can rethrow "nice" error
  n  = nan;         %flag to try other formats
end

if nargin==1 & isnan(n)
  %couldn't auto-process date? Try some other date formats  
  
  %- - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  %list of other formats to check (note that / will always be converted to -
  %so we only need to use - in these strings) These strings need to be in
  %"decreasing" order (most complicated first) or a string might be
  %interpreted without additional time information (for example: yyyy-mm-dd
  %superceedes yyyy-mm-dd HH:MM)

  formats = {
    'yyyy-mm-dd HH:MM:SS' 
    'HH:MM:SS'
    'yyyy-mm-dd HH:MM' 
    'HH:MM'
    'yyyy-mm-dd' 
    'yy-mm-dd'
    'dd-mm-yyyy'
    'dd-mm-yy'
    'yyyymmddTHHMMSS'
    };

  %- - - - - - - - - - - - - - - - - - - - - - - - - - - -

  ds = varargin{1};
  if ischar(ds); ds = str2cell(ds,true); end
  ds = strrep(ds,'/','-');  %replace / with -
  for findex = 1:length(formats)
    try
      n = datenum(ds,formats{findex});
      break;   %if we get here - date was converted without error
    catch
      n = nan;  %error on convert? set to nan to throw error below
    end
  end
end

%didn't process the date correctly?
if isnan(n)
  if nargout>1
    ok = false;
    return
  end
  rethrow(le)  %rethrow ORIGINAL error
end

ok = true;
