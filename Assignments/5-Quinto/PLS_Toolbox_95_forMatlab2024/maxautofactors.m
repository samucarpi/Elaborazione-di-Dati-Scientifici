function [model,options] = maxautofactors(x,ncomp,options)
%maxautofactors Maximum Autocorrelation / Difference Factors for images.
%  In it's default mode, maxautofactors calculates a maximum autocorrelation 
%  factors (MAF) model using a symmetric eigenvalue decomposition compliment
%  of a generalized eigenvalue decomposition of the MAF objective function.
%  For time-series (x), maxautofactors finds factors that captures maximum
%  correlated variance where the time-series is collected into the rows of (x).
%  For image (x), maxautofactors finds factors that captures maximum spatially
%  correlated variance.
%
%  The algorithm can be changed using options.algorithm (see options below).
%  In general the objective is to find weights (w) that maixmizes
%     R(w) = (w'*S0*w)/(x'*S1*w)
%  where S0 is the signal covariance and S1 is the clutter covariance.
%  S0 and S1 are defined diffently for each algorithm using options.sig* 
%  and options.clt* to govern the spatial derivatives. These options are
%  set automatically for MAF and maximum difference factors (MDF).
%
%  For options.algorithm=='maf' S0 = X'*X and S1 = X'*D1'*D1*X giving
%    MAXIMUM AUTOCORRELATION FACTORS where D1 is the first time (or spatial)
%    difference operator and variance captured is for X*sqrt(inv(S1)).
%    D1 is based on savgol(X,3,2,1). (See SAVGOL).
%  For options.algorithm=='mnf' S0 = X'*X and S1 = X'*d1'*d1*X giving
%    MINIMUM NOISE FACTORS where d1 is the first time (or spatial)
%    difference operator and variance captured is for X*sqrt(inv(S1)).
%    d1 is based on is the first difference (See DIFF).
%  For options.algorithm=='mdf' S0 = X'*D1'*D1*X and S1 = X'*D2'*D2*X giving
%    MAXIMUM DIFFERENCE FACTORS where D2 is the second time (or spatial)
%    difference operator and variance captured is for D1*X*sqrt(inv(S1)).
%    D1 is based on savgol(X,3,2,1) and D2 is based on savgol(X,3,2,2).
%  For options.algorithm=='manual' S0 = X'*D1'*D1*X and S1 = X'*D2'*D2*X
%    where D1 is based on savgol(x,sigw,sigo,sigd) and
%          D2 is based on savgol(x,cltw,clto,cltd) where
%    sig* and clt* are defined in the options. See SAVGOL for additional
%    information on these parameters. Note that options.sigd and
%    options.cltd cannot be equal.
%
%  INPUTS:
%          x = MxN is assumed to be time-series {class 'double' or
%              or class 'dataset' of type 'data'}.
%            = MxN class 'dataset' with .type = 'image' is assume to be an
%              image (See BUILDIMAGE).
%            = MxNxP image {class double} is assumed to be an image.
%      ncomp = number of components (integer).
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           display: [ 'off' | {'on'} ]  governs level of display to command window.
%             plots: [ 'none' | {'final'} ]  governs level of plotting.
%         algorithm: [ {'maf'} | 'mdf' | 'manual']
%            mdfdir: [ {'mean'} | 'c' | 'h' ] governs the default plot for MDF
%                      'mean' plots the mean statistics for down columns and
%                        across the rows,
%                      'c' plots the statistics calculated down the columns, and
%                      'r' plots the statistics calculated across the rows.
%     preprocessing: { [] } preprocessing structure (see PREPROCESS).
%                sc: [ {'X/D1'} | 'D1/D2' | "sig/jclt" ] signal definition
%              sigw: {0} odd scalar signal window width (0 for MAF [unused], 3 for MDF)
%              sigo: {0} scalar signal polynomial order (0 for MAF [unused], 2 for MDF)
%              sigd: {0} scalar signal derivative (0 for MAF [unused], 1 for MDF)
%              cltw: {3} odd scalar on [1,3,...] clutter window width (3 for MAF, 3 for MDF)
%              clto: {2} scalar clutter polynomial order (2 for MAF, 2 for MDF)
%              cltd: {1} scalar clutter derivative (1 for MAF, 2 for MDF)
%            smooth: [] smoothness penalty, based on the fraction of variance of
%                       X (typical value might be 1e-3 to 0.05).
%   confidencelimit: [{0.95}] 0<=Confidence level<1 for Q and T2 limits. A value
%                       of zero (0) disables calculation of confidence limits.
%
%  OUTPUTS:
%      model = standard model object (See EVRIMODEL) and documentation
%              on maxautofactors).
%    options = options structure where some fields may have been modified.
%
%I/O: [model,options] = maxautofactors(x,ncomp,options);
%I/O: pred            = maxautofactors(x,model);
%I/O: options         = maxautofactors('options');
%
%See also: MCR, SAVGOL PARAFAC, PCA, PLOTLOADS, PLOTSCORES, SAVGOL_2, SSQTABLE

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files"
% distributed by Eigenvector Research Inc. for use with any software other
% than MATLAB®, without written permission from Eigenvector Research, Inc.

%NOTE: add command line to start Analysis if no inputs when in the GUI

%options.algorithm = 'manual', changes to 'mdf' during calibration

%% Check I/O
if nargin==0; x = 'io'; end

if any(strcmp(x,evriio([],'validtopics')))
  options = [];
  options.name    = 'options';
  options.display = 'on';
  options.plots   = 'final';
  options.algorithm = 'maf'; % | 'mnf' | 'mdf' | 'manual'
  options.mdfdir  = 'mean'; %[{'mean' | 'c' | 'h'}]
  options.preprocessing   = {[]};
  options.sc      = 'X/D1';
  options.sigw    = 0;
  options.sigo    = 0;
  options.sigd    = 0;
  options.ssgwt   = '';
  options.cltw    = 3;
  options.clto    = 2;
  options.cltd    = 1;
  options.csgwt   = '';
  options.condmax = 1e6;
  options.smooth  = 0;
  options.confidencelimit = 0.95;
  options.functionname = 'mafautofacts';
  
  if nargout==0
    clear model; evriio(mfilename,x,options);
  else
    model       = evriio(mfilename,x,options);
  end
  return
end
if nargin<2
  error([ upper(mfilename) ' requires 2 inputs.'])
end

%Check options input and predictmode
predictmode     = false;    %default is calibrate mode

switch nargin
case 2 % two inputs
  % (x,ncomp)
  % (x,model)
  options       = maxautofactors('options');
  if ismodel(ncomp) % (x,model)
    predictmode = true;
    % ncomp is a calibrated model
    model       = evrimodel(ncomp.modeltype);   % prediction
  else              % (x,ncomp)
    model       = evrimodel(options.algorithm); % default = MAF
  end
case 3 % three inputs
  % (x,ncomp,options)
  % (x,model,options)
  options       = reconopts(options,maxautofactors('options'));
  if ismodel(ncomp) % (x,model,options)
    predictmode = true;
    % ncomp is a calibrated model
    model       = evrimodel(ncomp.modeltype);   % prediction
  else              % (x,ncomp,options)
    switch lower(options.algorithm)
    case 'manual'
      model     = evrimodel('mdf');
    case 'mnf'
      model     = evrimodel('maf');
    otherwise
      model     = evrimodel(options.algorithm);
    end
  end
end
 
%          x = MxN is assumed to be time-series {class 'double' or
%              or class 'dataset' of type 'data'}.
%            = MxN class 'dataset' with .type = 'image' is assume to be an
%              image (See BUILDIMAGE).
%            = MxNxP image {class double} is assumed to be an image.
%Check the form of the input data
if ndims(x)==1
  error('Input (x) cannot be scalar.')
end
if isa(x,'dataset')
  switch lower(x.type)
  case 'image'
    xtype = 'image';
  case 'data'
    xtype = 'data';
  otherwise
    error('Input (x) .datatype not recognized.')
  end
else
  switch ndims(x)
  case 2
    x     = dataset(x);
    xtype = 'data';
  case 3
    x     = buildimage(x,[1 2],1,inputname(1));
    xtype = 'image';
  otherwise
    error('Input (x) not recognized as time-series or image. Use class DataSet object.')
  end
end
  
switch xtype
case 'data'
  m       = size(x,1);
  n       = size(x,2);
case 'image'
  m       = x.imagesize;
  n       = length(x.include{2});
end
x.data    = double(x.data);
if n<2
  error('Input (x) should have more than one spectral channel.')
end

%Handle Preprocessing
if isempty(options.preprocessing)
  options.preprocessing = {[]};  %reinterpet as empty cell
end
if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};  %insert into cell
end

%% Prediction / Calibration
model.date      = date;
model.time      = clock;
model           = copydsfields(x,model,[],{1 1});            %copy all mode labels, etc.
%model.help wiki is incorrect (info incorrect)

if predictmode %predictmode = MODEL APPLICATION
  if size(x.data,2)~=model.datasource{1}.size(1,2)
    error('Variables included in data do not match variables expected by model');
  end
  x.include{2}  = ncomp.detail.include{2};
  x             = preprocess('apply',ncomp.detail.preprocessing{1},x); %apply preprocessing
  model.detail.preprocessing{1} = ncomp.detail.preprocessing{1}; %Move preprocessing to the MAF/MDF application
  model.detail.options          = ncomp.detail.options;          %Move options to the MAF/MDF application
  ncomp.detail.preprocessing{1} = []; %Remove preprocessing from the PCA application
  ncomp.modeltype = 'PCA';

  switch lower(ncomp.options.algorithm)
  case {'maf', 'mnf'}
    %Signal
    x.data(:,ncomp.detail.include{2})  = x.data(:,ncomp.detail.include{2})*ncomp.detail.ploads{1}; %apply weighting
    %Apply the model and copy fields
    covc        = ncomp.apply(x);
    model.modeltype = 'MAF_PRED';
    ncomp.modeltype = 'MAF';
  case {'mdf', 'manual'}
    %Signal
    switch xtype
    case 'data'   %time-series
      xc        = savgol(x',ncomp.options.sigw,ncomp.options.sigo, ...
                            ncomp.options.sigd,struct('wt',ncomp.options.ssgwt))';
      xc.data(:,ncomp.detail.include{2}) = xc.data(:,ncomp.detail.include{2})*ncomp.detail.ploads{1}; %apply weighting
      covc      = ncomp.apply(xc);       %Apply the model and copy fields
    case 'image'  %image
      [xc,xh]   = savgol_2(x,ncomp.options.sigw,ncomp.options.sigo, ...
                    ncomp.options.sigd,struct('wt',ncomp.options.ssgwt));
      xc.data(:,ncomp.detail.include{2}) = xc.data(:,ncomp.detail.include{2})*ncomp.detail.ploads{1}; %apply weighting
      xh.data(:,ncomp.detail.include{2}) = xh.data(:,ncomp.detail.include{2})*ncomp.detail.ploads{1}; %apply weighting
      covc      = ncomp.apply([xc;xh]);  %Apply the model and copy fields
    end
    model.modeltype   = 'MDF_PRED';
    ncomp.modeltype   = 'MDF';
  end
  model.loads = covc.loads;
  model.tsqs  = covc.tsqs;
  model.ssqresiduals  = covc.ssqresiduals;
  model.wts           = ncomp.wts;
  model.description   = ncomp.description;
  model.detail.ploads = ncomp.detail.ploads;
  covc.detail = rmfield(covc.detail,'options');       %PCA model does not preprocess
  covc.detail = rmfield(covc.detail,'preprocessing'); 
  ss          = fieldnames(covc.detail);
  for ii=2:length(ss)
    if ~isempty(eval(['covc.detail.',ss{ii}]))
      eval(['model.detail.',ss{ii},' = covc.detail.',ss{ii},';'])
    end
  end

  try
    if strcmpi(options.plots,'final')
      plotscores(ncomp,model);
    end
  catch me
    disp('EVRI:PlottingError')
    throw(me)
  end
else           %predictmode = MODEL CALIBRATON
  options     = ckoptions(options);
  model.detail.options  = options;              %keep the MAF/MDF options 

  %calibrate preprocessing
  [x,model.detail.preprocessing{1}] = preprocess('calibrate',options.preprocessing{1},x);

  %Clutter
  switch xtype
  case 'data'
    iinc        = rmexcld_1(size(x,1),x.include{1},options.cltw);
    if options.cltw==1
      covc      = x.data;
      covc(2:end,:) = diff(x.data);
    else
      covc      = savgol(x.data',options.cltw,options.clto,options.cltd,struct('wt',options.csgwt))'; %xc
    end
    covc        = covc(iinc,x.include{2});
    covc        = covc'*covc/length(iinc);
    if options.smooth>0
      [~,dd]    = savgol(1:n,3,2,2);
      covc      = covc + options.smooth*norm(x.include,'fro')^2*(dd*dd');
    end
  case 'image'
    [~,~,covc,covh] = savgol_2(x,options.cltw,options.clto,options.cltd,struct('wt',options.csgwt));
    if options.smooth>0
      [~,dd]    = savgol(1:n,3,2,2);
      covc      = (covc+covh)/2 + options.smooth*norm(x.include,'fro')^2*(dd*dd');
    else
      covc      = (covc+covh)/2; %Sigma_c
    end
  end
  model.detail.ploads{1}  = cov_cv(covc,struct('plots','none','display','off','calccov','no', ...
                              'sqrt','yes','preprocessing',0,'condmax',options.condmax)); %inv(sqrt(Sigma_c))

  covc        = evrimodel('pca');  % reuse the variable covc
  covc.ncomp  = ncomp;
  covc.options.confidencelimit = options.confidencelimit;
  switch lower(options.algorithm)
  case {'maf','mnf'}
    %Signal
    x.data(:,x.include{2})  = x.data(:,x.include{2})*model.detail.ploads{1};
    %SymEigProb
    covc.x      = x;
    switch lower(options.algorithm)
    case 'maf'
      model.description{1}  = 'Maximum Autocorrelation Factors Model';
      model.description{2}  = '  PCA of X*sqrt(inv(cov(1stDX))) = X*model.detail.ploads{1}';
      model.description{3}  = '  T = X*sqrt(inv(cov(1stDX)))*P = X*W';
    case 'mnf'
      model.description{1}  = 'Minimum Noise Fractions Model';
      model.description{2}  = '  PCA of X*sqrt(inv(cov(1stdX))) = X*model.detail.ploads{1}';
      model.description{3}  = '  T = X*sqrt(inv(cov(1stdX)))*P = X*W';
    end
  case {'mdf','manual'}    
    %Signal
    switch xtype
    case 'data'
      x.include{1}  = rmexcld_1(size(x,1),x.include{1},options.sigw);
      if options.sigw==1
        x.data(2:end,:) = diff(x.data);
      else
         x      = savgol(x',options.sigw,options.sigo,options.sigd,struct('wt',options.ssgwt))'; %xs
      end
      x.data(:,x.include{2})  = x.data(:,x.include{2})*model.detail.ploads{1};
      covc.x    = x;
    case 'image'
      [xc,xh]   = savgol_2(x,options.sigw,options.sigo,options.sigd,struct('wt',options.csgwt));
      xc.data(:,x.include{2}) = xc.data(:,x.include{2})*model.detail.ploads{1};
      xh.data(:,x.include{2}) = xh.data(:,x.include{2})*model.detail.ploads{1};
      covc.x    = [xc;xh];
    end
    model.description{1}  = 'Maximum Difference Factors Model';
    model.description{2}  = '  PCA of D1*X*sqrt(inv(cov(2ndDX))) = D1*X*model.detail.ploads{1}';
    model.description{3}  = '  T = D1*X*sqrt(inv(cov(2ndDX)))*P = D1*X*W';
  otherwise
    error('Input (options.algorithm) not recognized.')
  end
  covc        = covc.calibrate;     %SymEigProb

  model.loads = covc.loads;
  model.tsqs  = covc.tsqs;
  model.ssqresiduals    = covc.ssqresiduals;
  model.wts   = model.detail.ploads{1}*covc.loads{2};
  covc.detail = rmfield(covc.detail,'options');       %PCA model does not preprocess
  covc.detail = rmfield(covc.detail,'preprocessing'); 
  ss          = fieldnames(covc.detail);
  for ii=2:length(ss)
    if ~isempty(eval(['covc.detail.',ss{ii}]))
      eval(['model.detail.',ss{ii},' = covc.detail.',ss{ii},';'])
    end
  end
  try
    if strcmpi(options.plots,'final')
      plotloads(model);
      plotscores(model);
    end
    if strcmpi(options.display,'on')
      ssqtable(model,ncomp)
    end
  catch me
    disp('EVRI:PlottingError')
    throw(me)
  end
end %Predict_Mode
end %MAXAUTOFACTORS

function options = ckoptions(options)
  switch lower(options.algorithm)
  case 'maf'
    options.sc      = 'X/D1';
    options.sigw    = 0;
    options.sigo    = 0;
    options.sigd    = 0;
    options.cltw    = 3;
    options.clto    = 2;
    options.cltd    = 1;
  case 'mnf'
    options.sc      = 'X/d1';
    options.sigw    = 0;
    options.sigo    = 0;
    options.sigd    = 0;
    options.cltw    = 1;
    options.clto    = 0;
    options.cltd    = 1;    
  case 'mdf'
    options.sc      = 'D1/D2';
    options.sigw    = 3;
    options.sigo    = 2;
    options.sigd    = 1;
    options.cltw    = 3;
    options.clto    = 2;
    options.cltd    = 2;
  case 'manual'
    if options.sigd==options.cltd
      error('Maximization ill-defined options.sigd==options.cltd.')
    end
    if options.sigd==0
      options.sc    = ['X/D',int2str(options.cltd)];
    else
      options.sc    = ['D',int2str(options.sigd),'/D',int2str(options.cltd)];
    end
  otherwise
    error('Algorithm (option.algorithm) not recognized.')
  end
end %CKOPTIONS

function iinc = rmexcld_1(m,i1,w)
%RMEXCLD_1 Remove edges and excluded down columns
%  Used before running derivative operator down the columns
%  For a DataSet object (x) of type 'data'.
%  For a M by N image DataSet object.
%  For zc = the derivative down the columns is
%    covv = zv(iinc,:)'*zv(iinc,:)/length(iinc);.
%  The covariance matrix that are not influenced by excluded rows.
%    
%  INPUTS:
%      m = size(x,1) scalar of number of data set rows.
%     i1 = x.include{1} DataSet include field.
%      w = scalar window width (odd member of [1:2:odd scalar]).
%
%  OUTPUTS:
%   iinc = indices for down the columns.
%
%Example:
%   iinc = rmexcld_1(x.imagesize,x.include{1},5);
% 
%I/O: iinc = rmexcld_1(m,i1,w);
%
%See also: rmexcld_2

if w==1
  p2      = 1;
else
  p2      = floor(w/2);
end

%Remove indices next to the edges
iinc      = i1;
iinc      = setdiff(iinc,1:p2);
if w>1
  iinc    = setdiff(iinc,m(1)-p2+1:m(1));
end

%Remove due to excluded indices (excluded internal rows)
inu       = setdiff(1:m,i1); %excluded rows
if ~isempty(inu)
  for i1=1:length(inu)
    iinc    = setdiff(iinc,inu(i1)-p2:inu(i1)+p2);
  end
end

end