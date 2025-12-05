function res = distfit(x,options)
%DISTFIT  Chitest for all distributions
%  Performs a chi-squared test for each distribution in the
%  DF_Toolbox. The results are presented from the most likely
%  data generating distribution to the least likely.
%
%  NOTE: Some distributions will ignore parts of the sample
%    that are not part of the supported range.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%             plots: [ 'none' | {'final'} ]  governs level of plotting.
%
%I/O: res = distfit(x,options);
%
%See also: CHITEST, PLOTQQ

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin<1; x = 'io'; end
if isa(x,'char');
  options.plots = 'final';
  if nargout==0; clear res; evriio(mfilename,x,options); else; res = evriio(mfilename,x,options); end
  return;
end

if nargin < 2
  options = distfit('options');
end

options = reconopts(options,distfit('options'));

if ~isreal(x), error('X must be a real vector') ; end

if min(x) < 0
  x = x - min(x) + .0001 ;
end

dists = {'Beta','Cauchy','Chi squared','Exponential','Gamma',...
  'Gumbel','Laplace','Logistic','Lognormal','Normal',...
  'Pareto','Rayleigh','Triangle','Uniform','Weibull'}' ;

mywarn = warning; warning off;
chi2 = [] ;
pval = [] ;
wbhandle = waitbar(0,'Assessing distributions...');
for i = 1:length(dists)
  try;
    res  = chitest(x,char(dists(i))) ;
  catch
    res.chi2 = nan;
    res.pval = nan;
  end
  chi2 = [chi2 res.chi2] ;
  pval = [pval res.pval] ;
  if ishandle(wbhandle)
    waitbar(i./length(dists),wbhandle)
  else
    error('Stopped by user...')
  end
end
if ishandle(wbhandle)
  delete(wbhandle)
end

try
  if ~any(pval>0)
    % If all P-values = 0, then make the Normal distribution slightly more
    % likely so it will be selected as most likely
    inormal = find(strcmp('Normal', dists));
    pval(inormal) = 1.e-10;
  end
catch
end

[sp,si] = sort(-pval) ;
sp      = -sp;
sn      = dists(si) ;

if strcmp(options.plots,'final')
  content = {'     p-value         Distribution'};
  for i = 1:length(dists)
    val = chi2(si(i)) ;
    if ~isnan(val) & ~isinf(val)
      s = sprintf('     %6.4f             %s',sp(i),char(sn(i))) ;
      content{end+1} = s;
    end
  end
  content{end+1} = 'Ordered from most likely to least likely parent distribution' ;
  content{end+1} = 'P-values are for rejecting the associated distribution' ;
  infobox(content,struct('figurename','Distribution Fit Results'))
end
warning(mywarn);

res = struct('pval',mat2cell(sp',ones(1,length(sp)),1),'dist',sn) ;
