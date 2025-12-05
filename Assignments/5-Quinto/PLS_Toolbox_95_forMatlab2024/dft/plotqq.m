function vals = plotqq(x,distname,options)
%PLOTQQ Quantile-quantile plot of a sample.
%  Makes a QQplot of a sample in the input (x) against the optional
%  input (distname). A 45 degree line is also plotted. The larger the
%  deviation from the reference line the more likely it is the input (x)
%  does not come from the distribution (distname).
%    'beta'
%    'cauchy'
%    'chi squared'
%    'exponential'
%    'gamma'
%    'gumbel'
%    'laplace'
%    'logistic'
%    'lognormal'
%    'normal'     {default}
%    'pareto'
%    'rayleigh'
%    'triangle'
%    'uniform'
%    'weibull'
%  If distname = 'select' or = '', the user is prompted to select one of the valid
%  distribution types to use. If distname = 'auto' or 'automatic' then the
%  best fitting distribution is used as determined by DISTFIT.
%
%  Optional input (options) is an options structure containing one or more
%  of the following fields: 
%          plots: [ 'none' | {'final'} ] Governs plotting. If 'none', no
%                  plot is created and the function simply returns the fit
%                  (see outputs).
%      histogram: [ {'off'} | 'on' ] Governs the plotting of a histogram of
%                  the measured and reference distribution below the main
%                  QQ plot.
%      translate: [ 0 ] translate the x axis by this offset {default = 0}.
%        varname: [ '' ] label name to use on x-axis and title. Default is
%                  empty which uses the actual input variable name.
%          color: [ 'b' ] symbol color to use for the plot(s).
% OUTPUT is a structure containing two files:
%        q: quantile of the named distribution.
%        u: values at which the quantiles were evaluated.
%
%Examples:
%     vals = plotqq(x)
%     vals = plotqq(x,'normal')
%     vals = plotqq(x,'beta')
%
%I/O: vals = plotqq(x,distname,options);
%
%See Also: DISTFIT, PLOTCQQ, PLOTEDF, PLOTKD, PLOTSYM

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin<1; x = 'io'; end
if isa(x,'char');
  options = [];
  options.plots     = 'final';
  options.histogram = 'off';
  options.translate = 0;
  options.varname   = '';
  options.color     = 'b';
  if nargout==0; clear vals; evriio(mfilename,x,options); else; vals = evriio(mfilename,x,options); end
  return; 
end

nargchk(1,3,nargin) ;
fig = [];  %default is new figure
if nargin==2 & isa(x,'matlab.ui.Figure') | (isnumeric(x) & numel(x)==1);
  %(fig,distname) GUI call
  fig     = x;
  x       = getappdata(fig,'x');
  options = getappdata(fig,'options');
elseif nargin < 3
  options = [];
elseif ~isstruct(options)
  translate = options;
  options   = [];
  options.translate = translate;
end
options = reconopts(options,'plotqq');
translate = options.translate;

if nargin < 2
  distname = 'normal' ;
end

if ~isreal(x), error('X must be real.') ; end
x = x(isfinite(x));  %drop non-finite values

types = {
  'Beta'
  'Cauchy'
  'Chi Squared'
  'Exponential'
  'Gamma'
  'Gumbel'
  'Laplace'
  'Logistic'
  'Lognormal'
  'Normal'
  'Pareto'
  'Rayleigh'
  'Triangle'
  'Uniform'
  'Weibull'
  };
if isempty(distname) || strcmp(distname,'select')
  %Empty distname = 'select'
  [s,v] = listdlg('PromptString','Select a distribution type:',...
    'SelectionMode','single',...
    'ListString',types);
  if ~v; return; end
  distname = types{s};
end

if strcmpi(distname,'guihelp');
  msg = {...
    'This plot shows the comparison of your data to the currently-selected distribution. The better your data matches the 1:1 line, the better the fit.',...
    ' ',...
    'Use the "Distribution" menu to compare to a different distribution.'};
  evrihelpdlg(msg,'Quantile Plot Help');
  set(fig,'windowbuttondownfcn','');
  return
end

%'auto' or 'automatic' calls distfit to choose best fit distribution
if ismember(lower(distname),{'automatic' 'auto'})
  p = distfit(x,struct('plots','none'));
  distname = p(1).dist;
end

name = getname(distname) ;
if strcmp(name,'unknown')
  error(['Unknown or unsupported distribution: ', distname]) ;
end

if isempty(options.varname)
  options.varname = inputname(1);
end
if ~isempty(options.varname)
  tle = ['Quantile-Quantile Plot of ', options.varname ' and a ' distname ' Distribution'] ;
  vlabel = ['Quantiles of ',options.varname] ;
else
  tle = ['Quantile-Quantile Plot for a ' distname ' Distribution'] ;
  vlabel = 'Quantiles' ;
end

wrn = warning;
warning off ;

sortx = sort(x(:)) ;
n = length(sortx) ;
p = linspace(1,n,n) ./ (n+1)  ;

fy = distsub(name,p,sortx); %Call distribution sub function.

if strcmp(options.plots,'final')
  %do the plot
  if isempty(fig);
    fig = figure;
  else
    figure(fig);
  end
  if strcmp(options.histogram,'on');
    subplot(3,1,[1:2]);
  end
  h = plot(fy.pvals+translate,sortx+translate,'o');
  set(h,'color',options.color)
  clr = get(h,'color');  %used in histogram plotting below
  dp('k--');
  xlabel(vlabel)
  ylabel(fy.dlabel)
  title(tle)
  
  if strcmp(options.histogram,'on');
    %do histogram plot
    ax1 = axis;  %get main axis range
    xlabel('');  %drop xlable (will be on histogram instead)
    
    subplot(3,1,3);
    nbars = max(3,min(n/5,25));
    [n_std,xout_std] = hist(fy.pvals+translate,nbars);
    [n,xout]         = hist(sortx+translate,xout_std);
    
    %Remove 'v6' switch to avoid warning messages. Doesn't seem to impact
    %properties used with bar graph. This can be permanently removed in the
    %future.
    verinfo = {};
    %   if getmlversion>=6.5
    %     verinfo = {'v6'};
    %   else
    %     verinfo = {};
    %   end
    
    clr_std = [.7 .7 .7];
    width = 1;
    width_std = .4;
    h2 = bar(verinfo{:},xout,n,width);
    set(h2,'facecolor',clr,'linewidth',1,'edgecolor',clr*.5)
    legendname(h2,'Observed Dist.');
    set(h2,'handlevisibility','off');
    hold on;
    h3 = bar(verinfo{:},xout_std,n_std,width_std);
    set(h3,'facecolor',clr_std,'edgecolor',[0 0 0])
    legendname(h3,'Reference Dist.');
    set(h3,'handlevisibility','off');
    
    %   legend({'Observed Dist.' 'Reference Dist.'});
    hfake = plot(nan,1,nan,2);
    set(hfake(1),'color',clr,'linewidth',4);
    set(hfake(2),'color',clr_std,'linewidth',4);
    legendname(hfake(1),'Observed Dist.');
    legendname(hfake(2),'Reference Dist.');
    
    xlabel(vlabel)
    ylabel('Count at Value')
    hold off
    axis tight
    ax2 = axis;
    axis([ax1(1:2) ax2(3:4)]);
    
  end
  
  %add menu to choose other types of distributions
  h0 = findobj(fig,'tag','plotqqmenu');
  if isempty(h0)
    h0 = uimenu(fig,'label','Distribution','tag','plotqqmenu');
  else
    delete(allchild(h0));
  end
  for j=1:length(types);
    h1 = uimenu(h0,'label',types{j},'callback',['plotqq(gcbf,''' types{j} ''');']);
    if strcmpi(types{j},distname); set(h1,'checked','on'); end
  end
  h1 = uimenu(h0,'label','Best Fit (Automatic)','separator','on','callback',['plotqq(gcbf,''auto'');']);
  h1 = uimenu(h0,'label','Help','separator','on','callback',['plotqq(gcbf,''guihelp'');']);
  setappdata(fig,'x',x);
  setappdata(fig,'options',options);
  
  set(fig,'windowbuttondownfcn','plotqq(gcbf,''guihelp'')');
end

%prepare output
vals = struct('q',fy.pvals+translate,'u',p) ;

warning(wrn)

% ---------------------------------
% Subroutines for the distributions
% ---------------------------------
function result = distsub(dist,p,x)

switch dist

  case 'beta'
    params = parammle(x,'beta') ;
    options.scale = params.c;
    options.offset = params.d;
    pvals  = betadf('quantile',p,params.a,params.b,options) ;
    dlabel = sprintf('Quantiles of Beta (%0.3g,%0.3g)',params.a,params.b) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'cauc'
    params = parammle(x,'cauchy') ;
    pvals  = cauchydf('quantile',p,params.a,params.b) ;
    dlabel = sprintf('Quantiles of Cauchy (%0.3g,%0.3g)',params.a,params.b) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'chi2'
    params = parammle(x,'chi2') ;
    pvals  = chidf('quantile',p,params.a) ;
    dlabel = sprintf('Quantiles of Chi-squared (%0.3g)',params.a) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'expo'
    params = parammle(x,'exponential') ;
    pvals  = expdf('quantile',p,params.a) ;
    dlabel = sprintf('Quantiles of Exponential (%0.3g)',params.a) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'gamm'
    params = parammle(x,'gamma') ;
    pvals  = gammadf('quantile',p,params.a,params.b) ;
    dlabel = sprintf('Quantiles of Gamma (%0.3g,%0.3g)',params.a,params.b) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'gumb'
    params = parammle(x,'gumbel') ;
    pvals  = gumbeldf('quantile',p,params.a,params.b) ;
    dlabel = sprintf('Quantiles of Gumbel (%0.3g)',params.a) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'lapl'
    params = parammle(x,'laplace') ;
    pvals  = laplacedf('quantile',p,params.a,params.b) ;
    dlabel = sprintf('Quantiles of Laplace (%0.3g,%0.3g)',params.a,params.b) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'logi'
    params = parammle(x,'logistic') ;
    pvals  = logisdf('quantile',p,params.a,params.b) ;
    dlabel = sprintf('Quantiles of Logistic (%0.3g,%0.3g)',params.a,params.b) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'logn'
    params = parammle(x,'lognormal') ;
    pvals  = lognormdf('quantile',p,params.a,params.b) ;
    dlabel = sprintf('Quantiles of Lognormal (%0.3g,%0.3g)',params.a,params.b) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'norm'
    params = parammle(x,'normal') ;
    pvals  = normdf('quantile',p,params.a,params.b) ;
    dlabel = sprintf('Quantiles of Normal (%0.3g,%0.3g)',params.a,params.b^2)  ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'pare'
    params = parammle(x,'pareto') ;
    pvals  = paretodf('quantile',p,params.a,params.b) ;
    dlabel = sprintf('Quantiles of Pareto (%0.3g,%0.3g)',params.a,params.b) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'rayl'
    params = parammle(x,'rayleigh') ;
    pvals  = raydf('quantile',p,params.a) ;
    dlabel = sprintf('Quantiles of Rayleigh (%0.3g)',params.a) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'tria'
    params = parammle(x,'triangle') ;
    pvals  = triangledf('quantile',p,params.a,params.b,params.c) ;
    dlabel = sprintf('Quantiles of Triangle (%0.3g,%0.3g,%0.3g)',...
      params.a,params.b,params.c) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'unif'
    params = parammle(x,'uniform') ;
    pvals  = unifdf('quantile',p,params.a,params.b) ;
    dlabel = sprintf('Quantiles of Uniform (%0.3g,%0.3g)',params.a,params.b) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'weib'
    params = parammle(x,'weibull') ;
    pvals  = weibulldf('quantile',p,params.a,params.b,min(p)) ;
    dlabel = sprintf('Quantiles of Weibull (%0.3g,%0.3g)',params.a,params.b) ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  otherwise
    error('Unknown or unsupported distribution.');

end
