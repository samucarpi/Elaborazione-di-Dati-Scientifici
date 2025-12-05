function out = df(method,x,a,b,options)
%DF zzz distribution function.
%  INPUTS:
%     method = string defining type of request (see below).
%     Additional inputs depend on method string.
%         a = real scalar, alpha "location" parameter.
%         b = real scalar, beta "scale" parameter.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields used:
%
%I/O:  cumulative = expdf('cumulative',x,options)
%            x is ordinate in range (-inf,inf)
%            f(x) = 
%I/O:  density = expdf('density',x,options)
%            x is ordinate in range (-inf,inf)
%            density is f(x) density distribution at x.
%            f(x) = 
%I/O:  quantile = expdf('quantile',u,options)
%            u is cummulative distribution at q in range (-inf,inf)
%            quantile is Q ordinate.
%            f(x) = 
%I/O:  random = expdf('random',n,options)
%            n is the number of random numbers to generate
%            random is vector of random numbers drawn from f(x).
%
%See also: BETADF, CAUCHYDF, CHIDF, EXPDF, GAMMADF, LAPLACEDF, LOGISDF, LOGNORMDF, NORMDF, PARETODF, RAYDF, TRIDF, UNIFDF, WEIBULLDF

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; method = 'io'; end
if ischar(method) & ismember(method,evriio([],'validtopics'));
  options = [];
  if nargout==0; evriio(mfilename,method,options);
  else;          out = evriio(mfilename,method,options);
  end
  return;
end

method = ck_function(method);
switch lower(method)

  case 'cumulative'

  case 'density'

  case 'quantile'
    if ~isprob(x), error('Input x must be probability values: 0<=x<=1.'), end
    
  case 'random'

  otherwise
    disp('Method not recognized, output not assigned.')
    out     = [];
end
