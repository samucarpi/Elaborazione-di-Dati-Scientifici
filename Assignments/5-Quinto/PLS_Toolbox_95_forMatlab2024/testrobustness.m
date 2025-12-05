function [results,fig] = testrobustness(model,x,y,testtype,options)
%TESTROBUSTNESS Test regression model for robustness to various effects.
% Given a regression model and test data x and y, this function performs
% one of several tests to assess the effect of different perturbations on
% the test data x-block. The effect on prediction error, Q and T^2 are
% mapped as a function of the test parameters.
%
% Test type to perform is specified in the inputs and can be one of the
% following:
%  'interference' : adds a gaussian peak of varying width and position to
%              the x-block data. Results are mapped by peak width and
%              position.
%  'shift' : shifts and broadens the x-block data and maps the results
%              relative to shift amount and width of broadening filter.
%              Filter is based on savgol filter of a specified order and
%              width (see options.)
%
%  'singlevar' : adds std(variable)/100 to each sample for every variable. 
%                Results are the differences in the predictions between the
%                perturbed samples and original samples.
%
% INPUTS:
%     model = A standard model structure containing a regression model of
%              type PLS, PCR, MLR, CLS, LWR, SVM, ANN, ANNDL, and XGB.
%              Note: Multivariate y-block
%              models will cause the test to return the average error for
%              all y-columns at the given conditions.
%         x = X-block of the test data (can be performed on the calibration
%              data but results should be interpreted as relative to RMSEC
%              rather than RMSEP.
%         y = Y-block values corresponding to the X-block data.
%  testtype = String specifying the type of test to perform (see above)
%
% OPTIONAL INPUTS:
%   options = Options structure containing one or more of the following:
%         display: [ 'off' | {'on'} ] Governs level of display to command window.
%          plots : [ 'none' |{'final'}] Governs the creation of a plot
%                 summarizing the RMSEP results.
%
%           --- Used only with test type 'interference' ---
%     peakwidthsteps : [7] Number of peak widths to test between 0 and 20
%                      variables in width. See peakwidths to manually
%                      specify peak widths.
%        peakwidths : [] Optional explicit list of peak widths to use for
%                      interferent. If supplied, peakwidthsteps is ignored.
%                      Empty [] uses peakwidthsteps to determine widths.
%       peakspacing : [2] Spacing of interference peaks in number of
%                      variables. A value of one (1) will test the
%                      interference peaks centered at every variable.
%                      Larger values will test at fewer locations and speed
%                      the test but provide less detail for variable
%                      sensitivity.
%  
%           --- Used only with test type 'shift' ---
%        shiftlimit : [1] Maximum number of variables to test shift
%                      (negative and positive direction)
%         shiftstep : [0.05] Step size for each step of the shift test.
%                      Each sample is shifted by this number of variables
%                      between each step of the shift test.
%      deresolvemax : [21] Maximum width of deresolution filter to test.
%                      Shift test will include all odd filter sizes from 3
%                      to this value including an "unbroadened" copy at the
%                      start.
%   deresolvewidths : [] Optional explicit list of deresolution filter
%                      widths to test. If supplied, deresolvemax is
%                      ignored. Empty [] uses deresolvemax to determine
%                      widths.
%    deresolveorder : [0] Optional order of the polynomial broadening
%                      filter. Value of zero (0) will use an box filter.
%                      Higher values will use the specified polynomial
%                      filer.
%
% OUTPUT:
%   results = Structure containing the following fields:
%         rmsep : matrix of RMSEP results for each tested condition
%             q : matrix of Q residuals for each tested condition
%            t2 : matrix of Hotellings T^2 values for each tested condition
%         xaxis : vector of tested value for mode 2 of the above matrices
%                 (use on x-axis when producing an image of the results)
%         yaxis : vector of tested value for mode 1 of the above matrices
%                 (use on y-axis when producing an image of the results)
%     xaxisname : string label describing xaxis values
%     yaxisname : string label describing yaxis values
%           dso : a DataSet object containing all the above fields with
%                  results concatenated in mode 3. Can be used in PlotGUI:
%                     plotgui(results.dso(:,:,1))  %plots RMSEP
%
%I/O: results = testrobustness(model,x,y,testtype,options);
%
%See also: CLS, CROSSVAL, MLR, PCR, PLS, SAVGOL

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%BMW/JMS

if nargin == 0; model = 'io'; end
if ischar(model);
  options = [];
 
  options.peakwidths = [];
  options.peakwidthsteps = 7;
  options.peakspacing = 2;
  
  options.shiftlimit = 1;
  options.shiftstep = 0.05;
  options.deresolvewidths = [];
  options.deresolvemax = 21;
  options.deresolveorder = 0;

  options.display = 'off';
  options.plots = 'final';
  options.validmodeltypes = {'pls' 'pcr' 'cls' 'mlr' 'lwr' 'svm' 'ann' 'anndl' 'xgb'};

  if nargout==0; evriio(mfilename,model,options); else; results = evriio(mfilename,model,options); end
  return;
end

if nargin<4;
  error('Requires input of a model, x and y data, and a test type')
end
if nargin<5;
  options = [];
end
options = reconopts(options,mfilename);

if ~ismodel(model)
  error('Input model must be a standard model structure');
end
predonly = predonly_methods();
if ~ismember(lower(model.modeltype), options.validmodeltypes)
  error('Robustness tests can only be performed on PLS, PCR, CLS, MLR, LWR, SVM, ANN, ANNDL, and XGB models.');
end

if isa(x,'double')      %convert to DataSets
  x        = dataset(x);
  x.author = 'TESTROBUSTNESS';
elseif ~isa(x,'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if isa(y,'double')      %convert to DataSets
  y        = dataset(y);
  y.author = 'TESTROBUSTNESS';
elseif ~isa(y,'dataset')
  error(['Input Y must be class ''double'' or ''dataset''.'])
end

if size(y,2)~=length(model.detail.includ{2,2})
  if length(y.include{2})==length(model.detail.includ{2,2})
    %use y-block include field (matches in LENGTH to cols included in model)
    y = y(:,y.include{2});  %drop unused y variables
  elseif size(y,2)<=max(model.detail.includ{2,2});
    %if model's "include" field seems to work with this y-block, use it
    y = y(:,model.detail.includ{2,2});  %drop unused y variables
  else
    error('Insufficient columns in test y-block to match values predicted by model');
  end
end

%do a hard-delete of excluded samples
incl = intersect(x.include{1},y.include{1});
x = nindex(x,incl,1);
y = nindex(y,incl,1);

%run specific test
switch testtype

  %- - - - - - - - - - - - - - - - - - - - - - - - - - -
  case {'interferent','interference'}
    
    %interferent test
    results = interferenttest(model,x,y,options);

    %- - - - - - - - - - - - - - - - - - - - - - - - - - -
  case 'shift'

    results = shifttest(model,x,y,options);

    %- - - - - - - - - - - - - - - - - - - - - - - - - - -
  case 'singlevar'

    results = singlevartest(x,y,model,options);

    %- - - - - - - - - - - - - - - - - - - - - - - - - - -
  otherwise
    
    error('Unrecognized test type "%s"',testtype);
    
end
fig = [];
%create plot if desired
if strcmpi(options.plots,'final')
  fig = figure('name',summarize(model));
  
  switch lower(model.modeltype)
    case 'mlr'
      nplots = 1;
    case 'cls'
      nplots = 2;
    case predonly
      nplots = 1;
    otherwise
      nplots = 3;
  end
  
  if ~strcmpi(testtype,'singlevar')
    subplot(nplots,1,1);
    imagesc(results.xaxis,results.yaxis,results.rmsep);
    title(sprintf('RMSEP (%s)', upper(model.modeltype)))
    
    if nplots>1
      subplot(nplots,1,2);
      imagesc(results.xaxis,results.yaxis,results.q);
      if results.qlim~=1
        title('RMSE(Reduced Q Residuals)');
      else
        title('RMSE(Q Residuals)')
      end
    end
    
    if nplots>2
      subplot(nplots,1,3);
      imagesc(results.xaxis,results.yaxis,results.t2);
      if results.tlim~=1
        title('RMSE(Reduced Hotellings T^2)')
      else
        title('RMSE(Hotellings T^2)')
      end
    end
    
    for j=1:nplots;
      subplot(nplots,1,j);
      axis xy
      xlabel(results.xaxisname)
      ylabel(results.yaxisname)
      colorbar
    end
  else
    plotsinglevarresults(results,model);
  end
end

if nargout==0
  clear results
else
  %add DSO to output
  sens = dataset(cat(3,results.rmsep,results.q,results.t2));
  sens.axisscale{2}     = results.xaxis;
  sens.axisscalename{2} = results.xaxisname;
  if ~strcmpi(testtype,'singlevar')
    sens.axisscale{1}     = results.yaxis;
    sens.axisscalename{1} = results.yaxisname;
    sens.label{3}         = {'RMSEP' 'RMSE Q Residuals' 'RMSE Hotellings T^2'};
    sens.labelname{3}     = 'Summary Result Type';
    results.dso = sens;
  end
end

%--------------------------------------------------------------------
function res = interferenttest(model,x,y,options)
%INTERFERENCE test
predonly = predonly_methods();
[m,n] = size(x);

% Set up options for predictions
modeltype = lower(model.modeltype);
plsoptions = feval(modeltype,'options');
plsoptions.display = 'off';
plsoptions.plots = 'none';
if isfieldcheck(plsoptions,'.waitbar')
  plsoptions.waitbar = 'off';
end
%get limits
if isfieldcheck(model,'model.detail.tsqlim')
  tlim = model.detail.tsqlim{1};
else
  tlim = 1;
end
if isfieldcheck(model,'model.detail.reslim')
  qlim = model.detail.reslim{1};
else
  qlim = 1;
end

% If not supplied, set up interference peak widths to test
if isempty(options.peakwidths)
  widths = logspace(0,log10(20),options.peakwidthsteps);
else
  widths = options.peakwidths;
end
nwidths = length(widths);

peakmax = max(std(x.data));    % Set up maximum peak height
cs = options.peakspacing;    % Set channels to skip to speed calculation

sens = zeros(nwidths,ceil(n/cs),3);    % Set up matrix to hold data and results
perturbx = zeros(nwidths*m,n);  %create matrix for modified x

evriwaitbar('Testing Interference Sensitivity');
for j = 1:size(sens,2)  %outer loop (whatever that is for this method)

  for i = 1:nwidths  % interference peak width
    peakfun = peakgaussian([peakmax/widths(i) (cs*j)-(cs-1) widths(i)],1:n);
    perturbx((i-1)*m+1:i*m,:) = x.data + ones(m,1)*peakfun;
  end

  %get prediction
  perturbxds = copydsfields(x,dataset(perturbx),[2 2]);
  valid = feval(modeltype,perturbxds,model,plsoptions);

  %store results
  for comp=1:size(valid.pred{2},2)
    rmsep(:,comp) = rmse(scale(reshape(valid.pred{2}(:,comp),m,nwidths)',y.data(:,comp)')')';
  end
  if size(rmsep,2)>1;
    sens(:,j,1) = mean(rmsep,2);
  else
    sens(:,j,1) = rmsep;
  end
  
  switch modeltype
    case predonly
      % do nothing
    otherwise
      if ~strcmp(modeltype,'mlr')
        sens(:,j,2) = sqrt(mean(reshape(valid.ssqresiduals{1,1}./qlim,m,nwidths)))';
      end
      if ~ismember(modeltype,{'mlr' 'cls'})
        sens(:,j,3) = sqrt(mean(reshape(valid.tsqs{1,1}./tlim,m,nwidths)))';
      end
  end

  %update waitbar
  if mod(j,5)==0
    evriwaitbar(j/size(sens,2));
  end

end
evriwaitbar close

if ~isempty(x.axisscale{2})
  name = x.axisscalename{2};
  xaxis = x.axisscale{2}(1:cs:end);
  if isempty(name)
    name = 'unknown units';
  end
else
  xaxis = 1:cs:n;
  name = 'variable number';
end

res = [];
res.rmsep = sens(:,:,1);
res.q     = sens(:,:,2);
res.t2    = sens(:,:,3);
res.xaxis = xaxis;
res.xaxisname = sprintf('Center of Interferent (%s)',name);
res.yaxis = widths;
res.yaxisname = 'Interferent Peak Width (variables)';
res.tlim = tlim;
res.qlim = qlim;

%------------------------------------------------------
function res = shifttest(model,x,y,options)
%SHIFT/BROADENING test

[m,n] = size(x);
predonly = predonly_methods();  % methods with no diagnostics, e.g. 'svm' 'ann' 'xgb'

% Set up options for predictions
modeltype = lower(model.modeltype);
plsoptions = feval(modeltype,'options');
plsoptions.display = 'off';
plsoptions.plots = 'none';
if isfieldcheck(plsoptions,'.waitbar')
  plsoptions.waitbar = 'off';
end

%get limits
if isfieldcheck(model,'model.detail.tsqlim')
  tlim = model.detail.tsqlim{1};
else
  tlim = 1;
end
if isfieldcheck(model,'model.detail.reslim')
  qlim = model.detail.reslim{1};
else
  qlim = 1;
end

% If not supplied, set up filter widths to test
if isempty(options.deresolvewidths)
  widths = [0 3:2:max(0,min([floor(n/2) options.deresolvemax]))];
else
  widths = options.deresolvewidths;
end
nwidths = length(widths);

%set up shifts
shifts = -options.shiftlimit:options.shiftstep:options.shiftlimit;
nshifts = length(shifts);

% Set up matrix to hold data and results
sens = zeros(nshifts,nwidths,3);
shiftedx = zeros(nshifts*m,n);  %create matrix for modified x

%do prep of shifted data
ax = 1:size(x,2);
for i = 1:nshifts
  shiftedx((i-1)*m+1:i*m,:) = interp1(ax,x.data',ax+shifts(i),'spline')';
end

evriwaitbar('Testing Shift Sensitivity');
for j = 1:size(sens,2)  %outer loop (whatever that is for this method)

  if widths(j)>0
    %do broadening
    perturbx = savgol(shiftedx,widths(j),options.deresolveorder);
  else
    perturbx = shiftedx;
  end

  %get prediction
  perturbxds = copydsfields(x,dataset(perturbx),[2 2]);
  valid = feval(modeltype,perturbxds,model,plsoptions);

  %store results
  for comp=1:size(valid.pred{2},2)
    rmsep(:,comp) = rmse(scale(reshape(valid.pred{2}(:,comp),m,nshifts)',y.data(:,comp)')')';
  end
  if size(rmsep,2)>1;
    sens(:,j,1) = mean(rmsep,2);
  else
    sens(:,j,1) = rmsep;
  end
  
  switch modeltype
    case predonly 
      % do nothing
    otherwise
      if ~strcmp(modeltype,'mlr')
        sens(:,j,2) = sqrt(mean(reshape(valid.ssqresiduals{1,1}./qlim,m,nshifts)))';
      end
      if ~ismember(modeltype,{'mlr' 'cls'})
        sens(:,j,3) = sqrt(mean(reshape(valid.tsqs{1,1}./tlim,m,nshifts)))';
      end
  end

  %update waitbar
  evriwaitbar(j/size(sens,2));

end

%swap first two dims for shift mode (so shift is plotted on x-axis in plot)
sens = permute(sens,[2 1 3]);

evriwaitbar close

res = [];
res.rmsep = sens(:,:,1);
res.q     = sens(:,:,2);
res.t2    = sens(:,:,3);
res.xaxis = shifts;
res.xaxisname = 'Shift (variables)';
res.yaxis = widths;
res.yaxisname = 'Smoothing Window (variables)';
res.tlim = tlim;
res.qlim = qlim;

%------------------------------------------------------
function res = singlevartest(x,y,model,options)
%Single Variable test

[m,n] = size(x);
predonly = predonly_methods();  % methods with no diagnostics, e.g. 'svm' 'ann' 'xgb'
xcopy = x;
% Set up options for predictions
modeltype = lower(model.modeltype);
plsoptions = feval(modeltype,'options');
plsoptions.display = 'off';
plsoptions.plots = 'none';
if isfieldcheck(plsoptions,'.waitbar')
  plsoptions.waitbar = 'off';
end

%get limits
if isfieldcheck(model,'model.detail.tsqlim')
  tlim = model.detail.tsqlim{1};
else
  tlim = 1;
end
if isfieldcheck(model,'model.detail.reslim')
  qlim = model.detail.reslim{1};
else
  qlim = 1;
end

pret = std(x.data,0,1)/100;
evriwaitbar('Testing Individual Variable Sensitivity');
predictors = size(model.pred{2},2);
alldiffs = cell(1,predictors);
for j = 1:predictors
  % Sort data by Y values
  [Ys,inds] = sort(y.data(:,j));
  xsorted = xcopy(inds,:);
  pred = feval(lower(model.modeltype),xsorted,model,plsoptions);
  diffs = zeros(size(xcopy));
  includedvars = xcopy.include{2};
  for i = 1:length(includedvars)
    x = xsorted.data;
    x(:,includedvars(i)) = x(:,includedvars(i)) + pret(includedvars(i));
    npred = feval(lower(model.modeltype),x,model,plsoptions);
    diff = npred.pred{2} - pred.pred{2};
    diffs(:,includedvars(i)) = diff(:,j);
    %update waitbar
    evriwaitbar((i + (j-1)*length(includedvars))/(length(includedvars)*predictors)); 
  end
  alldiffs{j} = diffs;
end
evriwaitbar close

res = [];
res.rmsep = alldiffs;
res.q     = [];
res.t2    = [];
res.xaxis = xsorted.axisscale{2,1};
res.xaxisname = 'Variables';
res.yaxis = 1:size(x,1);
res.yaxisname = 'Samples ordered by ascending ';
res.tlim = tlim;
res.qlim = qlim;

%------------------------------------------------------
function evriwaitbar(pct)
%EVRIWAITBAR Create/use a waitbar with estimated time to completion note
%
%I/O: evriwaitbar('description here')  %open new with this string
%I/O: evriwaitbar(percentcomplete)   %update to this percent complete level (error if missing)
%I/O: evriwaitbar('close')           %close waitbar

persistent h starttime

%close or open command?
if ischar(pct)
  if ishandle(h)
    close(h)
    h = [];
  end
  if ~strcmp(pct,'close')
    %any other string is "open new waitbar"
    h = waitbar(0,[pct '... (close figure to cancel)']);
    starttime = now;
  end
  return
end

%update command
if isempty(h) | (~ishandle(h) & pct == 0)
  % Add wait bar (first call)
  evriwaitbar('Testing Robustness');

elseif ishandle(h)
  %update waitbar
  try
    est = round((now-starttime)*(1-pct)/pct*24*60*60);
    waitbar(pct,h)
    set(h,'name',['Est. Time Remaining: ' besttime(est)]);
  catch
    h = [];
    error('Robustness analysis canceled by user.');
  end
else
  %missing waitbar
  h = [];
  error('Robustness analysis canceled by user');

end

%--------------------------------------------------------------------------
function res = predonly_methods()
% Methods which have no diagnostics, only give ypred
res = {'svm' 'ann' 'anndl' 'xgb' };

%--------------------------------------------------------------------------
function plotsinglevarresults(results,model)
nplots = length(results.rmsep);


title(sprintf('Individual Variable Sensitivity (%s)', upper(model.modeltype)))

for j=1:nplots;
  subplot(nplots,1,j);
  thisres = results.rmsep{j}';
  imagesc(results.yaxis,results.xaxis,thisres);
  vmin = min(thisres(:));
  vmax = max(thisres(:));
  M = max(abs(vmin), abs(vmax));
  color_range = linspace(vmin,vmax, 256)';
  R = interp1([-M 0 M],[0 1 1], color_range);
  G = interp1([-M 0 M],[0 1 0], color_range);
  B = interp1([-M 0 M],[1 1 0], color_range);
  C = [R G B];
  ax = gca;
  colormap(ax,C)
  cb = colorbar;
  xlabel([results.yaxisname model.predictionlabel(j)]);
  ylabel(results.xaxisname);
  cblabel = get(cb,'Label');
  set(cblabel,'String','Difference in Prediction');
end
