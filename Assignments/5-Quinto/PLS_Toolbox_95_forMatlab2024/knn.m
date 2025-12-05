function [pclass,closest,votes] = knn(varargin);
%KNN K-nearest neighbor classifier.
% Performs kNN classification where the "k" closest samples in a reference
% set vote on the class of an unknown sample based on distance to the
% reference samples. If no majority is found, the unknown is assigned the
% class of the closest sample (see input options for other no-majority
% behaviors).
%
% INPUTS:
%   xref  = a DataSet object of reference data
%   xtest = a DataSet object or Double containing the unknown test data.
% OPTIONAL INPUTS:
%   model = an optional standard KNN model structure which can be passed
%           instead of xref (note order of inputs: (xtest,model) ) to apply
%           model to test data.
%   k     = an optional number of neighbors to use in vote for class of
%           unknown {default = 3}. If k=1, only the nearest sample will
%           define the class of the unknown.
%   options = options structure containing one or more of the following
%      fields:
%           display : [ 'off' |{'on'}] governs display to screen.
%           waitbar : [ 'off' | 'on' |{'auto'}] governs display of a
%                     waitbar when classifying. 'on' always shows a
%                     waitbar, 'off' never shows a waitbar, 'auto' shows a
%                     waitbar only when the data is particularly large.
%     preprocessing : {[]} A cell containing a preprocessing structure or
%                    keyword (see PREPROCESS). Use {'autoscale'} to perform
%                    autoscaling on reference and test data.
%         classset  : [ 1 ] indicates which class set in xref to use.
%        nomajority : [ 'error' | {'closest'} | class_number ] Behavior when
%                    no majority is found in the votes. 'closest' = return
%                    class of closest sample. 'error' = give error message.
%                    class_number (i.e. any numerical value) = return this
%                    value for no-majority votes (e.g. use 0 to return zero
%                    for all no-majority votes)
%  strictthreshold: [0.5] Probability threshold for assigning a sample to a
%                   class. Affects model.classification.inclass.
%   predictionrule: { {'mostprobable'} | 'strict' ] governs which
%                   classification prediction statistics appear first in
%                   the confusion matrix and confusion table summaries.
%      compression: [{'none'}| 'pca' | 'pls' ] type of data compression
%                    to perform on the x-block prior to calculaing or
%                    applying the KNN model. 'pca' uses a simple PCA
%                    model to compress the information. 'pls' uses a pls
%                    model.
%    compressncomp: [ 1 ] Number of latent variables (or principal
%                    components to include in the compression model.
%       compressmd: [ 'no' |{'yes'}] Use Mahalnobis Distance corrected
% OUTPUT:
%  pclass = the voted closest class, if a majority of nearest neighbors
%           were of the same class, or the class of the closest sample, if
%           no majority was found (Only returned if xtest is supplied).
%  closest = matrix of samples (rows) by closest neighbor index (columns).
%            Will always have k columns indicating which samples were the
%            closest to the given sample (row).
%  votes   = maxtix of samples (rows) by class numbers voted for (columns).
%            Will always have k columns indicating which classes were voted
%            for by each nearest neighbor corresponding to closest matrix.
%
%  model  = if no test data (xtest) is supplied, a standard model structure
%           is returned which can be used with test data in the future to
%           perform a prediction. When model is input and applied to test
%           data the preedictions ('pclass') are in the returned model as
%           model.pred{1}
%
%I/O: [pclass,closest,votes] = knn(xref,xtest,k,options);   %make prediction without model
%I/O: [pclass,closest,votes] = knn(xref,xtest,options);     %use default k
%I/O: [pclass,closest,votes] = knn(xref,k,options);   %self-prediction without model
%
% Calls using standard model structures:
%
%I/O: model = knn(xref,k,options);         %create model
%I/O: model = knn(xtest,model,k,options);  %apply model to xtest
%I/O: model = knn(xtest,model,options);
%
%See also: ANALYSIS, CLUSTER, DBSCAN, KNNSCOREDISTANCE, MODELSELECTOR, PLSDA, SIMCA

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% by BMW
%08/13/04 rsk -prepare for toolbox
%01/26/06 rsk -fix label bug and add correct spacing in display.
%6/13/06 jms -added true kNN behavior (allowed more than one neighbor)

if nargin==0;
  if nargout==0;
    analysis('knn');
  else
    pclass = analysis('knn');
  end
  return
end

if ischar(varargin{1});
  options = [];
  options.preprocessing = {[]};
  options.display = 'on';
  options.waitbar = 'auto';
  options.nomajority = 'closest';
  options.classset = 1;
  options.strictthreshold = 0.5;    %probability threshold for class assign
  options.predictionrule = 'mostprobable';
  options.compression   = 'none';
  options.compressncomp = 1;
  options.compressmd    = 'yes';
  options.definitions = @optiondefs;
  if nargout==0; evriio(mfilename,varargin{1},options); else; pclass = evriio(mfilename,varargin{1},options); end
  return;
end

%Sort out inputs into appropriate variables (unlocated variables are
%returned empty)
[xref,xtest,k,options,model] = parseinputs(varargin{:});

% update model
if ismodel(model);
  try
    model = updatemod(model);
  catch
    error(['Input MODEL not recognized.'])
  end
end

if isempty(k);
  if isempty(model);
    %no model
    k = 3;  %default k
  else
    %user passed model - use these settings instead
    k = model.k;
  end
end

%check for old I/O (as much as we can tell)
if k<1 | k~=fix(k)
  error('Invalid input for number of neighbors. k must be a positive integer.')
end
if nargin==3 & isnumeric(varargin{2}) & isnumeric(varargin{3}) & k==1;
  evritip('knnoldio','KNN I/O Note: In older versions of KNN, the third input controlled scaling of the data. The third input now defines "k". If you wanted k=1, no action is necessary. If you wanted autoscaling, you must use options.preprocessing = {''autoscale''} to autoscale.',2);
end

%force test data into dataset if it isn't already
if ~isa(xtest,'dataset');
  xtest = dataset(xtest);
end

%put preprocessing into cell if it isn't already
if ~iscell(options.preprocessing)
  options.preprocessing = {options.preprocessing};
end

%No test data? create model structure and apply to same data
calibratemode = false;
if isempty(xtest.data)
  if nargout==1
    %only one output - standard model output
    model = modelstruct('knn');
    
    model.date = date;
    model.time = clock;
    
    model.datasource  = {getdatasource(xref)};
    model.detail.data = {xref};
    model.k           = k;
    model.detail.preprocessing = options.preprocessing;
    model.detail.options       = options;
    
    model = copydsfields(xref,model);
  else
    model = [];
  end
  
  %now, apply to calibration data (with LOO-style) and save model on exit
  calibratemode = true;
  xtest = xref;
  originalmodel = []; %no model passed
  refclassset = options.classset;
elseif ~isempty(model);
  %got a model from user? extract pieces to do prediction
  originalmodel = model;
  options.preprocessing = model.detail.preprocessing;
  refclassset = model.detail.options.classset;
  xref = model.detail.data{1};
else
  refclassset = options.classset;
end

%test for reference data
if ~isa(xref,'dataset');
  error('Reference data must be in a DataSet object');
end
if isempty(xref.class{1,refclassset})
  cl = ones(1,size(xref,1));
  xref.class{1,refclassset} = cl;
  xref.classlookup{1,refclassset} = {1 'One Class'};
  if calibratemode & ~isempty(model)
    model.detail.class{1,1,refclassset} = cl;
    model.detail.classlookup{1,1,refclassset} = xref.classlookup{1,refclassset};
  end
end

if ndims(xref)==2
  if size(xref,2)~=size(xtest,2);
    if length(xref.include{2})==size(xtest,2);
      %looks like they pre-excluded the unwanted variables from the test data
      xref = xref(:,xref.include{2});  %pre-exclude variables in xref (so we match test data)
    else
      error('Number of variables in reference data do not match the number of variables in the test data');
    end
  else % sizes are same
    if length(setdiff(xref.include{2},xtest.include{2}))>0
      error('Test data do not have necessary variables to match variables in reference data');
    else
      xtest.include{2} = xref.include{2};
    end
  end
end

%apply preprocessing
if ~isempty(options.preprocessing) & ~isempty(options.preprocessing{1})
  [xref,pp] = preprocess('calibrate',options.preprocessing{1},xref);
  xtest     = preprocess('apply',pp,xtest);
end

%handle n-way unfold prior to distance calculation
if ndims(xref)>2
  xref = unfoldmw(xref,1);
  xtest = unfoldmw(xtest,1);
end

if calibratemode
  % Apply compression
  [xref, commodel] = getcompressionmodel(xref, options);
  [xtest, ~] = getcompressionmodel(xtest, options);
elseif ~isempty(model)
  if ~isempty(model.detail.compressionmodel)
    xref_scores = dataset(model.detail.compressionmodel.scores);
    xref = copydsfields(xref,xref_scores,1);
    [xtest, model] = applycompressionmodel(xtest, model);
  end
end

%============================================================
% Actual KNN algorithm starts here
%locate unique classes and prepare output vectors
myclass = xref.class{1,refclassset};
uclass  = unique(myclass);
[m,n]   = size(xtest);
pclass  = zeros(m,1);
[mr,nr] = size(xref);
labels  = xref.label{1};
if isempty(labels)
  labels = int2str([1:mr]');
end

if strcmp(options.display,'on')
  %prepare display strings
  c1 = strvcat('Unknown','Number','-------');
  c2 = strvcat('Unknown',' Label','-------');
  c3 = strvcat('Class','Number','------');
  c4 = strvcat('Nearest','Neighbor(s)','-----------');
end

%classify each sample
dists = ones(size(xref,1),1)*inf;  %use "inf" for any excluded reference samples
closest = zeros(m,k)*nan;
votes   = zeros(m,k)*nan;
ref_use = intersect(xref.include{1},find(myclass~=0));  %use only included, non-zero samples for prediction
if strcmpi(options.waitbar,'on') | (strcmpi(options.waitbar,'auto') & m>500)
  wbh = waitbar(0,'Performing Classification... (close to cancel)');
else
  wbh = [];
end
for i = 1:m

  if ~isempty(wbh) & mod(i,50)==0;
    if ~ishandle(wbh)
      error('Aborted by user');
    end
    waitbar(i/m,wbh); 
  end
  dists(ref_use) = sum((scale(xref.data(ref_use,xref.include{2}),xtest.data(i,xref.include{2}))).^2,2);

  if calibratemode;
    %don't consider self in predction (effectively LOO cross-validation)
    dists(i) = inf;
  end

  [what,where] = sort(dists);
  
  %Create label.
  if length(xtest.label{1})>=i
    labl1 = xtest.label{1}(i,:);
  else
    labl1 = '     ';
  end
  
  vclass = uclass.*0; %reset votes
  %let each of the k nearest samples vote and record results for display
  for nth = 1:k
    ind = where(nth);
    
    %tally vote
    vclassind = (uclass==myclass(ind));
    vclass(vclassind) = vclass(vclassind)+1;

    closest(i,nth) = ind;
    votes(i,nth)   = uclass(vclassind);

    if strcmp(options.display,'on')
      if nth==1;
        c1 = strvcat(c1,int2str(i));
        c2 = strvcat(c2,labl1);
      else
        c1 = strvcat(c1,' ');
        c2 = strvcat(c2,' ');
      end
      c3 = strvcat(c3,int2str(myclass(ind)));
      c4 = strvcat(c4,[labels(ind,:)]);
    end
  end

  if length(vclass)==1;
    %if only one class in all of reference, just use closest sample
    pclass(i) = myclass(where(1));
  else
    %tally votes
    %     [vclasswhat,vclasswhere] = sort(vclass,'descend');
    [vclasswhat,vclasswhere] = sort(-vclass);  %use - to force descend (works even in 6.5, 'descend' input doesn't work in 6.5)
    vclasswhat = -vclasswhat;
    if length(vclass)>1 & vclasswhat(2)<vclasswhat(1);  %if we have a "top vote getter"
      %the class is that top vote getter
      pclass(i) = uclass(vclasswhere(1));
    else
      %no majority in voting
      if strcmp(options.nomajority,'error')
        %give error if selected
        error(['No majority could be found in the voting for sample # ' num2str(i) ' ' labl1 ...
          ' Consider using option.nomajority = ''closest'' instead']);
      elseif strcmp(options.nomajority,'closest')
        %closest keyword, give the CLOSEST sample
        pclass(i) = myclass(where(1));
      elseif isnumeric(options.nomajority) & prod(size(options.nomajority))==1;
        %or give the value passed
        pclass(i) = options.nomajority;
      else
        error('unrecognized input for nomajority option')
      end
    end
  end

end

if ~isempty(wbh) & ishandle(wbh)
  close(wbh);
end
if strcmp(options.display,'on');
  pad = ones(size(c1,1),3).*' ';
  disp('  ')
  disp([c1 pad c2 pad c3 pad c4]);
  disp('  ')
end

if ~isempty(model)
  model.pred{1} = pclass;
  model.closest = closest;
  model.votes   = votes;
  
  mcopts.strictthreshold = options.strictthreshold;
  if ~calibratemode
    %if this was a model prediction request, return a prediction structure
    model.modeltype = 'KNN_PRED';

    model.date = date;
    model.time = clock;

    model.datasource  = {getdatasource(xtest)};
    model.detail.data = {xtest};

    model = copydsfields(xtest,model);
    model.detail.options.classset = options.classset; % prediction classset
    
    model = multiclassifications(originalmodel, model, mcopts);
    
    % misclassedp
    myclasstst = xtest.class{1,refclassset};
    if ~isempty(myclasstst)
      ydata = myclasstst';
      cm = confusionmatrix(ydata, model.pred{1});
      if ~isempty(cm)
        model.detail.classerrp = sum(cm(:,[2 4]),2)/2;
        misclassedp = cm(:,[2 4])';
        model.detail.misclassedp = cell(1,size(misclassedp,2));
        for i=1:size(misclassedp,2)
          model.detail.misclassedp{i} = misclassedp(:,i);
        end
      end
    end

  else
    %calibrate mode - add classification content
    model = multiclassifications(model, mcopts);  % do this before copydsfields
    model.detail.compressionmodel = commodel;
    % misclassedc
    if ~isempty(myclass)
      cm =confusionmatrix(myclass', model.pred{1});
      if ~isempty(cm)
        % misclassed row 1 = False Pos Rate, row 2 = False Neg Rate
        misclassedc = cm(:,[2 4])';
        model.detail.misclassedc = cell(1,size(misclassedc,2));
        for i=1:size(misclassedc,2)
          model.detail.misclassedc{i} = misclassedc(:,i);
        end
      end
    end
  end

  pclass = model;
end

%---------------------------------------------------------------
function [xref,xtest,k,options,model] = parseinputs(varargin)
%sort out inputs into appropriate local variable

%start with everything empty (default for all)
xref    = [];
xtest   = [];
model   = [];
k       = [];
options = [];

switch nargin
  case 1
    % (xref)
    xref    = varargin{1};
  case 2
    % (xref,k)
    % (xtest,model)
    % (xref,options)
    % (xref,xtest)
    if ismodel(varargin{2})
      % (xtest,model)
      xtest   = varargin{1};
      model   = varargin{2};
    elseif isstruct(varargin{2})
      % (xref,options)
      xref    = varargin{1};
      options = varargin{2};
    elseif numel(varargin{2})==1
      % (xref,k)
      xref    = varargin{1};
      k       = varargin{2};
    else
      % (xref,xtest)
      xref    = varargin{1};
      xtest   = varargin{2};
    end
  case 3
    % (xref ,xtest,options)
    % (xref ,xtest,k)
    % (xref ,k,options)
    % (xtest,model,options)
    % (xtest,model,k)
    if isnumeric(varargin{2}) & numel(varargin{2})==1;
        % (xref,k,options)
        xref    = varargin{1};
        k       = varargin{2};
        options = varargin{3};
    elseif isnumeric(varargin{2}) | isdataset(varargin{2})
      if isstruct(varargin{3});
        % (xref,xtest,options)
        xref    = varargin{1};
        xtest   = varargin{2};
        options = varargin{3};
      elseif numel(varargin{3})==1 & isnumeric(varargin{3})
        % (xref,xtest,k)
        xref    = varargin{1};
        xtest   = varargin{2};
        k       = varargin{3};
      else
        error('Unrecognized inputs')
      end
    elseif isstruct(varargin{3}) & ismodel(varargin{2})
      % (xtest,model,options)
      xtest   = varargin{1};
      model   = varargin{2};
      options = varargin{3};
    elseif ismodel(varargin{2}) & numel(varargin{3})==1
      % (xtest,model,k)
      xtest   = varargin{1};
      model   = varargin{2};
      k       = varargin{3};
    else
      error('Unrecognized inputs')
    end
  case 4
    % (xref,xtest,k,options)
    % (xtest,model,k,options)
    k       = varargin{3};
    options = varargin{4};
    if ismodel(varargin{2})
      xtest = varargin{1};
      model = varargin{2};
    elseif isnumeric(varargin{2}) | isdataset(varargin{2})
      xref  = varargin{1};
      xtest = varargin{2};
    else
      error('Unrecognized inputs')
    end
  otherwise
    error('Unrecognized inputs')
end

%handle defaults
options = reconopts(options,'knn',{'plots' 'rawmodel'});

if ~isempty(xref);
  if ~isdataset(xref)
    xref = dataset(xref);
  end
  if size(xtest,2)==1 & (size(xref.class,2)<options.classset | isempty(xref.class{1,options.classset}))
    %assume this is a column of classes
    xref.class{1,options.classset} = xtest;
    xtest = [];
  end
end

%-------------------------------------------------------------------
function [xpp, commodel] = getcompressionmodel(xpp,options)
%
% compress X-block data
%
% Apply data compression if desired by user
switch options.compression
  case {'pca' 'pls'}
    switch options.compression
      case 'pca'
        comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
        commodel = pca(xpp,options.compressncomp,comopts);
      case 'pls'
        ypp = class2logical(xpp,[],options.classset);
        comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
        commodel = plsda(xpp,ypp,options.compressncomp,comopts);
    end
    scores   = commodel.loads{1};
    if strcmp(options.compressmd,'yes')
      incl = commodel.detail.includ{1};
      eig  = std(scores(incl,:)).^2;
      commodel.detail.eig = eig;
      scores = scores*diag(1./sqrt(eig));
    else
      commodel.detail.eig = ones(1,size(scores,2));
    end
    xpp      = copydsfields(xpp,dataset(scores),1);
  otherwise
    commodel = [];
end

%--------------------------------------------------------------------------
function [xpp, model] = applycompressionmodel(xpp, model)
%
% compress X-block data using supplied compression model
%
%apply any compression model found to data
commodel = model.detail.compressionmodel;
comopts  = struct('display','off','plots','none');
compred  = feval(lower(commodel.modeltype),xpp,commodel,comopts);
scores   = compred.loads{1};
scores   = scores*diag(1./sqrt(commodel.detail.eig));
xpp      = copydsfields(xpp,dataset(scores),1);
model.detail.compressionmodel = compred;


%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab           datatype        valid                            userlevel       description
'display'                'Display'     'select'        {'on' 'off'}                     'novice'        '[ {''off''} | ''on''] governs level of display.';
'preprocessing'          'Set-Up'      'cell(vector)'  ''                               'novice'        '{[ ]} preprocessing structure (see PREPROCESS).';
'classset'               'Standard'    'double'        'int(1:inf)'                     'novice'        'Class set to model';
'nomajority'             'Set-Up'      'select'        {'error' 'closest'}              'novice'        '[ ''error'' | {''closest''} ] Behavior when no majority is found in the votes. ''closest'' = return class of closest sample. ''error'' = give error message.';
'strictthreshold'        'Classification'    'double'        'float(0:1)'               'advanced'      'Threshold probability for associating sample with a class in model.classification.inclass. (default = 0.5).';
'predictionrule'         'Classification'     'select'    {'mostprobable' 'strict' }    'advanced'      'Specifies which classification preciction results appear first in confusion matrix window opened from Analysis (default = ''mostprobable'').';
'compression'            'Compression'    'select'        {'none' 'pca' 'pls'}          'novice'        'Type of data compression to perform on the x-block prior to KNN model. ''PCA'' is a principal components model and ''PLS'' is partial least squares.';
'compressncomp'          'Compression'    'double'        'int(1:inf)'                  'novice'        'Number of latent variables or principal components to include in the compression model.'
'compressmd'             'Compression'    'select'        {'no' 'yes'}                  'novice'        'Use Mahalnobis Distance corrected scores from compression model.'
};

out = makesubops(defs);
