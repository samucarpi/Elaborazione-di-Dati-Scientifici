function [baselined_data,baselines] = baselineds(spec,options)
%BASELINEDS Wrapper for baselining functions.
%
%  INPUT:
%   spec = MxN matrix of ROW vectors to be baslined. Input (spec) can be
%          class DataSet or double.
%
%  OUTPUTS:
%     baselined_data = data with baseline removed.
%          baselines = baselines removed from data.
%
%  OPTIONAL INPUT:
%   options = struture array with the following fields passed to underlying
%             baseline functions:
%             display : [ {'off'} | 'on'] governs level of display (waitbar on/off).
%               plots : [ {'none'} | 'final' ] governs plotting, and
%           algorithm : [ {'wlsbaseline'} | 'baseline' | 'whittaker' | 'datafit']
%                        wlsbaseline - Baseline subtraction using iterative asymmetric least squares algorithm.
%                        baseline    - Subtracts a polynomial baseline offset from spectra.
%                        whittaker   - Baseline subtraction using Whittaker filter.
%                        datafit     - Asymmetric least squares baselining.
%                order : positive integer for polynomial order {default =1}.
%  wlsbaseline_options : see wlsbaseline.m.
%    whittaker_options : see wlsbaseline.m.
%       baseline_freqs : wavenumber or frequency axis vector, see baseline.m.
%       baseline_range : baseline regions, see baseline.m.
%     baseline_options : see baseline.m.
%      datafit_options : see datafit_engine.m. NOTE: 'lambdas' and 'trbflag'
%                        options have defaults updated for baselining.
%
%I/O: [baselined_data,baselines] = baselineds(spec,options); %Calibrate and apply.
%I/O: spec = baselineds(baselined_data,baselines);           %Undo
%
%See also: BASELINE, DATAFIT_ENGINE, PREPROCESS, WLSBASELINE

%Copyright Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


if ischar(spec);
  if strcmpi(spec,'test')
    % Try runtime tests.
    % baselineds('test')
    test
    return
  end
  options = [];
  options.display       = 'off';        %Displays output to the command window
  options.plots         = 'none';
  options.algorithm     = 'wlsbaseline'; % 'baseline' 'wlsbaseline' 'whittaker' 'datafit'
  options.order         = 2;%Order for all methods except baseline.
  
  options.wlsbaseline_options  = wlsbaseline('options');
  
  options.whittaker_options  = wlsbaseline('options');
  
  options.baseline_freqs      = [];
  options.baseline_range      = [];
  options.baseline_options    = baseline('options');
  
  options.datafit_options    = datafit_engine('options');
  options.datafit_options.lambdas = 1e4; %makes the smoothness penalty significant, better for baselining
  options.datafit_options.trbflag  = 'bottom'; %sets baselining to be the default
  
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,spec,options); else; baselined_data = evriio(mfilename,spec,options); end
  return;
end

baselines = [];

if nargin<2
  options = [];
else
  if ~isstruct(options)
    baselines = options;
  end
end

if ~isempty(baselines)
  %Undo
  baselined_data = spec+baselines;
else
  
  %Call with 0 options so non-default options won't get filtered. Other
  %baseline methods do this.
  options = reconopts(options,'baselineds',0);
  
  switch options.algorithm
    case 'wlsbaseline'
      [baselined_data,bweights,specb] = wlsbaseline(spec,options.order ,options.wlsbaseline_options);
      baselines = bweights*specb;
    case 'whittaker'
      options.whittaker_options.filter = 'whittaker';
      [baselined_data,bweights,specb] = wlsbaseline(spec,options.order,options.whittaker_options);
      baselines = bweights*specb;
    case 'baseline'
      options.baseline_options.order = options.order;
      [baselined_data,junk1,junk2,baselines] = baseline(spec,options.baseline_range,options.baseline_options);
    case 'datafit'
      options.datafit_option.order = options.order;
      [baselined_data,baselines] = datafit_engine(spec,options.datafit_options);
    otherwise
      error(['Unrecognized baseline algorithm : ' options.algorithm])
  end
  
end

%--------------------------
function out = optiondefs

baselinetxt = ['Baseline Algoritms: ' 10 10 'WLSBASELINE - Iteratively fits a baseline to a polynomial '...
  'or basis vector by down-weighting channels with positive residuals as these are assumed '... 
  'to be peaks. Uses the function wlsbaseline.' 10 10 'WHITTAKER - Flexible baseline using an '...
  'automated asymmetric least squares Whittaker algorithm.' 10 10 'DATAFIT - Fits baseline using an automated '...
  'asymmetric least squares Whittaker algorithm. Polynomials and basis can be added. '...
  'Calls the datafit_engine function.'];

defs = {
  %name                    tab               datatype        valid                                              userlevel       description
  'algorithm'              'Algorithm'       'enable'        {'wlsbaseline' 'whittaker' 'datafit'}   'novice'        baselinetxt
  'order'                  'Order'           'double'        'int(1:inf)'                                       'novice'        'Integer scalar value (order) corresponding to the order of polynomial baseline to use OR a scalar value (lambda) indicating required smoothness to use with Whittaker algorithm.'
  'wlsbaseline_options'    'WLS Baseline'    'struct'        ''                                                 'advanced'      'WLSBASELINE options.'
  %'baseline_freqs'         'Baseline'        'vector'        ''                                                 'advanced'      'BASELINE wavenumber or frequency axis vector {Default: taken from dataset axisscale or a linear vector}.'
  'baseline_range'         'Baseline'        'vector'        ''                                                 'advanced'      'BASELINE regions (indices to use).'
  'baseline_options'       'Baseline'        'struct'        'custom'                                           'advanced'      'BASELINE options. Opens window for manual selection of baseline.'
  'whittaker_options'      'Whittaker'       'struct'        ''                                                 'advanced'      'Whittaker options.'
  'datafit_options'        'Datafit Engine'  'struct'        ''                                                 'advanced'      'Datafit Engine options.'
  };

options.rmlist = {'display' 'plots' 'filter' 'order'};
defs = adoptdefinitions(defs,'wlsbaseline','wlsbaseline_options', options);

defs = adoptdefinitions(defs,'wlsbaseline','whittaker_options', options);

defs = adoptdefinitions(defs,'baseline','baseline_options', options);

defs = adoptdefinitions(defs,'datafit_engine','datafit_options', options);

out = makesubops(defs);


%--------------------------
function test
load raman_dust_particles.mat
%baselined = wlsbaseline(raman_dust_particles.data,1);

match_allgood = [];
undo_allgood = [];
try
  
  %Default uses wlsbaseline.
  a = wlsbaseline(raman_dust_particles);
  
  [b,c] = baselineds(raman_dust_particles);
  
  match_allgood(1) = comparevars(a,b);
  undo_allgood(1) = comparevars(raman_dust_particles.data,b.data+c);
  
  %Baseline.
  a = baseline(raman_dust_particles);
  
  [b,c] = baselineds(raman_dust_particles,struct('algorithm','baseline'));
  
  match_allgood(2) = comparevars(a,b);
  undo_allgood(2) = comparevars(raman_dust_particles.data,b.data+c);
  
  %Whittaker
  a = wlsbaseline(raman_dust_particles,2,struct('filter','whittaker'));
  
  [b,c] = baselineds(raman_dust_particles,struct('algorithm','whittaker'));
  
  match_allgood(3) = comparevars(a,b);
  undo_allgood(3) = comparevars(raman_dust_particles.data,b.data+c)
  
  %Datafit
  a = datafit_engine(raman_dust_particles);
  
  [b,c] = baselineds(raman_dust_particles,struct('algorithm','datafit'));
  
  match_allgood(4) = comparevars(a,b);
  undo_allgood(4) = comparevars(raman_dust_particles.data,b.data+c)
  
catch
  match_allgood = -1;
  undo_allgood = -1;
end

if all(match_allgood)
  disp('Runtime tests pass.')
elseif match_allgood(1)==-1
  disp('Runtime ERROR!')
else
  disp(['Error in tests:  ' num2str(match_allgood)])
end

if all(undo_allgood)
  disp('Match tests pass.')
elseif undo_allgood(1)==-1
  disp('Match tests ERROR!')
else
  disp(['Error in tests:  ' num2str(undo_allgood)])
end

