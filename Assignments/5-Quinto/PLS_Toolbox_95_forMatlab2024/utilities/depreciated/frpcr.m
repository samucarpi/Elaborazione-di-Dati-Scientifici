function varargout = frpcr(varargin)
%FRPCR Full-ratio PCR calibration and prediction.
%  Calculates a single full-ratio PCR model using the given number of
%  components (ncomp) to predict (y) from measurements (x). Random
%  multiplicative scaling of each sample can be used to aid model
%  stability.
%  Full-Ratio PCR models, also known as Optimized Scaling 2 PCR models, are
%  based on the simultaneous regression for both y-block prediction and
%  scaling variations (such as those due to pathlength and collection
%  efficiency variations in spectroscopy). The resulting PCR model is
%  usually much less sensitive to sample scaling errors.
%  NOTE: For best results, the x-block should not be mean-centered.
%
%  INPUTS:
%        x  = X-block: predictor block (2-way array or DataSet Object),
%        y  = Y-block: predicted block (2-way array or DataSet Object), and
%     ncomp = number of components to to be calculated (positive integer scalar).
%
%  OPTIONAL INPUT:
%   options = structure variable used to govern the algorithm with the following fields:
%           display: [ 'off' | {'on'} ]          Governs level of display to command window.
%             plots: [ {'none'} | 'intermediate' | 'final' ]  Governs level of plotting.
%     preprocessing: { [] [] }                    preprocessing structure (see PREPROCESS).
%      blockdetails: [ {'standard'} | 'all' ]     Extent of predictions and raw residuals
%                       included in model. 'standard' = only y-block, 'all' x and y blocks
%   confidencelimit: [{0.95}] Confidence level for Q and T2 limits. A value
%                     of zero (0) disables calculation of confidence
%                     limits.
%     In addition, there are several options relating to the algorithm. See
%     FRPCRENGINE.
%
%  OUTPUT:
%     model = standard model structure (See MODELSTRUCT)
%
%I/O: model = frpcr(x,y,ncomp,options);  %identifies model (calibration step)
%I/O: pred  = frpcr(x,model,options);    %makes predictions with a new X-block
%I/O: valid = frpcr(x,y,model,options);  %makes predictions with new X- & Y-block
%I/O: frpcr demo                         %runs a demo of the FRPCR function.
%
%See also: FRPCRENGINE, MSCORR, PCR

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 3/24/03 fixed bug when y is not dataset
%rsk 05/24/04 fix bug set include fields in y to those of model in test mode.
%jms 5/26/05 incorporated PCR changes into FRPCR

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1}) %Help, Demo, Options

  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';    %Governs plots to make
  options.preprocessing = {[] []};   %preprocessing structures
  options.blockdetails  = 'standard';
  options = reconopts(options,frpcrengine('options'));   %add engine options
  options.confidencelimit = 0.95;

  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin < 2; error(['Insufficient inputs']); end

%A) Check Options Input
predictmode = 0;    %default is calibrate mode

switch nargin
  case 2  %two inputs
    %v3 : (x,model)
    if isa(varargin{2},'struct')
      varargin = {varargin{1},[],[],frpcr('options'),varargin{2}};
    else
      error(['Input NCOMP is missing. Type: ''help ' mfilename '''']);
    end

  case 3  %three inputs
    %v3 : (x,y,ncomp)
    %v3 : (x,y,options) ??? (invalid, need ncomp)
    %v3 : (x,model,options)
    %v3 : (x,y,model)

    if ~isa(varargin{3},'struct');
      %v3 : (x,y,ncomp)
      varargin{4} = frpcr('options');
    elseif isa(varargin{2},'struct');
      %v3 : (x,model,options)
      varargin = {varargin{1},[],[],varargin{3},varargin{2}};
    elseif ~isfield(varargin{3},'modeltype');
      %v3 : (x,y,options) ???
      error(['Input NCOMP is missing. Type: ''help ' mfilename '''']);
    else
      %v3 : (x,y,model)
      varargin{5} = varargin{3};                    %check model format later
      varargin{4} = frpcr('options');                 %get default options
      varargin{3} = [];                             %get ncomp from model
    end

  case 4   %four inputs
    %v3 : (x,y,model,options)
    %v3 : (x,y,ncomp,model)
    %v3 : (x,y,ncomp,options)

    if ~isa(varargin{4},'struct');
      error(['Input OPTIONS or MODEL not recognized. Type: ''help ' mfilename ''''])

    elseif isa(varargin{3},'struct');
      %v3 : (x,y,model,options)
      varargin{5} = varargin{3};
      varargin{3} = [];

    elseif isfield(varargin{4},'modeltype')
      %v3 : (x,y,ncomp,model)
      varargin{5} = varargin{4};
      varargin{4} = frpcr('options');   %default options

    else
      %v3 : (x,y,ncomp,options)
    end

  case 5  %five inputs
    %v3 : (x,y,ncomp,model,options)
    %v3 : (x,y,ncomp,options,model)  (technically invalid but we'll accept it anyway)
    if ~isfield(varargin{5},'modeltype');
      varargin([4 5]) = varargin([5 4]);  %swap options and model so model is #5
    end

end

try
  options = reconopts(varargin{4},frpcr('options'));
catch
  error(['Input OPTIONS not recognized. Type: ''options = ' mfilename '(''options'');'])
end
options.blockdetails = lower(options.blockdetails);
if ~ismember(options.blockdetails,{'compact','standard','all'})
  error(['OPTIONS.BLOCKDETAILS not recognized. Type: ''help ' mfilename ''''])
end

%B) check model format
if length(varargin)>=5;
  try
    varargin{5} = updatemod(varargin{5});        %make sure it's v3.0 model
  catch
    error(['Input MODEL not recognized. Type: ''help ' mfilename ''''])
  end
  predictmode = 1;                                  %and set predict mode flag
  if isempty(varargin{3});
    varargin{3} = size(varargin{5}.loads{2,1},2);   %get ncomp from model (if needed)
  end
end

%C) CHECK Data Inputs
  [datasource{1:2}] = getdatasource(varargin{1:2});
if isa(varargin{1},'double')    %convert varargin{1} and varargin{2} to DataSets
  varargin{1}        = dataset(varargin{1});
  varargin{1}.name   = inputname(1);
  varargin{1}.author = 'FRPCR';
elseif ~isa(varargin{1},'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(varargin{1}.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(varargin{1}.data)),' modes.'])
end

if ~isempty(varargin{2});
  haveyblock = 1;
  if isa(varargin{2},'double') | isa(varargin{2},'logical')
    varargin{2}        = dataset(varargin{2});
    varargin{2}.name   = inputname(2);
    varargin{2}.author = 'FRPCR';
  elseif ~isa(varargin{2},'dataset')
    error(['Input Y must be class ''double'', ''logical'' or ''dataset''.'])
  end
  if isa(varargin{2}.data,'logical');
    varargin{2}.data = double(varargin{2}.data);
  end
  if ndims(varargin{2}.data)>2
    error(['Input Y must contain a 2-way array. Input has ',int2str(ndims(varargin{2}.data)),' modes.'])
  end
  if size(varargin{1}.data,1)~=size(varargin{2}.data,1)
    error('Number of samples in X and Y must be equal.')
  end
  %Check INCLUD fields of X and Y
  i       = intersect(varargin{1}.includ{1},varargin{2}.includ{1});
  if ( length(i)~=length(varargin{1}.includ{1,1}) | ...
      length(i)~=length(varargin{2}.includ{1,1}) )
    if (strcmp(lower(options.display),'on')|options.display==1)
      disp('Warning: Number of samples included in X and Y not equal.')
      disp('Using intersection of included samples.')
    end
    varargin{1}.includ{1,1} = i;
    varargin{2}.includ{1,1} = i;
  end
  %Change include fields in y dataset. Confirm there are enough y columns
  %before trying.
  if length(varargin)>=5
    if size(varargin{2}.data,2)==length(varargin{5}.detail.includ{2,2})
      %SPECIAL CASE - ignore the y-block column include field if the
      %y-block contains the same number of columns as the include field.
      varargin{5}.detail.includ{2,2} = 1:size(varargin{2}.data,2);
    else
      %otherwise, do the rest of this to match include fields with y.
        if any(varargin{5}.detail.includ{2,2}>size(varargin{2}.data,2))
        %trap this one error to give more diagnostic information than the
        %error below gives
        error('Y-block columns included in model do not match number of columns in test set.');
      end
      try
        varargin{2}.include{2} = varargin{5}.detail.includ{2,2};
      catch
        error('Model include field selections will not work with current Y-block.');
      end
    end
  end
else    %empty y = NOT haveyblock mode (predict ONLY)
  haveyblock = 0;
end

%D) Check Meta-Parameters Input
ncomp = varargin{3};
if isempty(ncomp) | prod(size(ncomp))>1 | ncomp<1 | ncomp~=fix(ncomp);
  error('Input NCOMP must be integer scalar.')
end
if predictmode & ncomp~=size(varargin{5}.loads{2,1},2);
  error('Cannot use a different number of components (NCOMP) with previously created model');
end

%----------------------------------------------------------------------------------------
x = varargin{1};
y = varargin{2};

if isempty(options.preprocessing);
  options.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};
end
if length(options.preprocessing)==1;
  options.preprocessing = options.preprocessing([1 1]);
end

preprocessing = options.preprocessing;

if ~predictmode;

  warning('EVRI:Depreciated','FRPCR is depreciated. Full-ratio PCR should be accessed via the .algorithm option of PCR.')
  
  if mdcheck(x);
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
    [flag,missmap,x] = mdcheck(x);
  end

  %Do preprocessing
  if ~isempty(preprocessing{2});
    [ypp,preprocessing{2}] = preprocess('calibrate',preprocessing{2},y);
  else
    ypp = y;
  end
  if ~isempty(preprocessing{1});
    [xpp,preprocessing{1}] = preprocess('calibrate',preprocessing{1},x,ypp);
  else
    xpp = x;
  end

  %Call regression Function
  [b,ssq,u,sampscales,msg,options] = frpcrengine(xpp, ypp, ncomp, options);
  options.msg = msg;

  model = modelstruct('pcr');
  model.modeltype = 'FRPCR';
  [datasource{1:2}] = getdatasource(xpp,ypp);
  model.datasource = datasource;
  model.date = date;
  model.time = clock;
  model.info = 'Scores are in row 1 of cells in the loads field.';
  model.reg  = b;
  model.loads{2,1} = u;
  model.description = { 'Full-Ratio Principal Components Regression Model' ; [] ; [] };

  model.detail.means{1,1}  = NaN*ones(1,size(xpp.data,2));
  model.detail.means{1,2}  = NaN*ones(1,size(ypp.data,2));
  model.detail.means{1,1}(1,xpp.includ{2}) = ...
    mean(xpp.data(xpp.includ{1},xpp.includ{2})); %mean of X-block
  model.detail.means{1,2}(1,ypp.includ{2}) = ...
    mean(ypp.data(ypp.includ{1},ypp.includ{2})); %mean of Y-block
  model.detail.stds{1,1}   = NaN*ones(1,size(xpp.data,2));
  model.detail.stds{1,2}   = NaN*ones(1,size(ypp.data,2));
  model.detail.stds{1,1}(1,xpp.includ{2}) = ...
    std(xpp.data(xpp.includ{1},xpp.includ{2})); %std of X-block
  model.detail.stds{1,2}(1,ypp.includ{2}) = ...
    std(ypp.data(ypp.includ{1},ypp.includ{2})); %std of Y-block

  model = copydsfields(xpp,model,[],{1 1});
  model = copydsfields(ypp,model,[],{1 2});

  model.datasource = datasource;
  model.detail.ssq           = ssq;
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model

else    %5 inputs implies that input #5 is a raw model previously output, don't decompose/regress

  model = varargin{5};
  if ~strcmp(lower(model.modeltype),'frpcr');
    error('Input MODEL is not a Full-Ratio PCR model');
  end

  if size(x.data,2)~=model.datasource{1}.size(1,2)
    error('Variables included in data do not match variables expected by model');
  else
    missing = setdiff(model.detail.includ{2,1},x.include{2,1});
    x.data(:,missing) = nan;  %replace expected but missing data with NaN's to force replacement
    x.includ{2,1} = model.detail.includ{2,1};
  end

  if mdcheck(x.data(:,x.includ{2,1}));
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess" from existing model. Results may be affected by this action.'); end
    x = replacevars(model,x);
  end

  preprocessing = model.detail.preprocessing;   %get preprocessing from model
  if haveyblock & ~isempty(preprocessing{2});
    [ypp]                           = preprocess('apply',preprocessing{2},y);
  else
    ypp = y;
  end
  if ~isempty(preprocessing{1});
    [xpp]                           = preprocess('apply',preprocessing{1},x);
  else
    xpp = x;
  end

  model = copydsfields(x,model,[1],{1 1});
  model.detail.includ{1,2} = x.includ{1};
  model.datasource = datasource;


  %Update time and date.
  model.date = date;
  model.time = clock;

end

%copy options into model
model.detail.options = options;
%fill in for all mode 1 sample values (in addition to the .includ field)
%calculate tsqs, residuals, scores for non-included samples.
if ~predictmode;
  %reduce to # of LVs requested (or maxrank of scores)
  maxrank = rank(model.loads{2,1});
  if maxrank < ncomp;
    ncomp = maxrank;
  end
  model.detail.ssq    = model.detail.ssq(1:ncomp,:);
end

%X-Block Statistics
model.loads{1,1}      = xpp.data(:,model.detail.includ{2,1})*model.loads{2,1};
model.detail.data{1}  = x;
model.pred{1}  = model.loads{1,1}*model.loads{2,1}';
model.detail.res{1}   = xpp.data(:,model.detail.includ{2,1}) - model.pred{1};

model.ssqresiduals{1,1} = model.detail.res{1}.^2;
model.ssqresiduals{2,1} = sum(model.ssqresiduals{1,1}(model.detail.includ{1,1},:),1); %based on cal samples only
model.ssqresiduals{1,1} = sum(model.ssqresiduals{1,1},2); %residuals for ALL samples
if ~predictmode;
  if isfield(model.detail,'pcassq') & size(model.detail.pcassq,1)>ncomp;
    model.detail.reseig = model.detail.pcassq(ncomp+1:end,2);
    if options.confidencelimit>0
      model.detail.reslim{1,1} = residuallimit(model.detail.reseig, options.confidencelimit);
    else
      model.detail.reslim{1,1} = 0;
    end
  else
    %calculate residual eigenvalues using raw residuals matrix
    if options.confidencelimit>0
      [model.detail.reslim{1,1} model.detail.reseig] = residuallimit(model.detail.res{1}(model.detail.includ{1,1},:), options.confidencelimit);
    else
      model.detail.reslim{1,1} = 0;
    end
  end
end

if ~predictmode;
  origmodel = model;
else
  origmodel = varargin{5};   %get pointer to original model
end
incl    = origmodel.detail.includ{1,1};
m       = length(incl);
T       = origmodel.loads{1,1};
P       = origmodel.loads{2,1};
T_cal   = T(incl,:);

f       = diag(sqrt(1./(diag(T_cal'*T_cal)/(m-1))));
predT   = model.loads{1,1};
if ncomp > 1
  tsq1    = sum((f*predT').^2)';
  tsq2    = sum((f*P').^2)';
else
  tsq1    = ((f*predT').^2)';
  tsq2    = ((f*P').^2)';
end
model.detail.leverage = tsq1/(m-1);
model.tsqs{1,1} = tsq1;
model.tsqs{2,1} = tsq2;

if ~predictmode;
  if options.confidencelimit>0
    model.detail.tsqlim{1,1} = tsqlim(length(model.detail.includ{1,1}),ncomp,options.confidencelimit*100);
  else
    model.detail.tsqlim{1,1} = 0;
  end
else
  model.tsqs(:,2) = {[];[]};
end

%Y-Block Statistics
%store original and predicted Y values
model.detail.data{1,2}   = y;
ypred                    = frpcrengine(xpp.data(:,xpp.includ{2}),model.reg);  %PREDICT mode
model.pred{1,2}   = preprocess('undo',preprocessing{2},ypred);
model.pred{1,2}   = model.pred{1,2}.data;
model = calcystats(model,predictmode,ypp,ypred);

%label as prediction
if predictmode
  model.modeltype = [model.modeltype '_PRED'];
else
  model = addhelpyvars(model);
end

%handle model compression
switch lower(options.blockdetails)
  case {'compact' 'standard'}
    model.detail.data{1} = [];
    model.pred{1} = [];
    model.detail.res{1}  = [];
end

varargout{1} = model;

switch lower(options.plots)
  case {'final','intermediate'}

    if ~predictmode

      if options.pathvar ~= 0;
        subplot(2,2,1)
      else
        subplot(2,1,1)
      end
      plot(model.detail.data{2}.data(model.detail.includ{1,1},:),...
        model.pred{2}(model.detail.includ{1,1},:),'.')
      dp
      title('Prediction')
      xlabel('Measured Y')
      ylabel('Predicted Y')

      if options.pathvar ~= 0;
        subplot(2,2,2)
      else
        subplot(2,1,2)
      end
      plot(model.detail.data{2}.data(model.detail.includ{1,1},:),...
        model.detail.res{2}(model.detail.includ{1,1},:),'.')
      hline
      title(['Residuals SEC: ' num2str(model.detail.rmsec)])
      xlabel('Measured Y')
      ylabel('Y Residuals')

      if options.pathvar ~= 0;
        yphat   = frpcrengine(diag(model.detail.options.sampscales)*xpp.data(xpp.includ{1},xpp.includ{2}),model.reg);
        yphat   = preprocess('undo',preprocessing{2},yphat);
        yphat   = yphat.data;
        scalerr = sqrt(sum((yphat-model.pred{2}(model.detail.includ{1,1},:)).^2)./(length(xpp.includ{1})-1))./options.pathvar;
        subplot(2,1,2)
        plot(model.detail.options.sampscales(model.detail.includ{1,1}),...
          yphat-model.pred{2}(model.detail.includ{1,1},:),'.');
        hline
        title(['Scaling sensitivity: ' num2str(scalerr)])
        xlabel('Y fractional variation')
        ylabel('Y sensitivity')
      end

      shg
      drawnow

    else
      figure
%       plotloads(varargin{5},model);
      plotscores(varargin{5},model);
    end

end

%End Input


