function [c,ikeep,res] = stepwise_regrcls(x,targspec,options)
%STEPWISE_REGRCLS Step-wise regression for CLS models.
%  For a given set of measured spectra (x), STEPWISE_REGRCLS finds
%  the subset of target spectra (targspec) that best fit each measured
%  spectrum in (x). This can be used for classification i.e. an
%  analyte identification algorithm. The model is:
%    x(i,:) = c(i,:)*targspec(ikeep{i},:)
%  where c(i,:) can be determined using non-negative least-squares
%  [see optional input (options)].
%
%  INPUTS:
%         x = MxN matrix of measured spectra (each row corresponds
%             to a measured spectrum).
%  targspec = KxN matrix of target (candidate) spectra.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%      display: [ {'on'} | 'off' ], governs level of display.
%     automate: [ {'yes'} | 'no' ],automate the algorithm?
%          automate = 'yes', makes no plots, and the step-wise regression
%               stops when the fit improvement is not sigificant in an
%               F Test at the probability level given in options.fstat.
%          automate = 'no', requires interactive user input for each of the
%               M spectra in (x).
%        fstat: 0.95, probability level the F test that determines the
%               significance of fit improvement.
%        fcrit: [ {'ratio'} , 'Chow' ], criterion for F-test.
%         ccon: [ 'none' | {'nnls'} ], uses non-negativity on concentrations,
%               in the concentration estimates.
%      cconind: [ ]  For use with ccon='nnls'; Indicates which elements
%                should be nonegatively constrained. 
%                Can be a 1xK vector [1x(Kp+K) if options.p not empty] with
%                1's indicating non-negative factors an 0's otherwise, or
%                a MxK [Mx(Kp+K)] logical matrix.
%                Default (empty) indicates that all elements are
%                constrained to be non-negative.
%            p: KpxN matrix of spectra that are always included in the
%               model. These correspond to the FIRST Kp entries in (c).
%         ccov: [], sqrt inverse noise/clutter covariance matrix,
%               e.g. if Xc is a matrix of measured clutter spectra then
%               ccov = inv(sqrt(cov(Xc))) [see COV_CV].
%         scls: [1:N],   % 1xN spectra scale axis {default = 1:N}.
%
%  OUTPUTS:
%       c = MxK matrix of concentrations / contributions, c is non-zero
%           only if a corresponding target spectrum is retained.
%           If (options.p) is not empty, then (c) is Mx(Kp+K) where the
%           first Kp columns correspond to the spectra in (options.p).
%   ikeep = Mx1 cell array of indices, each cell corresponds to a row
%           of input (x) and includes the indices of retained TARGET
%           SPECTRA.
%     res = Mx1 vector of mean sum-squared-residuals.
%           If (options.ccov) is not empty, it is a weighted mean
%           sum-squared-residuals.
%
%I/O: [c,ikeep,res] = stepwise_regrcls(x,targspec,options);
%I/O: options   = stepwise_regrcls('options'); %default options structure
%
%See also: CLS, COV_CV

%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NBG modified old proto-code from 2001, 7/05, 8/09

if nargin == 0; x = 'io'; end
if ischar(x)
  options = [];
  options.name     = 'options';
  options.display  = 'on';
  options.automate = 'yes';  % [ {'yes'} | 'no' ] automate the algorithm?
  options.fstat    = 0.95;   % significance level for f-test
  options.fcrit    = 'ratio';% [ {'ratio'} , 'Chow' ], criterion for F-test.
  options.ccon     = 'nnls'; % [ 'none' | {'nnls'} ]; non-negativity
  options.cconind  = [];
  options.ccov     = [];     % noise/clutter covariance matrix
  options.p        = [];     % kept spectra used to model interferences
  options.scls     = [];     % 1xN spectra scale axis {default = 1:N}
  if nargout==0
    evriio(mfilename,x,options);
  else
    c = evriio(mfilename,x,options);
  end
  return;
end
if nargin<2
  error('If not requesting OPTIONS, STEPWISE_REGRCLS requires at least 2 inputs.')
end
if nargin<3 || isempty(options) %set default options
  options = stepwise_regrcls('options');
else
  options = reconopts(options,stepwise_regrcls('options'));
end
options.fcrit = lower(options.fcrit);
[m,n]     = size(x);
k         = size(targspec,1);
if size(targspec,2)~=n
  error('For (x) MxN, (targspec) must have N columns.')
end

if strcmpi(options.automate,'yes')
  options.automate  = true;
else
  options.automate  = false;
end
if strcmpi(options.display,'on')
  options.display   = true;
  if ~options.automate
    disp('STEPWISE_REGRCLS')
  end
else
  options.display   = false;
end
if options.fstat<=0 || options.fstat>=1
  error('options.fstat must be 0<options.fstat<1.')
end

if options.automate && options.display
  hwait   = waitbar(0,'Initializing STEPWISE-REGRCLS.');
end
if ~isempty(options.p)
  if size(options.p,2)~=n
    error('For (x) MxN, (options.p) must have N columns.')
  end
  kp      = size(options.p,1);
else
  kp      = 0;
end

options.ccon        = lower(options.ccon); % [ 'none' | {'nnls'} ]; non-negativity
ccon  = ismember(lower(options.ccon),{'fasternnls','fastnnls','nnls'});%set flag indicating that non-negativity should be used (or not)
if ccon
  if isempty(options.cconind)
    options.cconind = ones(1,kp+k);
  end
  if isvec(options.cconind)
    options.cconind = options.cconind(:)';
  end
  if size(options.cconind,2)~=(kp+k)
    if kp==0
      error('size(options.cconind,2) must equal K')
    else
      error('size(options.cconind,2) must equal Kp+K')
    end
  end
end

if isempty(options.ccov)
  ccov    = false;
else
  ccov    = true;
  if size(options.ccov,1)~=n || size(options.ccov,2)~=n
    error('For (x) MxN, (options.cov) must be NxN.')
  end
  targsq  = targspec*options.ccov;
  if ~isempty(options.p)
    pintr = options.p*options.ccov;
  end
end

if isempty(options.scls)
  options.scls = 1:n;
else
  if length(options.scls)~=n
    error('For (x) MxN, (options.scls) must be 1:N.')
  end
  options.scls = options.scls(:)';
end

% Estimate mean residuals with 0 analyte spectra
if isempty(options.p)
  if ccov
    res   = sum((x*options.ccov).^2,2);
  else
    res   = sum(x.^2,2);
  end
  c       = zeros(m,k);
else
  if ccon
    cconind = options.cconind(:,1:kp);
    if ccov
      c     = fasternnls(pintr',options.ccov*x',[],[],[],cconind)';
    else
      c     = fasternnls(options.p',x',[],[],[],cconind)';
    end
  else
    if ccov
      c     = x*options.ccov*pinv(pintr);
    else
      c     = x*pinv(options.p);
    end
  end
  xhat    = c*options.p;
  if ccov
    res   = sum(((x-xhat)*options.ccov).^2,2);
  else
    res   = sum((x-xhat).^2,2);
  end
  c       = [c,zeros(m,k)];
end

ikeep   = cell(m,1);
if options.automate && options.display
  waitbar(0,hwait,'Please wait. Calculating STEPWISE-REGRCLS.');
end
if ~options.automate
  h1    = figure('Visible','off','Color',[1 1 1]);
end

for i1=1:m %loop over spectra in x
  inot      = 1:k;
  ikeep{i1} = [];
  keepit    = true;
  if isempty(options.p)
    skpwt   = [];
    skp     = [];
  else
    if ccov
      skpwt = pintr;
    end
    skp     = options.p;
  end
  err       = inf*ones(1,k);
  errold    = res(i1);
  xhatold   = zeros(1,n);
  if ~options.automate
    disp(['Sample ',int2str(i1),' of ',int2str(m)])
  end
  
  %look for components (as long as we find items)
  while keepit
    c1      = zeros(k,size(skp,1)+1);
    %search over all available components looking for the best delta error
    for i2=inot
      if ccon
        if isvec(options.cconind)
          cconind     = options.cconind( 1,[1:kp ikeep{i1}+kp i2+kp]);
        else
          cconind     = options.cconind(i1,[1:kp ikeep{i1}+kp i2+kp]);
        end
      end
      if ccov
        if ccon
          c1(i2,:)  = fasternnls([skpwt; targsq(i2,:)]',options.ccov*x(i1,:)',[],[],[],cconind);
        else
          c1(i2,:)  = x(i1,:)*options.ccov*pinv([skpwt; targsq(i2,:)]);
        end
        err(i2)   = sum(((x(i1,:)-c1(i2,:)*[skp; targspec(i2,:)])*options.ccov).^2);
      else
        if ccon
          c1(i2,:)  = fasternnls([skp; targspec(i2,:)]',x(i1,:)',[],[],[],cconind);
        else
          c1(i2,:)  = x(i1,:)*pinv([skp; targspec(i2,:)]);
        end
        err(i2)   = sum(((x(i1,:)-c1(i2,:)*[skp; targspec(i2,:)])).^2);
      end %if cov
    end
    [~,k1]  = min(err(inot)); 
    k1      = inot(k1);  %convert to index of spectra
    
    switch options.fcrit
    case 'ratio'
      fstat = res(i1)/err(k1);
      nikp  = length(ikeep{i1})+size(skp,1);
      ftabl = ftest(1-options.fstat,n-nikp,n-nikp-1);
    case 'chow'
      nikp  = length(ikeep{i1});
      fstat = (res(i1)-err(k1))/(err(k1)/(n-nikp));
      ftabl = ftest(1-options.fstat,1,n-nikp);
    end
    
    if options.automate
      %automatic decision
      if (fstat/ftabl)>1
        keepit  = true;
        xhat    = c1(k1,:)*[skp; targspec(k1,:)];
      else
        keepit  = false;
      end
    else
      %manual (non-automated) selection. Show user plot and allow decision
      set(h1,'Visible','on'), figure(h1)
      subplot(2,1,1)
      xhat    = c1(k1,:)*[skp; targspec(k1,:)];
      if ccov
        plot(options.scls,x(i1,:)*options.ccov,'b',options.scls,xhat*options.ccov,'r'), hold on
        plot(options.scls,xhatold*options.ccov,'color',[0.8 0.8 1])
        plot(options.scls,(x(i1,:)-xhat)*options.ccov,'k'), hold off
        title(['Sample ',int2str(i1),' of ',int2str(m),' *inv(sqrt(cov))'])
      else
        plot(options.scls,x(i1,:),'b',options.scls,xhat,'r'), hold on
        plot(options.scls,xhatold,'color',[0.8 0.8 1])
        plot(options.scls,x(i1,:)-xhat,'k'), hold off
        title(['Sample ',int2str(i1),' of ',int2str(m)])
      end
      
      legend('Measured','New Fit','Old Fit','Residuals', ...
        'Location','EastOutside')
      legend(gca,'boxoff')
      subplot(2,1,2)
      plot(inot,err(inot),'ob'), hold on
      plot(k1,err(k1),'or','markerfacecolor',[1 0 0]), hold off
      zz = hline(errold,'b'); set(zz,'color',[0.8 0.8 1])
      title(sprintf('SSE, F-Ratio = %5.2f ',fstat/ftabl))
      xlabel('Target Spectrum Index')
      legend('New Fit SSE','Minimum SSE','Old SSE', ...
        'Location','EastOutside')
      legend(gca,'boxoff')
      
      %ask for decision
      keepit = '';
      while isempty(keepit)
        keepit = deblank(lower(input(['Keep target ',int2str(k1), ...
          ' and continue (y/n)?'],'s')));
        if ~ismember(lower(keepit),{'y' 'n'})
          disp('Please enter ''y'' or ''n''.')
          keepit = '';
        end
      end
      keepit = strcmpi(keepit,'y');  %convert to logical
    end
    
    if keepit
      %keeping this spectrum, add it to set and recalculate stats
      ikeep{i1} = sort([ikeep{i1}, k1]);
      inot      = setdiff(inot,k1);
      res(i1)   = err(k1);
      errold    = err(k1);
      xhatold   = xhat;
      if ccov
        skpwt   = [skpwt; targsq(k1,:)];
      end
      skp     = [skp; targspec(k1,:)];
    end
    if length(ikeep{i1})==k %all were included? done
      keepit = false;
    end
  end %while keepit

  %do final fit
  if ccon
    if isvec(options.cconind)
      cconind     = options.cconind( 1,[1:kp ikeep{i1}+kp]);
    else
      cconind     = options.cconind(i1,[1:kp ikeep{i1}+kp]);
    end

    if ccov
      c(i1,[1:kp,kp+ikeep{i1}]) = fasternnls([pintr;targsq(ikeep{i1},:)]',options.ccov*x(i1,:)',[],[],[],cconind);
    else
      c(i1,[1:kp,kp+ikeep{i1}]) = fasternnls([options.p;targspec(ikeep{i1},:)]',x(i1,:)',[],[],[],cconind);
    end
  else
    if ccov
      c(i1,[1:kp,kp+ikeep{i1}]) = x(i1,:)*options.ccov*pinv([pintr;targsq(ikeep{i1},:)]);
    else
      c(i1,[1:kp,kp+ikeep{i1}]) = x(i1,:)*pinv([options.p; targspec(ikeep{i1},:)]);
    end
  end
  
  %get final xhat
  xhat    = c(i1,[1:kp,kp+ikeep{i1}])*[options.p; targspec(ikeep{i1},:)];

  %get final residuals
  if ccov
    res(i1) = sum((((x(i1,:)-xhat)*options.ccov).^2));
  else
    res(i1) = sum(((x(i1,:)-xhat)).^2);
  end

  %give final plot
  if ~options.automate && options.display
    figure(h1), clf
    plot(options.scls,x(i1,:),'b',options.scls,xhat,'r')
    hold on, plot(options.scls,x(i1,:)-xhat,'k'), hold off
    title(['Sample ',int2str(i1),' of ',int2str(m),' Fit'])
    legend('Measured','Fit','Residuals','Location','Best')
  end
  
  if options.automate && options.display
    if ~ishandle(hwait)
      error('User Aborted Fit')
    end
    waitbar(i1/m,hwait);
  end
  
end %loop over samples in x

if options.automate && options.display && ishandle(hwait)
  close(hwait)
end
