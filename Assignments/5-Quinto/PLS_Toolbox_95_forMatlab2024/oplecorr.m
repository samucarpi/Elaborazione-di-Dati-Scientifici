function [model,x] = oplecorr(x,y,ncomp,options)
%OPLECORR Optical Path-Length Estimation and Correction
% The OPLEC model is similar to EMSC but doesn't require esimates of the
% pure spectra for filtering. Instead it assumes closure on the chemical
% analyte contributions and the use of a non-chemical signal basis P
% defined by the input (options.order).
% For example, if options.order = 2, then P = [1, (1:n)', (1:n)'.^2]
% to account for offset, slope and curvature in the baseline.
%
%  INPUT:
%    1) Calibration:
%    x     = M by N matrix of spectra (class "double" or "dataset").
%    y     = M by 1 matrix of known reference values.
%    ncomp = number of components to to be used for the basis Z
%              (positive integer scalar).
%    2) Test:
%    x     = M by N matrix of spectra to be correctected .
%    model = OPLECORR model.
%
%  OPTIONAL INPUTS:
%    options = structure array with the following fields:
%     display: [ 'off' | {'on'} ]  Governs level of display to command window.
%       order: [{2}]               Order of the polynomial filter.
%      center: [{false}]           governs centering for PLS reg models (see doc)
%
%  OUTPUTS:
%    model = OPLECORR model.
%       sx = a M by N matrix of filtered ("corrected") spectra.
%
% Based on the paper:
%  Z-P Chen, J Morris, E Martin, Anal. Chem. 2006, 78, 7674-7681.
%
%I/O: model = oplecorr(x,y,ncomp,options); %identifies model  (calibration)
%I/O: sx    = oplecorr(x,model);           %applies the model (test)
%I/O: oplecorr demo
%
%See also:  EMSCORR, MSCORR, STDFIR

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 10/13 modified EMSCORR code.

%Notes:
% 0) The paper used multiple basis sets for Zb, the code here uses
%    exteriorpts to provide a nearly d-optimal soln.
% 1) Can it correct to the mean z? Seems like this would make for
%    a better conditioned problem.
% 2) Could NNLS also be used with Eqn 16? Why the sum of the equations?
% 3) Could NNLS (via CLS) be used for Eqn 17? It would avoid potential <0.
% 4) Can this be extended to more known y components?

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  options.name       = 'options';
  options.display    = 'on';
  options.order      = 2;
  options.center     = false;
  options.definitions = @optiondefs;
  if nargout==0; evriio(mfilename,varargin{1},options); else
    model = evriio(mfilename,varargin{1},options); end
  return;
end

predictmode = false;
switch nargin
case 2
  %(x,model)
  if ismodel(y) 
    predictmode = true;
  else
    error('OPLECORR second input is not an OPLECORR model.')
  end
  options = oplecorr('options');
case 3
  %(x,model,options)
  %(x,y,ncomp)
  if ismodel(y)  %(x,model,options)
    predictmode = true; %y is the model
    if isstruct(ncomp)
      options = reconopts(ncomp,oplecorr('options'));
    else
      error('OPLECORR third input is not a valid options structure.')
    end
  else           %(x,y,ncomp)
    options = oplecorr('options');
  end
case 4
  %(x,y,ncomp,options)
  if ismodel(y)
    error('OPLECORR second input must be reference (y) when using four inputs.')
  else
    options = reconopts(options,oplecorr('options'));
  end
otherwise
  error('OPLECORR requires at least two inputs.')
end
warning off backtrace

if isdataset(x)
  wasdso  = true;
else
  x       = dataset(x);
  wasdso  = false;
end

if predictmode %Test
  %x contains rows to correct
  %y contains the model
  %options is the options, ncomp is a copy
  
  if strcmpi(options.display,'on')
    hwait = waitbar(0,'OPLECORR Filter Being Applied.');
  end
  
  if ~isempty(y.detail.p)
    x.data(:,x.include{2}) = x.data(:,x.include{2}) - ...
      (x.data(:,x.include{2})/y.detail.p(x.include{2},:)')* ...
      y.detail.p(x.include{2},:)';
  end
  
  if y.detail.options.center      
    b  = rescale(x.data(:,x.include{2})*y.br,model.mb); %predicted b
  else  %force fit through zero
    b  = x.data(:,x.include{2})*y.br; %predicted b
  end
  
  x.data = spdiag(1./b)*x.data;
  if ~wasdso
    x   = x.data;
  end
  model = x;
else %Calibrate
  %x contains rows to correct
  %y contains the reference values
  %ncomp is number of factors
  %options is the options
  
  if isdataset(y)
    waydso  = true;
  else
    y       = dataset(y);
    waydso  = false;
  end
  [m,n] = size(x);
  if size(y,1)~=m %need to check size compatibility of X and Y
    error('Inputs (x) and (y) must have same number of rows.')
  end
  if size(y,2)>1
    warning('EVRI:OpleOneY','Only column 1 of (y) being used.')
    y.include{2} = 1;
  end
  %create an empty model
  model = evrimodel('oplecorr');
  model.detail.options  = options;
  model.date  = date;
  model.time  = clock;
  
  %need to use the include fields appropriately
  %right now just deal with mode 1 include
  if strcmpi(options.display,'on')
    hwait = waitbar(0,'OPLECORR Filter Being Estimated.');
  end

  %set non-chemical basis
  if isscalar(options.order)
    model.detail.p    = mncn((1:n)');
    bb    = 0:options.order;
    model.detail.p    = model.detail.p(:,ones(1,length(bb))).^bb(ones(n,1),:); %P
    model.detail.p    = normaliz(model.detail.p')';    
  elseif isempty(options.order)
    model.detail.p    = [];
  else %assume that p is a basis and check the size
    if size(options.order,1)~=n
      error('When options.order as a basis must have size(x,2) rows')
%     else
%       might have a rank check here
    end
  end

  %orthogonalize to p
  if strcmpi(options.display,'on')
    waitbar(0.2,hwait);
  end
  if ~isempty(model.detail.p)
    x.data(:,x.include{2}) = x.data(:,x.include{2}) - ...
      (x.data(:,x.include{2})/model.detail.p(x.include{2},:)')* ...
      model.detail.p(x.include{2},:)';
  end

  %find the basis vectors for Zb
  ib    = exteriorpts(mncn(x.data(x.include{1},x.include{2})),ncomp,struct('distmeasure','Mahalanobis'));
  ib    = x.include{1}(ib);  %these are used as the basis Zb
  ir    = setdiff(1:m,ib);
  ir1   = intersect(x.include{1},ir); %these are included Zr
  a     = x.data(ir1,x.include{2})*pinv(x.data(ib,x.include{2})); %gamma

  %set b_b,1 to 1 and find the remaining b_b,2:end (reuse bb variable)
  bb    = fasternnls(spdiag(y.data(ir1,1))*a(:,2:end) - ...
                     a(:,2:end)*spdiag(y.data(ib(2:end),1)),...
            (y.data(ib(1),1)*a(:,1))-spdiag(y(ir1,1))*a(:,1));
  bb    = [1; bb(:)];
  
  %next calculate br from bb and a
  model.detail.b      = ones(m,1);
  model.detail.b(ib)  = bb;
  model.detail.b(ir1) = spdiag(1./(y.data(ir1,1)+1))*a*spdiag(y.data(ib,1)+1)*bb;
  if strcmpi(options.display,'on')
    waitbar(0.6,hwait);
  end

  if options.center      
    model.mx  = mean(x.data(x.include{1},x.include{2}));
    model.mb  = mean(model.detail.b(x.include{1}));
    model.br  = simpls(mncn(x.data(x.include{1},x.include{2})), ...
                       mncn(model.detail.b(x.include{1})),ncomp, ...
                       struct('plots','none','display','off'));
    model.br  = model.br(ncomp,:)';
    model.detail.b  = rescale(x.data(:,x.include{2})*model.br,model.mb); %predicted b
  else  %force fit through zero
    model.br  = simpls(x.data(x.include{1},x.include{2}), ...
                       model.detail.b(x.include{1}),ncomp, ...
                       struct('plots','none','display','off'));
    model.br  = model.br(ncomp,:)';
    model.detail.b  = x.data(:,x.include{2})*model.br; %predicted b
  end
  
  x.data = spdiag(1./model.detail.b)*x.data;
  
  if ~wasdso
    x   = x.data;
  end
end

if strcmpi(options.display,'on')
  close(hwait), clear hwait
end


%--------------------------
function out = optiondefs

defs = {
  %name                    tab           datatype        valid                            userlevel       description
  'display'                'Display'      'select'        {'off' 'on'}                    'novice'        'Governs level of display to command window.'
  'order'                  'Settings'     'double'        'int(0:6)'                      'novice'        'Order of polynomial filter (0<=order<=6).'
  'center'                 'Settings'     'logical'       {true false}                    'novice'        'Governs use of centering in PLS correction models'
%   'logax'                  'Settings'     'select'        {'no' 'yes'}                    'intermediate'  'Use log of x.axisscale{2} as part of the filter?'
%   'p'                      'Settings'     'matrix'        []                              'novice'        'Kp by N spectra to filter out (N is number of variables).';
%   's'                      'Settings'     'matrix'        []                              'novice'        'K by N spectra to NOT filter out.';
%   'win'                    'Settings'     'double'        'int(1:inf),odd'                'intermediate'  'An odd scalar that defines the window width (number of variables) for piece-wise correction. If empty, piece-wise correction is not used.'
%   'xrefS'                  'Settings'     'select'        {'no' 'yes'}                    'advanced'      'Indicates whether (xref) includes spectra contained in the s option (options.s). If ''yes'' then the spectra in options.s are centered and an SVD estimate of options.s is used in EMSCORR.';
%   'algorithm'              'Algorithm'    'select'        {'cls' 'ils'}                   'intermediate'  'Defines correction model method.  ''cls'' uses Classical Least Squares i.e. EMSC, ''ils'' uses Inverse Least Squares i.e. IEMSC.'
%   'initwt'                 'Algorithm'    'vector'        []                              'advanced'      'Empty or Nx1 vector of initial weights (0<=w<=1). Low weights are used for channels not to be included in the fit.';
%   'condnum'                'Algorithm'    'double'        []                              'advanced'      'Condition number for x''*x used in the least squares estimates.';
%   'robust'                 'Algorithm'    'select'        {'none' 'lsq2top'}              'intermediate'  'Governs the use of robust least squares. if ''lsq2top'' is used then "trbflag", "tsqlim", and "stopcrit" are also used (see LSQ2TOP for descriptions of these fields).';
%   'res'                    'Algorithm'    'double'        []                              'intermediate'  'Scalar required when "robust" is "lsq2top". Input to LSQ2TOP function.';
%   'trbflag'                'Algorithm'    'select'        {'top' 'bottom' 'middle'}       'intermediate'  'Used only with "lsq2top" robust least squares mode. Defines if robust least squares is done to top, bottom, or middle of the data.';
%   'tsqlim'                 'Algorithm'    'double'        'float(0:1)'                    'intermediate'  'T-squared limit used only with "lsq2top" robust least squares mode.';
%   'stopcrit'               'Algorithm'    'vector'        []                              'intermediate'  'Stopping criteria used only with "lsq2top" robust least squares mode.';
%   'mag'                    'Algorithm'    'select'        {'yes' 'no'}                    'advanced'      'Use Multiplicative Correction?'
  };
out = makesubops(defs);

