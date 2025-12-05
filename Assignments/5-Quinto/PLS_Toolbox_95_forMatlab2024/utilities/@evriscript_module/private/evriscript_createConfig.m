function [] = evriscript_createConfig()
% evriscript_createConfig
%--------------------------------------------------------------------------
% Save script_module configuration information in a .mat, as a struct of structs
% with function name as key, example, key = 'pls', with value a struct 'module'.
% ann
% annda
% anndl
% anndlda
% auto
% autoimport
% choosecomp
% cls
% cluster
% cluster_img
% coadd
% crossval
% datahat
% ensemble
% knn
% knnscoredistance
% lda
% lregda
% lwr
% matchrows
% mncn
% mcr
% mlr
% mpca
% npls
% parafac
% pca
% pcr
% pls
% plsda
% preprocess
% svm
% svmda
% tsne
% umap
% xgb
% xgbda

%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLABÆ, without
% written permission from Eigenvector Research, Inc.

projRepository = fullfile(tempdir,'evriscript_config.mat')

modules = struct;


%--------------------------------------------------------------------------
% ann
%--------------------------------------------------------------------------                                                                         
%I/O: [model] = ann(x,y,nhid,options);   %identifies model (calibration step)
%I/O: [pred]  = ann(x,model,options);    %makes predictions with a new X-block
%I/O: [valid] = ann(x,y,model,options);  %makes predictions with new X- & Y-block
clear module
module                    = evriscript_module;

module.keyword            = 'ann';
module.description        = 'Artificial Neural Network regression for univariate or multivariate Y';

module.command(1).calibrate  = 'var.model = ann(var.x,var.y,var.nhid,options);';
module.command.apply      = 'var.pred  = ann(var.x,var.model,options);';
module.command.test       = 'var.valid = ann(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'y' 'nhid'};    
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).nhid       = 1;
module.options            = ann('factoryoptions');

modules.ann               = module;

%--------------------------------------------------------------------------
% annda
%--------------------------------------------------------------------------  
%I/O: model = annda(x,y,nhid,options);  %identifies model (calibration step)
%I/O: pred  = annda(x,model,options);    %makes predictions with a new X-block
%I/O: valid = annda(x,y,model,options);  %makes predictions with new X- & sample classes
%I/O: options = annda('options');        %returns a default options structure
clear module
module                    = evriscript_module;
module.keyword            = 'annda';
module.description        = 'Artificial Neural Net for classification';

module.command(1).calibrate  = 'var.model  = annda(var.x,var.y,var.nhid,options);';
module.command.apply      = 'var.pred   = annda(var.x, var.model,options);';
module.command.test       = 'var.valid   = annda(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'model'};

module.optional(1).calibrate = {'y' 'nhid'};
module.optional.apply     = {};
module.optional.test      = {'y'};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).y          = [];
module.default.nhid       = 1;
module.options            = annda('factoryoptions');

modules.annda             = module;

%--------------------------------------------------------------------------
% anndl
%--------------------------------------------------------------------------                                                                         
%I/O: [model] = anndl(x,y,nhid,options);   %identifies model (calibration step)
%I/O: [pred]  = anndl(x,model,options);    %makes predictions with a new X-block
%I/O: [valid] = anndl(x,y,model,options);  %makes predictions with new X- & Y-block
clear module
module                    = evriscript_module;

module.keyword            = 'anndl';
module.description        = 'Deep Learning Artificial Neural Network regression for univariate or multivariate Y';

module.command(1).calibrate  = 'var.model = anndl(var.x,var.y,options);';
module.command.apply      = 'var.pred  = anndl(var.x,var.model,options);';
module.command.test       = 'var.valid = anndl(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'y'};    
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).nhid       = 1;
module.options            = anndl('factoryoptions');

modules.anndl               = module;

%--------------------------------------------------------------------------
% anndl
%--------------------------------------------------------------------------                                                                         
%I/O: [model] = anndl(x,y,nhid,options);   %identifies model (calibration step)
%I/O: [pred]  = anndl(x,model,options);    %makes predictions with a new X-block
%I/O: [valid] = anndl(x,y,model,options);  %makes predictions with new X- & Y-block
clear module
module                    = evriscript_module;

module.keyword            = 'anndlda';
module.description        = 'Deep Learning Artificial Neural Network for classification';

module.command(1).calibrate  = 'var.model = anndlda(var.x,var.y,options);';
module.command.apply      = 'var.pred  = anndlda(var.x,var.model,options);';
module.command.test       = 'var.valid = anndlda(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'y'};    
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).nhid       = 1;
module.options            = anndlda('factoryoptions');

modules.anndlda               = module;

%--------------------------------------------------------------------------
% auto
%-------------------------------------------------------------------------- 
% I/O: [ax,mx,stdx,msg] = auto(x,options);
clear module
module                    = evriscript_module;
module.keyword            = 'auto';
module.description        = 'Autoscales matrix to mean zero unit variance';

module.command(1).calibrate  = '[var.mcx,var.xmean,var.stdx] = auto(var.x, options);';
module.command.apply      = '[var.mcx] = scale(var.x, var.xmean, var.stdx, options);';
module.command.undo       = '[var.x]   = rescale(var.x, var.xmean, var.stdx, options);';

module.required(1).calibrate = {'x'};
module.required.apply     = {'x', 'xmean', 'stdx'};
module.required.undo      = {'x', 'xmean', 'stdx'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.undo      = {};

module.outputs(1).calibrate  = {'mcx', 'xmean', 'stdx'};
module.outputs.apply      = {'mcx'};
module.outputs.undo       = {'x'};

module.options            = auto('factoryoptions');

modules.auto              = module;

%--------------------------------------------------------------------------
% autoimport
%-------------------------------------------------------------------------- 
%  I/O: [data,name,source] = autoimport(filename,methodname,options)
clear module
module                    = evriscript_module;
module.keyword            = 'autoimport';
module.description        = 'Automatically reads specified file. Handles all standard filetypes';

module.command(1).apply      = '[var.data,var.name,var.source] = autoimport(var.filename,var.methodname,options);';

module.required(1).apply     = {'filename'};

module.optional(1).apply     = {'methodname'};

module.outputs(1).apply      = {'data'};

module.options            = autoimport('factoryoptions');
module.options.error      = 'error';

modules.autoimport        = module;

%--------------------------------------------------------------------------
% choosecomp
%--------------------------------------------------------------------------                                                                         
% I/O: lvs = choosecomp(model,options)
clear module
module                    = evriscript_module;
module.keyword            = 'choosecomp';
module.description        = 'Returns suggestion for number of components to include in a model';

module.command(1).apply      = '[var.lvs]  = choosecomp(var.model);';
 
module.required(1).apply     = {'model'};

module.optional(1).apply     = {};

module.outputs(1).apply      = {'lvs'};

module.options            = [];

modules.choosecomp        = module;

%--------------------------------------------------------------------------
% cls
%-------------------------------------------------------------------------- 
%  I/O: model = cls(x,options);          %identifies model (calibration step)    
%  I/O: model = cls(x,y,options);        %identifies model (calibration step)    
%  I/O: pred  = cls(x,model,options);    %makes predictions with a new X-block   
%  I/O: valid = cls(x,y,model,options);  %makes predictions with new X- & Y-block
clear module
module                    = evriscript_module;
module.keyword            = 'cls';
module.description        = 'CLS Classical Least Squares regression for multivariate Y';

module.command(1).calibrate  = 'var.model  = cls(var.x,var.y,options);';
module.command.apply      = 'var.pred   = cls(var.x,var.model,options);';
module.command.test       = 'var.valid  = cls(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {'y'};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.options            = cls('factoryoptions');
module.options.algorithm  = 'cnnls'; 

modules.cls               = module;

%--------------------------------------------------------------------------
% cluster
%--------------------------------------------------------------------------
%  I/O: [results,fig,distances] = cluster(data,labels,options);
%  I/O: [results,fig,distances] = cluster(data,options);
clear module
module                    = evriscript_module;
module.keyword            = 'cluster';
module.description        = 'Perform aglomerative and K-means clustering using sample distances';

module.command(1).calibrate  = '[var.results, var.fig, var.distances] = cluster(var.x,options);';

module.required(1).calibrate = {'x'};

module.optional(1).calibrate = {};

module.outputs(1).calibrate  = {'results', 'fig', 'distances'};

module.default(1).labels     = {};
module.options            = cluster('factoryoptions');

modules.cluster           = module;
%--------------------------------------------------------------------------

% cluster_img:
%--------------------------------------------------------------------------
%  I/O: [clas,basis,info,h] = cluster_img(x,nclusters,options); %identifies basis (calibration step)
%  I/O: clas = cluster_img(x,basis,options);       %projects a new X-block onto existing basis
clear module
module                    = evriscript_module;
module.keyword            = 'cluster_img';
module.description        = 'Perform automatic clustering of image using sample distances';

module.command(1).calibrate  = '[var.clas, var.model] = cluster_img(var.x,var.nclusters,options);';
module.command.apply      = '[var.clas]  = cluster_img(var.x,var.model,options);';

module.required(1).calibrate = {'x' 'nclusters'};
module.required.apply     = {'x' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};

module.outputs(1).calibrate  = {'clas', 'model'};
module.outputs.apply      = {'clas'};

module.default(1).ncomp      = 2;
module.options            = cluster_img('factoryoptions');

modules.cluster_img       = module;

%--------------------------------------------------------------------------
% coadd
%--------------------------------------------------------------------------                                                                         
%  I/O: databin = coadd(data,binsize,options)     
clear module
module                    = evriscript_module;
module.keyword            = 'coadd';
module.description        = 'Reduce resolution through combination of adjacent variables or samples';

module.command(1).apply      = 'var.xbin = coadd(var.x, var.binsize, options);';

module.required(1).apply     = {'x' 'binsize'};

module.optional(1).apply     = {};

module.outputs(1).apply      = {'xbin'};

module.options            = coadd('factoryoptions');

modules.coadd             = module;

%--------------------------------------------------------------------------
% crossval
%-------------------------------------------------------------------------- 
%  I/O: results = crossval(x,y,rm,cvi,ncomp,options);
clear module
module                    = evriscript_module;
module.keyword            = 'crossval';
module.description        = 'Cross-validation for decomposition and linear regression';

% module.command.apply      = '[var.press,var.cumpress,var.rmsecv,var.rmsec,var.cvpred,var.misclassed] = crossval(var.x,var.y,var.rm,var.cvi,var.ncomp,options);';
module.command(1).apply      = '[var.cvresults] = crossval(var.x,var.y,var.rm,var.cvi,var.ncomp,options);';

module.required(1).apply     = {'x' 'y' 'rm' 'cvi'};

module.optional(1).apply     = {'ncomp'};

module.outputs(1).apply      = {'cvresults'}; %{'press','cumpress','rmsecv','rmsec','cvpred','misclassed'};

module.options            = crossval('factoryoptions');

modules.crossval          = module;

%--------------------------------------------------------------------------
% datahat
%--------------------------------------------------------------------------                                                                         
%I/O: xhat          = datahat(model);         %estimates model fit of data
%I/O: [xhat,resids] = datahat(model,data);    %estimates model fit of new data
%I/O: [xhat,resids] = datahat(loadings,data); %estimate loadings fit of new data
clear module
module                    = evriscript_module;
module.keyword            = 'datahat';
module.description        = 'Calculates the model estimate and residuals of the data';

module.command(1).apply      = '[var.xhat, var.resids]  = datahat(var.model,var.data);';
 
module.required(1).apply     = {'model'};

module.optional(1).apply     = {'data'};

module.outputs(1).apply      = {'xhat' 'resids'};

module.options            = [];

modules.datahat           = module;

%--------------------------------------------------------------------------
% ensemble
%--------------------------------------------------------------------------                                                                         

clear module
module                    = evriscript_module;

module.keyword            = 'ensemble';
module.description        = '';

module.command(1).calibrate  = 'var.model = ensemble(var.models,options);';
module.command.apply      = 'var.pred  = ensemble(var.x,var.model);';
module.command.test       = 'var.valid = ensemble(var.x,var.y,var.model);';

module.required(1).calibrate = {'models'};    
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.options            = ensemble('options');

modules.ensemble               = module;


%--------------------------------------------------------------------------
% evri_sdk
%--------------------------------------------------------------------------                                                                         
%  generated with the following m-files which are located in the repository
%
%  sdk
%      utility
%           encode_evriscript.m
%           scriptSDKapplyModel.m
clear module
module                    = evriscript_module;
module.keyword            = 'evri_sdk';
module.description        = 'evriscript module for EVRI sdk';

% used to apply most supported models in wiki (see list in scriptSDKapplyModel.m) 
module.command(1).apply_model    = encode_evriscript('scriptSDKapplyModel.m');
module.required(1).apply_model   = {'mdl'};
module.optional(1).apply_model   = {'data'};
module.outputs(1).apply_model    = {'out' 'errorMsg' 'errorBool'};

% % used for modelselector models
% module.command.apply_msmodel    = encode_evriscript('scriptSDKapplyMSModel.m');
% module.required.apply_msmodel   = {'mdl' 'data'};
% module.outputs.apply_msmodel    = {'out' 'errorMsg' 'errorBool' 'outType'};


% % used for returning outputs from decision nodes in a modelselector model
% module.command.track_msmodel  = encode_evriscript('scriptSDKtrackMSModel.m');
% module.required.track_msmodel = {'mdl' 'data'};
% module.outputs.track_msmodel  = {'outDS' 'outCell' 'errorMsg' 'errorBool'};

modules.evri_sdk          = module;

%--------------------------------------------------------------------------
% knn
%--------------------------------------------------------------------------                                                                         
%  NOT IMPL: pclass = knn(xref,xtest,k,options);   %make prediction without model
%  NOT IMPL: pclass = knn(xref,xtest,options);     %use default k                
%  I/O: model  = knn(xref,k,options);         %create model                 
%  I/O: pclass = knn(xtest,model,k,options);  %apply model to xtest         
%  I/O: pclass = knn(xtest,model,options);     

clear module
module                    = evriscript_module;
module.keyword            = 'knn';
module.description        = 'KNN K-nearest neighbor classifier';

module.command(1).calibrate  = 'var.model  = knn(var.x,var.k,options);';
module.command.apply      = 'var.pclass = knn(var.x,var.model,var.k,options);';
% module.command.test       = 'var.valid  = knn(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x'};
module.required.apply     = {'x' 'model'};

module.optional(1).calibrate = {'k'};
module.optional.apply     = {'k'};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pclass'};

module.default(1).k          = 3;
module.options            = knn('factoryoptions');

modules.knn               = module;

%--------------------------------------------------------------------------
% knnscoredistance
%--------------------------------------------------------------------------                                                                         
%  I/O: distance = knnscoredistance(model,k,options)
%  I/O: distance = knnscoredistance(model,pred,k,options)
clear module
module                    = evriscript_module;
module.keyword            = 'knnscoredistance';
module.description        = 'Calculate the average distance to the k-Nearest Neighbors in score space';

module.command(1).apply      = 'var.distance = knnscoredistance(var.model,var.pred,var.k,options);';

module.required(1).apply     = {'model'};

module.optional(1).apply     = {'k' 'pred'};

module.outputs(1).apply      = {'distance'};

module.default(1).k          = 3;
module.options            = knnscoredistance('factoryoptions');

modules.knnscoredistance  = module;

%--------------------------------------------------------------------------
% lda
%--------------------------------------------------------------------------                                                                         
%  I/O: model = lda(x,y,ncomp,options);  %identifies model (calibration step)    
%  I/O: pred  = lda(x,model,options);    %makes predictions with a new X-block   
%  I/O: valid = lda(x,y,model,options);  %makes predictions with new X- & Y-block
clear module
module                    = evriscript_module;
module.keyword            = 'lda';
module.description        = 'Linear discriminant analysis';

module.command(1).calibrate  = 'var.model  = lda(var.x,var.y,var.ncomp,options);';
module.command.apply      = 'var.pred   = lda(var.x,var.model,options);';
module.command.test       = 'var.valid  = lda(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'ncomp'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'model'};

module.optional(1).calibrate = {'y'};
module.optional.apply     = {};
module.optional.test      = {'y'};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).ncomp      = 1;
module.default.y          = [];
module.options            = lda('factoryoptions');

modules.lda               = module;

%--------------------------------------------------------------------------
% lregda
%--------------------------------------------------------------------------                                                                         
%  I/O: model = lregda(x,y,options);          %identifies model (calibration step)                         
%  I/O: pred  = lregda(x,model,options);      %makes predictions with a new X-block                        
%  I/O: pred  = lregda(x,y,model,options);    %performs a "test" call with a new X-block and known y-values
clear module
module                    = evriscript_module;
module.keyword            = 'lregda';
module.description        = 'Logistic Regression (LREGDA) for classification';

module.command(1).calibrate  = 'var.model  = lregda(var.x,var.y,options);';
module.command.apply      = 'var.pred   = lregda(var.x, var.model,options);';
module.command.test       = 'var.valid   = lregda(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'model'};

module.optional(1).calibrate = {'y' 'ncomp'};
module.optional.apply     = {};
module.optional.test      = {'y'};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).y          = [];
module.options            = lregda('factoryoptions');

modules.lregda             = module;

%--------------------------------------------------------------------------
% lwr
%--------------------------------------------------------------------------                                                                         
% I/O: model = lwr(x,y,ncomp,npts,options); %identifies model (calibration step)
% I/O: pred  = lwr(x,model,options);        %makes predictions with a new X-block  
% I/O: valid = lwr(x,y,model,options);      %makes predictions with new X- & Y-block
clear module
module                    = evriscript_module;
module.keyword            = 'lwr';
module.description        = 'Locally weighted regression for univariate Y';

module.command(1).calibrate  = 'var.model = lwr(var.x,var.y,var.ncomp,var.npts,options);';
module.command.apply      = 'var.pred  = lwr(var.x,var.model,options);';
module.command.test       = 'var.valid = lwr(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'y' 'ncomp' 'npts'};    
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).ncomp      = 1;
module.default.npts       = 15;
module.options            = lwr('factoryoptions');

modules.lwr               = module;

%--------------------------------------------------------------------------
% matchrows
%--------------------------------------------------------------------------                                                                         
% I/O: [x,y] = matchrows(x,y)     
clear module
module                    = evriscript_module;
module.keyword            = 'matchrows';
module.description        = 'Matches up rows from two DataSet objects using labels or sizes';

module.command(1).apply      = '[var.xout, var.yout] = matchrows(var.x, var.y);';

module.required(1).apply     = {'x' 'y'};

module.optional(1).apply     = {};

module.outputs(1).apply      = {'xout', 'yout'};

module.options            = {};

modules.matchrows         = module;

%--------------------------------------------------------------------------
% mcr
%--------------------------------------------------------------------------
%  I/O: model   = mcr(x,ncomp,options);  %identifies model (calibration step)                         
%  *** not impl: I/O: model   = mcr(x,c0,options);     %identifies model (calibration step)                         
%  I/O: pred    = mcr(x,model,options);  %projects a new X-block onto existing model, prediction mode.
clear module
module                    = evriscript_module;
module.keyword            = 'mcr';
module.description        = 'MCR Multivariate curve resolution with constraints';

module.command(1).calibrate  = 'var.model = mcr(var.x,var.ncomp,options);';
module.command.apply      = 'var.pred  = mcr(var.x,var.model,options);';

module.required(1).calibrate = {'x' 'ncomp'};    
module.required.apply     = {'x' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};

module.default(1).ncomp      = 1;
mcroptions                = mcr('factoryoptions');
mcroptions.alsoptions.definitions = [];
module.options            = mcroptions;

modules.mcr               = module;

%--------------------------------------------------------------------------
% mlr
%--------------------------------------------------------------------------
%  I/O: model = mlr(x,y,options);       %identifies model (calibration step)    
%  I/O: pred  = mlr(x,model,options);   %makes predictions with a new X-block   
%  I/O: valid = mlr(x,y,model,options); %makes predictions with new X- & Y-block
clear module
module                    = evriscript_module;
module.keyword            = 'mlr';
module.description        = 'MLR Multiple Linear Regression for multivariate Y';

module.command(1).calibrate  = 'var.model = mlr(var.x,var.y,options);';
module.command.apply      = 'var.pred  = mlr(var.x,var.model,options);';
module.command.test       = 'var.valid = mlr(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'y'};    
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.options            = mlr('factoryoptions');

modules.mlr               = module;

%--------------------------------------------------------------------------
% mncn
%-------------------------------------------------------------------------- 
% I/O: [mcx,mx,msg] = mncn(x,options); 
clear module
module                    = evriscript_module;
module.keyword            = 'mncn';
module.description        = 'Scale matrix to mean zero';

module.command(1).calibrate  = '[var.mcx, var.xmean] = mncn(var.x, options);';
module.command.apply      = '[var.mcx]            = scale(var.x, var.xmean, options);';
module.command.undo       = '[var.x]              = rescale(var.x, var.xmean, options);';
% module.command.undo = 'var.x = mncn(var.x, options);';

module.required(1).calibrate = {'x'};
module.required.apply     = {'x', 'xmean'};
module.required.undo      = {'x', 'xmean'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.undo      = {};

module.outputs(1).calibrate  = {'mcx', 'xmean'};
module.outputs.apply      = {'mcx'};
module.outputs.undo       = {'x'};

module.options            = mncn('factoryoptions');

modules.mncn              = module;

%--------------------------------------------------------------------------
% mpca:
%--------------------------------------------------------------------------
%  I/O: model   = mpca(mwa,ncomp,options);  %identifies model (calibration step)              
%  I/O: pred    = mpca(mwa,model,options);  %projects a new X-block onto existing model
clear module
module                    = evriscript_module;
module.keyword            = 'mpca';
module.description        = 'Multi-way (unfold) principal components analysis';

module.command(1).calibrate  = 'var.model = mpca(var.x,var.ncomp,options);';
module.command.apply      = 'var.pred  = mpca(var.x,var.model,options);';

module.required(1).calibrate = {'x' 'ncomp'};
module.required.apply     = {'x' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};

module.default(1).ncomp      = 1;
module.options            = mpca('factoryoptions');

modules.mpca               = module;

%--------------------------------------------------------------------------
% npls:
%--------------------------------------------------------------------------
%  I/O: model   = npls(x,y,ncomp,options);      %identifies model (calibration step)       
%  I/O: pred    = npls(x,ncomp,model,options);  %predict with prior model (prediction step)
clear module
module                    = evriscript_module;
module.keyword            = 'npls';
module.description        = 'Multilinear-PLS (N-PLS) for true multi-way regression';

module.command(1).calibrate  = 'var.model = npls(var.x,var.y,var.ncomp,options);';
module.command.apply      = 'var.pred  = npls(var.x,[], var.ncomp,var.model,options);';

module.required(1).calibrate = {'x' 'y' 'ncomp'};
module.required.apply     = {'x' 'ncomp' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};

module.default(1).ncomp      = 1;
module.options            = npls('factoryoptions');

modules.npls              = module;

%--------------------------------------------------------------------------
% parafac:
%--------------------------------------------------------------------------
%  I/O: model   = parafac(x,ncomp,initval,options); % identifies model (calibration step)        
%  I/O: pred    = parafac(xnew,model);              % find scores for new samples given old model
clear module
module                    = evriscript_module;
module.keyword            = 'parafac';
module.description        = 'Parallel factor analysis for n-way arrays';

module.command(1).calibrate  = 'var.model = parafac(var.x,var.ncomp,var.initval,options);';
module.command.apply      = 'var.pred  = parafac(var.x,var.model);';

module.required(1).calibrate = {'x' 'ncomp'};
module.required.apply     = {'x' 'model'};

module.optional(1).calibrate = {'initval'};
module.optional.apply     = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};

module.options            = parafac('factoryoptions');

modules.parafac           = module;

%--------------------------------------------------------------------------
% pca:
%--------------------------------------------------------------------------
%  I/O: model   = pca(x,ncomp,options);  %identifies model (calibration step)       
%  I/O: pred    = pca(x,model,options);  %projects a new X-block onto existing model
clear module
module                    = evriscript_module;
module.keyword            = 'pca';
module.description        = 'Perform principal components analysis';

module.command(1).calibrate  = 'var.model = pca(var.x,var.ncomp,options);';
module.command.apply      = 'var.pred  = pca(var.x,var.model,options);';

module.required(1).calibrate = {'x' 'ncomp'};
module.required.apply     = {'x' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};

module.default(1).ncomp      = 1;
module.options            = pca('factoryoptions');

modules.pca               = module;

%--------------------------------------------------------------------------
% pcr:
%--------------------------------------------------------------------------       
%  I/O: model = pcr(x,y,ncomp,options);  %identifies model (calibration step)    
%  I/O: pred  = pcr(x,model,options);    %makes predictions with a new X-block   
%  I/O: valid = pcr(x,y,model,options);  %makes predictions with new X- & Y-block
clear module                                                                
module                    = evriscript_module;
module.keyword            = 'pcr';
module.description        = 'PCR Principal components regression for multivariate Y';

module.command(1).calibrate  = 'var.model  = pcr(var.x,var.y,var.ncomp,options);';
module.command.apply      = 'var.pred   = pcr(var.x, var.model,options);';
module.command.test       = 'var.valid   = pcr(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'y' 'ncomp'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).ncomp      = 1;
module.options            = pcr('factoryoptions');

modules.pcr               = module;

%--------------------------------------------------------------------------
% pls
%--------------------------------------------------------------------------                                                                         
%  I/O: model = pls(x,y,ncomp,options);  %identifies model (calibration step)    
%  I/O: pred  = pls(x,model,options);    %makes predictions with a new X-block   
%  I/O: valid = pls(x,y,model,options);  %makes predictions with new X- & Y-block
clear module
module                    = evriscript_module;
module.keyword            = 'pls';
module.description        = 'Partial least squares regression for multivariate Y';

module.command(1).calibrate  = 'var.model  = pls(var.x,var.y,var.ncomp,options);';
module.command.apply      = 'var.pred   = pls(var.x,var.model,options);';
module.command.test       = 'var.valid   = pls(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'y' 'ncomp'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).ncomp      = 1;
module.options            = pls('factoryoptions');

modules.pls               = module;

%--------------------------------------------------------------------------
% plsda
%--------------------------------------------------------------------------                                                                         
%  I/O: model = plsda(x,y,ncomp,options);  %identifies model (calibration step)    
%  I/O: pred  = plsda(x,model,options);    %makes predictions with a new X-block   
%  I/O: valid = plsda(x,y,model,options);  %makes predictions with new X- & Y-block
clear module
module                    = evriscript_module;
module.keyword            = 'plsda';
module.description        = 'Partial least squares discriminant analysis';

module.command(1).calibrate  = 'var.model  = plsda(var.x,var.y,var.ncomp,options);';
module.command.apply      = 'var.pred   = plsda(var.x,var.model,options);';
module.command.test       = 'var.valid  = plsda(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'ncomp'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'model'};

module.optional(1).calibrate = {'y'};
module.optional.apply     = {};
module.optional.test      = {'y'};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).ncomp      = 1;
module.default.y          = [];
module.options            = plsda('factoryoptions');

modules.plsda               = module;

%--------------------------------------------------------------------------
% preprocess
%-------------------------------------------------------------------------- 
% I/O: [ppro] = preprocess(x); 
clear module
module                    = evriscript_module;
module.keyword            = 'preprocess';
module.description        = 'Return a preprocess structure';

module.command(1).calibrate  = 'var.ppro = preprocess(''default'', var.x);';
% s = preprocess('default',{'method1', 'method2', ...})

module.required(1).calibrate = {'x'};

% module.optional.calibrate = {};
% module.optional.apply     = {};
% module.optional.undo      = {};

module.outputs(1).calibrate  = {'ppro'};

% module.options            = mncn('options');

module.default(1).x          = {'autoscale'};

modules.preprocess        = module;

%--------------------------------------------------------------------------
% svm
%--------------------------------------------------------------------------                                                                         
%  I/O: model = svm(x,y,options);          %identifies model (calibration step)                         
%  I/O: pred  = svm(x,model,options);      %makes predictions with a new X-block                        
%  I/O: pred  = svm(x,y,model,options);  %performs a "test" call with a new X-block and known y-values
clear module
module                    = evriscript_module;
module.keyword            = 'svm';
module.description        = 'Support Vector Machine (LIBSVM) for regression';

module.command(1).calibrate  = 'var.model  = svm(var.x,var.y,options);';
module.command.apply      = 'var.pred   = svm(var.x, var.model,options);';
module.command.test       = 'var.valid   = svm(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'y'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {'ncomp'};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.options            = svm('factoryoptions');

modules.svm               = module;

%--------------------------------------------------------------------------
% svmda
%--------------------------------------------------------------------------                                                                         
%  I/O: model = svmda(x,y,options);          %identifies model (calibration step)                         
%  I/O: pred  = svmda(x,model,options);      %makes predictions with a new X-block                        
%  I/O: pred  = svmda(x,y,model,options);    %performs a "test" call with a new X-block and known y-values
clear module
module                    = evriscript_module;
module.keyword            = 'svmda';
module.description        = 'Support Vector Machine (LIBSVM) for classification';

module.command(1).calibrate  = 'var.model  = svmda(var.x,var.y,options);';
module.command.apply      = 'var.pred   = svmda(var.x, var.model,options);';
module.command.test       = 'var.valid   = svmda(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'model'};

module.optional(1).calibrate = {'y' 'ncomp'};
module.optional.apply     = {};
module.optional.test      = {'y'};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).y          = [];
module.options            = svmda('factoryoptions');

modules.svmda             = module;

%--------------------------------------------------------------------------
% tsne:
%--------------------------------------------------------------------------
%  I/O: model   = tsne(x,options);  %identifies model (calibration step)       
clear module
module                    = evriscript_module;
module.keyword            = 'tsne';
module.description        = 'Perform tSNE';

module.command(1).calibrate  = 'var.model = tsne(var.x,options);';

module.required(1).calibrate = {'x'};

module.optional(1).calibrate = {};

module.outputs(1).calibrate  = {'model'};

module.options            = tsne('factoryoptions');

modules.tsne               = module;

%--------------------------------------------------------------------------
% umap
%--------------------------------------------------------------------------                                                                         
%  I/O: model = umap(x,options);          %identifies model (calibration step)                         
%  I/O: pred  = umap(x,model,options);      %makes predictions with a new X-block                       
clear module
module                    = evriscript_module;
module.keyword            = 'umap';
module.description        = 'Uniform Manifold Approximation and Projection';

module.command(1).calibrate  = 'var.model  = umap(var.x,options);';
module.command.apply      = 'var.pred   = umap(var.x,var.model,options);';
%module.command.test       = 'var.valid   = umap(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x'};
module.required.apply     = {'x' 'model'};
%module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {};
module.optional.apply     = {};
%module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
%module.outputs.test       = {'valid'};

module.options            = umap('factoryoptions');

modules.umap               = module;

%--------------------------------------------------------------------------
% xgb
%--------------------------------------------------------------------------                                                                         
%  I/O: model = xgb(x,y,options);        %identifies model (calibration step)                         
%  I/O: pred  = xgb(x,model,options);    %makes predictions with a new X-block                        
%  I/O: pred  = xgb(x,y,model,options);  %performs a "test" call with a new X-block and known y-values
clear module
module                    = evriscript_module;
module.keyword            = 'xgb';
module.description        = 'Gradient Boosted Tree (XGBoost) for regression';

module.command(1).calibrate  = 'var.model  = xgb(var.x,var.y,options);';
module.command.apply      = 'var.pred   = xgb(var.x, var.model,options);';
module.command.test       = 'var.valid   = xgb(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x' 'y'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'y' 'model'};

module.optional(1).calibrate = {'ncomp'};
module.optional.apply     = {};
module.optional.test      = {};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.options            = xgb('factoryoptions');

modules.xgb               = module;

%--------------------------------------------------------------------------
% xgbda
%--------------------------------------------------------------------------                                                                         
%  I/O: model = xgbda(x,y,options);          %identifies model (calibration step)                         
%  I/O: pred  = xgbda(x,model,options);      %makes predictions with a new X-block                        
%  I/O: pred  = xgbda(x,y,model,options);    %performs a "test" call with a new X-block and known y-values
clear module
module                    = evriscript_module;
module.keyword            = 'xgbda';
module.description        = 'Gradient Boosted Tree (XGBoost) for classification';

module.command(1).calibrate  = 'var.model  = xgbda(var.x,var.y,options);';
module.command.apply      = 'var.pred   = xgbda(var.x, var.model,options);';
module.command.test       = 'var.valid   = xgbda(var.x,var.y,var.model,options);';

module.required(1).calibrate = {'x'};
module.required.apply     = {'x' 'model'};
module.required.test      = {'x' 'model'};

module.optional(1).calibrate = {'y' 'ncomp'};
module.optional.apply     = {};
module.optional.test      = {'y'};

module.outputs(1).calibrate  = {'model'};
module.outputs.apply      = {'pred'};
module.outputs.test       = {'valid'};

module.default(1).y          = [];
module.options            = xgbda('factoryoptions');

modules.xgbda             = module;


%--------------------------------------------------------------------------
% Set module.options.definitions = [] for any module which already has a
% definitions option, but not for others.
scripts = fieldnames(modules);
for iscript=1:numel(scripts)
  msg = sprintf('script %s: ', modules.(scripts{iscript}).keyword);
  script = modules.(scripts{iscript});
  if ~isempty(script.options)
    opts = script.options;
    hasdefinitions = isfield(opts, 'definitions');
    if hasdefinitions
      msg = sprintf('%s has definitions option: Set it to empty', msg);
      modules.(scripts{iscript}).options.definitions = [];
    end
  end
  disp(msg)
end

%--------------------------------------------------------------------------
save(projRepository,'-struct','modules') 
%--------------------------------------------------------------------------

end
