function [ccov,results] = cov_cv(x,options,model)
%COV_CV Estimation of a regularized inverse covariance matrix.
%  For (x) M by N, COV_CV estimates a regularized inverse of x'*x/(M-1).
%  If [V,S] = svd(x'*x/(M-1)), and S = diag(S); then the regularized
%  inverse takes the form  V*diag(1./(S+alpha))*V'.
%  The 1 by N vector alpha is output in (results.alpha) [see options.algorithm].
%
%  INPUT:
%        x  = X-block class "double" or "dataset".
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%        display: [ 'off' | {'on'} ] Governs output to command window,
%          plots: [ 'none' | {'final'} ] Governs plotting.
%        condmax: {1e4} maximum regularization (condmax>1).
%                 This is the maximum condition number for (ccov).
%        inverse: [ {'yes'} | 'no' ] If set to 'yes' {default} the inverse covariance
%                 matrix is estimated. If set to 'no' the output (ccov) is a
%                 regularized covariance matrix.
%           sqrt: [ {'no'} | 'yes' ], governs if the output is sqrt of the cov
%      algorithm: [ 2 ], regularization method where ac = S(1)/options.condmax
%                algorithm = 1: results.alpha = (ac./(ac+S))*ac ;
%                algorithm = 2: results.alpha = (ac^2./(ac^2+S.^2))*ac ;
%                algorithm = 3: results.alpha = ac*ones(1,length(S)) ;
%  preprocessing: { [1] }  Controls preprocessing.
%              Two methods can be used to control preprocessing.
%              1) For typical preprocessing methods use a scalar:
%                 0 = none, { 1 = mean centering, default }, or 2 =
%                 autoscaling.
%              2) For more varieties of preprocessing enter a cell
%                 array options.preprocessing = {pre} where pre is
%                 a standard preprocessing structure output by PREPROCESS.
%        calccov: 'yes'. If 'yes', it is assumed that the covariance matrix
%                 must first be calculated before estimating the inverse.
%                 If 'no', it is assumed that input (x) is already a
%                 covariance and the calculation is not performed. If 'no'
%                 options.preprocessing is set to 0.
%
%  OUTPUT:
%      ccov = ccov is the regularized (inverse and/or sqrt) covariance.
%   results = a structure array with the following fields
%           cond: condition number of x'*x/(M-1) [before after] regularization.
%          alpha: regularization parameters.
%             sd: are the regularized eigenvalues (or sqrt) of Cov(X).
%              s: are the eigenvalues (or sqrt) of Cov(X).
%             ss: are the variances (or std) of X.
%          ncomp: number of factors at which S(1)/S = options.condmax (it
%                 can be a fraction).
%        options: is the input (options) structure
%
%I/O: [ccov,results] = cov_cv(x,options);
%I/O: cov_cv demo
%
%See also: PLS, PREPROCESS, STEPWISE_REGRCLS

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 5/19/08, 8/09

%change to allow for an output that has v instead of cov(x)
%  this will make it really useable for 'big' problems

if nargin == 0; x = 'io'; end
if ischar(x)
  options = [];
  options.name          = 'options';
  options.display       = 'on';
  options.plots         = 'final';
  options.condmax       = 1e4;
  options.inverse       = 'yes';
  options.sqrt          = 'no';
  options.algorithm     = 2;
  options.preprocessing = 1;
  options.calccov       = 'yes';
  options.compact       = 'no';
  if nargout==0; evriio(mfilename,x,options); else
    ccov      = evriio(mfilename,x,options);  end
  return;
end

if nargin<1
  error('COV_CV requires at least one input (x).');
end
if nargin<3
  model = [];
end
if nargin<2
  options = [];
elseif ismodel(options)
  model = options;
  options = [];
end
options = reconopts(options,cov_cv('options'));

if ~isempty(model)
  %applying model to data...
  if isdataset(x)
    x = x.data.include;
  end
  xv = x*model.v; 
  if size(x,1)<5000
    %small matrix? do at once
    ccov = xv*model.D*model.v' + model.d*x - model.d*xv*model.v';
  else
    %big matrix? do picewise
    m = size(x,1);
    for j=1:500:m
      ind = j:min(m,j+500-1);
      x(ind,:) = xv(ind,:)*model.D*model.v' + model.d*x(ind,:) - model.d*xv(ind,:)*model.v';
    end
    ccov = x;
  end
  return
end

if strcmpi(options.calccov,'no')
  options.preprocessing = 0;
end
if options.condmax<1
  error('options.condmax must be >=1')
end
m             = size(x);

results.modeltype = 'COV_CV';
results.info  = char('Cov_CV', ...
  'ccov is the regularized (inverse and/or sqrt) covariance.', ...
  'alpha are the regularization parameters.', ...
  'sd   are the regularized eigenvalues (or sqrt) of Cov(X).', ...
  's    are the eigenvalues (or sqrt) of Cov(X).', ...
  'ss   are the variances (or std) of X.', ...
  'cond is the condition number [before after] regularization.', ...
  'options is the input (options) structure');
results.sd    = [];
results.s     = [];
results.ss    = [];
results.cond  = [];

if isa(options.preprocessing,'cell')
  if ~isempty(options.preprocessing)&&isstruct(options.preprocessing{1})
    x    = preprocess('calibrate',options.preprocessing{1},x);
  end
  if isa(x,'dataset')
    x    = x.data.include;
  end
else
  if isa(x,'dataset')
    x    = x.data.include;
  end
  switch options.preprocessing
  case 2    %autoscale
    x    = auto(x);
  case 1    %mean centering
    x    = mncn(x);
  end
end
if strcmpi(options.plots,'final')
  if strcmpi(options.calccov,'yes')
    results.ss  = sort(std(x)'.^2,'descend');
  else
    results.ss  = sort(diag(x),'descend');
  end
end

%%
results.sd      = zeros(m(2),1);
mkmonot         = (m(2):-1:1)'*eps;
switch lower(options.calccov) %if the input is already a cov(x), use 'no'
case 'yes'   
  if m(2)>m(1)
    xx = x*x';
    xx = xx/(m(1)-1);
    results.s = results.sd;
    s  = svd(xx);
    results.s(1:length(s)) = s(:);
    k1 = find(s>max(m)*s(1)*eps);
    if s(end)>s(1)/options.condmax
      results.ncomp = length(s);
    elseif k1==1
      results.ncomp = 1;
    else
      results.ncomp = interp1(mkmonot(k1)+s(k1),k1,results.s(1)/options.condmax, ...
        'pchip',length(k1)); %estimated number of components
    end
  else
    xx = x'*x;
    xx = xx/(m(1)-1);
    results.s = svd(xx);
    results.s = results.s(:);
    k1 = find(results.s>max(m)*results.s(1)*eps);
    results.ncomp   = interp1(mkmonot(k1)+results.s(k1),k1,results.s(1)/options.condmax, ...
      'pchip',length(k1)); %estimated number of components
  end
case 'no'
  xx = x;
  results.s   = svd(x);
  results.s   = results.s(:);
  k1          = find(results.s>max(m)*results.s(1)*eps);
  results.ncomp   = interp1(mkmonot(k1)+results.s(k1),k1,results.s(1)/options.condmax, ...
    'pchip',length(k1)); %estimated number of components
end
results.cond(1) = results.s(1)/results.s(end);
results.sd    = results.s;

if results.s(1)==0
  error('Input (x) appears to be all 0')
end

[v,s] = svd(xx,0);
s     = diag(s);
v     = v(:,1:ceil(results.ncomp));
s     = s(1:ceil(results.ncomp));

if m(2)>m(1)
  v = normaliz(v'*x)';
end
results.v = v;

%calculate regularized eigenvalues (sd)
if results.ncomp>=m(2)
  results.alpha = []; %full rank? use just eigenvalues
else
  s_ncomp = interp1(1:length(results.s),results.s, results.ncomp, ...
    'pchip',max(m)*results.s(1)*eps); %eigenvalue at estimated number of components
  switch options.algorithm
  case 1 %Tikonhov Filtering 1
    results.alpha = (s_ncomp./(s_ncomp+results.sd))*s_ncomp;
  case 2 %Tikonhov Filtering 2
    results.alpha = (s_ncomp^2./(s_ncomp^2+results.sd.^2))*s_ncomp;
  case 3 %Tikonhov Filtering ... Ridging
    results.alpha = s_ncomp*ones(length(results.sd),1);
  end
  results.sd    = results.s + results.alpha;
  results.sd(floor(results.ncomp+1):end) = results.s(1)/options.condmax;
end
results.cond(2) = results.sd(1)/results.sd(end);

%prepare weighting matrix
if strcmpi(options.sqrt,'yes')
  results.sd    = sqrt(results.sd);
  results.s     = sqrt(results.s);
  results.ss    = sqrt(results.ss);
end

switch lower(options.sqrt)
case 'no'
  cmax = options.condmax;
case 'yes'
  cmax = sqrt(options.condmax);
end
switch lower(options.inverse)
case 'yes'
  results.D = diag(1./results.sd(1:ceil(results.ncomp))); %floor
  results.d = (cmax/results.s(1));
case 'no'
  results.D = diag(results.sd(1:ceil(results.ncomp))); %floor
  results.d = (results.s(1)/cmax);   
end
results.options = options;

%Prepare output
if strcmpi(options.compact,'yes')
  results.v = v;
  ccov  = results;
else
  ccov = v*results.D*v' + results.d*(eye(size(v,1))-v*v');
end

%Do final plots
if strcmpi(options.plots,'final')
  figure
  semilogy(results.s,'ob-'), hold on
  semilogy(results.ss,'sr-')
  semilogy(results.sd,'dk-')
  if ~isempty(results.alpha)
    if strcmpi(options.sqrt,'no')
      semilogy(results.alpha,'.-','color',[0 0.5 0])
    else
      semilogy(sqrt(results.alpha),'.-','color',[0 0.5 0])
    end
  end, hold off
  %   set(gca,'yscale','log')
  xlabel('Factor'), %title(sprintf('alpha = %1.4f',results.alphamin))
  if strcmpi(options.sqrt,'no')
    if isempty(results.alpha)
      legend('Eigenvalue of Cov(\bfX\rm)','std(\bfX\rm)^2', ...
        'Regularized Eigenvalues','location','best')
    else
      legend('Eigenvalue of Cov(\bfX\rm)','std(\bfX\rm)^2', ...
        'Regularized Eigenvalues','alpha') %,'location','southwest')
    end
  else
    if isempty(results.alpha)
      legend('Eigenvalue of Cov(\bfX\rm)^{1/2}','std(\bfX\rm)', ...
        'Regularized Eigenvalues','location','best')
    else
      legend('Eigenvalue of Cov(\bfX\rm)^{1/2}','std(\bfX\rm)', ...
        'Regularized Eigenvalues','alpha') %,'location','southwest')
    end
  end
end
