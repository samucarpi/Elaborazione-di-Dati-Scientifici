function [ varargout ] = nlstd( varargin)
%NLSTD, Nonlinear Standardization (calibration transfer).
% NLSTD uses one of several nonlinear methods to transform the data
% collected from from instrument (slave) to look like data collected from
% another (master). During this process the data is transformed into a
% 'long and narrow' metadata using a window size (win) input argument.
%
%  INPUTS:
%       xSlave = Xdata from 'slave instrument'
%       xMaster = data from 'master instrument'
%       modl = ANN, LWR, SVM model.
%       win = window (used to tranform the XSlave from m-by-n to (mn)-by-(w+1) matrix)
%       pts = (LWR only) local window for number of samples to use in sub-models
%
%  OPTIONAL INPUT:
%       opts = options structure
%              name: {'options'} the name of the structure (options) 
%              display: [ {'off'} | 'on' ] governs level of display to command window.<- TODO
%              plots: [ 'none' | {'final'} ] governs level of plotting. <- TODO
%              waitbar: [ 'off' |{'auto'}| 'on' ] governs use of waitbar during. <- TODO
%              algorithm: [ {'ann'} | 'svm'| 'lwr' ]
%              useopts: [] user inputs: complete or partial options for selected algorithm
%              edges: [ {'const'} | 'zeros' | 'linterp' | 'pinterp' ]
%              ncomp: 1 <- LWR only (for now), sets the number of components to use in the model.
%
%  OUTPUT:
%       modl = standard model structure containing the ANN/LWR/SVM model
%       pred = structure array with ANN/LWR/SVM predictions
%       valid = structure array with ANN/LWR/SVM predictions
%
%I/O: modl = nlstd(xSlave,xMaster,win);
%I/O: modl = nlstd(xSlave,xMaster,win,opt);
%I/O: modl = nlstd(xSlave,xMaster,win,pts,opt); % for lwr
%I/O: pred = nlstd(xSlave,modl,win,opt);
%I/O: valid = nlstd(xSlave,xMaster,modl,win,opt);

%See also: ANN, SVM, LWR

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Create default options structure.
defaults = [];
defaults.name = 'options';
defaults.display = 'off';
defaults.plots = 'none';
defaults.waitbar = 'auto';
defaults.algorithm = 'ann'; % [ {'ann'} | 'svm'| 'lwr' ]
defaults.useopts = []; % user inputs: complete or partial options for the relevent algorithm
defaults.edges = 'const'; % [ {'const'} | 'zeros' | 'linterp' | 'pinterp' ]
defaults.ncomp = 1; % LWR only (for now), sets the number of components to use in the model.

pred = false;
val=false;
gotopts=false;

% Input argument check
if nargin == 0
  error('Empty input arguments not implamented yet');
end
if nargin < 3 & nargin > 0
  if isa(varargin{1},'char')
    if strcmp(lower(varargin{1}),'options') % return defult options struct
      varargout{1}=defaults;
    end
    return;
  else
    error('Function requires three input arguments');
  end
else % get user input
  % are we in prediction mode, validation mode or neither?
  if isa(varargin{2},'evrimodel')
    pred = true;
  elseif isa(varargin{3},'evrimodel')
    val = true;
  end
  
  % did user provide an options structure
  if isstruct(varargin{end})
    gotopts=true;
  end
  
  if gotopts
    if val
      [xSlave,xMaster,modl,win,options] = deal(varargin{1:5});
    elseif pred
      [xSlave,modl,win,options]=deal(varargin{1:4});
      xMaster=0;
    else % cal
      if strcmp(lower(varargin{end}.algorithm),'lwr')
        [xSlave,xMaster,win,pts,options]=deal(varargin{1:5});
      else % cal for ann | svm
        [xSlave,xMaster,win,options]=deal(varargin{1:4});
      end
      modl=0;
    end
  else
    options = defaults;
    if val
      [xSlave,xMaster,modl,win] = deal(varargin{1:4});
    elseif pred
      [xSlave,modl,win]=deal(varargin{1:3});
      xMaster=0;
    else % cal
      [xSlave,xMaster,win]=deal(varargin{1:3});
      modl=0;
    end
  end
end

% Open a Waitbar (if needed)
if strcmp(options.waitbar,'auto') | strcmp(options.waitbar,'on')
  h = waitbar(0.1,'Checking input arguments','name',sprintf('Nonlinear Standardization: %s',options.algorithm));
end

% Input check
if isa(modl,'evrimodel')
  if ~ismember(modl.modeltype, {'ANN','SVM','LWR'})
    error('Only ANN, SVM, and LWR models are supported.');
  else % modl is a (compatible) model
    opts = modl.detail.options;
    options.algorithm = modl.modeltype;
  end
end

if ~pred
  if isa(xMaster,'dataset')
    xMaster = xMaster.data;
  end
  % Transform y block
  if size(xMaster,2)>1
    xMaster = xMaster';
    xMaster = xMaster(:);
    if ~isa(xMaster,'double')
      xMaster=double(xMaster);
    end
  end
else % prediction mode, assign modl to y & use the method that way (for brevity)
  xMaster = modl;
  clear modl;
end

if ~pred & ~val % Obtain default options for selected algorithm
  switch lower(options.algorithm)
    case 'ann'
      opts = ann('options');
    case 'svm'
      opts = svm('options');
      % change defaults to get it to work here
    case 'lwr'
      opts = lwr('options');
    otherwise
      error('Only ANN, SVM, and LWR models are supported.');
  end
  
  % Overwrite default ANN/SVM/LWR opt struct with user's specified preferences.
  % TODO: optimize it & make it smarter. (check if it's a char, numeric...)
  if ~isempty(options.useopts)
    names = fieldnames(options.useopts);
    for i=1:length(names)
      if isfield(opts,names(i))
        opts.(names{i})=options.useopts.(names{i});
      else
        warnining(sprintf('%s is not a field in the %s options structure. Input Ignored.', names(i),options.algorithm));
      end
    end
  end
  
end

% win must be an odd number. Correct if needed.
if win>size(xSlave,2)
  error('window parameter must be smaller than the second mode of the x-block');
end
if (mod(win,2)==0)
  if win~=0
    warning('Even numbers is invalid for window size. Setting to next odd number');
  else
    warning('Zero is invalid for window size. Setting window to 1');
  end
  win = win + 1;
end

updatewaitbar(h,options.waitbar,0.2,'Creating Metadata');
% Transform x block
if ~isa(xSlave,'dataset')
  xSlave = dataset(xSlave);
end
xp = zeros(size(xSlave,2)*size(xSlave,1),win+1);
for i=1:size(xSlave,1)
  for j=1:size(xSlave,2)
    xp(j+size(xSlave,2)*(i-1),end) = j; % append target index at the end (important)
    if j<=(win-1)/2 | j>(size(xSlave,2)-(win-1)/2) % at the edges
      continue;
    else % in the middle
      xp(j+size(xSlave,2)*(i-1),1:end-1) = xSlave(i,(j-(win-1)/2):(j+(win-1)/2));
    end
  end
end

updatewaitbar(h,options.waitbar,0.8,'Creating Metadata');
% Depending on user input, fill the edges of xp matrix.
switch options.edges
  case 'const' % Default
    for i=1:size(xSlave,1)
      for j=1:size(xSlave,2)
        if j<=(win-1)/2  % near the begining
          xp(j+size(xSlave,2)*(i-1),1:end-1) = xSlave(i,1); % preassign (i,1) values
          xp(j+size(xSlave,2)*(i-1),((win-1)/2)+(2-j):end-1) = xSlave(i,1:(j+(win-1)/2));
        elseif j>(size(xSlave,2)-(win-1)/2) % near the end
          xp(j+size(xSlave,2)*(i-1),1:end-1) = xSlave(i,end); % preassign (i,end) values
          xp(j+size(xSlave,2)*(i-1),1:(((win-1)/2)+1+size(xSlave,2)-j)) = xSlave(i,(j-(win-1)/2):end);
        else % in the middle
          continue;
        end
      end
    end
  case 'linterp' % NOT implemented yet
    error('''linterp'' for options.edge is not implamented yet, use ''const'' instead');
  case 'pinterp' %? NOT implemented yet
    error('''pinterp'' for options.edge is not implamented yet, use ''const'' instead');
  case 'zeros' % Do nothing
  otherwise
    error('Unrecignized options.edges instruction.');
end

close(h);
clear defaults i j h; % cleanup

if ~val % build model/make prediction
  switch lower(options.algorithm)
    case 'ann'
      out = ann(xp,xMaster,opts);
    case 'svm'
      out = svm(xp,xMaster,opts);
    case 'lwr'
      if pred
        out = lwr(xp,xMaster,opts);
      else
        out = lwr(xp,xMaster,options.ncomp,pts,opts);
      end
  end
else % validate model
  switch lower(options.algorithm)
    case 'ann'
      out = ann(xp,xMaster,modl,opts);
    case 'svm'
      out = svm(xp,xMaster,modl,opts);
    case 'lwr'
      out = lwr(xp,xMaster,modl,opts);
  end
end

% Output model/predictions
if pred | val % use the function below and return predictions
  if ~isempty(out.pred{1,2})
    pd = origdims(out.pred{1,2}, size(xSlave));
  else
    warning(sprintf('%s failed to make a prediction.',options.algorithm));
    pd = nan(size(xSlave));
  end
  varargout{1}=pd;
else
  varargout{1}=out;
end
end

function out = origdims(in,sizes)
  % sizes input should be size(x)
  out = reshape(in,[sizes(end:-1:1)])';
end

function updatewaitbar(h,stat,val,msg)
if strcmp(stat,'auto') | strcmp(stat,'on')
  waitbar(val,h,msg);
else
  return;
end
end
