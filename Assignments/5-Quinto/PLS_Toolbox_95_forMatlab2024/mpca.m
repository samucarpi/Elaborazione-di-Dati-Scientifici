function model = mpca(varargin)
%MPCA Multi-way (unfold) principal components analysis.
%  Principal Components Analysis of multi-way data using
%  unfolding to a two way matrix followed by conventional PCA.
%
%  INPUTS:
%       mwa = multi-way array (3-way array or higher class "double" or "dataset"), and
%     ncomp = number of components to to be calculated (positive integer scalar).
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           display: [ 'off' | {'on'} ]      governs level of display to command window.
%             plots: [ 'none' | {'final'} ]  governs level of plotting.
%     outputversion: [ 2 | {3} ]             governs output format.
%     preprocessing: { [] }                  preprocessing structure (see PREPROCESS), default
%                                            is none.
%      blockdetails: [ {'standard'} | 'all' ]   Extent of predictions and raw residuals  
%                     included in model. 'standard' = none, 'all' x-block 
%        samplemode: [ {3} | [] ] Mode (dimension) which becomes the new sample mode  
%
%  It is also possible to input just the preprocessing option as an
%  ordinary string in place of (options) and have the remainder of options
%  filled in with the defaults from above. The following strings are valid:
%   'none'  -  no scaling
%   'auto'  -  unfolds array then applies autoscaling
%   'mncn'  -  unfolds array then applies mean centering
%   'grps'  -  unfolds array then group scales each variable, i.e.
%                the same variance scaling is used for each variable
%                along its time trajectory (Default)
%
%  Example: model = mpca(mwa,3,'auto'); creates an MPCA model with
%    three components where the data has been autoscaled.
%
%  OUTPUT:
%     model = standard model structure containing the MPCA model (See MODELSTRUCT)
%
%I/O: model   = mpca(mwa,ncomp,options);  %identifies model (calibration step)
%I/O: model   = mpca(mwa,ncomp,preprostring); %model with prepro shortcut
%I/O: pred    = mpca(mwa,model,options);   %projects a new X-block onto existing model
%
%See also: ANALYSIS, EVOLVFA, EWFA, EXPLODE, PARAFAC, PCA, PREPROCESS

%Copyright © Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw
%Modified BMW April 1998-2003
%bmw, August 2002, rewrote to work with new PCA
%jms 8/6/03 -removed extra see also
%rsk 02/28/05 -change default pp to [] to maintain consistency with other
%              functions.

%Start Input
if nargin==0  % LAUNCH GUI
  analysis mpca
  return
elseif ischar(varargin{1});
  options = pca('options');
  options.samplemode = 3;
  options.preprocessing{1} = [];%preprocess('default','none');
  if nargout==0; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return; 
end

mwa = varargin{1};
nocomp = [];
model  = [];
options = [];
switch nargin
  case 1
    error('MPCA requires at least two inputs');
  case 2
    % (mwa,nocomp)
    % (mwa,model)
    if ismodel(varargin{2});
      model = varargin{2};
    else
      nocomp = varargin{2};
    end
  case 3
    % (mwa,nocomp,options)
    % (mwa,nocomp,model)
    % (mwa,model,options)
    % (mwa,nocomp,preprocessing)   --old style call with text preprocessing
    if ~ismodel(varargin{2});
      nocomp = varargin{2};
      if ismodel(varargin{3});
        % (mwa,nocomp,model)
        model = varargin{3};
      elseif isstruct(varargin{3});
        % (mwa,nocomp,options)
        options = varargin{3};
      else
        % (mwa,nocomp,preprocessing)
        prepro = varargin{3};
        options = mpca('options');
        switch lower(prepro)
          case 'mncn'
            options.preprocessing{1} = preprocess('default','mean center');
          case 'auto'
            options.preprocessing{1} = preprocess('default','autoscale');
          case 'grps'
            options.preprocessing{1} = preprocess('default','groupscale');
            options.preprocessing{1}.userdata.numblocks = size(mwa,2);
          case 'none'
            options.preprocessing{1} = [];% preprocess('default');
          otherwise
            error('Unknown or unallowed preprocessing method')
        end
      end
    else
      % (mwa,model,options)
      model  = varargin{2};
      options = varargin{3};
    end
  case 4
    % (mwa,nocomp,model,options)
    [nocomp,model,options] = deal(varargin{2:end});
end
options = reconopts(options,'mpca');

if ~isa(mwa,'dataset')
  mwa = dataset(mwa);
end

if isempty(model)  % Make a model
  
  %get datasource info
  ds = getdatasource(mwa);

  %and get folded dataset field info
  mwadetails = copydsfields(mwa);
  
  %unfold data
  if ndims(mwa)~=3;
    error('MPCA requires a 3-way matrix (time x variable x batch)');
  end

  if mdcheck(mwa);
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
    [flag,missmap,mwa] = mdcheck(mwa);
  end

  % update folded dataset field info
  mwadetails.detail.includ = mwa.include';

  mwa = unfoldmw(mwa,options.samplemode);
  
  %auto-handle group scaling
  ppcomp = preprocess('default','groupscale');
  if ~iscell(options.preprocessing);%in case preprocessing is not given as cell
      options.preprocessing={options.preprocessing};
  end;
  for j=1:length(options.preprocessing{1});
    if strcmp(options.preprocessing{1}(j).description,ppcomp.description)
      %got a group-scale
      if options.preprocessing{1}(j).userdata.numblocks<2
        options.preprocessing{1}(j).userdata.numblocks = ds.size(2);
      end
    end
  end

  %build model
  model = pca(mwa,nocomp,options);
  model.modeltype = 'MPCA';
  model.datasource{1} = ds;
  model.detail.mwadetails = mwadetails;

elseif ismodel(model)
  
  if ~strcmp(model.modeltype,'MPCA')
    error(['Unable to do predictions with models of type ' model.modeltype])
  end

  if (isfield(options,'rawmodel') & options.rawmodel)  
    %reduce a previous model
    
    %reorganize data
    if ndims(mwa)~=3;
      error('MPCA requires a 3-way matrix (time x variable x batch)');
    end
    order = model.detail.options.samplemode;  
    mwa = unfoldmw(mwa,options.samplemode);
    
    %modify model so PCA can predict using it
    ds              = model.datasource{1};
    model.modeltype = 'PCA';
    mwasize         = model.datasource{1}.size;
    nsz             = [mwasize(order) prod(mwasize([1:order-1 order+1:length(mwasize)]))];
    model.datasource{1}.size = nsz;
    
    %Do model reduction
    model = pca(mwa,nocomp,model,options);
    model.modeltype = 'MPCA';
    model.datasource{1} = ds;
    
  else
    % Project onto old model
    
    %reorganize data
    order           = model.detail.options.samplemode;
    if ndims(mwa)~=3;
      %Assume this is a single sample and force into a 3-way DSO
      mwa = cat(3,mwa,mwa);
      mwa = mwa(:,:,1);
      switch order
        case 1
          mwa = permute(mwa,[3 1 2]);
        case 2
          mwa = permute(mwa,[1 3 2]);
        otherwise
          %don't do anything
      end
    end
    mwa             = unfoldmw(mwa,order);
    
    %modify model so PCA can predict using it
    ds              = model.datasource;
    model.modeltype = 'PCA';
    mwasize         = model.datasource{1}.size;
    nsz             = [mwasize(order) prod(mwasize([1:order-1 order+1:length(mwasize)]))];
    model.datasource{1}.size = nsz;
    
    %do prediction
    model  = pca(mwa,model,options);
    
    %reset model fields back to original values
    model.modeltype     = 'MPCA_PRED';
    model.datasource    = ds;
    
  end
  
else
  error('Input not a model structure')
end

