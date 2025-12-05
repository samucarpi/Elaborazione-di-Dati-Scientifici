function model = multiclassifications(model, pred, options)
%Classification by three rules, mostprobable, inclass and inclasses
% Assigns multi-classifications to each calibration sample for model types 
% svmda, plsda, knn and simca. Similarly for pred structures. 
%
% When a prediction structure is input, it usually must be passed with the
% calibration model it was generated from. The single output will be the
% prediction structure modified to include the classification information.
%
%  INPUTS: 
%      model = standard model structure for a classification model.
%
%  OPTIONAL INPUTS:
%       pred = prediction structure generated from the input for new data
%             (if classification results should be made for predicted data
%             rather than calibration data)
%    options = structure array with the following fields:
%         strictthreshold: [0.5] Threshold probability for associating
%                          sample with a class.
%  OUTPUTS:
%  model or prediction updated by the addition of the classification field.
%  classification is a struct with fields:
%        .probability  = predprobability;
%        .mostprobable = mostprobable;
%        .inclass      = inclass;   % 0 means no class identified
%        .inclasses    = inclasses; % 0/1 = is not/is in class
%        .classnums    = mapping from index (or column) to class
%        .classids     = cell array containing string descriptions for each
%                        class identified in classnums.
% and where:
%  probability:  nsamples x nclasses array of per-sample, per-class probs,
%                with columns in order of classnums.
%  mostprobable: index to classnums. associates sample with the class  
%                having the largest prob. These are INDICES into classnums
%  inclasses:    nsamples x nclasses array, columns in order of classnums.
%                associates sample with one or more classes if prob for
%                that class is greater than 
%                options.strictthreshold (default 0.5).               
%  inclass:      index to classnum: associates sample with at most one 
%                class if prob is greater than the threshold for that one 
%                class. The sample is assigned to class 0 if no class prob, 
%                or more than one class prob, exceeds the threshold.
%                These are INDICES into classnums
%  classnums:    Vector of classes, sorted ascending.
%   classids:    Vector of classes, order matching classnums.
%
%I/O: model = multiclassifications(model, options)
%I/O: pred  = multiclassifications(model, pred, options)
%
%See also: KNN, PLSDA, SIMCA, SVMDA

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==1 & ischar(model)
  options = [];
  options.strictthreshold = 0.5;
  options.simcathreshold  = 0.95;
  
  temp = model;
  clear model;
  if nargout==0; evriio(mfilename,temp,options); else; model = evriio(mfilename,temp,options); end
  return; 
end

switch nargin
  case 1
    % (model)
    pred = [];
    options = model.detail.options;
  case 2
    % (model, options)
    % (model, pred)
    if ~ismodel(pred)
      % (model, options)
      options = pred;
      pred = [];
    else
      % (model, pred)
      options = model.detail.options;
    end
  case 3
    % (model, pred, options)
end
options = reconopts(options,mfilename,0);
threshold = options.strictthreshold;

if isempty(model)
  error('Model is empty')
elseif ~ismodel(model)
  error('Model is not recognized as a standard model structure')
end

%initialize these two as empty...
classification = struct([]);
cvclassification = struct([]);

switch lower(model.modeltype)
  case {'knn' 'knn_pred'}
    %KNN model classification information
    classset = model.detail.options.classset;
    if isempty(pred);
      knnp = model.pred{1};
      knnv = model.votes;
      k    = model.k;
    else
      knnp = pred.pred{1};
      knnv = pred.votes;
      k    = pred.k;
    end

    classnums = setdiff( unique(model.detail.class{1,1,classset}), 0);
    if isempty(classnums) & ~isempty(model.detail.classlookup{1,1,classset})
      %no classes but a lookup table is there? use it
      tmp = model.detail.classlookup{1,1,classset}(:,1);
      classnums = setdiff( unique( [tmp{:}]), 0);
    end
    classids  = getclassid(model,classnums);
    
    %calculate probability (based on votes)
    predprob = repmat(0, size(knnp,1), length(classnums));
    ici = 0;
    for ic=classnums
      ici = ici+1;
      match = repmat(ic, size(knnv));
      imatch = knnv == match;
      predprob(:,ici) = sum(imatch,2)/k;
    end
    classification = gettheclassifications( predprob, classnums, classids, threshold );
    
    if ~isempty(model.detail.cvpred)
      %cross-validated classification information (if available)
      cvclassification = classification;
      
      cvp=model.detail.cvpred(:,:,k);
      [tmp,tindex] = ismember(cvp, cvclassification.classnums);
      tindex(~tmp) = nan;  %put NaN for any classes not found in classnums
      
      cvclassification.mostprobable = tindex; % mostprobable and inclass are INDICIES into classnums
      cvclassification.inclass      = tindex;
      cvclassification.probability  = repmat(nan, size(tindex,1), size(classification.probability,2)); %classification.probability.*nan;
      cvclassification.inclasses    = cvclassification.probability; %classification.inclasses.*nan;
    end
    
    
  case {'plsda' 'plsda_pred' 'annda' 'annda_pred' 'lregda' 'lregda_pred' 'anndlda' 'anndlda_pred'}
    mods1 = {'plsda' 'plsda_pred'};
    mods2a = {'annda' 'annda_pred'};
    mods2b = {'anndlda' 'anndlda_pred'};
    mods3 = {'lregda' 'lregda_pred'};
    %PLSDA model classification information
    % Set each sample's predictedclass to the class with the highest predprobability value
    model.detail.predictedclass = [];
    classnums = model.detail.class{2,2};
    if ~isempty(classnums)
      %user-supplied y-block without classes on columns
      classids  = getclassid(model,classnums);
    else
      %no classes on y (prob a custom y-block)? use column index 
      classnums = 1:model.datasource{2}.size(2);
      classids  = str2cell(sprintf('Column %i\n',classnums))';
    end
    if isempty(pred)
      prob = model.detail.predprobability;
    else
      prob = pred.detail.predprobability;
    end
    if ~isempty(prob)
      classification = gettheclassifications( prob, classnums, classids, threshold );
      
      if ~isempty(model.detail.cvpred)
        %cross-validated classification information (if available)
        nlv = size(model.detail.cvpred,3);
        switch lower(model.modeltype)
          case mods1     % plsda
            ncom = min(size(model.loads{2},2), nlv); 
          case mods2a    % annda
            ncom = model.detail.options.nhid1;
          case mods2b    % anndlda
            ncom = nlv;
          case mods3     % lregda
            ncom = 1;
          otherwise
            ncom = 1;
        end
        cvpred = model.detail.cvpred(:,:,ncom);
        
        if ncom <= nlv
          pr = cvpred*nan;
          if strcmp(lower(model.modeltype), 'lregda')
            pr = getsoftmax(cvpred);
          else
            for j=1:size(cvpred,2);
              use = isfinite(cvpred(:,j));
              pr(use,j) = lookupprobability(model.detail.probability{j},cvpred(use,j));
            end
          end
          cvclassification = gettheclassifications( pr, classnums, classids, threshold );
        end
      end
    end
    
    
  case {'svmda' 'svmda_pred'}
    %SVMDA model classification information
    % predprobability columns are classes, as  model.detail.svm.model.label
    classnums = double(model.detail.svm.model.label');
    classids  = getclassid(model,classnums);
    if isempty(pred)
      prob = model.detail.predprobability;
      predclassnum=model.pred{2};  
    else
      prob = pred.detail.predprobability;
      predclassnum=pred.pred{2};  
    end
    % "prob" values are all nan if option probabilityestimates=0. Instead,
    % set prob based on use model.pred{2} or pred. Set prob=1 for the pred
    % class, zero for the other classes.
    % prob columns are classnums: col 1 is prob for class=classnums(1)
    % model.pred{2} values are classnums
    % Convert model.pred{2} to prob:
    if all(isnan(prob(:)))
      %       predclassnum=model.pred{2};
      [Y,I] = sort(classnums);
      tx = ones(max(classnums),1);
      tx(Y)=I;  % map from classnums to index of classnum
      predclassnumindex = tx(predclassnum);  %
      prob = class2logical(predclassnumindex);
      prob = prob.data;
      % may need to size down the classnums/classids to match prod columns 
      isin = ismember(classnums, predclassnum);
      classnums = classnums(isin);
      classids = classids(isin);
    end

    classification = gettheclassifications( prob, classnums, classids, threshold );
        
    if ~isempty(model.detail.cvpred)
      %cross-validated classification information (if available)
      cvclassification = classification;
      % get indicies of sorted classnums
      [lia, classnumindex] = ismember(model.detail.cvpred', classification.classnums);
      cvclassification.mostprobable = classnumindex; % is index into sorted classnums 
      cvclassification.inclass      = classnumindex; 
      cvclassification.probability  = classification.probability.*nan;
      cvclassification.inclasses    = classification.inclasses.*nan;
    end
    
  case {'simca' 'simca_pred'}
    %SIMCA model classification information
    predprob  = getsimcapredprob(model,pred,model.options.rule.name);
    subcls    = model.detail.submodelclasses;
    classids  = getclassid(model,subcls);
    classnums  = 1:length(subcls); % these will always be simply 1, 2, ...
    classification = gettheclassifications(predprob, classnums, classids, threshold);
    
    %cannot do any cross-validated classification (yet)
  case {'xgbda' 'xgbda_pred'}
    % model classification information
    classset = model.detail.options.classset;
    classnums = double(model.detail.xgb.model.label');
    classids  = getclassid(model,classnums);
 
    if isempty(pred)
      prob = model.detail.predprobability;
    else
      prob = pred.detail.predprobability;
    end
    if ~isempty(prob)
        classification = gettheclassifications( prob, classnums, classids, threshold );
        
        if ~isempty(model.detail.cvpred)
            %cross-validated classification information (if available)
            cvclassification = classification;
            % get indicies of sorted classnums
            [lia, classnumindex] = ismember(model.detail.cvpred', classification.classnums);
            cvclassification.mostprobable = classnumindex; % is index into sorted classnums
            cvclassification.inclass      = classnumindex;
            cvclassification.probability  = classification.probability.*nan;
            cvclassification.inclasses    = classification.inclasses.*nan;
        end
    end

  case {'lda' 'lda_pred'}
    % LDA model classification information
    classification = [];
    predprob  = model.predprobability;

    classnums = model.detail.class{2,2};
    if ~isempty(classnums)
      %user-supplied y-block without classes on columns
      classids  = getclassid(model,classnums);
    else
      %no classes on y (prob a custom y-block)? use column index 
      classnums = 1:model.datasource{2}.size(2);
      classids  = str2cell(sprintf('Column %i\n',classnums))';
    end
    if isempty(pred)
      prob = model.detail.predprobability;
    else
      prob = pred.detail.predprobability;
    end
    if ~isempty(prob)
      classification = gettheclassifications( prob, classnums, classids, threshold );

      if ~isempty(model.detail.cvpred)
        %cross-validated classification information (if available)
        ncomp   = size(model.loads{1},2);
        cvpred1 = model.detail.cvpred(:,:, ncomp);  % These are class probs
        cvclassification = gettheclassifications( cvpred1, classnums, classids, threshold );
      end
    end
    
    %cannot do any cross-validated classification (yet)
    
    otherwise
    % error('Cannot calculate classification information for model type "%s"',model.modeltype);
    return;

end
if isempty(pred)
  %acting on calibration data
  model.classification = classification;
  if ~isempty(cvclassification)
    model.detail.cvclassification = cvclassification;
  end
else
  %had a prediction structure? save results there
  pred.classification = classification;
  %and pass back pred as output
  model = pred;
end

%--------------------------------------------------------------------------
function classification = gettheclassifications(predprobability, classnums, classids, threshold)
% Fill the classification fields (for use in model.classification)
% probability:  is predprobability, with columns possibly reordered to
%               match sorted classnums
% mostprobable: index to classnum of the most probable class
% inclass:      index to classnum of identified class according to 'strict'
%               classification rules. 0 means no class is identified.
% inclasses:    array corresponding to predprobability, of 0/1 where 1
%               indictes that column class is suggested. May be more than
%               one class suggested.
% classnums:    Vector of classes, sorted ascending.
%  classids:    Vector of classes, order matching classnums.
% 
% Note, returned classification fields classnums are sorted in increasing
% order. classids are correspond to classnums. Also, the columns of
% probability and inclasses are in order classnums

classification = [];
classification.mostprobable = [];
classification.inclass      = [];   % 0 means no class identified
classification.inclasses    = [];   % 0/1 = is not/is in class
classification.probability  = [];
classification.classnums    = [];
classification.classids     = {};

if ~isempty(predprobability)
  
  % reorder columns of predprobability to be in order of sorted classnums
  [classnums, ii] = sort(classnums);
  predprobability = predprobability(:,ii);
  classids = classids(ii);
  
  % do not consider columns which are all NaNs
  nancolumns = all(isnan(predprobability), 1);
  isbad = any(~isfinite(predprobability(:, ~nancolumns)),2);
  
  [maxval, predictedClassInd]=max(predprobability, [], 2);
  mostprobable =  predictedClassInd;
  mostprobable(isbad) = nan;  
  inclasses = predprobability>threshold;
  inclasses(isbad,:) = false;
  % inclass
  [maxval, ind] = max(inclasses, [], 2);
  indg = sum(inclasses,2)==1;  % rows with only one non-zero
  ind(~indg) = 0;
  inclass = ind;
  inclass(isbad) = nan;
  
  % NOTE: mostprobable and inclass give index of classnums (or 0)
  classification.mostprobable = mostprobable;
  classification.inclass      = inclass;   % 0 means no class identified
  classification.inclasses    = inclasses; % 0/1 = is not/is in class
end
classification.probability  = predprobability;
classification.classnums    = classnums;
classification.classids     = classids;

%--------------------------------------------------------------------------
function probabilities = getsimcapredprob(model,pred,rule)
%Get per-sample, per-class probabilites from simca model
submodelclasses = model.detail.submodelclasses;
ns = length(submodelclasses);

if isempty(pred)
  submodels = model.submodel;
  m = model.datasource{1}.size(1);
  combinedvalue = model.rules.combined.value;
else
  submodels = pred.submodel;
  m = pred.datasource{1}.size(1);
  combinedvalue = pred.rules.combined.value;
end

if strcmp(rule,'combined')
  %special handling for combined rule
  nsteps = 100;
  tsthresh = model.detail.options.rule.limit.t2;
  minth = 2*tsthresh-1;
  maxth = max(.999,(1+minth)/2);
  tclrnge  = linspace(minth,maxth,nsteps);  %confidence limit range needed for probability mapping
  tp = (1-(tclrnge))/(1-tsthresh)*0.50;  %corresponding probabilities

  qsthresh = model.detail.options.rule.limit.q;
  minth    = 2*qsthresh-1;
  maxth    = max(.999,(1+minth)/2);
  qclrnge  = linspace(minth,maxth,nsteps);  %confidence limit range needed for probability mapping
  qp = (1-(qclrnge))/(1-qsthresh)*0.50;  %corresponding probabilities

  p = (tp+qp)/2;
  
  probabilities = combinedvalue.*nan;
  for im=1:length(submodelclasses)
    tlim = tsqlim(model.submodel{im},[tclrnge model.detail.options.rule.limit.t2]);
    tlim = tlim(1:end-1)./tlim(end);  %scale to  limit
    qlim = residuallimit(model.submodel{im},[qclrnge model.detail.options.rule.limit.q]);
    if qlim(end)>0
      qlim = qlim(1:end-1)./qlim(end);  %scale to limit
    else
      qlim = qlim(1:end-1);
    end
    %If we wanted to put the ellipse ending at Q and T^2 independent limits
    %tlim = tlim./sqrt(2);
    %qlim = qlim./sqrt(2);
    probabilities(:,im) = interp1([0 sqrt(qlim.^2+tlim.^2)],[1 p],combinedvalue(:,im),'linear',0);
  end

else
  %all other rules
  
  if ~strcmpi(rule,'q')  %EXCEPT for Q only rule
    % T2
    clevtsq = nan(m, ns);
    for im=1:length(submodelclasses)
      tsqs = submodels{im}.tsqs;
      if iscell(tsqs)
        tsqs = tsqs{1};
      end
      clevtsq(:,im) = tsqlim(model.submodel{im}, tsqs, 2);
    end
    probtsq = 1 - clevtsq;
  end
  
  if ~strcmpi(rule,'t2')  %EXCEPT for T2 only rule
    % Q
    clevq = nan(m, ns);
    resopts = residuallimit('options');
    resopts.algorithm = 'invjm';
    for im=1:length(submodelclasses)
      ssqresiduals = submodels{im}.ssqresiduals;
      if iscell(ssqresiduals)
        ssqresiduals = ssqresiduals{1};
      end
      clevq(:,im) = residuallimit(model.submodel{im}, ssqresiduals, resopts);
    end
    probq   = 1 - clevq;
  end
  
  switch lower(rule)
    case 't2'
      probabilities = probtsq;
      sthresh = model.detail.options.rule.limit.t2;
      probabilities = probabilities/(1-sthresh)*0.50;  %transform using confidence level threshold
    case 'q'
      probabilities = probq;
      sthresh = model.detail.options.rule.limit.q;
      probabilities = probabilities/(1-sthresh)*0.50;  %transform using confidence level threshold
    case 'both'
      % Take the lower of the T2 or Q probability
      probtsq = probtsq/(1-model.detail.options.rule.limit.t2)*0.5;
      probq   = probq/(1-model.detail.options.rule.limit.q)*0.5;      
      probabilities = probtsq;
      useq = probq<probtsq;
      probabilities(useq) = probq(useq);
  end
  
end

probabilities = max(min(probabilities,1),0);

%--------------------------------------------------------------
function  pr = lookupprobability(probmap,pred)
%use probability map to look up a given predictions probabilty
if size(probmap,1) > 1
  pr = interp1(probmap(:,1),probmap(:,3),pred,'linear','extrap');
else
  pr = ones(size(pred,1),1)*probmap(:,3);  % handle LREG case
end
bad = ~isfinite(pr);
if any(bad)
  %for values outside of range, go to highest or nearest probability
  pr(bad) = interp1(probmap(:,1),probmap(:,3),pred(bad),'nearest','extrap');
end

%--------------------------------------------------------------
function classid = getclassid(model,cls)

classset = model.detail.options.classset;
switch lower(model.modeltype)
  case {'plsda' 'svmda' 'annda' 'anndlda' 'lregda'}
    lu = model.detail.classlookup{2,2,1};
    if isempty(lu);
      lu = model.detail.classlookup{1,1,classset};
    end
    
  case 'simca'
    lu = model.detail.modeledclasslookup{1};  %ALWAYS first set (modified)
    classes = cell2mat(lu(:,1));
    classid = lu(classes>0,2);  % Do not return class 0
    classid = classid(:)';  %force it to be a ROW vector (to match others)
    return;
    
  case 'xgbda'   
    lu = model.detail.classlookup{2,2,1};
    if isempty(lu);
      lu = model.detail.classlookup{1,1,classset};
    end
    
  case 'lda'    
    lu = model.detail.classlookup{2,2,1};
  otherwise
    lu = model.detail.classlookup{1,1,classset};
    
end
if ~iscell(cls)
  %force to be a cell (isn't if not grouped)
  cls = num2cell(cls);
end
if isempty(lu)
  %no lookup table? base it on cls
  luval = unique([cls{:}])';
  lu = [num2cell(luval) str2cell(sprintf('Class %i\n',luval))];
else
  luval = [lu{:,1}];
end
classid = cell(1,length(cls));
[classid{:}] = deal('n/a');
for j=1:length(cls)
  indx = findindx(luval,cls{j});  %find rows of lookup which match class #
  id   = sprintf('%s,',lu{indx,2});  %create string of all (if grouped)
  classid{j} = id(1:end-1);  %drop ending comma
end
