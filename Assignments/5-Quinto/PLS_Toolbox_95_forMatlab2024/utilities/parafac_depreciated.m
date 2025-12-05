function model = parafac(x,varargin);
%PARAFAC Parallel factor analysis for n-way arrays.
%  PARAFAC decomposes an array of order K (where K >= 3, i.e. it has
%  K modes) into the summation over the outer product of K vectors.
%  Missing values must be NaN or Inf. 
% 
%  INPUTS:
%         x = the multi-way array to be decomposed
%     ncomp = the number of components to estimate
%
%  OPTIONAL INPUTS:
%   initval = If a PARAFAC model is input, the data are fit to this model where
%             the loadings for the first mode (scores) are estimated.
%           = If the loadings are input (e.g. model.loads) these are used
%             as starting values. Type PARAFAC INITVAL for more help
%   options = is a structure that is used to enable constraints, weighted loss
%             function, govern plotting and display, and input stopping
%             criteria, etc. Type PARAFAC OPTIONS for more help
%
%  OUTPUT:
%     model = standard model structure (See MODELSTRUCT), or
%     pred  = a structure with PARAFAC predictions [i.e. the loadings
%             for the first mode (scores) are estimated].
%
%  This routine uses alternating least squares (ALS) in combination with
%  a line search every fifth iteration. For 3-way data, the intial estimate
%  of the loadings is obtained from the tri-linear decomposition (TLD).
%
% I/O: model   = parafac(x,ncomp,initval,options); % identifies model (calibration step)
% I/O: options = parafac('options');               % returns a default options structure
% I/O: pred    = parafac(xnew,model);              % find scores for new samples given old model
% I/O: parafac demo
% I/O: parafac(model)                              % provides a table of variances per component.
%
%See also: DATAHAT, EXPLODE, GRAM, MPCA, OUTERM, PARAFAC2, PREPROCESS, TLD, TUCKER, UNFOLDM

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Rb, Mar, 2005, introduced new scaling of loadings in PARAFAC (set in
% options.scaletype

if nargin==0  % LAUNCH GUI
  analysis parafac
  return
else  
  varargout = [];
  
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
  for i=1:order
    constraint{i} = regresconstr('options');
  end
  iterative.fractionold_w = 0;
  iterative.cutoff_residuals = 3;
  iterative.updatefreq = 100;
  scaletype.value = 'norm';
  scaletype.text = ['Choose the way to normalize loadings. Default ''norm'' sets to unit area whereas ''max'' sets the max of the loads to 1. The variance will be in the sample mode loads'];
  standardoptions = struct('name','options','display','on','plots','final','waitbar','on','weights',[],'stopcrit',standardtol,...
    'init',0,'line',1,'algo','als','iterative',iterative,'scaletype',scaletype,'blockdetails','standard','coreconsist','on','samplemode',1);
  standardoptions.preprocessing = {[]};     %See Preprocess
  standardoptions.constraints = constraint;
  standardoptions.definitions   = @optiondefs;
  
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
end

% Filter standard options for possible user-defined modifications
standardoptions = evriio('parafac','options',standardoptions);
model = nwengine(x,'parafac',standardoptions,xsize,order,varargin{:});

%-----------------------------------------------------
function out = optiondefs()
defs = {
%Name                         Tab             Datatype        Valid                         Userlevel       %Description
'display'                     'Display'       'select'        {'on' 'off'}                  'novice'        'Turn text output to command window on or off';
'plots'                       'Display'       'select'        {'final' 'all' 'off'}         'novice'        'Turn plotting of final model on or off. By choosing ''all'' you can choose to see the loadings as the iterations proceed. The final plot can also be produced using the function MODELVIEWER after the model has been fitted.';
'weights'                     'Algorithm'     'matrix'        ''                            'advanced'      'Weight array for weighted least squares fitting. Must be the same size as data';
'stopcrit'                    'Algorithm'     'vector'        ''                            'intermediate'  'Stopping criteria. Four-element vector [relative_convergence absolute_convergence max_iterations max_time_sec]';
'init'                        'Algorithm'     'double'        'int(1:100)'                  'intermediate'  'Governs how the initial guess for the loadings is obtained. Mostly use 0 for default or 10 for models that are difficult to fit. See HTML documentation for details (>> doc parafac).';
'line'                        'Algorithm'     'boolean'       ''                            'advanced'      'Turn line-search on or off ("off" is not normally recommended)';
'algo'                        'Algorithm'     'select'        {'als' 'tld' 'swatld'}        'advanced'      'Governs algorithm used (not recommended to modify from ALS unless data are close to perfect; i.e. low model error, low noise)';
'iterative'                   'Iterative'     'struct'        ''                            'advanced'      'Settings for iterative reweighted least squares fitting (see help on weights).';
'iterative.fractionold_w'     'Iterative'     'double'        'float'                       'advanced'      'Deafult 0. If > 0 (and <1) iteratively refined weights are linear combination of new and old weights. Used for stabilizing purposes but modification is not normally recommended.';
'iterative.cutoff_residuals'  'Iterative'     'double'        'float'                       'advanced'      'Defines the cutoff for large residuals in terms of the number of robust standard deviations. Default is 3 meaning all residuals larger than 3 robust standard deviations are set to zero weight.';
'iterative.updatefreq'        'Iterative'     'double'        'float'                       'advanced'      'To speed convergence, the iteratively refined weights are only updated infrequently (default every 100 iterations).';
'scaletype.value'             'Scale Type'    'select'        {'norm' 'max'}                'advanced'      'Normally, loading vectors are scaled to norm one and the variance is in the sample loadings/scores. Can be changed so that loadings are scaled to have maximum value one.';
'blockdetails'                'Display'       'select'        {'compact','standard','all'}  'novice'        'Governs amount of information returned in model. Compact means that only essential parameters are retained whereas e.g. residuals of X etc. are not kept.'
'coreconsist'                 'Algorithm'     'select'        {'on' 'off'}                  'advanced'      'Governs calculation of core consistency (turning off may save time with large data sets and many components).';
'samplemode'                  'Algorithm'     'double'        'int(1:inf)'                  'advanced'      'Defines which mode should be considered the sample (i.e. object) mode.';
'preprocessing'               'Algorithm'     'cell(vector)'  ''                            'advanced'      'Preprocessing structures for each mode.';
'constraints'                 'Algorithm'     'cell(vector)'  'loadfcn=optionsgui'          'intermediate'  'Used to employ constraints on the parameters (opens a separate instance of OptionsGUI).';
};

options.rmlist = {'display' 'plots'};
out = makesubops(defs);
