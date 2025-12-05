function [model_adj,intercept,slope] = correctbias(new,ymeas,model,useslope)
%CORRECTBIAS Automatically adjust regression model for bias and slope errors.
% Given test data (x, y) and a regression model (model), this function
% calculates bias and, optionally, slope of the predictions and adjusts
% model to give unbiased predictions. 
%
% The output is the model structure with correcttions added so that
% re-application to the same test data will give a slope of unity (1) and
% offset of zero. Whether or not these corrections are appropriate depends
% on the validity of the test data. This correction works best when the
% test data includes many samples and covers a wide range of predictive
% values.
%
% If only one sample is provided, or all samples have the same measured y
% value, or the optional input useslope is set to zero, only a bias
% correction will be done.
%
% INPUTS:
%        x = new X-block test data appropriate for the model.
%           --OR--
%        ypred = new predicted Y-block values (presumably under influence of bias)
%
%        ymeas = Y-block reference data corresponding to x (unbiased).
%        model = Standard PLS_Toolbox regression model (PLS, PCR, MLR, NPLS, etc.)
%
% OPTIONAL INPUTS:
%   useslope = Flag indicating that a slope correction should be included
%              in the correction. Slope is NOT used when set to "false", or
%              0 (zero). Default is to use slope correction ("true".)
%
% OUTPUTS:
%    model_adj = Model with adjustments to give unbiased predictions.
%    intercept = intercept observed for test data.
%    slope     = slope observed for test data.
%
%I/O: [model_adj,intercept,slope] = correctbias(x,ymeas,model);
%I/O: [model_adj,intercept,slope] = correctbias(ypred,ymeas,model,useslope);
%I/O: model_adj = correctbias(x,y,model,0);  %do NOT correct for slope

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; new = 'io'; end
if ischar(new);
  options = [];
  if nargout==0; evriio(mfilename,new,options); else; model_adj = evriio(mfilename,new,options); end
  return; 
end

if nargin < 3 
  error('Not enough input arguments provided');
end

%Default is to use slope correct ('true')
if nargin<4
  useslope = true;
end

% NOTE: Assuming inputs are oriented correctly with samples as rows
if size(new,1) ~= size(ymeas,1)
  error('Inputs do not have the same number of rows/samples');
end

if ~ismodel(model) | length(model.datasource)<2
  %must be model structure with datasource indicating y-values were used
  error('Input model does not appear to be a valid regression model');
end

%make sure ymeas is a DSO
if ~isdataset(ymeas)
  ymeas = dataset(ymeas);
end

if size(new,2) == size(ymeas,2) | size(new,2) == ymeas.include{2};
  % columns of "x" match "ymeas" (with or without include having been applied to ymeas)? 
  % input is actually ypred!
  ypred = new; 
  %force into DSO so the rest of the call can be consistent
  if ~isdataset(ypred)
    ypred = dataset(ypred);
  end

  %find the intersection of their include fields
  incl    = ymeas.include;  %start with the measured include
  incl{1} = intersect(incl{1},ypred.include{1});  %make samples match
  ymeas   = ymeas.data(incl{:});  %apply to ymeas
  if size(ypred,2)==incl{2};
    %if the columns of ypred already matched length of the included
    %columns, assume the user has pre-selected the relevent columns already
    incl{2} = 1:size(ypred,2);
  end
  ypred   = ypred.data(incl{:});  %apply to both ypred and ymeas
  
  if length(incl{2})~=length(model.detail.include{2,2})
    error('Included columns of supplied y-measured values does not match included columns in model')
  end
  
else                           % input is x, ymeas, model
  %make predictions for the test data; no ypred provided
  fn   = lower(model.modeltype);
  pred = feval(fn,new,ymeas,model,struct('plots','none','display','off'));

  %extract predictions
  incl  = pred.detail.includ;
  ymeas = pred.detail.data{2}.data(incl{1,2},incl{2,2});
  ypred = pred.pred{2}(incl{1,2},:);
  
end

%calculate offset and (optionally) slope
if ~useslope | size(ymeas,1)==1 | any(range(ymeas)==0)
  %offset only
  for ycol = 1:size(ypred,2);
    fit(ycol,:) = [1 mean(ypred(:,ycol)-ymeas(:,ycol))];
  end
else
  %slope and offset
  for ycol = 1:size(ypred,2);
    fit(ycol,:) = polyfit(ymeas(:,ycol),ypred(:,ycol),1);
  end
end

%create correction step for y-block preprocessing
clear pp;
pp.description = 'Remove Prediction Bias/Slope errors';
pp.calibrate  = { '' };
pp.apply  = { '' };
pp.undo   = { 'data = rescale(data,out{1},out{2},userdata);' };
pp.out    = {-fit(:,2)'./fit(:,1)' 1./fit(:,1)'};     %create preprocessing to correct for bias/slope
pp.settingsgui   = '';
pp.settingsonadd = 0;
pp.usesdataset   = 1;
pp.caloutputs    = 2;
pp.keyword  = 'correctbias';
pp.tooltip  = 'Correct bias and slop for output of regression model';
pp.category = 'Scaling and Centering';
pp.userdata.offset = 0;
pp.userdata.badreplacement = 0;
pp.userdata.stdthreshold = 0;
pp = preprocess('validate',pp);

%add changes to model
model_adj = model;
model_adj.detail.preprocessing{2} = [pp model.detail.preprocessing{2}];   %add bias/slope correction
model_adj.detail.options.preprocessing{2} = [pp model.detail.options.preprocessing{2}];  %and update options too (so regenerating model gives THIS model)
model_adj.date = date;  %note that the model has been modified by changing the date/time
model_adj.time = clock;
model_adj.author = userinfotag;  %and note that THIS user recreated the model

%relabel fit results for return to caller
intercept = fit(:,2)';
slope = fit(:,1)';


