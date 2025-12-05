classdef evriPyClient
  %EVRIPYCLIENT Liason object to handle Python code for evrimodels.
  % Object that takes care of data manipulation, model serialization,
  % calibrating and applying Python model objects. One central location
  % to handle all Python code that is associated with making predictions
  % for evrimodel objects.
  %
  % INPUTS:
  %     options = options structure from evrimodel object.
  %
  %  OUTPUT:
  %     client = object of this class.
  %
  %I/O: [client]         = evriPyClient(options);                    %calibrate mode
  %I/O: [client]         = evriPyClient(options, serialized_model);  %apply mode
  %I/O: [client]         = client.calibrate(x_included, x_all, y_included);
  %I/O: [client]         = client.apply(x);
  %I/O: [extractions]    = client.extractions;
  %
  
  % Copyright © Eigenvector Research, Inc. 2021
  % Licensee shall not re-compile, translate or convert "M-files" contained
  %  in PLS_Toolbox for use with any software other than MATLAB®, without
  %  written permission from Eigenvector Research, Inc.
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %     The objective of this class is to handle all Python code here for any
  %      PLS_Toolbox Python-based methods. Instructions on adding new Python
  %      methods are as follows:
  %        - make associated .m file
  %        - come here and
  %          - add case for new method in init() for new Python object
  %          - add case in map_options() to cast Matlab to Python
  %          - add case in safe_calibrate()
  %          - add case in serialize()
  %          - add case in extract()
  %          - add case in safe_apply()
  %        - instantiate object in .m file (look at I/O)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % public
  properties
    mode                                % 'calibrate' or 'apply'
    model                               % Python model object
    serialized_model                    % uint8 byte-stream of model object
    calibration_xblock_included         % included calibration x block
    calibration_xblock_all              % all x block
    calibration_yblock_included         % included calibration y block
    calibration_pred                    % calibration predictions (not populated for TSNE, UMAP)
    validation_xblock                   % validation x block
    validation_yblock                   % validation y block
    validation_pred                     % validation predictions
    version                             % version of Python
    executable                          % path to Python executable
    library                             % path to Python library directory
    home                                % path to Python environment directory
    status                              % pyenv status
    executionmode                       % pyenv mode (should be InProcess)
    processid                           % process id for pyenv (same as Matlab)
    useroptions                         % options structure for evrimodel
    method                              % evrimodel method name
    extractions                         % values extracted from model field, will vary by model
    dlopenflags                         % result of py.sysgetdlopenflags() for unix systems
    warnings                            % Python warnings
    notes                               % notes regarding client
  end
  
  %---------------------------public methods---------------------------------
  methods
    % constructor
    function thisObject = evriPyClient(varargin)
      % parse varargin
      % input args should only be an options structure or a serialized
      % model.
      [options, sm, mode] = parsevarargin(varargin);
      
      % initialize all properties
      thisObject.mode                             = mode;
      thisObject.model                            = [];
      thisObject.serialized_model                 = sm;
      thisObject.calibration_xblock_included      = [];
      thisObject.calibration_xblock_all           = [];
      thisObject.calibration_yblock_included      = [];
      thisObject.calibration_pred                 = [];
      thisObject.validation_xblock                = [];
      thisObject.validation_xblock                = [];
      thisObject.validation_pred                  = [];
      thisObject.version                          = [];
      thisObject.executable                       = [];
      thisObject.library                          = [];
      thisObject.home                             = [];
      thisObject.status                           = [];
      thisObject.executionmode                    = [];
      thisObject.processid                        = [];
      thisObject.useroptions                      = options; %user method options
      thisObject.method                           = options.functionname;        % needs to be a valid evrimodel
      thisObject.extractions                      = [];
      thisObject.dlopenflags                      = [];
      thisObject.warnings                         = [];
      thisObject.notes                            = [];
      
      % get pyenv fields and merge them to the object properties
      % adjusts dlopen flags if needed
      % gets output of check_pyenv
      thisObject = thisObject.extract_pyenv();
      
      % at this point user has a plstb virtual environment, start model
      % initialization
      thisObject = thisObject.init();
      thisObject = thisObject.map_options();
    end
    %----------------------------------------------------------------------
    
    function thisObject = calibrate(thisObject, calibration_xblock_included, calibration_xblock_all, calibration_yblock_included)
      % calibration step for Python model object. Fit on included data
      % (calibration_xblock_included,calibration_yblock_included)
      % then predict on the full xblock (calibration_xblock_all)
      
      info = [];
      info.x_all_size = size(calibration_xblock_all);
      
      % set up properties, cast data to Python data type
      thisObject = thisObject.define_cal_data(calibration_xblock_included, calibration_xblock_all, calibration_yblock_included);
      [x_cal_inc, x_cal_all, y_cal_inc] = thisObject.get_cal_data();
      
      % perform safe calibration to capture any Python-related errors or
      % warnings
      thisObject = thisObject.safe_calibrate(x_cal_inc, x_cal_all, y_cal_inc, info);
      
      % serialize model for later model application
      thisObject = thisObject.serialize();
      
      % extract various information from calibrated model
      thisObject = thisObject.extract();
    end
    %----------------------------------------------------------------------
    
    function thisObject = apply(thisObject, validation_xblock)
      % apply model to validation data, do model application in private
      % safe_apply method
      
      thisObject = thisObject.define_val_data(validation_xblock);
      x_val = thisObject.get_val_data();
      thisObject = thisObject.safe_apply(check_pydata(x_val));
    end
  end
  %-----------------------end of public methods----------------------------
  
  
  %------------------------private methods---------------------------------
  methods (Access=private)
    function thisObject = extract_pyenv(thisObject)
      % get information from pyenv, set up dlopenflags to prevent
      % MATLAB/Python library mismatches, make sure user is using a
      % PLS_Toolbox virtual environment
      
      pe = pyenv;
      thisObject.version             = char(pe.Version);
      thisObject.executable          = char(pe.Executable);
      thisObject.library             = char(pe.Library);
      thisObject.home                = char(pe.Home);
      thisObject.status              = char(pe.Status);
      thisObject.executionmode       = char(pe.ExecutionMode);
      thisObject.processid           = char(pe.ProcessID);
      % check for version of Matlab
      prep_pyenv;
      if isunix
        thisObject.dlopenflags = py.sys.getdlopenflags();
      else
        thisObject.dlopenflags = nan;
        note = sprintf('Machine is Windows, dlopenflags will be NaN.\n');
        thisObject.notes = [thisObject.notes; note];
      end 
    end
    %----------------------------------------------------------------------
    
    function thisObject = init(thisObject)
      % initialize Python model object, populate model property
      
      opts = thisObject.get_useroptions();
      switch thisObject.mode
        case 'calibrate'
          try
            % condition on thisObject.method
            switch thisObject.method
              case 'umap'
                thisObject.model = py.umap.UMAP();
              case 'tsne'
                thisObject.model = py.sklearn.manifold.TSNE();
              case {'anndl' 'anndlda'}
                %sklearn or tensorflow
                switch opts.algorithm
                  case 'sklearn'
                    thisObject.model = py.sklearn.neural_network.MLPRegressor();
                  case 'tensorflow'
                    thisObject.model = py.tensorflow.keras.Sequential();
                  otherwise
                    error('Unknown algorithm. Expecting ''sklearn'' or ''tensorflow''')
                end
              case 'xgb'
                switch computer
                  case 'GLNXA64'
                    % using gradient boosting on linux
                    thisObject.model = py.sklearn.ensemble.GradientBoostingRegressor();
                  otherwise
                    % using xgb on everything else
                    thisObject.model = py.xgboost.XGBRegressor();
                end
              case 'xgbda'
                switch computer
                  case 'GLNXA64'
                    thisObject.model = py.sklearn.ensemble.GradientBoostingClassifier();
                  otherwise
                    thisObject.model = py.xgboost.XGBClassifier();
                end
              otherwise
                error('Unsupported Python model for initialization')
            end
          catch E
            augment_python_error(E);
          end
        case 'apply'
          % unserialize the model object and populate model property
          thisObject = thisObject.unserialize();
      end
    end
    %----------------------------------------------------------------------
    
    function thisObject = map_options(thisObject)
      % map options from options structure to Python with correct
      % data types
      
      % only do this for calibration mode
      switch thisObject.mode
        case 'calibrate'
          
          %grab this options structure
          opts = thisObject.get_useroptions();
          %set warnings before building
          set_python_warnings(opts.warnings);
          
          %cast Python parameters by method
          switch thisObject.method
            case 'umap'
              thisObject.model.n_neighbors       = py.int(opts.n_neighbors);
              thisObject.model.min_dist          = py.float(opts.min_dist);
              thisObject.model.spread            = py.float(opts.spread);
              thisObject.model.n_components      = py.int(opts.n_components);
              thisObject.model.metric            = py.str(opts.metric);
              thisObject.model.n_jobs            = py.int(-1); %Allows for multiprocessing
              thisObject.model.random_state      = py.int(opts.random_state);
              
            case 'tsne'
              thisObject.model.n_components                = py.int(opts.n_components);
              thisObject.model.perplexity                  = py.float(opts.perplexity);
              thisObject.model.learning_rate               = py.float(opts.learning_rate);
              thisObject.model.early_exaggeration          = py.float(opts.early_exaggeration);
              thisObject.model.n_iter                      = py.int(opts.n_iter);
              thisObject.model.n_iter_without_progress     = py.int(opts.n_iter_without_progress);
              thisObject.model.min_grad_norm               = py.float(opts.min_grad_norm);
              thisObject.model.metric                      = py.str(opts.metric);
              thisObject.model.init                        = py.str(opts.init);
              thisObject.model.method                      = py.str(opts.method);
              thisObject.model.angle                       = py.float(opts.angle);
              thisObject.model.n_jobs                      = py.int(-1); %Allows for multiprocessing
              thisObject.model.random_state                = py.int(opts.random_state);
              
            case {'anndl' 'anndlda'}
              switch opts.algorithm
                case 'sklearn'
                  anndlopts = opts.sk;
                  % handle hidden layers, list of elements where the ith
                  % element in hidden layer has hid(i) nodes.
                  if size(opts.sk.hidden_layer_sizes,2)==1
                    hid = py.tuple({int64(cell2mat(opts.sk.hidden_layer_sizes))});
                  else
                    hid = py.tuple(int64(cell2mat(opts.sk.hidden_layer_sizes)));
                  end
                  thisObject.model.alpha                  = py.float(anndlopts.alpha);
                  thisObject.model.activation             = py.str(anndlopts.activation);
                  thisObject.model.hidden_layer_sizes     = hid;
                  thisObject.model.tol                    = py.float(anndlopts.tol);
                  thisObject.model.max_iter               = py.int(anndlopts.max_iter);
                  thisObject.model.solver                 = py.str(anndlopts.solver);
                  thisObject.model.batch_size             = py.int(anndlopts.batch_size);
                  thisObject.model.early_stopping         = py.True;
                  thisObject.model.random_state           = py.int(anndlopts.random_state);
                  thisObject.model.learning_rate_init     = py.float(anndlopts.learning_rate_init);
                  
                case 'tensorflow'
                  % silence Tensorflow log
                  tflogger = py.tensorflow.get_logger;
                  tflogger.setLevel('ERROR');
                  
                  % this one is a little different due to the need for the data
                  % in order to setup the model using build_tfmodel.m.
                  % actual option mapping will take place in .calibrate
                  note = sprintf('Tensorflow option mapping not done until calibration.\n');
                  thisObject.notes = [thisObject.notes note];
                  
                otherwise
                  error('Unsupported algorithm to calibrate ANNDL/ANNDLDA')
              end
            case {'xgb' 'xgbda'}
              switch computer
                case 'GLNXA64'
                  % using gradient boosting object in linux
                  thisObject.model.learning_rate = py.float(opts.eta);
                  thisObject.model.n_estimators = py.int(opts.num_round);
                  thisObject.model.min_impurity_decrease = py.float(opts.gamma);
                  thisObject.model.max_depth = py.int(opts.max_depth);
                  thisObject.model.random_state = py.int(opts.random_state);
                otherwise
                  % using xgb on everything else
                  thisObject.model.learning_rate = py.float(opts.eta);
                  thisObject.model.n_estimators = py.int(opts.num_round);
                  thisObject.model.reg_lambda = py.float(opts.lambda);
                  thisObject.model.reg_alpha = py.float(opts.alpha);
                  thisObject.model.gamma = py.float(opts.gamma);
                  thisObject.model.max_depth = py.int(opts.max_depth);
                  thisObject.model.random_state = py.int(opts.random_state);
                  thisObject.model.booster = py.str(opts.booster);
                  thisObject.model.eval_metric = py.str(opts.eval_metric);
                  thisObject.model.objective = py.str(opts.objective);
                  thisObject.model.importance_type = py.str('gain');
                  %thisObject.model.verbosity = py.int(3);
                  %thisObject.model.njobs = py.int(-1);
              end
            otherwise
              error('Unknown method for options setup')
          end
        case 'apply'
          % do nothing, no options to set up
      end
    end
    %----------------------------------------------------------------------
    
    function thisObject = define_cal_data(thisObject, calibration_xblock_included, calibration_xblock_all, calibration_yblock)
      % get calibration data into Python data type
      
      thisObject.calibration_xblock_included = check_pydata(calibration_xblock_included);
      thisObject.calibration_xblock_all      = check_pydata(calibration_xblock_all);
      thisObject.calibration_yblock_included = check_pydata(calibration_yblock);
    end
    %----------------------------------------------------------------------
    
    function [x_cal_inc, x_cal_all, y_cal_inc] = get_cal_data(thisObject)
      % get method for calibration data
      
      x_cal_inc = thisObject.calibration_xblock_included;
      x_cal_all = thisObject.calibration_xblock_all;
      y_cal_inc = thisObject.calibration_yblock_included;
    end
    %----------------------------------------------------------------------
    
    function thisObject = define_val_data(thisObject, validation_xblock)
      % get validation data into Python data type
      
      thisObject.validation_xblock = check_pydata(validation_xblock);
    end
    %----------------------------------------------------------------------
    
    function [x_val] = get_val_data(thisObject)
      % get method for validation data
      
      x_val = thisObject.validation_xblock;
    end
    %----------------------------------------------------------------------
    
    function [modl] = get_model(thisObject)
      % get method for Python model object
      
      modl = thisObject.model;
    end
    %----------------------------------------------------------------------
    
    function [opts] = get_useroptions(thisObject)
      % get method for user options structure
      
      opts = thisObject.useroptions;
    end
    %----------------------------------------------------------------------
    
    function thisObject = serialize(thisObject)
      
      % serialize and assign the serialized_model property
      modelInBytes = [];
      modl = thisObject.get_model();
      opts = thisObject.get_useroptions();
      % this way of serializing works for all except for tensorflow
      switch thisObject.method
        case {'tsne' 'umap' 'xgb' 'xgbda'}
          modelInBytes = uint8(py.pickle.dumps(modl));
        case {'anndl' 'anndlda'}
          switch opts.algorithm
            case 'sklearn'
              modelInBytes = uint8(py.pickle.dumps(modl));
            case 'tensorflow'
              modelInBytes.config = char(modl.to_json());
              modelInBytes.weights = uint8(py.pickle.dumps(modl.get_weights()));
            otherwise
              error('Unknown algorithm for mode serialization')
          end
        otherwise
          error('Unknown Python model passed for serialization')
      end
      
      thisObject.serialized_model = modelInBytes;
    end
    %----------------------------------------------------------------------
    
    function [thisObject] = unserialize(thisObject)
      % unserialize Python model object for model application
      
      opts = thisObject.get_useroptions();
      switch thisObject.method
        case {'tsne' 'umap' 'xgb' 'xgbda'}
          modl = py.pickle.loads(thisObject.serialized_model);
        case {'anndl' 'anndlda'}
          switch opts.algorithm
            case 'sklearn'
              modl = py.pickle.loads(thisObject.serialized_model);
            case 'tensorflow'
              modl = py.tensorflow.keras.models.model_from_json(py.str(thisObject.serialized_model.config)); %gets architecture of tensorflow model
              modl.set_weights(py.pickle.loads(thisObject.serialized_model.weights)); %config weights after unserializing them
            otherwise
              error('Unknown algorithm for mode unserialization.')
          end
        otherwise
          error("Unknown method for model unserialization")
      end
      thisObject.model = modl;
    end
    %----------------------------------------------------------------------
    
    function thisObject = extract(thisObject)
      % extract various info based on the method
      out = thisObject.extractions;
      modl = thisObject.get_model();
      opts = thisObject.get_useroptions();
      try
        switch thisObject.method
          case 'umap'
            embeddings = modl.transform(thisObject.calibration_xblock_all);
            d = py.getattr(modl, '__dict__');
            out.supervised = d{'_supervised'};
            out.embeddings = double(embeddings);
            %get connectivity graph information
            g = py.getattr(modl,'graph_');
            coordinates = g.tocoo();
            %coordinates are 0-indexed, add 1 to rows and columns
            r = double(coordinates.row+1);
            c = double(coordinates.col+1);
            G = graph(r, c, double(coordinates.data));
            %get linewidths, function of the edge weights
            linewidths = (10*G.Edges.Weight)/max(G.Edges.Weight);
            out.graph = G;
            out.linewidths = linewidths;
            % known umap-learn/scipy issue that the inverse_transform does not work
            % with UMAP models built using 1 component:
            %https://github.com/lmcinnes/umap/issues/408
            if opts.n_components > 1
              xhat = double(modl.inverse_transform(out.embeddings));
            else
              xhat = [];%double(modl.inverse_transform(check_pydata(out.embeddings)));
            end
            out.xhat = xhat;
            
          case 'tsne'
            out.embeddings = double(py.getattr(modl, 'embedding_'));
            out.niter = double(py.getattr(modl, 'n_iter_'));
            out.kl_divergence = py.getattr(modl, 'kl_divergence_');
          case {'anndl' 'anndlda'}
            switch opts.algorithm
              case 'sklearn'
                out.niter = double(py.getattr(modl, 'n_iter_'));
                % lbfgs solver does not provide a loss for each epoch
                if strcmp(opts.sk.solver,'adam') || strcmp(opts.sk.solver,'sgd')
                  out.loss = cell2mat(cell(py.getattr(modl,'loss_curve_')))';
                else
                  out.loss = nan(out.niter,1);
                  out.loss(out.niter,1) = double(py.getattr(modl,'loss_'));
                end
              case 'tensorflow'
                % history object containing loss is in extractions
                hist = out.history;
                out.loss = cell2mat(cell(hist.history{'loss'}))';
                out.niter = length(out.loss);
              otherwise
                error('Unrecognized algorithm for model info extraction')
            end
          case {'xgb' 'xgbda'}
            out.feature_importance = double(py.getattr(modl,'feature_importances_'));
          otherwise
            error('Unknown method passed while extracting info from Python')
        end
      catch E
        augment_python_error(E);
      end
      thisObject.extractions = out;
    end
    %----------------------------------------------------------------------
    
    function [thisObject] = safe_calibrate(thisObject, x_cal_inc, x_cal_all, y_cal_inc, info)
      % private method for model calibration. augment to any Python-related
      % errors
      
      % do calibration step
      modl = thisObject.get_model();
      opts = thisObject.get_useroptions();
      
      % wrap everything in a try-catch since we want to augment the Python
      % errors
      try
        switch thisObject.method
          case 'umap'
            % here we want the embeddings
            modl.fit(x_cal_inc);
            
          case 'tsne'
            % here we want the embeddings
            modl.fit_transform(x_cal_inc);
            
          case {'anndl' 'anndlda'}
            % switch on algorithm used
            switch opts.algorithm
              case 'sklearn'
                modl.fit(x_cal_inc, y_cal_inc);
                thisObject.calibration_pred = reshape(double(modl.predict(x_cal_all)), [], int64(y_cal_inc.shape{2}));
              case 'tensorflow'
                % we do the option mapping here and then build
                x_all_size = info.x_all_size;
                input_shape = py.numpy.array(int64(x_all_size(2:end)));
                modl = build_tfmodel(opts.tf,{input_shape,},int64(y_cal_inc.shape{2}),x_cal_all.shape);
                % set up early stopping callback
                early_stopping = py.tensorflow.keras.callbacks.EarlyStopping(pyargs('monitor','loss','min_delta',opts.tf.min_delta,'patience',int8(20)));
                history = modl.fit(pyargs('x',py.numpy.array(x_cal_inc),...
                  'y',py.numpy.array(y_cal_inc),...
                  'epochs',int64(opts.tf.epochs),...
                  'batch_size',int64(opts.tf.batch_size),...
                  'callbacks', py.list({early_stopping}),...
                  'verbose',int64(0),...
                  'use_multiprocessing',py.True...
                  )...
                  );
                thisObject.calibration_pred = reshape(double(modl.predict(x_cal_all)), [], int64(y_cal_inc.shape{2}));
                thisObject.extractions.history = history;  % retain calibration information, such as the loss curve
            end
          case {'xgb' 'xgbda'}
            modl.fit(x_cal_inc, y_cal_inc);
            thisObject.calibration_pred = reshape(double(modl.predict(x_cal_all)), [], int64(y_cal_inc.shape{2}));
        end
        % update the fitted model
        thisObject.model = modl;
      catch E
        augment_python_error(E);
      end
    end
    %----------------------------------------------------------------------
    
    function [thisObject] = safe_apply(thisObject, x_val)
      % private model application method. augment to any Python-related
      % errors
      
      modl = thisObject.get_model();
      
      % wrap everything in a try-catch since we want to augment the Python
      % errors
      try
        % do validation step
        switch thisObject.method
          case 'umap'
            thisObject.validation_pred = double(modl.transform(x_val));
            thisObject.extractions.xhat = double(modl.inverse_transform(check_pydata(thisObject.validation_pred)));
          case 'tsne'
            error('Cannot apply TSNE to new data')
          case {'anndl' 'anndlda'}
            thisObject.validation_pred = double(modl.predict(x_val)); %reshape(double(modl.predict(x_val)),[],size(thisObject.calibration_pred,2));
          case 'xgb'
            thisObject.validation_pred = double(modl.predict(x_val))';
          case 'xgbda'
            thisObject.validation_pred = double(modl.predict_proba(x_val));
          otherwise
            error('Error when applying model, unsupported model')
        end
      catch E
        augment_python_error(E);
      end
    end
  end
  %----------------------end of private methods----------------------------
end
%-----------------------end of class definition----------------------------

function [options, sm, mode] = parsevarargin(varargin)
% parse input arguments
% possible evriPyClient calls...
% this = evriPyClient(opts);
% this = evriPyClient(opts, serialized_model);
% where opts = user options structure and serialized_model will be uint8
% byte array of Python model

varargin = varargin{1};
nargs = length(varargin);
if nargs==1
  if isstruct(varargin{1})
    options = varargin{1};
    sm = [];
    mode = 'calibrate';
  else
    error('Unexpected first argument. Expecting options structure.')
  end
elseif nargs==2
  if isstruct(varargin{1})
    options = varargin{1};
  else
    error('evriPyClient called with 2 arguments expects a struct as the first argument.')
  end
  if isnumeric(varargin{2}) || isstruct(varargin{2})
    sm = varargin{2};
  else
    error('evriPyClient called with 2 arguments expects the serialized model as the second argument.')
  end
  mode = 'apply';
else
  error('Unexepected number of arguments.')
end
end

function [] = augment_python_error(E)
if strcmp(E.identifier,'MATLAB:Python:PyException')
  aug = sprintf('EVRIPyError: The following error is specific to Python, please contact the helpdesk at helpdesk@eigenvector.com for assistance.\n\n');
  error([aug E.message])
else
  error(E.message)
end
end
