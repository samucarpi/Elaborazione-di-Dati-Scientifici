function string = ck_function(string)
%CK_FUNCTION Validates distribution function string.
%  Translates various function string names into internal keyword
%  Current pseudonyms:
%     'cumulative' 'c' 'cdf' 
%     'density'    'd' 'pdf'
%     'quantile'   'q' 'inv' 'inverse'
%     'random'     'r'
%
%     where 
%       cdf = cumulative distribution function.
%       pdf = probability density function.
%
%       See the following web page for more information:
%
%       http://www.itl.nist.gov/div898/handbook/eda/section3/eda362.htm
%
%I/O: string = ck_function(string);
%
%See also: ENSUREP

% Copyright © Eigenvector Research, Inc. 2003
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
% NBG 04/03
% JMS 12/05 -revsied and added extra pseudonyms
% rsk 12/14/05 - change pseudonym terminology.

switch lower(string)
  case {'cumulative' 'c' 'cdf'}
    string = 'cumulative';
  case {'density' 'd' 'pdf'}
    string = 'density';
  case {'quantile' 'q' 'inv' 'inverse'}
    string = 'quantile';
  case {'random' 'r'}
    string = 'random';
  otherwise
    error(['Keyword not recognized (' string '). First input to Distribution'...
      ' Function must be a recognized method category ("cumulative", "density", "quantile", "random").'])
end
