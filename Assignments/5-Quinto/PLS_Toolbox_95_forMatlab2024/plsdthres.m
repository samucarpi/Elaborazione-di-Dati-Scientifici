function [threshold,misclassed,prob,distprob] = plsdthres(varargin)
%PLSDTHRES Bayesian threshold determination for PLS Discriminate Analysis.
%  PLSDTHRES uses the distribution of calibration-sample predictions
%  obtained from a PLS model built for two or more logical classes 
%  to automatically determine a threshold value which will best split 
%  those classes with the least probability of false classifications 
%  of future predictions. It is assumed that the predicted values for 
%  each class are approximately normally distributed. 
%  The calibration can contain more than 2 classes, in which case 
%  thresholds to distinguish all classes will be determined. It is 
%  assumed that with more than 2 classes the primary misclassification
%  threat is from the adjacent class(es). 
%
%  INPUTS:
%         y = measured Y-block values used in PLS, and
%     ypred = PLS predicted Y values for calibration samples.
%  OR model = a PLS/PLSDA model structure from which y and ypred should be
%              obtained automatically.
%
%  OPTIONAL INPUTS: 
%   options = structure array with any of the following fields:
%   display: [ 'off' | {'on'} ]      governs level of display to command window.
%    plots : [ {'none'} | 'final' ], governs plotting
%     cost : [ ] Vector of logarithmic cost biases for each class in (y).
%            (cost) is used to bias against misclassification of a particular 
%            class or classes. The default [] uses all zeros i.e. equal cost.
%    prior : [ ] Vector of prior probabilities of observing each class.
%            If any class prior is Inf, the frequency of observation of that
%            class in the calibration is used as its prior probability. If all
%            priors are Inf, this has the effect of providing the fewest incorrect
%            predictions assuming that the probability of observing a given class
%            in future samples is similar to the frequency that class in the
%            calibration set. The default [] uses all ones i.e. equal priors.
%
%  OUTPUT:
%    threshold = vector of thresholds. If (y) consists of more than two classes,
%                threshold will be a vector giving the upper bound y-value for each class.
%   misclassed = array containing the fraction of misclassifications for each class
%                (rows): Column 1 = false negatives and Column 2 = false positives.
%         prob = lookup matrix of predicted (y) (column 1) vs. probability of  
%                each class (columns 2 to end).
%     distprob = Cell array containing struct of c, s, and prior for each 
%                class as returned by call to discrimprob
%
%I/O: [threshold,misclassed,prob] = plsdthres(model,options);
%I/O: [threshold,misclassed,prob] = plsdthres(y,ypred,options);
%I/O: plsdthres demo
%
%See also: CLASS2LOGICAL, CROSSVAL, DISCRIMPROB, PLSDA, PLSDAROC, SIMCA

%Copyright Eigenvector Research 2001-2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 9/01
% JMS 11/01/01 -added error check for classes < 2
% JMS 3/1/02  -converted to use discrimprob and modified algorithm for calc of threshold
% JMS 3/23/02 -catch problems with interp when finding thresholds
% JMS 1/16/03 -plot to new figure with output
% JMS 4/3/03  -modified plots
% JMS 4/31/04 -added options structure and support for passing in a model

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name  = 'options';
  options.plots = 'none';
  options.cost  = [];
  options.prior = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; threshold = evriio(mfilename,varargin{1},options); end
  return; 
end

%defaults for inputs
y       = [];
ypred   = [];
model   = [];
options = [];

%parse inputs
switch nargin
  %(y,ypred,options)
  %(model,options)
  %OLD I/O: (y,ypred,cost,prior,out)
  case 1
    % (model)
    if ismodel(varargin{1});
      model = varargin{1};
    else
      error('Input (ypred) is required with input (y)')
    end
  case 2
    % (y,ypred)
    % (model,options)
    if ~ismodel(varargin{1})
      y     = varargin{1};
      ypred = varargin{2};
    else
      model = varargin{1};
      options = varargin{2};
    end
  case 3
    % (y,ypred,options)
    y     = varargin{1};
    ypred = varargin{2};
    if isa(varargin{3},'struct')
      options = varargin{3};
    else
      options.cost = varargin{3};
    end
  case {4,5}
    % (y,ypred,cost,prior,out)
    y     = varargin{1};
    ypred = varargin{2};
    options.cost  = varargin{3};
    options.prior = varargin{4};
    if nargin==5
      if varargin{5}
        options.plots = 'final';
      else
        options.plots = 'none';
      end    
    end
end
options = reconopts(options,'plsdthres');

%check for model structure instead of y and ypred
if ~isempty(model);
  y     = model.detail.data{2}.data(model.detail.includ{1,2},model.detail.includ{2,2});
  ypred = model.pred{2}(model.detail.includ{1,2},model.detail.includ{2,2});
end

%extract from datasets
if isa(y,'dataset')
  y = y.data(y.include{1},y.include{2});
end
if isa(ypred,'dataset')
  ypred = ypred.data(ypred.include{1},ypred.include{2});
end

%test for mismatch
if size(y,2)~=size(ypred,2);
  error('Number of pred variables does not match number of calibration y variables');
end

if nargout>1 & size(y,2)>1
  warning('EVRI:PlsdathresOutputLimit','Only one output can be provided with more than one predicted y column');
end

%loop over columns of y
ally = y;
allypred = ypred;
allthreshold = [];
for yindex = 1:size(ally,2);
  y = ally(:,yindex);
  ypred = allypred(:,yindex);
  
  %get list of logical classes
  classes = unique(y)';
  
  if length(classes) < 2;
    allthreshold(yindex) = nan;
    prob = [0 nan nan; 1 nan nan];    %empty probability table 
    misclassed = [0 nan; 0 nan];
    continue;  %cycle to next yindex (if any)
%     error('Cannot calculate discriminate threshold with less than 2 classes');
  end
  
  %defaults
  if isempty(options.cost);
    options.cost = zeros(1,length(classes));
  end
  if isempty(options.prior);
    options.prior = ones(1,length(classes));
  end
  
  if length(options.cost) ~= length(classes);
    error(['cost vector must be equal in length to number of classes in y (=' num2str(length(classes)) ')'])
  end
  if length(options.prior) ~= length(classes);
    error(['prior vector must be equal in length to number of classes in y (=' num2str(length(classes)) ')'])
  end
  if any(options.prior==0);
    warning('EVRI:PlsdathresZeroPrior',['prior for class(es) [' num2str(find(options.prior==0)) '] is zero. It will be completely discounted.']);
  end
  
  [prob,classes,distprob] = discrimprob(y,ypred,options.prior);
  
  %scale probabilities by cost of misclassification
  prob = prob.*(ones(size(prob,1),1)*[1 10.^options.cost]);
  
  %loop over all classes
  for classind = 1:length(classes)-1;
    
    %find reasonable index range to search in
    [what,maxc1] = max(prob(:,classind+1));
    [what,maxc2] = max(prob(:,classind+2));
    rng          = sort([maxc1 maxc2]);
    
    %look for minimum difference between probability curves in that range
    [what,where] = min(abs(prob(rng(1):rng(2),classind+2)-prob(rng(1):rng(2),classind+1)));
    
    %translate into a predicted y-value to use as threshold
    where        = where + rng(1) - 1;
    if where > 1 & where < size(prob,1);
      probdiff = prob(where+[-1:1],classind+2)-prob(where+[-1:1],classind+1);
      if length(unique(probdiff))==3;
        threshold(classind) = interp1(probdiff,prob(where+[-1:1],1),0);
      else
        threshold(classind) = prob(where,1);
      end
    else  %at edge
      threshold(classind) = prob(where,1);
    end
    
    if ~isfinite(threshold(classind))
      %do best guess based on middle between means of the two classes
      threshold(classind) = prob(where,1);
      %threshold(classind) = (mean(ypred(y==classes(classind))) + mean(ypred(y==classes(classind+1))))/2;
    end
    
    %determine how many mis-classifications that threshold gives us
    % misclassed is n by 2 where n is the total number of classes
    % each row represents the results for a class:
    %  column 1 is false negatives (class x NOT classified as class x)
    %  column 2 is false positives (class y wrongfully classed as class x)
    class0 = y==classes(classind);
    if classind == 1;
      misclassed(classind,1) = sum(ypred(class0) > threshold(classind));
      misclassed(classind,2) = sum(ypred(~class0) < threshold(classind));
    else
      misclassed(classind,1) = sum(ypred(class0) > threshold(classind)) + sum(ypred(class0) < threshold(classind-1));
      misclassed(classind,2) = sum((ypred(~class0) < threshold(classind)) & (ypred(~class0) > threshold(classind-1)));
    end
    
    misclassed(classind,1) = misclassed(classind,1)./sum(class0);
    misclassed(classind,2) = misclassed(classind,2)./sum(~class0);
    
  end
  
  %unscale probabilities by cost of misclassification
  prob = prob./(ones(size(prob,1),1)*[1 10.^options.cost]);
  
  %determine misclassification for last class
  %get the class
  classind = length(classes);
  class0   = (y == classes(classind));
  misclassed(classind,1) = sum(ypred( class0) < threshold(end));
  misclassed(classind,2) = sum(ypred(~class0) > threshold(end));
  misclassed(classind,1) = misclassed(classind,1)./sum(class0);
  misclassed(classind,2) = misclassed(classind,2)./sum(~class0);
  
  if strcmp(options.plots,'final');
    figure;
    subplot(2,1,1)
    for classind = 1:length(classes);
      [by bx] = hist(ypred(y==classes(classind)),min([25 sum(y==classes(classind))]));
      
      h = bar(bx,by);
      clr = dec2bin(classind); 
      while length(clr)<3; clr=['0' clr]; end; 
      if length(clr)>3; clr=clr(end-2:end); end
      set(h,'facecolor',clr==49)
      hold on
      
    end
    hold on
    h = vline(threshold,'r--');%plot([threshold;threshold],[0 max(max(by))],'r--');
    set(h,'linewidth',2);
    xlabel('Predicted Value')
    ylabel('Number of Samples')
    ax = axis;
    
    %   h = plot(prob(:,1),prob(:,2:end)*ax(4));
    
    for k=2:size(prob,2);
      h = plot(prob(:,1),prob(:,k)*ax(4));
      
      clr = dec2bin(k-1); 
      while length(clr)<3; clr=['0' clr]; end; 
      if length(clr)>3; clr=clr(end-2:end); end
      set(h,'color',clr==49)
      
    end
    hold off
    
    subplot(2,1,2);
    
    if 1; %1 for false-negative only bar plot
      bar(misclassed(1,:),'stacked')
    else
      bar(misclassed,'stacked')
      legend('False Neg.','False Pos.')
    end
    xlabel('Class Number');
    ylabel('Fraction Misclassified')
  end
  
  allthreshold(yindex) = threshold;
end

threshold = allthreshold;
