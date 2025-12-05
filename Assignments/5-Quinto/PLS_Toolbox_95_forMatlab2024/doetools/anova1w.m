function varargout = anova1w(dat,alpha)
%ANOVA1W One-way analysis of variance.
%  Calculates one way ANOVA table and tests significance of
%  between factors variation (it is assumed that each column
%  of the data represents a different treatment). Inputs
%  are the data table (dat) and the optional desired confidence 
%  level (alpha), expressed as a fraction (e.g. 0.99, 0.999).
%  {default = 0.95}. A text table is displayed if no output is requested.
%INPUTS:
%    dat = Data table where columns are factors
%OPTIONAL INPUTS:
%    alpha = desired confidence level expressed as a fraction (default = 0.95)
%OUTPUTS:
%  results = A structure array containing all the contents of the table
%            including the fields:
%           .ssq     : Sum of Squares (with sub-fields for factors,
%                       residual and total)
%           .dof     : Degrees of Freedom (with sub-fields for factors,
%                       residual and total)
%           .mean_sq : Mean Square (with sub-fields for factors and residual)
%           .F       : F-test value for factors
%           .F_crit  : F-test critical value (for given alpha)
%           .alpha   : provided alpha
%           .p       : p-value for F-test value (alpha where F is significant)
%           .table   : cell array containing the the text description of the
%                       results (same as displayed with no outputs).
%
%I/O: anova1w(dat,alpha)
%I/O: results = anova1w(dat,alpha)
%
%See also: ANOVADOE, ANOVA2W, FTEST, STATDEMO

% Copyright © Eigenvector Research, Inc. 1994
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified NBG 1996
%Checked on MATLAB 5 by BMW  1/4/97, 3/99
%Modified BMW 12/98 via Paul Gemperline
%jms 3/02 updated help io
%bmw 8/02 updated to accept dataset object

if nargin==0; dat = 'io'; end
if ischar(dat);
  options = [];
  if nargout==0; evriio(mfilename,dat,options); else; varargout{1} = evriio(mfilename,dat,options); end
  return; 
end

if isa(dat,'dataset')
  inds = dat.includ;
  dat = dat.data(inds{:});
end
if nargin == 1
  alpha = 0.95;
end
[n,k]     = size(dat);
a_mean    = mean(mean(dat));
a_tr_mean = mean(dat);

sst     = sum(sum((dat - a_mean).^2));
sstr    = n*sum((a_tr_mean - a_mean).^2);
sse     = sum(sum((dat - a_tr_mean(ones(1,n),:)).^2));

msstr   = sstr/(k-1);
msse    = sse/((n-1)*k);
ff      = msstr/msse;
doff    = k-1;
dofr    = (n-1)*k;
doft    = doff+dofr;

desc = {};
desc = add(desc,'  ');
desc = add(desc,'___________________________________________________________');
desc = add(desc,'  Source of           Sum  of        Degrees          Mean');
desc = add(desc,'  Variation           Squares      of  Freedom       Square');
desc = add(desc,'___________________________________________________________');
s = sprintf('Between factors   %11.5g       %4.0f        %10.4g',sstr,doff,msstr);
desc = add(desc,s);
desc = add(desc,'(columns)');
s = sprintf('Residual          %11.5g       %4.0f        %10.4g',sse,dofr,msse);
desc = add(desc,s); 
desc = add(desc,'  ');
s = sprintf('Total             %11.5g       %4.0f',sst,doft);
desc = add(desc,s);
desc = add(desc,'  ');
s = sprintf('Effect of factor = %g/%g = %g',msstr,msse,ff);
desc = add(desc,s);
desc = add(desc,'  ');
fstatf = ftest(1-alpha,k-1,(n-1)*k);
pc = (alpha)*100;
s = sprintf('F at %g percent confidence = %g',pc,fstatf); 
desc = add(desc,s);
if fstatf < ff
  desc = add(desc,sprintf('Effect of factors IS significant at %g percent confidence level',alpha*100));
else
  desc = add(desc,sprintf('Effect of factors IS NOT significant at %g percent confidence level',alpha*100));
end
p = ftest(ff,k-1,(n-1)*k,2);
s = sprintf('Probability of null hypothesis, p = %g',p);
desc = add(desc,s);
desc = add(desc,'  ');

if nargout==0
  disp(char(desc))
else
  out = [];
  out.ssq.factors = sstr;
  out.ssq.residual = sse;
  out.ssq.total = sst;
  
  out.dof.factors = doff;
  out.dof.residual = dofr;
  out.dof.total = doft;
  
  out.mean_sq.factors = msstr;
  out.mean_sq.residual = msse;
  
  out.F      = ff;
  out.F_crit = fstatf;
  out.alpha  = alpha;
  out.p      = p;
  
  out.table = desc;
  
  varargout{1} = out;
  
end

%----------------------------------------
function s = add(s,item);
s{end+1,1} = item;


