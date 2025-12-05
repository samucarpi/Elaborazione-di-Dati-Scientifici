function [prob,classes,distprob] = discrimprob(y,ypred,prior)
%DISCRIMPROB Discriminate probabilities for continuous predicted values.
%  Inputs are the logical classes (y) for each sample, the observed 
%  continuous predicted values for those samples (ypred), and an 
%  optional input of the prior probabilities for each class (prior)
%  {default = 1}.
%
%  Outputs are a lookup matrix (prob) consisting of an index of y values
%  in the first column and the probability of that value being of each
%  class in y in the subsequent columns, and the discrete classes observed
%  in y (classes).
%  Use interp1(prob(:,1),prob(:,n+1),ypred)  to predict a probability
%  that observed value (ypred) is in class "n".
%
%I/O: [prob,classes] = discrimprob(y,ypred,prior);
%I/O: discrimprob demo
%
%See also: PLSDA, PLSDAROC, PLSDTHRES, SIMCA

%Copyright Eigenvector Research, 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 3/1/02 -initial release coding
%jms 3/6/02 -mods for speed
%jms 3/23/02 -fixed divide by zero in norm to 100%
%jms 3/7/05 -better handle "no distribution" of a class by using 1/4
%   distance to nearest not-in-class point as distribution.

if nargin == 0; y = 'io'; end
varargin{1} = y;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; prob = evriio(mfilename,varargin{1},options); end
  return; 
end

%get list of logical classes
% y       = logical(y);
classes = unique(y)';

if length(classes) < 2;
  error('Cannot calculate discriminate threshold with less than 2 classes');
end
if nargin <3  | isempty(prior);
  prior = ones(1,length(classes));
end

llim = inf; hlim = -inf;  %these will be overwritten the first time through the class loop
s_minthreshold = 0.02;  % Avoid extremely narrow Gaussians since lookup-table has only 100 intervals.
for classind = 1:length(classes);

  inclass = y==classes(classind);
  s(classind) = std(ypred(inclass));
  c(classind) = mean(ypred(inclass));
  
  llim = min([llim min(ypred(inclass))]);
  hlim = max([hlim max(ypred(inclass))]);
  
  s(classind) = max(s(classind), s_minthreshold);

  %inf prior? use # of items in class
  if isinf(prior(classind)); prior(classind) = sum(inclass); end;
  
end

%get gaussian interpretation of those stats
prec   = abs(hlim-llim)/100;
if prec == 0; prec = 1; end;
inrng  = [llim:prec:hlim]';

for classind = 1:length(classes);
  in(:,classind) = 1./(sqrt(2*pi)*(s(classind)./prec)) * exp(-(([0:(length(inrng)-1)]'-((c(classind)-llim)/prec)).^2)./2./((s(classind)./prec).^2))*prior(classind);
end

in = in + realmin;  % floor for P(y|A) and P(y|B) to prevent norm = 0.
norm = sum(in')';
norm(norm==0) = inf;
prob = in ./ (norm*ones(1,size(in,2)));

prob(~isfinite(prob)) = 0;  %default probability if not finite

prob = [inrng(:) prob];     %tag range of y values on as first column

distprob.s = s;
distprob.c = c;
distprob.prior = prior;