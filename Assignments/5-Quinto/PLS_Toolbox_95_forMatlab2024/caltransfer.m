function varargout = caltransfer(varargin)
%CALTRANSFER Create or apply calibration and instrument transfer models.
%  CALTRANSFER uses one of the several transfer functions (methods) available in
%  PLS_Toolbox to return a model and transformed data. The exact I/O is
%  dictated by the transfer function (method) used.
%
%  INPUTS:
%         x1 = (2-way array class "double" or "dataset") calibration data
%              (e.g., spectra from the standard instrument).
%         x2 = (2-way array class "double" or "dataset") data to be
%              transformed (e.g., spectra from the instrument to be
%              standardized).
%     method = (string) indicating which calibration transfer function
%              (method) to use. Choices are:
%              'ds'       : Direct Standardization
%              'pds'      : Piecewise Direct Standardization
%              'dwpds'    : Double Window Piecewise Direct Standardization
%              'sst'      : Spectral Subspace Transformation calibration transfer
%              'glsw'     : Generalized Least-Squares Weighting
%              'osc'      : Orthogonal Signal Correction
%              'alignmat' : Matrix Alignment
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           display: [ 'off' | {'on'} ] Governs level of display to command window.
%      blockdetails: [ 'compact' | {'standard'} | 'all' ] Extent of data
%                     included in model. 'standard' = none, 'all' x-block.
%     preprocessing: {[] []} Preprocessing structures for x1 and x2 (see PREPROCESS).
%
%      NOTE: There are sub-structures for each 'method'. The sub-structures
%            include additional input parameters (additional inputs needed by
%            the function) as well as optional inputs (i.e., the options 
%            structure for that particular function). For more
%            information oni nputs to each method see the help for that
%            function (e.g., help stdgen, or help sstcal).
%
%      Example: OSC requires a "y" block in addition to x1 and x2. The y-block
%               should be assigned via the options structure:
%                   opts.osc.y = yblock;
%
%      Example: To assign window widths for DWPDS:
%                   options.dwpds.win = [5 3];
%
%      Example: To assign the number of factors and implement
%               mean-centering in SST:
%                   options.sst.ncomp  = 4;
%                   options.sst.center = true;
%
%  OUTPUT:
%     transfermodel = standard model structure containing the Calibration Transfer
%                     model (See MODELSTRUCT).
%               x1t = Calibration data returned. Depending on the type of
%                     calibration function (method) used this may or may not be
%                     transformed from the input data (x1).
%
%               x2t = Transformed data.
%
%I/O: [transfermodel,x1t,x2t] = caltransfer(x1,x2,method,options);
%I/O: x2t = caltransfer(x2,transfermodel,options);
%I/O: [transfermodel,x1t,{x2t_1 x2t_2 x2t_3}] = caltransfer(x1,{{x2_1 x2_2 x2_3},method,options);
%I/O: {x2t_1 x2t_2 x2t_3} = caltransfer({x2_1 x2_2 x2_3},transfermodel,options);
%
%See also: ALIGNMAT, GLSW, OSCAPP, OSCCALC, STDGEN, STDIZE

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0 | (nargin>0 & ischar(varargin{1}) & strcmpi(varargin{1},'drop'))
  if nargout==0
    caltransfergui(varargin{:});
  else
    [varargout{1:nargout}] = caltransfergui(varargin{:});
  end
  return;
end

%Special call for combinations.
if nargin>=3 & iscell(varargin{3})
  %[transfermodel] = caltransfer(x1,x2,methodcombos,options);
  varargout{1} = makecombos(varargin{:});
  return
end

if ischar(varargin{1});
  options = [];
  options.display       = 'on';        %Displays output to the command window
  options.blockdetails  = 'standard';  %level of details
  options.preprocessing = {[] []};  %See preprocess

  %STD
  options.ds = stdgen('options');
  options.ds.center = true;
  
  options.pds = stdgen('options');
  options.pds.win = [11]; %Window [scalar].
  options.pds.center = true;
  options.pds = orderfields(options.pds,{'win','name','waitbar','tol','maxpc','center','definitions','functionname'}); %Reorder so meta param is above options.

  options.dwpds = stdgen('options');
  options.dwpds.win = [11 21]; %Window [nx2 vector].
  options.dwpds.center = true;
  options.dwpds = orderfields(options.dwpds,{'win','name','waitbar','tol','maxpc','center','definitions','functionname'});
  %GLSW
  options.glsw = glsw('options');%Meta input 'a' is already in options structure.
  %OSC
  %OSCCALC
  options.osc.y = []; %Required input.
  options.osc.ncomp = []; %Required input.
  options.osc.iter = 0; %Default from function.
  options.osc.tol = 99.9; %Default from function.
  %OSCAPP
  options.osc.nofact = []; %If 'nofact' is empty then don't include as input, it will be calculated in the function.
  %ALIGNMAT
  options.alignmat = alignmat('options');
  options.alignmat.ncomp = 1;
  options.alignmat = orderfields(options.alignmat,{'ncomp','name','display','algorithm','interpolate','definitions','functionname'});
  %SST
  options.sst.ncomp  = 1;
  options.sst.center = false;

  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

x1   = [];
x2   = [];
model   = [];
options = [];
method  = '';
switch nargin
  case 1
    % (x1) (apply to data after interactive load of model)
    model = lddlgpls('struct','Locate Calibration Transfer Model');
    if isempty(model)
      varargout = {[]};
      return
    end
    if ~ismodel(model) | ~strcmpi(model.modeltype,'caltransfer')
      error('Not a valid Calibration Transfer model');
    end
    x2 = varargin{1};
    method = model.transfermethod;
    options = struct('plots','none','display','off');
  case 2
    % (x1,method)
    % (x2,transfermodel)
    if ischar(varargin{2})
      % (x1,method)
      x1      = varargin{1};
      method  = varargin{2};
    else
      % (x2,transfermodel)
      x2    = varargin{1};
      model = varargin{2};
      method  = model.transfermethod;
    end
  case 3
    % (x1,x2,method)
    % (x2,transfermodel,options)
    % (x1,method,options)
    if ischar(varargin{2});
      % (x1,method,options)
      x1      = varargin{1};
      method  = varargin{2};
      options = varargin{3};
    elseif ~ismodel(varargin{2});
      % (x1,x2,method)
      x1     = varargin{1};
      x2     = varargin{2};
      method = varargin{3};
    else
      % (x2,transfermodel,options)
      x2      = varargin{1};
      model   = varargin{2};
      options = varargin{3};
      method  = model.transfermethod;
    end
  case 4
    % (x1,x2,method,options)
    x1      = varargin{1};
    x2      = varargin{2};
    method  = varargin{3};
    options = varargin{4};
  otherwise
    error('Unrecognized input. Check number of inputs.');
end

apply   = ~isempty(model);

%Run recursive on cell input.
if iscell(x2)
  %I/O: [transfermodel,x1t,{x2t_1 x2t_2 x2t_3}] = caltransfer(x1,{{x2_1 x2_2 x2_3},method,options);
  %I/O: {x2t_1 x2t_2 x2t_3} = caltransfer({x2_1 x2_2 x2_3},transfermodel,options);
  
  x2tcell = '';
  
  if ~apply
    tempx2 = x2{1};
    x2     = x2(2:end);
    [model,x1t,x2t] = caltransfer(x1,tempx2,method,options);
    x2tcell = {x2t};
  end

  for i = 1:length(x2)
    x2tnew = caltransfer(x2{i},model,options);
    x2tcell = [x2tcell {x2tnew}];
  end

  if ~apply
    %Create outputs.
    varargout{1} = model;
    varargout{2} = x1t;
    varargout{3} = x2tcell;
  else
    varargout{1} = x2tcell;
  end
  %get first entry in cell
  %call caltransfer with that cell and calculate model
  %loop over remaining entries in cell and call caltransfer in predict mode
  %assemble all results
   return

end

options = reconopts(options,'caltransfer');

%TODO: Add size checking against model (if input). Make sure include fields
%don't index outside incoming data.

if apply
  showerr = false;
  if strcmpi(model.transfermethod,'osc')
    %OSC requires Y block and that data is stored in model.datasource{2} so
    %take expected size from model.datasource{1}.
    expected_size = model.datasource{1}.size(2);
  else
    %All other calt methods have secondary instrument data in .datasource{2}
    expected_size = model.datasource{2}.size(2);
  end
  
  if expected_size~=size(x2,2)
    error('Number of variables in data does not match number expected by model. Please check model datasource information.');
  end
  %TODO: ?If includefield of model is equal to size(x2,2) then use all.
end

%Level 2 function so make everything a dataset.
if ~isdataset(x1)
  x1 = dataset(x1);
end

if ~isdataset(x2)
  x2 = dataset(x2);
end

if apply
  %check for valid model type
  if ~ismodel(model) | ~strcmpi(model.modeltype,'caltransfer')
    error('Input model is not a CALTRANSFER model')
  end
  
  %Grab preprocessing and apply. 
  preprocessing = model.detail.preprocessing;
  
  if ~isempty(preprocessing{2});
    [x2] = preprocess('apply',preprocessing{2},x2);
  end
  
else
  model = modelstruct('caltransfer');
  model.date = date;
  
  %Add name so model developed at command line is compatible with
  %caltransfer gui.
  model.detail.modelname = ['CTM_' upper(method) '-' datestr(now,30)];
  
  %Preprocessing same as PLS.
  preprocessing = options.preprocessing;

  if ~isempty(preprocessing{2});
    [x2,preprocessing{2}] = preprocess('calibrate',preprocessing{2},x2);
  end
  if ~isempty(preprocessing{1});
    [x1,preprocessing{1}] = preprocess('calibrate',preprocessing{1},x1);
  end
  model.detail.preprocessing = preprocessing;
  
  %Do not use matchvars by default. This can cause unforseen affects if,
  %for example, there's a shift on the slave instrument. 
  model.matchvars = 'off';
end

%Sort through methods and call appropriate type
%NOTES:
% * Each method must handle both "calibrate" and "apply" calls. The
%   method to be used can be determined from the "apply" variable.
% * Methods must handle when x2 is a CELL using the following rules:
%    a) For methods where x2 is used specifically to generate the transfer
%       function, the first element in the x2 cell is used to create the
%       function then the model is applied to each additional entry in x2.
%    b) For methods where the model is independent of x2, the model is
%       simply applied to each
%Output fields:
%  .datasource : fill in as appropriate for method {x1 x2}
%  .transfermethod : the name of the method used to create the transfer
switch lower(method)
  
  case {'ds' 'pds' 'dwpds'}
    %ds - No win input.
    %pds - Scalar win input.
    %dwpds - 2 element win input.

    if ~apply
      %Account for Direct Standard having no windows.
      options.ds.win = 0;

      %Call to function.
      if ~options.(lower(method)).center
        stdmat  = stdgen(x1,x2,options.(lower(method)).win,options.(lower(method)));
        stdvect = zeros(1, size(stdmat, 2));
      else
        [stdmat,stdvect] = stdgen(x1,x2,options.(lower(method)).win,options.(lower(method)));
      end
      
      

      %Create model then apply will occur outside 'if' statement.
      model.transfermethod = lower(method);
      model.detail.stdmat  = stdmat;
      model.detail.stdvect = stdvect;
      model.detail.options = options;

      model.datasource{1} = getdatasource(x1);
      model.datasource{2} = getdatasource(x2);

      %Store both x1 and x2 dataset fields. (Same as PLS)
      model = copydsfields(x1,model,[],{1 1});
      model = copydsfields(x2,model,[],{1 2});
    end

    %Get transformed X2 data (X2T).
    %NOTE: Always uses background correction from stdgen (stdvec).
    x2inclv = model.detail.includ{2,2};%Pull include from variables in X2 of model.
    x2t = stdize(x2.data(:,x2inclv),model.detail.stdmat,model.detail.stdvect);

    %Make sure x2t has correct size (include may have truncated).
    x1inclv = model.detail.includ{2,1};%Pull include from variables of X1 of model.
    nvars = model.datasource{1}.size(2);
    x2t = expandvars(x2t,x1inclv,nvars);

    %Create dataset from raw data.
    x2t = dataset(x2t);

    %Block details.
    if ~apply && strcmp(options.blockdetails,'all')
      %Add orginal data.
      model.detail.data{1,1} = x1;
      model.detail.data{1,2} = x2;
    end

    %Get correct field values for x2t dataset from model.
    x2t = copydsfields(model,x2t,2,1);
    x2t = copydsfields(x2,x2t,1); %TODO: Check and get these out of model.
    %Userdata doesn't get copied from orginal x2.
    x2t.userdata = x2.userdata;

    if ~apply
      %Create outputs.
      varargout{1} = model;
      varargout{2} = x1;
      varargout{3} = x2t;
    else
      varargout{1} = x2t;
    end
    
  case 'glsw'

    if ~apply
      %Verify that include fields match - if not, do intersection and give
      %warning (same as pls.m).
      for j = 1:2 %Loop over modes.
        i = intersect(x1.includ{j,1},x2.includ{j,1});
        if (length(i)~=length(x1.includ{j,1}) || length(i)~=length(x2.includ{j,1}) )
          if strcmp(lower(options.display),'on')
            disp(['Warning: Number of included samples in X1.INCLUD{' num2str(j) '} and X2.INCLUD{' num2str(j) '} not equal.'])
            disp(['Using INTERSECT(X1.INCLUD{' num2str(j) '},X2.INCLUD{' num2str(j) '}).'])
          end
          x1.includ{j,1} = i;
          x2.includ{j,1} = i;
        end
      end

      %Generate model from data.
      gmodel = glsw(x1.data(x1.include{1},x1.include{2}),x2.data(x2.include{1},x2.include{2}),options.glsw.a);

      %Populate model structure.
      model.transfermethod = lower(method);
      %NOTE: glsw model has some redundant model information in it (e.g.,
      %datasource).
      model.glswmodel = gmodel;

      model.detail.options = options;
      model.datasource{1} = getdatasource(x1);
      model.datasource{2} = getdatasource(x2);

      %Store both x1 and x2 dataset fields. (Same as PLS)
      model = copydsfields(x1,model,[],{1 1});
      model = copydsfields(x2,model,[],{1 2});
      %Userdata doesn't get copied from orginal x2.
      x2t.userdata = x2.userdata;
      
      %Indicate that model modifies x1 block.
      model.detail.block1modified = 1;
    end

    if ~isempty(x1.data)
      %GLSW modifies the X1 block so apply model to it and return.
      x1t = glsw(x1, model.glswmodel);
    end

    %GLSW uses include from apply dataset so insert from model.
    x2.include{2} = model.detail.includ{2,1};
    x2t = glsw(x2, model.glswmodel);

    if ~apply
      %Create outputs.
      varargout{1} = model;
      varargout{2} = x1t;
      varargout{3} = x2t;
    else
      varargout{1} = x2t;
    end
    
  case 'osc'

    if ~apply
      if isempty(options.osc.y)
        error('OSC Calibration requires a y block (options.osc.y).');
      else
        %TODO: Will preprocessing need to be used here?
        y = options.osc.y;
        if ~isdataset(y)
          y = dataset(y);
        end
      end

      %Mode 2 needs to match for X1 and X2, warning if not, same as glsw.
      i = intersect(x1.includ{2,1},x2.includ{2,1});
      if (length(i)~=length(x1.includ{2,1}) || length(i)~=length(x2.includ{2,1}) )
        if strcmp(lower(options.display),'on')
          disp(['Warning: Number of included samples in X1.INCLUD{2} and X2.INCLUD{2} not equal.'])
          disp(['Using INTERSECT(X1.INCLUD{2},X2.INCLUD{2}).'])
        end
        x1.includ{2,1} = i;
        x2.includ{2,1} = i;
      end

      %Augment data (so can be input to OSC) then check mode 1 sizing.
      x = [x1;x2];
      y = [y;y];
      if size(x,1)~=size(y,1)
        error('Mode 1 (sample) sizes of X and Y (options.osc.y) don''t match. Check data sizing.')
      end

      %Then use intersect of mode 1 for x and y.
      i = intersect(x.includ{1,1},y.includ{1,1});
      if (length(i)~=length(x.includ{1,1}) || length(i)~=length(y.includ{1,1}) )
        if strcmp(lower(options.display),'on')
          disp(['Warning: Number of included samples in X and Y not equal.'])
          disp(['Using INTERSECT(X,Y).'])
        end
        x.includ{1,1} = i;
        y.includ{1,1} = i;
      end

      %Generate model from data.
      [nx,nw,np,nt] = osccalc(x.data(x.includ{1,1},x.includ{2,1}),...
        y.data(y.includ{1,1},y.includ{2,1}),...
        options.osc.ncomp,...
        options.osc.iter,...
        options.osc.tol);

      %Populate model structure.
      model.transfermethod = lower(method);

      model.nw = nw;
      model.np = np;
      model.nt = nt; %Scores

      model.detail.options = options;
      model.datasource{1} = getdatasource(x);
      model.datasource{2} = getdatasource(y);

      %Store both x and y dataset fields.
      model = copydsfields(x,model,[],1);
      model = copydsfields(y,model,[],2);
      %Userdata doesn't get copied from orginal x2.
      x2t.userdata = x2.userdata;
      
      %Indicate that model modifies x1 block.
      model.detail.block1modified = 1;
    else
      %X2 must have at least the variables included in model.
      minclude = model.detail.includ{2,1};

      %Error if x2 doesn't have enough vars.
      i = intersect(minclude,x2.includ{2,1});
      if length(i)~=length(minclude)
        error('Missing variables found in X2. Check X2.include{2,1} against model include field (model.detail.includ{2,1}).')
      else
        x2.includ{2,1} = i;
      end

    end

    if isempty(options.osc.nofact)
      if ~apply
        x1t = oscapp(x1.data,model.nw,model.np);
        %OSC won't change size of data so stick back into dataset for output.
        x1.data = x1t;
      end
      x2t = oscapp(x2.data,model.nw,model.np);
      %OSC won't change size of data so stick back into dataset for output.
      x2.data = x2t;
    else
      if ~apply
        x1t = oscapp(x1.data,model.nw,model.np,options.osc.nofact);
        x1.data = x1t;
      end
      x2t = oscapp(x2.data,model.nw,model.np,options.osc.nofact);
      x2.data = x2t;
    end

    if ~apply
      %Create outputs.
      varargout{1} = model;
      varargout{2} = x1;
      varargout{3} = x2;
    else
      varargout{1} = x2;
    end
    
  case 'alignmat'

    if ~apply

      %Mode 2 needs to match, warning if not, same as glsw.
      i = intersect(x1.includ{2,1},x2.includ{2,1});
      if (length(i)~=length(x1.includ{2,1}) || length(i)~=length(x2.includ{2,1}) )
        if strcmp(lower(options.display),'on')
          disp(['Warning: Number of samples in X1.INCLUD{2} and X2.INCLUD{2} not equal.'])
          disp(['Using INTERSECT(X1.INCLUD{2},X2.INCLUD{2}).'])
        end
        x1.includ{2,1} = i;
        x2.includ{2,1} = i;
      end

      %Generate model from data.
      [bi,itst] = alignmat(x1',x2',options.alignmat.ncomp);

      %Populate model structure.
      model.transfermethod = lower(method);

      %Data "is the model" so store here.
      model.detail.data{1,1} = x1;

      model.detail.options = options;

      %Store only x1 data.
      model.datasource{1} = getdatasource(x1);
      model = copydsfields(x1,model,[],{1 1});
    else
      %If X2 variables less than Model then use intersect. Add warning.

      %Apply with data stored in model.
      [bi,itst] = alignmat(model.detail.data{1,1}',x2',model.detail.options.alignmat.ncomp);
    end

    if ~isdataset(bi)
      x2t = zeros(size(x1))*nan;
      x2t(:,x1.include{2}) = bi';
      x2t = dataset(x2t);
      x2t = copydsfields(x1,x2t,2);
      x2t = copydsfields(x2,x2t,1);
%       %Userdata doesn't get copied from orginal x2.
%       x2t.userdata = x2.userdata;
    else
      x2t = bi;
    end

    if ~apply
      %Create outputs.
      varargout{1} = model;
      varargout{2} = x1;
      varargout{3} = x2t;
    else
      varargout{1} = x2t;
    end
  
  case 'sst'
    if ~apply
      if ~options.sst.center
        stdmat  = sstcal(x1, x2, options.sst.ncomp);
        stdvect = zeros(1, size(stdmat, 2));
      else
        [stdmat, stdvect] = sstcal(x1, x2, options.sst.ncomp);
      end
      
      model.transfermethod = lower(method);
      model.detail.stdmat  = stdmat;
      model.detail.stdvect = stdvect;
      model.detail.options = options;
      
      model.datasource{1}  = getdatasource(x1);
      model.datasource{2}  = getdatasource(x2);
      
      model = copydsfields(x1, model, [], {1 1});
      model = copydsfields(x2, model, [], {1 2});
    end
    
    x2inclv = model.detail.include{2,2};%Pull include from variables in X2 of model
    x2t     = stdize(x2.data(:, x2inclv), model.detail.stdmat, model.detail.stdvect);
    
    x1inclv = model.detail.include{2,1};%Pull include from variables of X1 of model
    nvars   = model.datasource{1}.size(2);
    x2t     = expandvars(x2t, x1inclv, nvars);
    
    x2t     = dataset(x2t);
    
    if ~apply && strcmp(options.blockdetails, 'all')
      model.detail.data{1,1} = x1;
      model.detail.data{1,2} = x2;
    end
    
    x2t = copydsfields(model, x2t, 2, 1);
    x2t = copydsfields(x2, x2t, 1);
    
    x2t.userdata = x2.userdata;
    
    if ~apply
      %Create outputs
      varargout{1} = model;
      varargout{2} = x1;
      varargout{3} = x2t;
    else
      varargout{1} = x2t;
    end
        
    
  case 'dtw'
    error('Not Yet Implemented')
  case 'cow'
    error('Not Yet Implemented')
  case 'lw'
    error('Not Yet Implemented')
end

%---------------------------------------------
function xout = expandvars(xin, vused, vtotal)
%Expand matrix in mode 2 to vtotal. Infill with nan.

xout = nan*ones(size(xin,1),vtotal);
xout(:,vused) = xin;

%---------------------------------------------
function modelcombos = makecombos(x1,x2,methodcombos,coptions)
%Create calt models based on methodcombos cell array of settings. This only
%  works with DS, PDS, DWPD, and SST.
%
%  methodcombos - nx5 cell array (modelType, parameterName, min, step, max)
%  
%  EXAMPLE:
%    load nir_data
%    mycombos = caltransfer(m5spec,mp5spec,{'pds' 'win' 11 2 31;'sst' 'ncomp' 1 1 5;'ds' '' [] [] []})
%    mycombos = caltransfer(spec1,spec2,{'dwpds' 'win1' 5 2 11;'dwpds' 'win2' 3 1 7;'pds' 'win' 5 2 11;'sst' 'ncomp' 2 1 4})
%
%  NAMES: 
%         modelType   parameterName
%         ---------   -------------
%         pds         win
%         dwpds       win1
%         dwpds       win2
%         sst         ncomp

modelcombos = [];
if nargin<4
  coptions = caltransfer('options');
end

coptions = reconopts(coptions,'caltransfer');

%For each calt method create settings. For dwpds, create all compbos.
[mymethods,midx,junk] = unique(methodcombos(:,1));
%Put back in original order (can't use 'stable' input to unique until min ML vesion is 2012a) 
[junk,myorder] = sort(midx);
mymethods = mymethods(myorder);
 
for i = mymethods'
  myidx = find(ismember(methodcombos(:,1),i));
  switch i{:}
    case 'pds'
      myvec = makeVec(methodcombos{myidx,3},methodcombos{myidx,4},methodcombos{myidx,5},1);
    case 'dwpds'
      %Need to make DOE of two windows.
      win1idx = find(ismember(methodcombos(:,2),'win1'));
      if isempty(win1idx)
        %Get default from options.
        win1val = coptions.dwpds.win(1);
      else
        win1val = makeVec(methodcombos{win1idx,3},methodcombos{win1idx,4},methodcombos{win1idx,5},1);
      end
      
      win2idx = find(ismember(methodcombos(:,2),'win2'));
      if isempty(win2idx)
        %Get default from options.
        win2val = coptions.dwpds.win(2);
      else
        win2val = makeVec(methodcombos{win2idx,3},methodcombos{win2idx,4},methodcombos{win2idx,5},1);
      end
      
      [doe,msg] = doegen('full',{'win1' 'win2'},{win1val win2val});
      myvec = num2cell(doe.data,2)';
      
    case 'sst'
      myvec = makeVec(methodcombos{myidx,3},methodcombos{myidx,4},methodcombos{myidx,5},0);
    case 'ds'
      myvec = 1;
  end
  
  if ~iscell(myvec)
    myvec = num2cell(myvec);
  end
  
  %Make models.
  for j = 1:size(myvec,2)
    if length(myidx)==2
      thismethod = 'dwpds';
      thisopt = 'win';
    else
      thismethod = methodcombos{myidx,1};
      thisopt = methodcombos{myidx,2};
    end
    if ~isempty(thisopt)
      coptions.(thismethod).(thisopt) = [myvec{j}];
    end
    coptions.(thismethod).waitbar = 'off';
    [thismodel,x1t,x2t] = caltransfer(x1,x2,thismethod,coptions);
    
    modelcombos(end+1).method = thismethod;
    %Might want to put parameters in substruct so can handle more than one
    %parameter per method. 
    if ~isempty(thisopt)
      modelcombos(end).parameter = thisopt;
      modelcombos(end).parameter_value = [myvec{j}];
    else
      %DS model
      modelcombos(end).parameter = '';
      modelcombos(end).parameter_value = [];
    end
    modelcombos(end).model = thismodel;
    modelcombos(end).transfer_data = x2t;
    modelcombos(end).diff = calcdifference(x1,x2t);%NOTE: None of the methods alter x1. 
  end
end

%---------------------------------------------
function thisval = makeVec(startval,mstep,endval,isodd)
%Make a vector of values.

mmstep = round((endval-startval)/mstep)+1;

thisval = round(linspace(startval,endval,mmstep));
if isodd
  thisval(~mod(thisval,2)) = thisval(~mod(thisval,2))-1;
end

thisval = unique(thisval);
    

