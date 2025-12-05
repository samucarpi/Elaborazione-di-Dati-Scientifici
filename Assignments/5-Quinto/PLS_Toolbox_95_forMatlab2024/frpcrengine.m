function [b,ssq,u,sampscales,msg,options] = frpcrengine(x, y, ncomp, options)
%FRPCRENGINE Engine for full-ratio PCR regression.
%  Calculates a single full-ratio, FR, PCR model using the given number of
%  components (ncomp) to predict (y) from measurements (x). Random 
%  multiplicative scaling of each sample can be used to aid model stability. 
%  Full-Ratio PCR models, also known as Optimized Scaling 2 PCR models, are
%  based on the simultaneous regression for both y-block prediction and
%  scaling variations (such as those due to pathlength and collection
%  efficiency variations in spectroscopy). The resulting PCR model is
%  usually much less sensitive to sample scaling errors. 
%  NOTE: For best results, the x-block should not be mean-centered.
%
%  OPTIONAL INPUT:
%   options = structure with any of the following fields:
%      pathvar: {0.2}               Std deviation of random multiplicative scaling to use
%    useoffset: [ {'off'} | 'on' ]  Use of offset term in equation (may be necessary 
%                                   for mean-centered x-block)
%      display: [ 'off' | {'on'} ]  Governs level of display to command window.
%        plots: [ {'none'} | 'intermediate' ]  Governs level of plotting.
%    algorithm: [ {'direct'} | 'emprical' ]    Governs solution algorithm
%    tolerance: [ {5e-5} ]  threshold for change to trigger stop of loop 
%      maxiter: [ {100} ]   maximum number of iterations to allow 
%
%  OUTPUTS:
%             b = the full-ratio regression vector for a SINGLE MODEL at the given number of PCs,
%           ssq = PCA variance information,
%             u = the x-block loadings (u),
%    sampscales = random scaling used on the samples,
%           msg = warning messages, and
%       options = the modified options structure.
%
%  FRPCRENGINE can be used for prediction by passing the new x-block (x)
%  and the regression vector (b). The sole output is the predicted
%  y-values (yhat). There is no options structure used in this mode.
%
%I/O: [b,ssq,u,sampscales,msg,options] = frpcrengine(x,y,ncomp,options);  %calibration
%I/O: [yhat]                           = frpcrengine(x,b);                %prediction
%I/O: frpcrengine demo
%
%See also:  FRPCR, MSCORR, PCR, PLS

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% jms

% Algorithm:
% B1 = Y'.*B2T pinv(T)
% and
% b2i = (B1T - Y'.*(B2'T')) pinv(Y'.*ti)
% x is mxn  y is mx1, t is nxk
%
%DISABLED: 
% B2 = B1T.*1/Y' pinv(T)
% b1i = (Y'.*(B2T) - (B1'T')) pinv(ti)

if nargin == 0; x = 'io'; end
if ischar(x) %Help, Demo, Options
  
  options = [];
  options.name          = 'options';
  options.pathvar       = .2;        %scaling factor for random simulated pathlength variations
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'none';    %Governs plots to make
  options.algorithm     = 'direct';  %Solution algorithm
  options.useoffset     = 'off';     %include offset term in equation (often necessary for mean-centered data)
  options.tolerance     = 5e-5;      % threshold for change to trigger stop of loop
  options.maxiter       = 100;       %max # of iterations to allow
  
  if nargout==0; clear b; evriio(mfilename,x,options); else; b = evriio(mfilename,x,options); end
  return; 
end

if nargin<4;
  options = [];
end
options = reconopts(options,frpcrengine('options'),0);
  
dispfreq = 10;     %frequency of plot/display during 'intermediate' cycling

msg = cell(0);

if isa(x,'dataset');
  x = x.data(x.includ{1},x.includ{2});
end
if isa(y,'dataset');
  y = y.data(y.includ{1},y.includ{2});
end

if nargin==2;
  %try as predict
  b = frpred(x,y);
  return
end

if size(y,2)>1
  error('FRPCR only operates on univariate y-blocks. Please select a single y-column to model.')
end
options.sampscales = [];
if options.pathvar ~= 0;
  if ~isfield(options,'sampscales') | length(options.sampscales) ~= size(x,1);
    sampscales = 1+randn(size(x,1),1)*options.pathvar;     %random sample scaling
    options.sampscales = sampscales;
  end
else
  sampscales = [];
end

if mean(mean(y)) > 1e-8;
  msg{end+1} = 'Y-block is not mean centered. Model may not converge or may be unstable.';
  if strcmp(options.display,'on')
    warning('EVRI:Frpcr',msg{end});
  end
end

if mean(mean(x))./sum(sum(x)) < 1e-8 & ~strcmp(options.useoffset,'on');
  msg{end+1} = 'X-block appears to be mean centered but option ''useoffset'' is not on - model may not converge or may be unstable.';
  if strcmp(options.display,'on')
    warning('EVRI:Frpcr',msg{end});
  end
end

if length(ncomp)==1 & isa(ncomp,'double');
  %standard ncomp option, it specifies the # of PCs to use from a pcr model

  %check for rank problems
  r = rank(x);
  if ncomp>r;
    ncomp = r;
  end
  
  if ncomp < 2 & ~strcmp(options.useoffset,'on');
    options.algorithm = 'empirical';
    msg{end+1} = 'Can not use direct solution with only one component. Switching to Empirical solution';
    if strcmp(options.display,'on')
      warning('EVRI:Frpcr',msg{end});
    end
    %     error('Input (ncomp) must be > 1');
  end
  if ncomp < 1;
    error('Input (ncomp) must be > 0');
  end
  
  opts = pcr('options');    %we're actually using PCR because it also gives us y-block var cap
  
  opts.display       = 'off';
  opts.plots         = 'none';
  opts.outputversion = 3;
  opts.preprocessing = { [] [] };
  opts.blockdetails  = 'standard';
  opts.rawmodel      = 1;
  
  temp = pcr(x,y,ncomp,opts);
  t = temp.loads{1,1};
  u = temp.loads{2,1};
  ssq = temp.detail.ssq;

  %if random scaling was requsted, recalculate scores for randomly scaled
  %samples
  if ~isempty(options.sampscales)
    x     = diag(options.sampscales)*x;
    temp2 = pcr(x,y,temp,opts);
    t     = temp2.loads{1,1};
  end


  
  if strcmp(options.display,'on');
    ssqtable(ssq);
  end
  
elseif ismodel(ncomp);
  
  %hidden feature: pass model structure as pcs to use those loadings instead of pca results
  if ~isfield(ncomp,'modeltype');
    error('Missing or invalid value for (ncomp)')
  end
  u     = ncomp.loads{2,1};
  t     = x*u;
  ssq   = ncomp.detail.ssq;
  ncomp = size(u,2);
  
elseif isa(ncomp,'double')
  
  %hidden feature: pass loadings as pcs to use those instead of pca results
  u     = ncomp;
  ncomp = size(u,2);
  t     = x*u;
  ssq   = [];
  
else
  
  error('Unrecognized input for (ncomp)')
  
end

if strcmp(options.useoffset,'on'); 
  t(:,end+1) = 1; 
end
tinv  = pinv(t);

% calc initial guesses
[z,s] = mscorr(x, mean(x));     %use multipliciative scatter correction for initial guess of denominator
b2    = tinv*s;
b1    = tinv*(y.*(t*b2));
%b2 = tinv*((t*b1)./y);       %This works poorly... disabled

b2    = b2 ./ max(b1);
b1    = b1 ./ max(b1);

% if strcmp(options.display,'on');
%   %optional command window display
%   disp(['Iterations    SEC       Delta(SEC)'])
% end

%Main Loop
iter      = 0;        % of iterations
Db        = inf;      % get WHILE loop started
while Db > options.tolerance & iter < options.maxiter;
  
  b1old = b1; b2old = b2;
  
  switch options.algorithm
  case 'direct'
    
    b1 = tinv*(y.*(t*b2));
    %b2 = tinv*((t*b1)./y);       %This works poorly... disabled
    for i = 1:size(t,2);
      %b1(i) = t(:,i)\(y.*(t*b2) - (t(:,[1:i-1 i+1:end])*b1([1:i-1 i+1:end])));       %This works poorly... disabled
      b2(i) = (y.*t(:,i))\((t*b1) - y.*(t(:,[1:i-1 i+1:end])*b2([1:i-1 i+1:end])));
    end
    
  case 'empirical'
    
    %slow!
    b = fminsearch(@evpred,[b1' b2'],[],t,y);
    b1 = b(1:end/2)';
    b2 = b(end/2+1:end)';
    
  otherwise
    
    error('Unrecognized solution algorithm')
    
  end
  
  b2 = b2 ./ max(b1);
  b1 = b1 ./ max(b1);
  
  Db1 = b1-b1old;
  Db2 = b2-b2old;
  Db  = sqrt(Db1'*Db1 + Db2'*Db2);
  
  iter = iter + 1;
  
  %optional display of results (every N iterations)
  if mod(iter-1,dispfreq)==0;
    
    if strcmp(options.plots,'intermediate') | strcmp(options.display,'diag');
      %calculate these only if we need them below...  
      yhat = ((t*b1)./(t*b2));
      sec = sqrt(mean((yhat-y).^2));
    end
    
    if strcmp(options.plots,'intermediate');
      %optional plots
      if options.pathvar ~= 0;
        subplot(2,2,1)
      else
        subplot(2,1,2)
      end
      plot(y,yhat,'.')
      dp
      title(['Iterations: ' num2str(iter)])
      
      if options.pathvar ~= 0;
        subplot(2,2,2)
      else
        subplot(2,1,2)
      end
      plot(y,yhat-y,'.')
      hline
      title(['SEC: ' num2str(sec) '  Delta(SEC): ' num2str(Db) ])
      
      shg
      drawnow
    end
    
    if strcmp(options.display,'diag');      %optional command window display
      disp(sprintf('  %2i         %f    %f',iter,sec,Db))
    end
  end
  
end

if strcmp(options.display,'diag');      %optional command window display
  disp(sprintf('  %2i         %f    %f',iter,sec,Db))
end

if iter >= options.maxiter;
  msg{end+1} = 'Model did not converge';
  if strcmp(options.display,'on')
    warning('EVRI:Frpcr',msg{end});
  end
end

b2 = b2 ./ max(b1);
b1 = b1 ./ max(b1);

%convert inner-relation vectors to regression vector
if ~strcmp(options.useoffset,'on');
  b1 = u*b1;      
  b2 = u*b2;
  b  = [b1';b2'];
else
  b1temp = u*b1(1:end-1);
  b2temp = u*b2(1:end-1);
  b1temp(end+1) = b1(end);    %append offset term to end of regression vectors
  b2temp(end+1) = b2(end);
  b1 = b1temp;
  b2 = b2temp;
  b  = [b1';b2'];
end


%-----------------------------------------------------
function yhat = frpred(x,b)
%FRPRED does a full-ratio prediction based on an input full-ratio regression vector and data

if size(b,1) ~= 2;
  error('Invalid full-ratio regression vector');
end

if size(b,2) == size(x,2)+1;
  x(:,end+1) = 1;
end

if size(b,2) ~= size(x,2);
  error('Regression vector does not match data size');
end

yhat = (x*b(1,:)')./(x*b(2,:)');

%-----------------------------------------------------
function sec = evpred(bin,t,y)
%EVPRED is used in the emprical (fminsearch) algorithm
% note: input bin is the inner-relation parameters, NOT a
%  regression vector

b1   = bin(1:end/2)';
b2   = bin(end/2+1:end)';
yhat = ((t*b1)./(t*b2));
sec  = sqrt(mean((yhat-y).^2));

