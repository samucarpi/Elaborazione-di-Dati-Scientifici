function model = simca(x,classid,labels)
%SIMCA Soft Independent Method of Class Analogy.
%  Develops a SIMCA model, which is a collection of PCA models,
%  one for each class of data in the data set.
%
%  INPUTS:
%         x = MxN data matrix of class "double" or a DataSet object where
%             class and labels are extracted from the standard class and
%             labels fields
%   classid = a Mx1 vector of class identifiers where each element is an integer
%             identifying the class number of the corresponding sample.
%             Class 0 (zero) samples are not modeled (only used when x is
%             class double)
% modelCell = cell array of PCA models built from x (dataset) with embedded
%             classes in the model object
%  OPTIONAL INPUTS:
%     ncomp = the number of PCs to use in each model. This is rarely known
%             a priori. When ncomp=[] {default} the user is querried for
%             number of PCs for each class.
%    labels = a character array with M rows that is used to label samples
%             on Q vs. T^2 plots, otherwise the class identifiers are used.
%    options = structure array with the following fields:
%              display: ['off' | {'on'} ]     governs display to command window
%                plots: ['none' | {'final'}]  governs plotting
%          staticplots: [{'no'} | 'yes' ]     produce old-style "static" plots
%             classset: [ 1 ] indicates which class set in x to model.
%                 rule: [{'combined'} | 'both' | 'T2' | 'Q' ] decision rule
%        preprocessing: { [] }                preprocessing structure used for each
%                                             class model (see PREPROCESS).
%  strictthreshold: [0.5] Probability threshold for assigning a sample to a
%                   class. Affects model.classification.inclass.
%   predictionrule: { {'mostprobable'} | 'strict' ] governs which
%                   classification prediction statistics appear first in
%                   the confusion matrix and confusion table summaries.
%  Note: with display='off', plots='none', nocomp=(>0 integer) and preprocessing
%  specified that SIMCA can be run without command line interaction.
%
%  OUTPUT:
%     model = standard model structure containing the SIMCA model.
%      pred = SIMCA prediction structure.
%
%  SIMCA cross-validates the PCA model of each class using leave-one-out
%  cross-validation if the number of samples in the class is <= 20. If there
%  are more than 20 samples, the data is split into 10 contiguous blocks.
%
%I/O: model = simca(x,ncomp,options);  %creates simca model on dataset x
%I/O: model = simca(x,classid,labels); %creates simca model on double x with classid
%I/O: model = simca(x,modelCell,options); %creates simca model from cell
%array of PCA models derived from dataset x
%I/O: pred  = simca(x,model,options);  %makes simca predictions on x with model
%I/O: simca demo
%
%See also: CLUSTER, CROSSVAL, DISCRIMPROB, KNN, MODELSELECTOR, PCA, PLSDA, PLSDAROC, PLSDTHRES

%Copyright Eigenvector Research 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified NBG 10/96
%Checked by BMW 1/11/97
%Modified BMW 3/27/98
%Modified BMW 5/16/98
%nbg 11/00 put out=0 in crossval to limit ssqtable prints
%nbg 6/1/01 change to switch, added scaling 'none' option
%jms 6/19/01 added test to skip text labels on points if # of items > 300
%jms 4/24/02 updated for use with new pca, added dataset compatibility
%nbg 8/02 changed DataSet compatibility to Ver 3 DataSet, changed variable (class) to (classid)
%         added simca predictions
%jms 8/03 - added test for rank-deficient case when displaying ssq table
%jms 3/2/04 -refined class ordering code
%   -drop class zero during calibration
%rb 19/4/04 Added new decision rules (changes marked "% rb" + one line in help above)
%rsk 09/18/06 Add check so won't prompt if prepro present in options.

if nargin == 0; analysis simca; return; end
varargin{1} = x;
if ischar(varargin{1});
  options               = [];
  options.name          = 'options';
  options.display       = 'on';
  options.plots         = 'final';
  options.classset      = 1;
  options.staticplots   = 'no';
  options.rule.name     = 'combined';
  options.rule.limit.t2 = .95;
  options.rule.limit.q  = 0.95;
  options.preprocessing = {[]};
  options.strictthreshold = 0.5;    %probability threshold for class assign
  options.predictionrule = 'mostprobable';
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin==1 | ~ismodel(classid)
  %Calibration mode
  if nargin>1
    switch class(classid)
      case 'double'
        switch class(x)
          case 'double'
            % should be of length(size(x.data,1)) if classid
            if length(classid(:))~=size(x,1)
              error('Input (classid) should be a vector with size(x,1) elements.')
            end
          case 'dataset'
            % or vector of length of number of classes if nocomp
            %           if length(classid(:))>1
            %             error('Input (nocomp) should be scalar.')
            %           end
            %(not testing here...)
        end
      case 'cell' %second input classid is a cell
        % xblock & cell array of individual PCA models from same
        modelCell = classid;
        if nargin>2 & isstruct(labels)
          options = labels;
        else
          options = [];
        end
        options = reconopts(options, mfilename, ...
          {'algorithm' 'blockdetails' 'confidencelimit' ...
          'outputversion' 'rawmodel' 'roptions'});
        model = buildSIMCAfromCell(x, modelCell, options);
        return
      otherwise
        error('Class of input (classid) not recognized.')
    end
  else
    % assumes the I/O is model = simca(x);
    if ~isdataset(x)
      error('Input (x) must be class "dataset" when only one input to SIMCA.')
    end
  end
  if nargin>2 & isstruct(labels)
    options  = labels;
  else
    options  = [];
  end
  options   = reconopts(options,mfilename,{'algorithm' 'blockdetails' ...
      'confidencelimit' 'outputversion' 'rawmodel' 'roptions'});

  model    = modelstruct('simca');
  model.submodel = {};  %start with empty submodel structure
  switch class(x)
    case 'double'
      if nargin < 2;
        error('Input (classid) must be provided when (x) is class "double".');
      end
      dsize    = size(x);
      classid  = classid(:);
      if length(classid)~=dsize(1)
        error('Input (classid) must be a vector with number of elements the same as number of rows of (data).')
      end
      model.datasource{1}.name = inputname(1);
      model.datasource{1}.size = size(x);
      
      x  = dataset(x);
      x.class{1,options.classset} = classid;
      if nargin > 2 & ~isstruct(labels)
        if size(labels,1)~=dsize(1) | ~isa(labels,'char')
          error('Input (labels) must be a chararacter array with the same number of rows of (x).')
        else
          x.label{1,1} = labels;
        end
      end
      nocomp   = [];
      
    case 'dataset'
      if options.classset == 0
        error('Options classset (= %i) must be a positive integer identifying a calibration data Class set',options.classset);
      end
      if options.classset > size(x.class,2) | isempty(x.class{1,options.classset})
        error('When (x) is a DataSet object, the class field must contain the classes to model (Class set = %i).', options.classset)
      end
      model.datasource{1} = getdatasource(x);
      if nargin>1
        nocomp   = classid;
      else
        nocomp   = [];
      end
    otherwise
      error('Class of input (x) not recognized.')
  end
  
  if ~isa(options.preprocessing,'cell');
    options.preprocessing = {options.preprocessing};  %insert into cell
  end

  if isempty(x.label{1,1})
    x.label{1,1} = int2str([1:size(x,1)]');
  end

  if isempty(x.includ{1})
    error('No samples included. Can not calculate model.')
  end
  
  % Determine the number of classes
  myclass = x.class{1,options.classset};
  classes = unique(myclass(x.include{1,1}));
  classes(classes==0) = [];  %drop class zero if it is there
  noclass = length(classes);     %number of classes
  
  switch lower(options.display)
    case {'on'}
      disp(sprintf('\nThere are %g classes in this data set.\n',noclass))
      sflag       = 1; %flag that is 1 until the user provides correct input
      while sflag == 1
        if isempty(options.preprocessing{1})
          disp(sprintf('How would you like to scale the data for each class?\n'))
          as        = input('None (N), Autoscaling (A) or Mean-Centering (M)?  ','s');
          if isempty(as), as = 0; end
          switch lower(as(1))                  %change to switch, added 'none', nbg 6/1/01
            case {'a'}
              options.preprocessing = {preprocess('default','autoscale')};   sflag   = 0;  %sopt   = 3;
            case {'m'}
              options.preprocessing = {preprocess('default','mean center')}; sflag   = 0;  %sopt   = 2;
            case {'n'}
              options.preprocessing = {[]};                                  sflag   = 0;  %sopt   = 1;
            otherwise
              disp(sprintf('\nPlease input either N, A or M.\n'))
          end
        else
          sflag = 0;
        end
      end
  end
  model.date  = date;
  model.time  = clock;
  model = copydsfields(x,model);

  model.detail.options   = options;
  pcaopts          = pca('options');
  pcaopts.classset = options.classset;
  pcaopts.display  = 'off';
  pcaopts.plots    = 'none';
    
  if isempty(nocomp)    % Create a window for cross validation and one for PCA plots
    cvwin     = figure;
  end

  for ii=1:noclass
    %include only samples in this class
    cdata            = x;
    cinds            = find(myclass==classes(ii));
    cinds            = intersect(x.include{1},cinds);
    cdata.include{1} = cinds;
    pcaopts.preprocessing = options.preprocessing;
    
    switch options.display
      case 'on'
        disp(sprintf('\nNow developing model on class %g ',classes(ii)))
        disp(sprintf(['First sample in class is %s'],cdata.label{1,1}(min(cdata.include{1}),:)))
    end
    
    %calculate ssq table and cross-validation info for a given class
    engopts   = pcaengine('options');
    engopts.display = 'off';
    mac       = length(cdata.includ{1,1});
    nac       = length(cdata.includ{2,1});
    
    if min([mac nac])-1<2
      switch options.display
        case 'on'
          disp(sprintf('Not enough data to model Class %g - skipping class',classes(ii)))
      end
      continue
    end
      
    if isempty(nocomp)
      switch options.display
        case 'on'
          disp(sprintf('\nPerforming Cross-Validation.'))
      end
      if mac<21
        [press,cumpress] = crossval(cdata,[],'pca',{'loo'},min([mac nac])-1, ...
          0,options.preprocessing);
      else
        [press,cumpress] = crossval(cdata,[],'pca',{'con' 10},min([mac nac])-1, ...
          0,options.preprocessing);
      end
        figure(cvwin); subplot(2,1,1);
      semilogy(cumpress,'-or','markerfacecolor',[0 0 0.8])
      title(sprintf('PRESS Plot for Class %g',classes(ii)));
      ylabel('PRESS')
      xlabel('Number of PCs')
      
      %ask for # of PCs, create a model, and ask if this is model is good
      sflag   = 'n';
      while strcmp(lower(sflag),'n')
        pdata = preprocess('calibrate',options.preprocessing{1},cdata);
        ssq   = pcaengine(pdata.data,[],engopts);
        figure(cvwin); subplot(2,1,2);
        plot(ssq(:,2),'or-','markerfacecolor',[0 0.8 0])
        title('Eigenvalue vs. PC Number')
        xlabel('PC Number'), ylabel('Eigenvalue')
        disp(' '), disp('        Percent Variance Captured by PCA Model'), disp(' ')
        disp('Principal     Eigenvalue     % Variance     % Variance')
        disp('Component         of          Captured       Captured')
        disp(' Number         Cov(X)        This  PC        Total          PRESS')
        disp('---------     ----------     ----------     ----------     ----------')
        formt = '   %3.0f         %3.2e        %6.2f         %6.2f         %6.2f';
        for pc=1:min(length(cumpress),size(ssq,1))
          disp(sprintf(formt,ssq(pc,:),cumpress(pc)))
        end
        
        flag = 0;            %Input Number of PCs
        while flag==0;
          pc    = input('How many principal components do you want to keep?  ');
          if pc>min([mac nac])
            disp('Number of PCs must be <= min of number of samples and variables')
          elseif pc==0
            break;
          elseif pc<1
            disp('Number of PCs must be > 0')
          elseif isempty(pc)
            disp('Number of PCs must be > 0')
          else
            flag = 1;
          end
        end %flag

        %Got the # of PCs they want, create the model for this class
        submodel = simcasub(x,classes(ii),pc,pcaopts);

        disp('** Press any key to page through diagnostic plots for this model **')
        
        if strcmp(options.staticplots,'yes')
          pred  = pca(x,submodel,pcaopts);
          
          %show PCs and T2/Q figures
          scoresfig = figure;
          for ik=1:size(pred.loads{1},2)  %just plot the included data for now
            plot(x.includ{1,1},pred.loads{1}(x.includ{1,1},ik),'r*'), hold on
            plot(cinds,pred.loads{1}(cinds,ik), ...
              'ob','markerfacecolor',[0 0 0.8]), hold off
            pclim = sqrt(ssq(ik,2))*ttestp(0.025,mac-ik,2);
            hline([mean(pred.loads{1}(cinds,ik))-pclim, ...
                mean(pred.loads{1}(cinds,ik))+pclim],'--b')
            title(sprintf('Scores of all data on PC %g of Class %g',ik,classes(ii)))
            pause
          end
          loglog(pred.tsqs{1,1}(x.includ{1,1},1),pred.ssqresiduals{1,1}(x.includ{1,1},1),'r*'), hold on
          loglog(pred.tsqs{1,1}(cinds), ...
            pred.ssqresiduals{1,1}(cinds),'ob','markerfacecolor',[0 0 0.8]), hold off
          grid off
          if length(x.includ{1,1})<200
            text(pred.tsqs{1,1}(x.includ{1,1},1), ...
              pred.ssqresiduals{1,1}(x.includ{1,1},1),x.label{1,1}(x.includ{1,1},:))
          end
          title(sprintf('Q vs. T^2 for all Data Projected on Model of Class %g',classes(ii)))
          xlabel('T^2'), ylabel('Q')
          hline(submodel.detail.reslim{1,1}), vline(submodel.detail.tsqlim{1,1})
          pause

        else
          
          plotscores(submodel);
          scoresfig = gcf;
          plotgui('update','figure',scoresfig,'showlimits',1,'viewclasses',1);
          pause
          for ik = 2:pc;
            plotgui('update','figure',scoresfig,'axismenuvalues',{0 ik})
            pause
          end
          plotgui('update','figure',scoresfig,'axismenuvalues',{pc+2 pc+1},'viewlog',[1 1],'showlimits',1)
          pause
        end
        
        flag = 0;            %Happy with this model?
        while flag==0;
          sflag = input('Are you happy with this model? Yes or No?  ','s');
          sflag = deblank(fliplr(deblank(fliplr(sflag))));  %remove extra spaces in response
          if isempty(sflag), sflag = -1; end
          switch lower(sflag(1))
            case {'y', 1}
              flag  = 1;
              sflag = 'y';
            case {'n', 0}
              flag  = 1;
              sflag = 'n';
            otherwise          %else
              disp(sprintf('\nPlease input either Y or N\n'))
          end
        end % flag
        
        if ishandle(scoresfig);
          close(scoresfig);
        end
        
      end %sflag

      %store submodel in model
      model.submodel{end+1} = submodel;
      
    else %isempty(nocomp) %assumes nocomp is the number of components
      if length(nocomp)==1;
        usecomp = nocomp;   %same # of components for each model
      elseif length(nocomp)>=ii
        usecomp = nocomp(ii);  %specific # of components for each model
      else
        error('Input NCOMP must specify the number of components for each model (or a single value for all models)');
      end
      submodel = pca(cdata,usecomp,pcaopts);
      
      %store submodel in model
      model.submodel{end+1} = submodel;
      
    end %isempty(nocomp)
  end
  model = simcastats(model);
  model.detail.modeledclasslookup = model.detail.classlookup;
  mcopts.strictthreshold = options.strictthreshold;
  model = multiclassifications(model, mcopts);
    
else 
  %=================================================================
  % prediction mode
  
  % update model
  if ismodel(classid) & strcmpi(classid.modeltype,'simca')
    try
      originalmodel = updatemod(classid);
    catch
      error('Input MODEL not recognized.')
    end
  else
    error('Input (model) does not appear to be a valid SIMCA model.')
  end
  
  switch class(x)
    case 'double'
      x         = dataset(x);
    case 'dataset'
      %do nothing this is expected
    otherwise
      error('Class of input (x) not recognized.')
  end
  if originalmodel.datasource{1}.size(2)~=size(x.data,2)
    error('The input test data (x) must have the same number of columns as the calibration data.')
  end
  
  %make a prediction with an existing model
  if nargin<3
    %options not supplied, use options from model
    options = originalmodel.detail.options;
  else
    options   = reconopts(labels,mfilename,{'algorithm' 'blockdetails' ...
      'confidencelimit' 'outputversion' 'rawmodel' 'roptions'});
  end
  model       = modelstruct('simca',1);
  model.date  = date;
  model.time  = clock;

  model       = copydsfields(x,model);
  model.detail.options = options;

  noclass     = length(originalmodel.submodel);
  model.rtsq  = zeros(size(x.data,1),noclass);
  model.rq    = model.rtsq;

  pcaopts     = pca('options');
  pcaopts.display = 'off';
  pcaopts.plots   = 'none';
  pcaopts.blockdetails = 'compact';

  for ii=1:noclass
    model.submodel{ii} = pca(x,originalmodel.submodel{ii},pcaopts);
  end
  
  model = simcastats(model,originalmodel,options);
  mcopts.strictthreshold = options.strictthreshold;
  model = multiclassifications(originalmodel,model, mcopts);
  
  model.detail.modeledclasslookup = originalmodel.detail.modeledclasslookup;
  
  mx    = size(x.data,1);
  switch options.display
    case 'on'
      for ii=1:mx
        
        switch lower(options.rule.name)
          case 'combined'
            indc    = find(model.rules.combined.value(ii,:)<sqrt(2));
          case 't2'
            indc    = find(model.rules.t2.value(ii,:)<1);
          case 'q'
            indc    = find(model.rules.q.value(ii,:)<1);
          case 'both'
            indc    = find(model.rules.q.value(ii,:)<1&model.rules.t2.value(ii,:)<1);
        end
        
        ni      = length(indc);
        switch ni
          case 0
            disp(sprintf('\nSample %g does not belongs to any class,',ii)); %should add x.label
            if (isa(model.nclass(ii),'cell')) % this if-else is probably overkill but in for good measure 
              disp(sprintf('  it is closest to class %g',model.nclass{ii}));
            else
            disp(sprintf('  it is closest to class %g',model.nclass(ii)));
            end
            disp(sprintf('  with reduced Q = %g and reduced T^2 = %g', ...
              model.rq(ii,model.detail.nsubmodel(ii)),model.rtsq(ii,model.detail.nsubmodel(ii))))
          case 1
            disp(sprintf('\nSample %g belongs to class %g',ii,model.detail.submodelclasses{indc}));
          otherwise %ni>1
            disp(sprintf('\nSample %g belongs to %g classes',ii,ni));
            disp(['  They are classes ',int2str(model.detail.submodelclasses{model.detail.nsubmodel(ii)})])
            if (isa(model.nclass(ii),'cell')) % this if-else is probably overkill but in for good measure
              disp(sprintf('  It is nearest the center of class %g',model.nclass{ii}));  
            else
            disp(sprintf('  It is nearest the center of class %g',model.nclass(ii)));  
            end
        end
      end  
  end
end

end

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab           datatype        valid                            userlevel       description
'classset'               'Standard'    'double'        'int(1:inf)'                     'novice'        'Class set to model';
'display'                'Display'     'select'        {'on' 'off'}                     'novice'        '[ {''off''} | ''on''] governs level of display.';
'plots'                  'Display'     'select'        {'none' 'final'}                 'novice'        '[ ''none'' | {''final''} ]  governs level of plotting.';
'staticplots'            'Set-Up'      'select'        {'yes' 'no'}                     'novice'        '[{''no''} | ''yes'' ] Produce old-style "static" plots.' 
'rule.name'              'rule'        'select'        {'combined' 'both' 'T2' 'Q'}    'novice'         '[{''combined''} | ''both'' | ''T2'' | ''Q'' ] Decision rule for classification.  ''Q'' means reduced Q is used as distance measure. ''T2'' means reduced T2 is used. ''both'' means both T2 and Q are used (if either is outside the limit, the sample will be considered outside the class). ''combined'' uses sqrt(Q^2 + T2^2), each reduced, as the distance measure.' 
'rule.limit.t2'          'rule'        'double'        []                               'novice'        'T-squared confidence limit for inclusion in a model. Applies to all class sub-models. To use separate limits, use separate SIMCA models in Hierarchical model.' 
'rule.limit.q'           'rule'        'double'        []                               'novice'        'Q residuals confidence limit for inclusion in a model. Applies to all class sub-models. To use separate limits, use separate SIMCA models in Hierarchical model.' 
'preprocessing'          'Set-Up'      'cell(vector)'  ''                               'novice'        '{[ ]} preprocessing structure used for each class model (see PREPROCESS).';
'strictthreshold'        'Classification'    'double'        'float(0:1)'               'advanced'      'Threshold probability for associating sample with a class in model.classification.inclass. (default = 0.5).';
'predictionrule'         'Classification'     'select'    {'mostprobable' 'strict' }    'advanced'      'Specifies which classification preciction results appear first in confusion matrix window opened from Analysis (default = ''mostprobable'').';
};

out = makesubops(defs);

end

function modl = buildSIMCAfromCell(xblock, modelCell, options)

% start off with some checks

if ~all(cellfun(@(x)isequal(xblock.uniqueid, x.datasource{1}.uniqueid), ...
    modelCell))
  error('Mismatch between data and model(s)')
end

modl = modelstruct('simca');
modl.submodel = {};
modl.date = date;
modl.time = clock;
modl = copydsfields(xblock, modl);
modl.detail.options = options;
modl.submodel = modelCell;
modl = simcastats(modl);
modl.detail.modeledclasslookup=modl.detail.classlookup;
modl = simcagui('setsimcaclasses', modl);
mcopts.strictthreshold=options.strictthreshold;
modl = multiclassifications(modl, mcopts);
end
