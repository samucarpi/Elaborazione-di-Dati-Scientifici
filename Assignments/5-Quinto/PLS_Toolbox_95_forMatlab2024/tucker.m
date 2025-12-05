function model = tucker(x,varargin);
%TUCKER Analysis for n-way arrays.
%  TUCKER decomposes an array of order K (where K >= 3) into the 
%  summation over the outer product of K vectors. As opposed to parafac
%  every combination of factors in each mode are included (subspaces).
%  Missing values must be NaN or Inf. 
%  
%  INPUTS:
%         x = the multi-way array to be decomposed, and
%     ncomp = the number of components to estimate, or
%     model = a TUCKER model structure.
%
%     Note that when specifying (ncomp), it must be a vector with K elements
%     specifying the number of components for each mode.
%
%  OPTIONAL INPUTS:
%   initval = If initval is a TUCKER model structure, the data are fit to
%             this model where
%             the loadings for the first mode (scores) are estimated.
%           = If the loadings are input (e.g. model.loads) these are used
%             as starting values. Type TUCKER INITVAL for more help
%   options = is a structure that is used to enable constraints, weighted loss
%             function, govern plotting and display, and input stopping
%             criteria, etc. Type TUCKER OPTIONS for more help
%
%  OUTPUT:
%     model = standard model structure (See: MODELSTRUCT), or
%     pred  = a structure with TUCKER predictions [i.e. the loadings
%             for the first mode (scores) are estimated].
%
%  This routine uses alternating least squares (ALS) in combination with
%  a line search every fifth iteration.  
%
%I/O: model   = tucker(x,ncomp,initval,options); % identifies model (calibration step)
%I/O: pred    = tucker(x,model);                 % find scores for new samples given old model
%I/O: options = tucker('options');               % returns a default options structure
%I/O: tucker demo
%I/O: tucker(model);                             % provides a table of variances per component.
%
%See also: CONLOAD, CORCONDIA, COREANAL, CORECALC, DATAHAT, GRAM, MPCA, OUTERM, PARAFAC, PARAFAC2, TLD, UNFOLDM

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% rb march 2002, added functionality for plotting model.detail.ssq.percomponent by parafac(model.detail.ssq.percomponent)
% rb jun 2002, speed up initialization

varargout = [];
if nargin == 0; x = 'io'; end

% Define standard options etc.
if isa(x,'dataset')% Then it's a SDO
  inc = x.includ;
  xsize = size(x.data(inc{:}));
  order = ndims(x.data);
else
  if ~isstr(x)
    xsize = size(x);
    order = ndims(x);
  else
    xsize = [2 2 2];
    order = 3;
  end
end
  

% Generate standard options
standardtol = [1e-6 1e-6 10000 60*60];
constraint = cell(order,1);
for i=1:order+1
  constraint{i} = regresconstr('options');
  if i<order+1 % Don't set the last one (corresponding to the core, to orthogonality)
    constraint{i}.orthogonal = 1;
  end
end
  iterative.fractionold_w = 0;
  iterative.cutoff_residuals = 3;
  iterative.updatefreq = 100;
  scaletype.value = 'norm';
standardoptions = struct('name','options','display','on','plots','final','waitbar','on','weights',[],'stopcrit',standardtol,...
  'init',0,'line',1,'algo',0,'iterative',iterative,'scaletype',scaletype,'blockdetails','standard','samplemode',1);
standardoptions.preprocessing = {[]};     %See Preprocess
standardoptions.constraints = constraint;

if nargin == 0; 
  x = 'io'; 
end
if ischar(x)
  options=standardoptions;
  if nargout==0; 
    clear varargout; 
    evriio(mfilename,x,options); 
  else; 
    model = evriio(mfilename,x,options); 
  end
  return; 
end

% Filter standard options for possible user-defined modifications
standardoptions = evriio('tucker','options',standardoptions);
model = nwengine(x,'tucker',standardoptions,xsize,order,varargin{:});
