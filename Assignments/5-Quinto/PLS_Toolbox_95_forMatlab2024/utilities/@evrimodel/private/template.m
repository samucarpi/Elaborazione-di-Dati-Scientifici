function model = template(varargin)
%TEMPLATE Constructs an empty model structure.
%  Inputs:
%  modeltype = character string containing the model type to output:
%          'ALS_SIT' : ALS Shift Invariant Trilinearity
%              'ANN' : Artificial Neural Network
%            'ANNDA' : Artificial Neural Network discriminant analysis
%            'ANNDL' : Deep Learning Neural Network
%          'ANNDLDA' : Deep Learning Neural Network discriminant analysis
%             'ASCA' : ANOVA Simultaneous Component Analysis
%         'B3SPLINE' : B3Spline model
%    'BATCHMATURITY' : batch maturity
%      'CALTRANSFER' : Calibration transfer (CALTRANSFER)
%              'CLS' : classical least squares
%         'CORRSPEC' : Correlation spectroscopy.
%            'DSPLS' : partial least squares (PLS) via DSPLS
%             'GLSW' : Generalized Least Squares Weighting
%              'KNN' : K Nearest Neighbor
%              'LDA' : Linear Discriminant Analysis
%    'LWRPRED'|'LWR' : locallly weighted regression
%      'MAF' | 'MDF' : maximum autocorrelation/difference factors.
%              'MCR' : multivariate curve resolution (MCR)
%              'MLR' : Multiple Linear Regression
%    'MODELSELECTOR' : Model Selector 
%       'MULTIBLOCK' : Multiple datasets/models model. 
%              'NIP' : partial least squares (PLS) via NIPLS
%       'NPL'|'NPLS' : Multilinear partial least squares (NPLS)
%         'OPLECORR' : Optical PathLength Estimation Correction
%    'PAR'|'PARAFAC' : parallel factor analysis (PARAFAC)
%   'PA2'|'PARAFAC2' : PARAFAC2
%              'PCA' : principal components analysis (PCA)
%              'PCR' : principal components regression (PCR)
%            'PLSDA' : partial least squares discriminant analysis (PLSDA)
%    'POLYTRANSFORM' : polynomial transformation
%           'PURITY' : Self-modeling mixture analysis.
%              'SIM' : partial least squares (PLS) via SIMPLS
%            'SIMCA' : SIMCA classification model
%              'SVM' : support vector machine for regression
%            'SVMDA' : support vector machine for classification
%            'SVMOC' : support vector machine for one class
%             'TSNE' : t-distribution stochastic neighbor embedding
%              'XGB' : gradient boosted decision tree for regression
%            'XGBDA' : gradient boosted decision tree for classification
%             'UMAP' : Uniform Manifold Approximation Projection
%          'TEXTURE' : texture analysis
%        'OPTIMIZER' : model optimizer
%    'TRIGGERSTRING' : triggerstring for Model Selector models
%
%************************************************************************
%                                                                       *
%     NOTE: If modifying existing model ADD CODE TO                     *
%                                                                       *
%           @EVRIMODEL/PRIVATE/UPDATEMOD.M                              *
%                                                                       *
%           for new fields and or fields that have changed locations.   *
%           for new version number.                                     *
%                                                                       *
%           @EVRIMODEL/PRIVATE/TEMPLATE.M                               *
%                                                                       *
%           for new fields with defaults.                               *
%                                                                       *
%                                                                       *
%           @EVRIMODEL/EVRIMODEL.M                                      *
%                                                                       *
%           for new version number.                                     *
%                                                                       *
%           @EVRISCRIPT_MODULE/PRIVATE/EVRISCRIPT_CREATECONFIG.M        *
%                                                                       *
%           for new models update evriscript_config.mat.                *
%                                                                       *
%           @EVRIMODEL/GETSSQTABLE.M                                    *
%                                                                       *
%           add/verify SSQ table logic                                  *
%                                                                       *
%************************************************************************
%
%  Optional Input:
%  pred      = flag used to govern output
%    0 : standard model structure {default}, and
%    1 : standard prediction structure.
%
%  Output:
%    model   = standard model structure (format depends on input).
%
%I/O: model = template(modeltype,pred);
%
%See also: ANALYSIS, COPYDSFIELDS, DECOMPOSE, EXPLODE, GETDATASOURCE, PARAFAC, PCA, PCR, PLS, REGRESSION, UPDATEMOD

%Copyright (c) Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 12/20/01
%jms 02/28/02
%rb 03/18/02 added parafac
%nbg 03/19/02 added pcr, added details.options
%jms 03/20/02 modified SIM/NIP to be PLS
% -use default options for detail.options fields
%jms 03/25/02 added 'pls' as synonym for 'SIM'
%rb,june,2002, added npls
%jms aug 13 2002, added test/prediction structures for all but multiway models
%rb 8/02 changed multiway
%nbg 08/22/02 added simca, changed help
%jms 10/02/02 added genalg
%jms 3/17/04 modified genalg
%jms 5/7/04 add pcassq field to PCR details to speed up Q limits calc
%nbg 5/16/07 added model.detail.bias for PCR and PLS
%nbg 5/19/08 added model.detail.esterror.pred  = []; %m by ny

%List of valid model types : this list is ONLY used to allow users to ask what types
%are available, so preferred name for a given model type should be listed here
valid_modeltypes = ...
  {'pca' 'mpca' 'mcr' 'purity' ...
  'mlr' 'pcr' 'frpcr' 'lwrpred' 'lwr' 'ann' 'annda' 'anndl' 'anndlda'...
  'lda' 'lreg' 'lregda' 'asca' 'mlsca' 'svm' 'svmda' 'svmoc'...
  'tsne' 'xgb' 'xgbda' 'umap'...
  'cls' 'clsti' 'sim' 'nip' 'dspls' 'pls' 'polypls' 'robustpls' ...
  'plsda' 'knn' 'simca' ...
  'parafac' 'tucker' 'parafac2' 'npls' 'als_sit' ...
  'genalg' 'caltransfer' 'corrspec' 'trendtool' 'analyzeparticles'...
  'texture' 'batchmaturity'...
  'polytransform' 'b3spline' ...
  'modelselector' 'triggerstring' 'multiblock' ...
  'maf' 'mdf' 'ensemble'};

valid_modeltypes = sort(valid_modeltypes)';

if nargin == 0
  %no input = return list of types
  model = valid_modeltypes;
  return
end

modeltype = lower(varargin{1});

if nargin < 2
  pred = 0;
else
  pred = varargin{2};
end
if ~isempty(strfind(modeltype,'_pred'))
  modeltype = regexprep(modeltype,'_pred','');  %drop any "_PRED" in modeltype
  pred = true;
end

datasource = getdatasource; %get empty datasource cell

model.modeltype   = ''; %char string of modeling method
model.author      = userinfotag;
model.datasource  = {datasource}; %row of input block information
model.date        = date; %model construct date
model.time        = clock; %model construct time
model.info        = ''; %1 line char string of model info
model.userdata    = []; %Generic userdata field
model.help        = [];
model.detail.history = sethistory({''},'','',['=== Built from template by ' userinfotag]);
model.detail.history = sethistory(model.detail.history,'','',['=== Product Information:  ' prodinfo]);
model.detail.copyparentid = '';%ID of parent model (used when copying). 

switch lower(modeltype)
  %-----------------------------------
  case {'pca' 'mpca'}
    if ~pred
      model.modeltype   = upper(modeltype);
    else
      model.modeltype   = [upper(modeltype) '_PRED'];
    end
    
    model.datasource  = {datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Scores are in cell 1 of the loads field.';
    model.loads       = cell(2,1); %nmodes by nblocks
    model.pred        = cell(1,1); %1 by nblocks
    model.tsqs        = cell(2,1); %nmodes by nblocks
    model.ssqresiduals         = cell(2,1); %nmodes by nblocks, Q
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'Principal Components Model';
    model.detail.data          = cell(1,1); %1 by nblocks
    model.detail.res           = cell(1,1); %1 by nblocks
    model.detail.ssq           = []; %sum squares table
    model.detail.eig           = []; %eigenvalues of the X-block
    model.detail.rmsec         = []; %1 by pc
    model.detail.rmsecv        = []; %1 by pc
    model.detail.esterror      = struct([]);%
    model.detail.means         = cell(1,1); %1 by nblocks
    model.detail.stds          = cell(1,1); %1 by nblocks
    model.detail.reslim        = cell(1,1); %1 by nblocks (95% limit)
    model.detail.tsqlim        = cell(1,1); %1 by nblocks (95% limit)
    model.detail.reseig        = []; %pcs by 1
    model.detail.eigsnr        = []; %pcs by 1
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model.detail.componentnames = {}; %Labels for components/lvs.
    model                      = add_dso_fields(model,2,1);
    model.detail.robustpca     = [];
    model.detail.originalinclude = {};
    model.detail.mwadetails    = [];
    model.detail.preprocessing = {[]};
    model.detail.options       = [];
    model.help.predictions  = makepredhelp({
      'Scores'           'scores'           'vector'
      'Hotelling''s T^2' 'T2'               'scalar'
      'Q Residuals'      'Q'                'scalar'
      'T Contributions'  'tcon'             'vector'
      'Q Contributions'  'qcon'             'vector'
      });
    
    %-----------------------------------
  case {'mcr','sit','als_sit'}
    model                 = modelstruct('pca');

    switch lower(modeltype)
    case 'mcr'
      if ~pred
        model.modeltype     = 'MCR';
      else
        model.modeltype     = 'MCR_PRED';
      end
      model.description{1}  = 'Multivariate Curve Resolution';
    case {'sit', 'als_sit'}
      if ~pred
        model.modeltype     = 'ALS_SIT';
        model.sitmodel.p    = [];
        model.sitmodel.t    = [];
        model.sitmodel.a0   = [];
        model.sitmodel.length1  = [];
        model.sitmodel.include  = [];
        model.sitmodel.info = [];
        model.info = 'Scores and loadings are in cells of the loads field. SIT models are in sitmodels.';
      else
        model.modeltype     = 'ALS_SIT_PRED';
      end
      model.description{1}  = 'ALS Shift Invariant Trilinearity';
    end

    model.detail.options  = [];
    model.help.predictions  = makepredhelp({
      'Scores'           'scores'           'vector'
      'Q Residuals'      'Q'                'scalar'
      'Q Contributions'  'qcon'             'vector'
      });

    %-----------------------------------
  case 'purity'
    model                 = modelstruct('pca');
    if ~pred
      model.modeltype   = 'PURITY';
    else
      model.modeltype   = 'PURITY_PRED';
    end
    model.description{1}  = 'Self-modeling Mixture Analysis';
    model.detail.purvarindex  = [];
    model.detail.purspecindex = [];
    model.detail.cursor_index = [];
    model.detail.slab         = [];
    model.detail.diag         = [];
    model.detail.window_der   = [];
    model.detail.cursor_select = [];
    model.detail.inactivate   = [];
    model.detail.base         = [];
    model.detail.rrssq        = [];
    
    model.detail.options  = [];
    model.help.predictions  = makepredhelp({
      'Scores'           'scores'           'vector'
      'Q Residuals'      'Q'                'scalar'
      'Q Contributions'  'qcon'             'vector'
      });
    model.info      = 'PURITY Prediction Results';
    
    %-----------------------------------
  case {'pcr' 'frpcr'}
    if ~pred
      model.modeltype   = 'PCR';
    else
      model.modeltype   = 'PCR_PRED';
    end
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Scores are in row 1 of cells in the loads field.';
    model.reg         = [];        %regression vector
    model.loads       = cell(2,1); %nmodes by nblocks
    model.pred          = cell(1,2); %1 by nblocks
    model.tsqs        = cell(2,2); %nmodes by nblocks
    model.ssqresiduals         = cell(2,2); %nmodes by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'Principal Components Regression Model';
    model.detail.data          = cell(1,2); %1 by nblocks
    model.detail.res           = cell(1,2); %1 by nblocks
    model.detail.ssq           = []; %sum squares table
    model.detail.eigs          = []; %eigenvalues of the X-block
    model.detail.leverage      = []; %leverage
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.dy            = [];  %scalar or ny
    model.detail.esterror.pred   = []; %m by ny
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.means         = cell(1,2); %1 by nblocks
    model.detail.stds          = cell(1,2); %1 by nblocks
    model.detail.reslim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.tsqlim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.pcassq        = []; %pcs by 1
    model.detail.reseig        = []; %pcs by 1
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing = {[] []};
    model.detail.robustpcr     = [];
    model.detail.options       = [];
    model.help.predictions  = makepredhelp({
      'Predictions'      'prediction'  'vector'
      'Hotelling''s T^2' 'T2'          'scalar'
      'Q Residuals'      'Q'           'scalar'
      'T Contributions'  'tcon'        'vector'
      'Q Contributions'  'qcon'        'vector'
      });
    
    %-----------------------------------
  case {'lwrpred' 'lwr'}
%     model.modeltype   = 'LWR';
    model.modeltype   = upper(modeltype);
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Scores are in row 1 of cells in the loads field.';
    model.loads       = cell(2,1); %nmodes by nblocks
    model.pred        = cell(1,2); %1 by nblocks
    model.tsqs        = cell(2,2); %nmodes by nblocks
    model.ssqresiduals            = cell(2,2); %nmodes by nblocks
    model.description             = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}          = 'Locally weighted regression structure';
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.res              = cell(1,2); %1 by nblocks
    model.detail.ssq              = [];
    model.detail.lvs              = []; %number of principal components used
    model.detail.npts             = []; %number of points defined as local
    model.detail.globalmodel.au   = []; %
    model.detail.globalmodel.umx  = []; %
    model.detail.globalmodel.ustd = []; %
    model.detail.extrap           = [];
    model.detail.nearestpts       = []; % nearest points
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.reslim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.tsqlim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.eig           = []; %pcs by 1
    model.detail.reseig        = []; %pcs by 1
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing    = {[] []};
    model.detail.options          = [];
    
    model.help.predictions  = makepredhelp({
      'Scores'           'scores'      'vector'
      'Hotelling''s T^2' 'T2'          'scalar'
      'Q Residuals'      'Q'           'scalar'
      'T Contributions'  'tcon'        'vector'
      'Q Contributions'  'qcon'        'vector'
      });
    
  %-----------------------------------
  case {'ann'}
    if ~pred
      model.modeltype   = 'ANN';
    else
      model.modeltype   = 'ANN_PRED';
    end
    model.modeltype   = upper(modeltype);
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Neural Net weights stored in details field';
    model.pred        = cell(1,2); %1 by nblocks
    model.ssqresiduals            = cell(2,2); %nmodes by nblocks
    model.description             = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}          = 'Artificial Neural Network regression structure';
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.res              = cell(1,2); %1 by nblocks
    model.detail.compressionmodel = []; %model structure
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing   = {[] []};
    model.detail.options         = [];
    model.detail.ann.niter       = []; % NN number of training iterations
    model.detail.ann.W           = []; % NN weights and data range
    model.detail.ann.rmsecviter  = []; % rmsecv at each learning iter in CV
    
    model.help.predictions  = makepredhelp({'Predictions'      'prediction'         'vector' });
    
    %-----------------------------------
  case 'annda'
    
    model = modelstruct('ann');
    model.modeltype = 'ANNDA';
    model = add_classification_fields(model);
    model.detail.predictedclass = [];
    model.detail.distprob = [];
    
    %-----------------------------------
  case 'anndl'
    
    if ~pred
      model.modeltype   = 'ANNDL';
    else
      model.modeltype   = 'ANNDL_PRED';
    end
    model.modeltype   = upper(modeltype);
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Neural Net weights stored in details field';
    model.pred        = cell(1,2); %1 by nblocks
    model.ssqresiduals            = cell(2,2); %nmodes by nblocks
    model.description             = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}          = 'Deep Learning Neural Network regression structure';
    if nargin>1
      anntype = varargin{2};
      switch anntype
        case 'sk'
          model.description{2}      = 'Scikit-Learn Implementation';  
        case 'tf'
          model.description{2}      = 'Tensorflow Implementation';
      end
    end
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.res              = cell(1,2); %1 by nblocks
    model.detail.compressionmodel = []; %model structure
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing   = {[] []};
    model.detail.options         = [];
    model.detail.anndl.niter       = []; % NN number of training iterations
    model.detail.anndl.W           = []; % NN weights and data range
    model.detail.anndl.W.loss      = [];
    model.detail.anndl.rmsecviter  = []; % rmsecv at each learning iter in CV
    
    model.help.predictions  = makepredhelp({'Predictions'      'prediction'         'vector' });
    
    %-----------------------------------
    
    case 'anndlda'
    
    model = modelstruct('anndl');
    model.modeltype = 'ANNDLDA';
    model = add_classification_fields(model);
    model.detail.predictedclass = [];
    if nargin>1
      anntype = varargin{2};
      switch anntype
        case 'sk'
          model.description{2}      = 'Scikit-Learn Implementation';  
        case 'tf'
          model.description{2}      = 'Tensorflow Implementation';
      end
    end
    model.detail.distprob = [];
    
    %-----------------------------------
    
  case 'lreg'
    if ~pred
      model.modeltype   = 'LREG';
    else
      model.modeltype   = 'LREG_PRED';
    end
    
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'LREG info stored in details field';
    model.referencedata  = 'See detail.data field';
    
    model.detail.lreg          = [];
    model.pred        = cell(1,2); %1 by nblocks
    model.ssqresiduals            = cell(2,2); %nmodes by nblocks
    model.description             = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}          = 'Logistic Regression structure';
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.res              = cell(1,2); %1 by nblocks
    model.detail.compressionmodel = []; %model structure
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing   = {[] []};
    model.detail.options         = [];
    
    model = add_dso_fields(model,2,2);   % 
    model.help.predictions  = makepredhelp({
      'Class Predictions'      'prediction'    'vector'
      });
    
    %-----------------------------------
  case 'lregda'
    
    model = modelstruct('lreg');
    model.modeltype = 'LREGDA';
    model = add_classification_fields(model);
    model.detail.predictedclass = [];
    
  case 'lda'
    if ~pred
      model.modeltype   = 'LDA';
    else
      model.modeltype   = 'LDA_PRED';
    end
    
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'LDA info stored in details field';
    model.referencedata  = 'See detail.data field';
    
    model.detail.lda          = [];
    model.loads               = cell(2,1); %2 modes by 1 block
    model.pred                = cell(1,2); %1 by nblocks
    model.detail.ssq          = []; %sum squares table
    model.ssqresiduals        = cell(2,2); %nmodes by nblocks
    model.description         = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}      = 'Linear Discriminant Analysis structure';
    model.detail.data         = cell(1,2); %1 by nblocks
    model.detail.res          = cell(1,2); %1 by nblocks
    model.detail.compressionmodel = []; %model structure
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing   = {[] []};
    model.detail.options         = [];
    
    model.help.predictions  = makepredhelp({
      'Class Predictions'      'prediction'    'vector'
      });
   
    model = add_classification_fields(model);
    model.detail.predictedclass = [];
    
    %-----------------------------------
  case {'asca'}    
    model.modeltype   = 'ASCA';
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'PCA class models are in field "submodel"';
    %model.pred        = cell(1,2); %1 by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'ASCA Model';
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.preprocessing    = {[] []};
    model.detail.options          = [];
    model.detail.decomp           = [];
    model.detail.decompdata       = [];
    model.detail.decompnames      = [];
    model.detail.effects          = [];
    model.detail.effectnames      = [];
    model.detail.decompresiduals  = [];
    model.detail.interactions     = {};
    model.detail.pvalues          = [];
    model.nclass                  = [];
    model.submodel                = {};
    model.combinedscores          = {};
    model.combinedprojected       = {};
    model.combinedloads           = {};
    model.detail.nsubmodel        = [];
    model                         = add_dso_fields(model,2,1);
    model.detail.options          = [];
    model.detail.anovadoe         = [];
    model.detail.anovadoe.table   = [];
    model                         = add_dso_fields(model,2,2);
    
    %-----------------------------------
  case {'mlsca'}    
    model.modeltype   = 'MLSCA';
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'PCA models for each level are in field "submodel"';
    %model.pred        = cell(1,2); %1 by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'MLSCA Model';
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.preprocessing    = {[] []};
    model.detail.options          = [];
    model.detail.effects          = [];
    model.detail.effectnames      = [];
    model.detail.globalmean       = [];
    model.submodel                = {};
    model.combinedscores          = {};
    model.combinedqs              = {};
    model.combinedprojected       = {};
    model.combinedloads           = {};
    model.detail.nsubmodel        = [];
    model                         = add_dso_fields(model,2,1);
    model.detail.options          = [];
    model                         = add_dso_fields(model,2,2);
    
    %-----------------------------------
  case {'svm'}
    model.modeltype   = upper(modeltype);
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Support Vectors stored in details field';
    model.pred        = cell(1,2); %1 by nblocks
    model.ssqresiduals            = cell(2,2); %nmodes by nblocks
    model.description             = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}          = 'Support vector machine regression/classification structure';
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.res              = cell(1,2); %1 by nblocks
    model.detail.compressionmodel = []; %model structure
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing    = {[] []};
    model.detail.options          = [];
    model.detail.svm.model     = []; % Matlab version of the libsvm svm_model
    model.detail.svm.cvscan    = []; % Struct containing results of CV parameter scan
    
    model.help.predictions  = makepredhelp({
      'Scores'           'scores'         'vector'
      });
    
    %-----------------------------------
  case 'svmda'
    
    model = modelstruct('svm');
    model = rmfield(model, 'ssqresiduals');
    model.modeltype = 'SVMDA';
    model = add_classification_fields(model);
    
    %-----------------------------------
  case 'svmoc'
    
    model = modelstruct('svm');
    model = rmfield(model, 'ssqresiduals');
    model.modeltype = 'SVMOC';
    model = add_classification_fields(model);
    
    %-----------------------------------
  case 'tsne'
    
    model.modeltype = 'TSNE';
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'TSNE info stored in detail.tsne field';
    model.loads                   = cell(2,1);
    model.description{1}          = 'TSNE Decomposition Model';
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.preprocessing    = {[] []};
    model.detail.options          = [];
    model.detail.tsne.model       = []; % Pickled Python model
    model.detail.tsne.distance_metrics = [];
    model.detail.compressionmodel = [];
    model                         = add_dso_fields(model,2,2);
    
    %-----------------------------------
  case {'xgb'}
    model.modeltype   = upper(modeltype);
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'XGB info stored in detail.xgb field';
    model.pred        = cell(1,2); %1 by nblocks
    model.ssqresiduals            = cell(2,2); %nmodes by nblocks
    model.description             = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}          = 'Gradient Boosted Decision Tree regression/classification structure';
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.res              = cell(1,2); %1 by nblocks
    model.detail.compressionmodel = []; %model structure
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing    = {[] []};
    model.detail.options          = [];
    model.detail.xgb.model     = []; % Matlab version of the libsvm svm_model
    model.detail.xgb.cvscan    = []; % Struct containing results of CV parameter scan
    
    model.help.predictions  = makepredhelp({
      'Scores'           'scores'         'vector'
      });
    
    %-----------------------------------
  case 'xgbda'
    
    model = modelstruct('xgb');
    model = rmfield(model, 'ssqresiduals');
    mdetail = model.detail;
    mdetail = rmfield(mdetail, 'rmsec');
    mdetail = rmfield(mdetail, 'rmsecv');
    mdetail = rmfield(mdetail, 'rmsep');
    mdetail = rmfield(mdetail, 'bias');
    mdetail = rmfield(mdetail, 'predbias');
    mdetail = rmfield(mdetail, 'selratio');
    mdetail = rmfield(mdetail, 'cvbias');
    mdetail = rmfield(mdetail, 'r2c');
    mdetail = rmfield(mdetail, 'r2cv');
    mdetail = rmfield(mdetail, 'r2p');
    mdetail = rmfield(mdetail, 'q2y');
    mdetail = rmfield(mdetail, 'r2y');
    model.detail = mdetail;
    model.modeltype = 'XGBDA';
    model = add_classification_fields(model);
    
    %-----------------------------------
  case 'umap'
    
    model.modeltype = 'UMAP';
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'UMAP info stored in detail.umap field';
    model.description{1}          = 'UMAP Decomposition Model';
    model.loads                   = cell(2,1);
    model.pred                    = cell(1,1);
    model.ssqresiduals            = cell(2,1);
    model.detail.res              = [];
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.preprocessing    = {[] []};
    model.detail.options          = [];
    model.detail.umap.model       = []; % Pickled Python model
    model.detail.umap.distance_metrics = [];
    model.detail.umap.xhat        = [];
    model.detail.compressionmodel = [];
    model                         = add_dso_fields(model,2,2);
    
    %-----------------------------------
  case 'cls'
    
    if ~pred
      model.modeltype   = 'CLS';
    else
      model.modeltype   = 'CLS_PRED';
    end
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Scores are in row 1 of cells in the loads field.';
    model.loads       = cell(2,1); %nmodes by 1
    model.pred        = cell(1,2); %1 by nblocks
    model.tsqs        = cell(2,2); %nmodes by nblocks
    model.ssqresiduals         = cell(2,2); %nmodes by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'Principal Components Regression Model';
    model.detail.data          = cell(1,2); %1 by nblocks
    model.detail.res           = cell(1,2); %1 by nblocks
    model.detail.ssq           = []; %sum squares table
    model.detail.elsmodel      = {}; %nmodes by 1 Bilinear models for ELS-type filtering
    model.detail.glscov        = {}; %nmodes by 1 Inverse covariance for GLS weighting
    model.detail.leverage      = []; %leverage
    model.detail.means         = [];
    model.detail.stds          = [];
    model.detail.reseig        = [];
    model.detail.rmsec         = [];
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.dy            = [];  %scalar or ny
    model.detail.esterror.pred   = []; %m by ny
    model.detail.bias          = []; %m by ny
    model.detail.predbias      = [];
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.reslim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.tsqlim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.originalinclude = {};
    model.detail.preprocessing = {[] []};
    model.detail.options       = [];
    model.help.predictions  = makepredhelp({
      'Predictions'      'prediction'       'vector'
      'Hotelling''s T^2' 'T2'               'scalar'
      'Q Residuals'      'Q'                'scalar'
      'T Contributions'  'tcon'             'vector'
      'Q Contributions'  'qcon'             'vector'
      });
    
    %-----------------------------------
  case 'clsti'
    model = modelstruct('cls');
    if ~pred
      model.modeltype   = 'CLSTI';
    else
      model.modeltype   = 'CLSTI_PRED';
    end
    model.datasource = {datasource};
    model.detail.clsti.refData = {};
    model.detail.clsti.componentNames = {};
    
    %-----------------------------------
  case 'corrspec'
    model.modeltype   = 'CORRSPEC';
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Scores are in row 1 of cells in the loads field.';
    model.reg         = [];        %regression vector
    model.loads       = cell(2,1); %nmodes by nblocks
    model.pred        = cell(1,2); %1 by nblocks
    model.tsqs        = cell(2,2); %nmodes by nblocks
    model.ssqresiduals         = cell(2,2); %nmodes by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'Correlation Spectroscopy Model';
    model.detail.data          = cell(1,2); %1 by nblocks
    model.detail.res           = cell(1,2); %1 by nblocks
    model.detail.ssq           = []; %sum squares table
    model.detail.reslim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.tsqlim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.maps          = [];
    model.detail.matrix        = [];
    model.detail.purvarindex   = [];
    model.detail.dispmat       = [];
    model.detail.dispmat_reconstructed = [];
    model.detail.sum_matrix    = [];
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing = {[] []};
    model.detail.options       = [];
    
    %-----------------------------------
  case {'sim','nip','dspls','pls','polypls','robustpls'}
    if strcmpi(modeltype,'pls'); modeltype='sim'; end
    if ~pred
      model.modeltype = 'PLS';
    else
      model.modeltype   = 'PLS_PRED';
    end
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Scores are in row 1 of cells in the loads field.';
    model.reg         = [];        %regression vector
    model.loads       = cell(2,2); %nmodes by nblocks
    model.pred        = cell(1,2); %1 by nblocks
    model.wts         = [];        %double (only for X-block)
    model.tsqs        = cell(2,2); %nmodes by nblocks
    model.ssqresiduals         = cell(2,2); %nmodes by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}     = 'PLS Regression Model';
    model.detail.data          = cell(1,2); %1 by nblocks
    model.detail.res           = cell(1,2); %1 by nblocks
    model.detail.ssq           = []; %sum squares table
    model.detail.bin           = []; %inner relation regression coefficients
    model.detail.basis         = []; %basis of x-loads, nvars by pc
    model.detail.leverage      = []; %leverage
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.dy            = [];  %scalar or ny
    model.detail.esterror.pred   = []; %m by ny
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.means         = cell(1,2); %1 by nblocks
    model.detail.stds          = cell(1,2); %1 by nblocks
    model.detail.reslim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.tsqlim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.eig           = []; %pcs by 1
    model.detail.reseig        = []; %pcs by 1
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')\
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing = {[] []};
    model.detail.robustpls     = [];
    model.detail.options       = [];
    model.detail.options.algorithm = lower(modeltype);
    model.help.predictions  = makepredhelp({
      'Predictions'      'prediction'  'vector'
      'Hotelling''s T^2' 'T2'          'scalar'
      'Q Residuals'      'Q'           'scalar'
      'T Contributions'  'tcon'        'vector'
      'Q Contributions'  'qcon'        'vector'
      });
    
    %-----------------------------------
  case 'plsda'
    
    model = modelstruct('sim');
    model.modeltype = 'PLSDA';
    model = add_classification_fields(model);
    model.detail.predictedclass = [];
    model.detail.distprob = [];

    %-----------------------------------
  case {'par','parafac','tuc','tucker','pa2','parafac2'}
    if nargin>1
      % Second input is order
      order = varargin{2};
    else
      % Assume three-way
      order = 3;
    end
    switch lower(modeltype)
      case {'par', 'parafac'}
        model.modeltype   = 'PARAFAC';
      case {'tuc','tucker'}
        model.modeltype   = 'TUCKER';
      case {'pa2', 'parafac2'}
        model.modeltype   = 'PARAFAC2';
      case {'sit', 'als_sit'}
        model.modeltype   = 'ALS_SIT';
    end
    model.datasource  = {datasource};  %(put in order above, just assigning correct # of blocks)
    
    switch lower(model.modeltype)
      case 'parafac2'
        model.info    = 'Scores and loadings are in cells of the loads field. First cell is a structure (see help)';
      otherwise
        model.info    = 'Scores and loadings are in cells of the loads field.';
    end
    model.loads       = cell(order,1); %nmodes by nblocks
    model.pred        = cell(1,1);     %1 by nblocks
    
    model.tsqs        = cell(order,1); %nmodes by nblocks
    model.ssqresiduals         = cell(order,1); %nmodes by nblocks, Q
    model.description          = cell(order,1); %column cell of char, line 1 has model name
    switch lower(modeltype)
      case {'par', 'parafac'}
        model.description{1}   = 'PARAFAC model (PARAllel FACtor analysis)';
        model.detail.componentnames = {}; %Labels for components/lvs.
      case {'pa2', 'parafac2'}
        model.description{1}   = 'PARAFAC2 model';
      case {'tuc','tucker'}
        model.description{1}   = 'TUCKER model';
      case {'sit','als_sit'}
        model.description{1}   = 'ALS_SIT model';
      otherwise
        error('Unknown modeltype')
    end
    model.detail.data          = cell(1,1); %1 by nblocks
    model.detail.res           = cell(1,1); %1 by nblocks
    model.detail.ssq           = []; %sum squares table
    model.detail.means         = cell(1,1); %1 by nblocks
    model.detail.stds          = cell(1,1); %1 by nblocks
    model.detail.reslim        = cell(1,1); %1 by nblocks (95% limit)
    model.detail.tsqlim        = cell(1,1); %1 by nblocks (95% limit)
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model.detail.stopcrit      = [];
    model.detail.critfinal     = [];
    model.detail.core          = [];
    model.detail.validation    = [];
    model.detail.iteratively_found_weights=[];
    model = add_dso_fields(model,order,1);
    model.detail.preprocessing = {[]};
    switch lower(modeltype)
      case {'par', 'parafac', 'pa2', 'parafac2', 'tuc','tucker', 'sit', 'als_sit'}
        model.detail.options       = [];
      otherwise
        error('Unknown modeltype')
    end

    model.detail.innercore        = [];
    model.detail.coreconsistency  = [];  %[1x1 struct]
    model.detail.tuckercongruence = []; %[2x2 double]
    model.detail.algo             = '';
    model.detail.initialization   = '';
    model.detail.converged        = struct('isconverged',0,'message','');
    
    model.help.predictions  = makepredhelp({
      'Sample Loadings'  'scores'       'vector'
      'Hotelling''s T^2' 'T2'           'scalar'
      'Q Residuals'      'Q'            'scalar'
      'T Contributions'  'tcon'         'matrix'
      'Q Contributions'  'qcon'         'matrix'
      });
    
    %-----------------------------------
  case {'npl','npls'}
    if nargin>1
      % Second input is order
      order = varargin{2};
    else
      % Assume three-way
      order = 3;
    end
    if strcmpi(modeltype,'npls'); modeltype='NPLS'; end
    model.modeltype   = 'NPLS';
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Scores are in row 1 of cells in the loads field.';
    model.reg         = [];        %regression vector
    model.loads       = cell(order,2); %nmodes by nblocks
    model.core        = [];
    model.pred        = cell(1,2); %1 by nblocks
    model.tsqs        = cell(order,2); %nmodes by nblocks
    model.ssqresiduals         = cell(order,2); %nmodes by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'N-PLS Regression Model';
    model.detail.data          = cell(1,2); %1 by nblocks
    model.detail.res           = cell(1,2); %1 by nblocks
    model.detail.ssq           = []; %sum squares table
    model.detail.ssqpred       = struct('X',[]); %SSQ table for prediction
    model.detail.bin           = []; %inner relation regression coefficients
    model.detail.leverage      = []; %leverage
    model.detail.rmsec         = []; %ny by pc
    model.detail.bias          = [];
    model.detail.predbias      = [];
    model.detail.dy            = [];  %scalar or ny
    model.detail.esterror.pred   = []; %m by ny
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.means         = cell(1,2); %1 by nblocks
    model.detail.stds          = cell(1,2); %1 by nblocks
    model.detail.reslim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.tsqlim        = cell(1,2); %1 by nblocks scalar (95% limit)
    model.detail.reseig        = []; %pcs by 1
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.preprocessing = {[] []};
    model.detail.options       = [];
    model.detail.options.algorithm = lower(modeltype);
    model.help.predictions  = makepredhelp({
      'Predictions'      'prediction'  'vector'
      'Hotelling''s T^2' 'T2'          'scalar'
      'Q Residuals'      'Q'           'scalar'
      'T Contributions'  'tcon'        'matrix'
      'Q Contributions'  'qcon'        'matrix'
      });
    
    %-----------------------------------
  case {'simca'}
    if ~pred
      model.modeltype   = 'SIMCA';
    else
      model.modeltype     = 'SIMCA_PRED';
    end
    
    model.datasource  = {datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'PCA class models are in field "submodel"';
    %model.pred        = cell(1,1); %1 by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'SIMCA Model';
    model.rtsq          = [];
    model.rq            = [];
    model.nclass        = [];
    model.rules         = [];
    model.submodel             = {};
    model.detail.nsubmodel     = [];
    model.detail.submodelclasses = {};
    model.detail.modeledclasslookup = {};
    model = add_dso_fields(model,2,1);
    model.detail.options       = [];
    model.help.predictions  = makepredhelp({
      'Classes'          'detail.submodelclasses'  'vector'
      'Hotelling''s T^2' 'rtsq'                    'vector'
      'Q Residuals'      'rq'                      'vector'
      });
    model = add_classification_fields(model);
    
    %-----------------------------------
  case {'genalg'}
    
    model.modeltype   = 'GENALG';  %sets.name = 'GenAlg';
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Fit results in "rmsecv", population included variables in "icol"';
    model.rmsecv      = [ ];
    model.icol        = [ ];
    model.detail.avefit   = [ ];
    model.detail.bestfit  = [ ];
    model.detail.allvarsfit  = [ ];
    model.detail.options  = [ ];
    
    %-----------------------------------
  case 'polytransform'
    model.modeltype = 'POLYTRANSFORM';
    model.datasource = {datasource};
    
    model.detail.means = [];
    model.detail.stds = [];
    model.detail.isnewmodel = [];
    model.detail.options = [];
    
    %-----------------------------------
  case 'mlr'
    if ~pred
      model.modeltype   = 'MLR';
    else
      model.modeltype   = 'MLR_PRED';
    end
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'MLR models do not contain scores or loadings';
    model.reg         = [];        %regression vector
    model.algorithm   = [];        %regularization type
    model.pred          = cell(1,2); %1 by nblocks
    model.tsqs          = cell(2,2);
    model.ssqresiduals         = cell(2,2); %nmodes by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'Multiple Linear Regression Model';
    model.detail.data          = cell(1,2); %1 by nblocks
    model.detail.res           = cell(1,2); %1 by nblocks
    model.detail.cov           = []; %m by m (!)
    model.detail.leverage      = []; %leverage
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.dy            = [];  %scalar or ny
    model.detail.esterror.pred   = []; %m by ny
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.bias          = [];
    model.detail.predbias      = [];
    model.detail.biaspred      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.means         = cell(1,2); %1 by nblocks
    model.detail.stds          = cell(1,2); %1 by nblocks
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.originalinclude = {};
    model.detail.preprocessing = {[] []};
    model.detail.options       = [];
    model.help.predictions  = makepredhelp({
      'Predictions'      'prediction'   'vector'
      'Hotelling''s T^2' 'T2'            'scalar'
      });
    model.detail.mlr.best_params.optimized_ridge = [];
    model.detail.mlr.best_params.optimized_lasso = [];
    model.detail.mlr.condmax_value               = [];
    model.detail.mlr.condmax_ncomp               = [];
    model.detail.mlr.ridge_theta                 = [];
    model.detail.mlr.ridge_hkb_theta             = [];
    model.detail.mlr.optimized_ridge_theta       = [];
    model.detail.mlr.optimized_lasso_theta       = [];
    
    
    %-----------------------------------
  case 'b3spline'
    if ~pred
      model.modeltype   = 'B3SPLINE';
    else
      model.modeltype   = 'B3SPLINE_PRED';
    end
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'B3Spline Model';
    model.reg         = [];        %regression vector
    model.pred          = cell(1,2); %1 by nblocks
    model.description          = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}       = 'B3Spline Model';
    model.t                    = [];
    model.m                    = [];
    model.detail.options       = [];
    model.help.predictions  = makepredhelp({
      'Predictions'      'prediction'         'vector'
      });
    
    %-----------------------------------
  case {'knn'}
    
    model.modeltype   = 'KNN';
    model.datasource  = {datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'K Nearest Neighbor (KNN) Model';
    model.referencedata  = 'See detail.data field';
    model.k              = [ ];
    model.pred           = [ ]; %Predicted classes
    model.closest        = [ ]; %closest sample(s)
    model.votes          = [ ]; %votes from each neibour
    model.detail.data    = {[ ]};
    model.detail.compressionmodel = []; %model structure
    model.detail.cvpred           = []; %cv prediction error for the Y-block
    model.detail.cv               = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split            = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter             = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi              = []; %exact cvi used
    model.detail.preprocessing    = {[]};
    model.detail.options          = [ ];
    model = add_dso_fields(model,2,1);
    model = add_classification_fields(model);
    model.help.predictions  = makepredhelp({
      'Class Predictions'      'prediction'    'vector'
      });
    
    %-----------------------------------
  case {'caltransfer'}
    
    model.modeltype       = 'CALTRANSFER';
    model.datasource      = {datasource datasource};%Same as PLS...
    model.transfermethod  = '';  %Method used to perform transfer (e.g., .
    model.info            = 'Calibration Transfer Model';
    model.description     = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}  = 'Calibration Transfer model, method stored in model.transfermethod.';
    model.glswmodel       = [];
    model.nw              = [];
    model.np              = [];
    model.nt              = [];
    model.detail.data     = cell(1,2); %1 by nblocks
    model.detail.stdmat   = [];
    model.detail.stdvect  = [];
    model.detail.block1modified = 0; %Has the method used modified the fist block.
    model.detail.modelname  = '';
    model.detail.preprocessing = {[] []};
    model = add_dso_fields(model,2,2);
    model.detail.options       = [];
    
    %-----------------------------------
  case {'trendtool'}
    
    model.modeltype = 'TRENDTOOL';
    model.datasource = {datasource};
    model.markers    = [];
    model            = add_dso_fields(model,2,1);
    model.detail.preprocessing = {[]};
    
    %-----------------------------------
  case {'analyzeparticles'}
    model.modeltype   = upper(modeltype);
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Particle properties stored in particletable field';
    model.allparticles            = []; % pixels which are in a particle = 1
    model.particles               = []; % pixels in particle j = j
    model.foreground              = []; % pixels which = 1 in binary mask are  = 1
    % Same as allparticles if no particles
    % are excluded because of filters
    model.particletable           = []; % array (DSO?) holding particles' properties
    model.description             = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}          = 'Analyze particles model data structure';
    model.detail.thresholdValue   = [];
    model.detail.height           = [];
    model.detail.width            = [];
    model.detail.nparticles       = [];
    model.detail.ij               = [];
    model.detail.options          = [];
    model                         = add_dso_fields(model,2,2);
    
    %-----------------------------------
  case {'texture'}
    
    model.modeltype         = 'TEXTURE';
    model.datasource        = {datasource};
    model.info              = 'Texture Analysis Model';
    model.description       = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}    = 'Texture Analysis Model';
    model.texture_method    = '';
    model.vararg            = {[]};%Optional additional arguments to texture method.
    model.detail.options    = [];%Texture options.


    %-----------------------------------
  case {'batchfold'}
    
    model.modeltype         = 'BATCHFOLD';
    model.datasource        = {datasource};
    model.info              = 'Batch Fold Model';
    model.description       = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}    = 'Batch Fold Model';
    model.fold_method       = '';
    model.detail.options    = [];%Batchfold options.
          
    %-----------------------------------
  case {'modeloptimizer'}
    
    model.modeltype         = 'MODELOPTIMIZER';
    model.info              = 'Model Optimizer';
    model.description       = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}    = 'Model Optimizer';
    model.optimizer          = [];
    model.detail.options    = [];%optimizer options.
          

    %-----------------------------------
  case {'batchmaturity'}
    if ~pred
      model.modeltype   = 'BATCHMATURITY';
    else
      model.modeltype     = 'BATCHMATURITY_PRED';
    end
    
    model.datasource  = {datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'BM class models are in fields "submodelreg" and "submodelpca"';
    model.description     = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}  = 'BATCHMATURITY Model';
    model.limits.cl       = [];
    model.limits.bm       = [];
    model.limits.low      = [];
    model.limits.high     = [];
    model.inlimits        = [];
    model.scores_reduced        = [];
    model.submodelreg     = evrimodel('pls');
    model.submodelpca     = evrimodel('pca');
    model.detail.preprocessing = {[] []};
    model = add_dso_fields(model,2,1);
    model.detail.options       = [];

    model.help.predictions  = makepredhelp({
      'Hotelling''s T^2' 'rtsq'                    'vector'
      'Q Residuals'      'rq'                      'vector'
      });
    
    %----------------------------------
  case 'modelselector'
    model.modeltype = 'MODELSELECTOR';
    model.datasource = {};
    model.info = 'Target models are in field "targets"';
    model.description = { 'MODEL SELECTOR Model' ; [ ] ; [ ] };
    model.trigger = [];
    model.targets = {};
    model.outputfilters = {};
    model.detail.options = [];
    
    model = add_dso_fields(model,2,1);
    
    %----------------------------------
  case 'multiblock'
    model.modeltype = 'MULTIBLOCK';
    model.datasource = {getdatasource};
    model.info = 'Mulitple datasets/modles model.';
    model.description = { 'MULTIBLOCK Model' ; [ ] ; [ ] };
    model.mdata = {};
    model.matchinginfo = {};
    model.detail.options = [];
    
    model = add_dso_fields(model,2,1);
    
    %----------------------------------
  case 'triggerstring'
    model.modeltype = 'TRIGGERSTRING';
    model.datasource = {};
    model.info = 'Trigger model using simple trigger strings';
    model.description = { 'TRIGGER STRING Model' ; [ ] ; [ ] };
    model.triggers = {};

    model = add_dso_fields(model,2,2);
    
    %-----------------------------------
  case 'glsw'
    model.modeltype  = 'GLSW';
    model.datasource = {getdatasource};
    model.info       = 'See GLSW for help with this model';
    model.detail.v   = [];
    model.detail.s   = [];
    model.detail.xdm = [];
    model.detail.a   = [];
    model.detail.d   = [];
    model.detail.groups = [];
    model.detail.options = [];
    
    %-----------------------------------
  case {'maf' }    
    model                 = modelstruct('pca');
    model.modeltype       = 'MAF';
    model.wts             = [];
    model.detail.ploads   = cell(2,1);
    model.detail.tsqmtx   = cell(2,1);
    model.detail.dinclud  = cell(1,2);
    
    %-----------------------------------
  case {'mdf' }    
    model                 = modelstruct('pca');
    model.modeltype       = 'MDF';
    model.wts             = [];
    model.detail.ploads   = cell(2,1);
    model.detail.tsqmtx   = cell(2,2);
    model.detail.dinclud  = cell(1,2);
    
  case {'oplecorr' }    
    model.modeltype  = 'OPLECORR';
    model.datasource = {getdatasource};
    model.info       = 'See OPLECORR for help with this model';
    model.mx         = [];
    model.br         = [];
    model.mb         = [];
    model.detail.p   = [];
    model.detail.b   = [];
    model.detail.options = [];
    
    %-----------------------------------
  case 'ensemble'
    
    if ~pred
      model.modeltype   = 'ENSEMBLE';
    else
      model.modeltype   = 'ENSEMBLE_PRED';
    end
    model.modeltype   = upper(modeltype);
    model.datasource  = {datasource datasource};  %(put in order above, just assigning correct # of blocks)
    model.info        = 'Models are stored in the .detail.ensemble.children field';
    model.pred        = cell(1,2); %1 by nblocks
    model.ssqresiduals            = cell(2,2); %nmodes by nblocks
    model.description             = cell(3,1); %column cell of char, line 1 has model name
    model.description{1}          = '';
    model.detail.data             = cell(1,2); %1 by nblocks
    model.detail.res              = cell(1,2); %1 by nblocks
    model.detail.compressionmodel = []; %model structure
    model.detail.rmsec         = []; %ny by pc
    model.detail.rmsecv        = []; %ny by pc
    model.detail.rmsep         = []; %ny by pc
    model.detail.bias          = []; %5/16/07
    model.detail.predbias      = [];
    model.detail.selratio      = []; %ny by included nx
    model.detail.cvpred        = []; %cv prediction error for the Y-block
    model.detail.cvbias        = []; %cv bias
    model.detail.r2c           = []; %ny by pc
    model.detail.r2cv          = []; %ny by pc
    model.detail.r2p           = []; %ny by pc
    model.detail.q2y           = []; %ny by pc
    model.detail.r2y           = []; %ny by pc
    model.detail.cv            = ''; %cv method ('loo','vet','con','rnd', cvi)
    model.detail.split         = []; %scalar cv splits (for 'vet', 'con', 'rnd')
    model.detail.iter          = []; %scalar cv iterations (for 'rnd')
    model.detail.cvi           = []; %exact cvi used
    model                      = add_dso_fields(model,2,2);
    model.detail.options         = [];
    model.detail.ensemble.children      = cell(1,1);
    
    model.help.predictions  = makepredhelp({'Predictions'      'prediction'         'vector' });
    
    %-----------------------------------
  case evriio([],'validtopics')
    options = [];
    if nargout==0; clear model; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
    return;
    
  otherwise
    error('Unrecognized model type "%s"',upper(modeltype))
    
end

%move some fields to the bottom of the model
tomove = {'help' 'modelversion'};   %order of these fields (at the bottom)
for f = tomove;
  if isfield(model,f{:})
    content = model.(f{:});
    model = rmfield(model,f{:});
    model.(f{:}) = content;
  end
end

%---------------------------------------------------------
% Add DSO fields to a model
function model = add_dso_fields(model,nmodes,nblocks)

model.detail.includ        = cell(nmodes,nblocks);
model.detail.label         = cell(nmodes,nblocks); %nmodes by nblocks by nsets
model.detail.labelname     = cell(nmodes,nblocks); %nmodes by nblocks by nsets
model.detail.axisscale     = cell(nmodes,nblocks); %nmodes by nblocks by nsets
model.detail.axisscalename = cell(nmodes,nblocks); %nmodes by nblocks by nsets
model.detail.axistype      = cell(nmodes,nblocks); %nmodes by nblocks by nsets
model.detail.imageaxisscale = cell(nmodes,nblocks);
model.detail.imageaxisscalename = cell(nmodes,nblocks);
model.detail.title         = cell(nmodes,nblocks); %nmodes by nblocks by nsets
model.detail.titlename     = cell(nmodes,nblocks); %nmodes by nblocks by nsets
model.detail.class         = cell(nmodes,nblocks); %nmodes by nblocks by nsets
model.detail.classname     = cell(nmodes,nblocks); %nmodes by nblocks by nsets
model.detail.classlookup   = repmat({{}},nmodes,nblocks); %nmodes by nblocks by nsets

%---------------------------------------------------------
% Add classification fields to a model
function  model = add_classification_fields(model)
model.classification              = struct;
model.classification.probability  = [];
model.classification.mostprobable = [];
model.classification.inclass      = [];
model.classification.inclasses    = [];
model.classification.classnums    = [];
model.classification.classids     = {};

model.detail.originalinclude = {};
model.detail.modelgroups     = {};
model.detail.threshold       = [];
if ~strcmp(model.modeltype, 'SVMDA')
  model.detail.probability     = {};
end
model.detail.predprobability = [];
model.detail.misclassedc     = {};
model.detail.misclassedcv    = {};
model.detail.misclassedp     = {};
model.detail.classerrc       = [];
model.detail.classerrcv      = [];
model.detail.classerrp       = [];

model.detail.cvclassification              = struct;
model.detail.cvclassification.probability  = [];
model.detail.cvclassification.mostprobable = [];
model.detail.cvclassification.inclass      = [];
model.detail.cvclassification.inclasses    = [];
model.detail.cvclassification.classnums    = [];
model.detail.cvclassification.classids     = {};

%------------------------------------------------------
function out = modelstruct(varargin)
%OVERLOAD of modelstruct for internal calls (allows us to keep the old code
%and simply call recursively for these sub-structures when needed)

out = template(varargin{:});

%------------------------------------------------------
function out = prodinfo

persistent myinfo

if isempty(myinfo)
  try
    [myver,myprod] = evrirelease('all');
    if ~isempty(myver) & ~isempty(myprod)
      info = {myprod{:};myver{:}};
      myinfo = sprintf('%s %s, ',info{:});
      myinfo = myinfo(1:end-2);
    else
      myinfo = '(Unavailable)';
    end
  catch
    myinfo = '(Unavailable)';
  end
end
out = myinfo;
