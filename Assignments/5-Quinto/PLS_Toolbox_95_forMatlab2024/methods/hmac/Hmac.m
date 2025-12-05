classdef Hmac < handle
  %HMAC Automatic Hierarchical Model Builder Object for Classification.
  % Object that automatically creates a hierarchical model for
  % classification problems. The object splits up the classification
  % problem into smaller classification problems following the strategy
  % that is described in [Marchi, Lorenzo, et al. “Automatic Hierarchical
  % Model Builder.” Journal of Chemometrics, 2022,
  % https://doi.org/10.1002/cem.3455]. It will recursively build PLSDA
  % models for each possible pair of classes and separate the classes by
  % how difficult it is to classify those samples. The algorithm is
  % completed once there are two classes left or perfect classification.
  %
  % INPUTS:
  %         x = X-block (predictor block) class "double" or "dataset",
  %         y = Y-block (OPTIONAL) if (x) is a dataset containing classes for
  %                sample mode (mode 1) otherwise, (y) is a vector of sample
  %                classes for each sample in x.
  %   options = Options structure with one or more of the following fields:
  %
  %     classset: [1] Specify the classset of x to use if y is empty
  %       maxlvs: [6] Number of components to use in crossval call
  %       cvopts: Options passed to crossval call (see crossval.m)
  %
  %  OUTPUT:
  %       hmac  = object of this class.
  %
  %I/O: [hmac]         = Hmac();                % instantiate object of this class.
  %I/O: [hmac]         = hmac.setX(x);          % set x-block
  %I/O: [hmac]         = hmac.setY(y);          % set classes
  %I/O: [hmac]         = hmac.calibrate;        % create hierarchical model
  %I/O: [options]      = hmac.getOptions;       % get options structure
  %I/O: [hmac]         = hmac.setOptions(opts); % set options
  %
  %I/O: modelselectorgui(hmac.model);           % view model in gui
  %
  %See also: AUTOCLASSIFER, MERGELEASTSEPARABLE, GETMISCLASSIFICATION, GETPAIRMISCLASSIFICATION, MODELSELECTOR, CROSSVAL, PLSDA

  % Copyright © Eigenvector Research, Inc. 2022
  % Licensee shall not re-compile, translate or convert "M-files" contained
  %  in PLS_Toolbox for use with any software other than MATLAB®, without
  %  written permission from Eigenvector Research, Inc.


  % An object to support the Automatic Hierarchical Model Classifier code
  % from Rasmus et al.

  properties (Access = private)
    x;             % Xblock
    y;             % Yblock
    options = [];  % autoClassifier options
    resetX = false;
    resetY = false;
    origXinclude = [];
    origY        = [];
  end
  properties (Access = public)
    model   = [];    % Resulting hierarchical model
    history = '';
  end

  methods (Access = public)
    %----------------------------------------------------------------------
    % class constructor
    function obj = Hmac()
      obj.setDefaultOptions();
      d = datetime;
      d.Format = 'uuuu-MM-dd'' ''HH:mm:ss';
      obj.history = sprintf('Created on [%s]\n', char(d));
    end

    %----------------------------------------------------------------------
    function [obj] = setX(obj, X)
      % Ensure X always a DSO
      if ~isdataset(X)
        X = dataset(X);
      end

      obj.x = X;
      obj.origXinclude = X.include;
      obj.resetX = false;
    end

    %----------------------------------------------------------------------
    function [x] = getX(obj)
      x = obj.x;
    end

    %----------------------------------------------------------------------
    function [obj] = setY(obj, Y)
      % Ensure Y will always be a DSO
      if ~isdataset(Y)
        Y = dataset(Y);
      end
      [my,ny] = size(Y);

      % transpose Y if it seems samples are not dim 1
      if ~isempty(obj.x)
        [mx,nx] = size(obj.x);       
        if ny==mx & my==1
          Y = Y';
        end
      elseif my==1 & ny>1
          Y = Y';
      end

      obj.y = Y;
      obj.y.class{1,1} = Y.data;  % creates a class lookup table
      obj.origY = Y;
      obj.resetY = false;
    end

    %----------------------------------------------------------------------
    function [y] = getY(obj)
      y = obj.y;
    end

    %----------------------------------------------------------------------
    function [opts] = getOptions(obj)
      opts = obj.options;
    end

    %----------------------------------------------------------------------
    function [obj] = setOptions(obj, opts)
      obj.options = opts;
      obj.resetX = true;
      obj.resetY = true;
    end

    %----------------------------------------------------------------------
    function [obj] = resetXinclude(obj)
      if ~isempty(obj.origXinclude)
        nincls = length(obj.origXinclude);
        for j = 1:nincls
          obj.x.include{j} = obj.origXinclude{j};
        end
      end
    end

    %----------------------------------------------------------------------
    function [obj] = calibrate(obj)
      % build hierarchical model using ahimbu strategy
      obj.initXY();

      usesamples = obj.x.include{1};
      xd = obj.x.data(usesamples,:);
      yd = obj.y.data(usesamples,:);

      % create class lookup
      if isdataset(obj.y) && ~isempty(obj.y.classlookup{1,1})
        % user explicitly passed a y, this y has a lookup table, use that
        clslookup = obj.y.classlookup{1,1};
      elseif isdataset(obj.x)
        clslookup = obj.x.classlookup{1,obj.options.classset};
      else
        clslookup = [];
      end

      if strcmpi(obj.options.outputfilter,'model')
        obj.model = convertEndNodesToModels(autoClassifier(xd,yd,obj.options,clslookup));
      elseif strcmpi(obj.options.outputfilter,'string')
        obj.model = autoClassifier(xd,yd,obj.options,clslookup);
      else
        error('Unsupported output filter. Expecting output filter to be either ''model or ''string''')
      end
    end

    %----------------------------------------------------------------------
    function [obj] = setDefaultOptions(obj)
      % set default options for Hmac
      opts = [];
      opts.classset = 1;
      opts.maxlvs = 6;

      % set default options for cross-validation
      cvopts = crossval('options');
      ao = analysis('options');
      pre = {preprocess(ao.defaultxpreprocessing) preprocess(ao.defaultypreprocessing)};
      cvopts.preprocessing = pre;
      cvopts.plots = 'none';
      cvopts.discrim = 'yes';
      cvopts.display = 'no';
      opts.cvi = {'vet' 10 1};

      opts.cvopts = cvopts;
      opts.outputfilter = 'model';

      obj.options = opts;
    end
  end

  methods (Access = protected)

    %----------------------------------------------------------------------
    function obj = checkXYisset(obj)
      % Convert y to matrix, or if y is empty then set y from x classset

      if obj.resetX | obj.resetY
        obj.resetXandY;
      end

      if isempty(obj.y)
        if ~isempty(obj.x.class{1,obj.options.classset})
          obj.y = dataset(obj.x.class{1,obj.options.classset}'); 
        else
          errmsg = 'No class information provided.';
          error('checkXyisset:YNotInputOrAvailableFromX',  errmsg);
        end
      end

      % samples in x have to equal samples in y
      if size(obj.y,1) ~= size(obj.x, 1)
        errmsg = 'x and y have different number of samples.';
        error('checkXyisset:DifferentNumberSamples',  errmsg);
        % (%d, %d)', size(obj.x, 1), size(obj.y,1)
      end
    end

    %----------------------------------------------------------------------
    function obj = resetXandY(obj)
      % Restore X include and Y to what user loaded
      if obj.resetX
        if ~isempty(obj.origXinclude)
          obj.resetXinclude();
        end
        obj.resetX = false;
      end
      if obj.resetY
        obj.y = obj.origY;
        obj.resetY = false;
      end
    end

    %----------------------------------------------------------------------
    function obj = ignoreClass0(obj)
      % Exclude or delete samples which have y equal to zero. Called when
      % calibrating model
      % exclude any class 0 samples. If A is matrix, just delete class 0
      % Note: call after checkXY has been called

      % exclude Class 0 samples. Both x and y are DSO
      inclx = obj.x.include{1};
      isclass0 = (obj.y.data(inclx)==0);  % ttt
      obj.x.include{1} = inclx(~isclass0);

    end

    %----------------------------------------------------------------------
    function obj = initXY(obj)
      % Set X and Y properties properly for autoClassifier
      obj.checkXYisset();
      %       obj.resetSampleIncludes();
      obj.ignoreClass0();
    end
  end
end

