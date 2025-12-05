function varargout = anova2w(dat,alpha)
%ANOVA2W Two-way analysis of variance.
%  Calculates two way ANOVA table and tests significance of
%  between factors variation (it is assumed that each column
%  of the data represents a different factor) and between
%  blocks variation (it is assumed that each row represents
%  a block). Inputs are the data table (dat) and the optional
%  desired confidence level (alpha), expressed as a fraction
%  (e.g. 0.99, 0.999) {default is 0.95}. A text table is displayed if no
%  output is requested.
%INPUTS:
%    dat = Data table where columns are factors and rows are blocks
%OPTIONAL INPUTS:
%    alpha = desired confidence level expressed as a fraction (default = 0.95)
%OUTPUTS:
%  results = A structure array containing all the contents of the table
%            including the fields:
%           .ssq     : Sum of Squares (with sub-fields for factors, blocks,
%                       residual and total)
%           .dof     : Degrees of Freedom (with sub-fields for factors,
%                       blocks, residual and total)
%           .mean_sq : Mean Square (with sub-fields for factors, blocks,
%                       and residual)
%           .F       : F-test value for factors (with sub-fields for
%                       factors and blocks)
%           .F_crit  : F-test critical value for given alpha (with
%                       sub-fields for factors and blocks)
%           .alpha   : provided alpha
%           .p       : p-value for F-test value (alpha where F is
%                       significant; with sub-fields for factors and blocks)
%           .table   : cell array containing the the text desription of the
%                       results (same as displayed with no outputs).
%
%I/O: anova2w(dat,alpha)
%I/O: results = anova2w(dat,alpha)
%
%See also: ANOVADOE, ANOVA1W, FTEST, STATDEMO

% Copyright © Eigenvector Research, Inc. 1994
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified NBG 1996
%Checked on MATLAB 5 by BMW  1/4/97,3/99
%Modified BMW 12/98 via Paul Gemperline

if nargin==0; dat = 'io'; end
varargin{1} = dat;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if isa(dat,'dataset')
  inds = dat.includ;
  dat = dat.data(inds{:});
end
if nargin == 1
  alpha = 0.95;
end
[n,k] = size(dat);
xbar  = mean(mean(dat));
xbari = mean(dat);
xbarj = mean(dat');

sst   = sum(sum((dat - xbar).^2));
sstr   = n*sum((xbari - xbar).^2);
ssb  = k*sum((xbarj - xbar).^2);

doff  = k-1;
dofb  = n-1;
dofr  = doff*dofb;
doft  = dofr+dofb+doff;

sse   = sst - sstr - ssb;
mssb  = ssb/(dofb);
msstr = sstr/(doff);
msse  = sse/(dofr);
ff    = msstr/msse;
fb    = mssb/msse;

desc = {};
desc = add(desc,'  ');
desc = add(desc,'___________________________________________________________');
desc = add(desc,'  Source of           Sum  of        Degrees          Mean');
desc = add(desc,'  Variation           Squares      of  Freedom       Square');
desc = add(desc,'___________________________________________________________');
s = sprintf('Between factors   %11.5g       %4.0f        %10.4g',sstr,doff,msstr);
desc = add(desc,s);
desc = add(desc,'(columns)');
s = sprintf('Between blocks    %11.5g       %4.0f        %10.4g',ssb,dofb,mssb);
desc = add(desc,s);
desc = add(desc,'(rows)');
s = sprintf('Residual          %11.5g       %4.0f        %10.4g',sse,dofr,msse);
desc = add(desc,s); 
desc = add(desc,'  ');
s = sprintf('Total             %11.5g       %4.0f',sst,doft);
desc = add(desc,s); 
desc = add(desc,'  ');
s = sprintf('Effect of factor = %g/%g = %g',msstr,msse,ff);
desc = add(desc,s);
fstatf = ftest(1-alpha,doff,dofr);
pc = alpha*100;
s = sprintf('F at %g percent confidence = %g',pc,fstatf);
desc = add(desc,s);
if fstatf < ff
  desc = add(desc,sprintf('Effect of factors IS significant at %g percent confidence',alpha*100));
else
  desc = add(desc,sprintf('Effect of factors IS NOT significant at %g percent confidence',alpha*100));
end
pf = ftest(ff,doff,dofr,2);
s = sprintf('Probability of null hypothesis for factors, p = %g',pf);
desc = add(desc,s);
desc = add(desc,'  ');
s = sprintf('Effect of block  = %g/%g = %g',mssb,msse,fb);
desc = add(desc,s);
fstatb = ftest(1-alpha,dofb,dofr);
s = sprintf('F at %g percent confidence = %g',pc,fstatb);
desc = add(desc,s);
if fstatb < fb
  desc = add(desc,sprintf('Effect of blocks IS significant at %g percent confidence',alpha*100));
else
  desc = add(desc,sprintf('Effect of blocks IS NOT significant at %g percent confidence',alpha*100));
end
pb = ftest(ff,dofb,dofr,2);
s = sprintf('Probability of null hypothesis for blocks, p = %g',pb);
desc = add(desc,s);
desc = add(desc,'  ');

if nargout==0
  disp(char(desc))
else
  out = [];
  out.ssq.factors = sstr;
  out.ssq.blocks  = ssb;
  out.ssq.residual = sse;
  out.ssq.total = sst;
  
  out.dof.factors  = doff;
  out.dof.blocks   = dofb;
  out.dof.residual = dofr;
  out.dof.total    = doft;
  
  out.mean_sq.factors  = msstr;
  out.mean_sq.blocks   = mssb;
  out.mean_sq.residual = msse;
  
  out.F.factors = ff;
  out.F.blocks  = fb;
  out.F_crit.factors = fstatf;
  out.F_crit.blocks = fstatb;
  out.alpha  = alpha;
  out.p.factors = pf;
  out.p.blocks  = pb;
  
  out.table = desc;
  
  varargout{1} = out;
end

%----------------------------------------
function s = add(s,item);
s{end+1,1} = item;
