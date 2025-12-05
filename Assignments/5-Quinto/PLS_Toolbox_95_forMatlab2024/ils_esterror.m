function varargout = ils_esterror(model,pred,options)
%ILS_ESTERROR Estimation error for ILS models.
%  Returns estimated errors for predictions of ILS models. 
%  INPUTS:
%    model = a standard model structure (PLS, PCR, MLR).
% 
%  OPTIONAL INPUT:
%    pred  = a standard model prediction or validation structure
%            [i.e. outputs (pred) or (valid) from PLS, PCR, or MLR].
%
%  OUTPUTS:
%    este  = estimation error for y. If (pred) was supplied, the estimation
%            error for the prediction or validation is returned. Otherwise,
%            the estimation error for the calibration samples is returned.
%    info  = string describing how the estimation was calculated (using
%            RMSEC or RMSECV).
%
%  The estimate uses Eqn 9 of Faber, N.M. and Bro, R., Chemomem. and Intell.
%  Syst., 61, 133-149 (2002). If available, MSECV is used instead of MSE [see
%  output (info)]. Note from the ref.: "Faber [N.M. Faber, Chemom. Intell. Lab.
%  Syst. 52 (2000) 123] has found the performance of Eq. (8)" (which is used
%  to derive Eqn 9) "to rely heavily on the ability to correctly estimate the
%  optimum model dimensionality.
%  Note that the estimate can be <0, in those cases it is set ==0.
%
%I/O: [este,info] = ils_esterror(model);       %calibration estimation error
%I/O: [este,info] = ils_esterror(model,pred);  %prediction estimation error
%
%See also: ANALYSIS, MLR, PCR, PLS

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%NBG

%Questions:
%  How do we make the estimation error have a Warning or
%    caution when T2 > T2 lim and Q > Qlim?
%  How do we calculate confidence limit (need to determine appropriate
%    degrees of freedom)
%NOTE: hidden output format: see options below

%the CL calculation will use ttestp and is not yet implemented 1/9/09 NBG
%    cl    = confidence limit in terms of probability point (0<cl<1).
%            If (cl) is input, the output (este) is interpreted as a
%            confidence limit instead of "raw" estimation error.

%nbg 5/21/12 squared the model.detail.dy for the estimate

if nargin == 0; model = 'io'; end
if ischar(model);  
  options = [];
  options.outputformat = 'raw';   % [ 'raw' | 'model' ] governs output format: model returns values inserted into model structure
  if nargout==0; evriio(mfilename,model,options); else; varargout{1} = evriio(mfilename,model,options); end
  return; 
end

%reconcile options
if nargin<3; options = []; end
options = reconopts(options,mfilename);

%determine how function was called
predictmode = nargin>1;
usemsecv    = ~isempty(model.detail.rmsecv);

if ~ismember(lower(model.modeltype),{'mlr' 'pls' 'pcr' 'plsda'})
  varargout = cell(1,nargout);
  return;
end

%see if user supplied dy in the model
ny   = size(model.pred{2},2);
if ~isfield(model.detail,'dy') || isempty(model.detail.dy)
  model.detail.dy = 0;
end
if numel(model.detail.dy)==1 %it's a scalar
  model.detail.dy = ones(1,ny)*model.detail.dy;
end
if size(model.detail.dy,2)~=ny
  error('Number of entries in (model.detail.dy) does not equal number of y variables in (model).')
end
my   = size(model.pred{2},1);
if size(model.detail.dy,1)==1 & my>1
  model.detail.dy = ones(my,1)*model.detail.dy;
end

%and check pred too
if predictmode
  if ~isfield(pred.detail,'dy') || isempty(pred.detail.dy)
    pred.detail.dy = 0;
  end
  if numel(pred.detail.dy)==1 %it's a scalar
    pred.detail.dy = ones(1,ny)*pred.detail.dy;
  end
  if size(pred.detail.dy,2)~=ny
    error('Number of entries in (pred.detail.dy) does not equal number of y variables in (model).')
  end
  mpy = size(pred.pred{2},1);
  if size(pred.detail.dy,1)==1 & mpy>1
    pred.detail.dy = ones(mpy,1)*pred.detail.dy;
  end
end

%get appropriate values for msec
switch lower(model.modeltype)
case 'mlr'
  ncomp = length(model.detail.includ{2,1});   %use # of variables as # components (for later calculation)
  if usemsecv
    msec  = model.detail.rmsecv.^2;           %RMSECV
  else
    msec  = model.detail.rmsec.^2;            %RMSEC
  end
case {'pls','pcr','plsda','npls'}
  ncomp = size(model.loads{2,1},2);           %Number of Factors
  if usemsecv
    msec  = model.detail.rmsecv(:,min(end,ncomp)).^2;  %RMSECV
  else
    msec  = model.detail.rmsec(:,min(end,ncomp)).^2;   %RMSEC
  end
end
m     = length(model.detail.includ{1}); %Number of Calibration Samples

%Sample Leverage
if usemsecv
  %using RMSECV - no special corrections needed for h
  info = 'Estimation error estimated from RMSECV';
  h    = 1;
else
  %using RMSEC requires more calculation
  info = 'Estimation error estimated from RMSEC';
  %  Is the last preprocessing step, mean-centering or is it a zero
  %  intercept model? Only look at X-block.
  if ~isempty(model.detail.preprocessing{1}) & ...
      (strcmpi(model.detail.preprocessing{1}(end).keyword,'mean center') ...
      | strcmpi(model.detail.preprocessing{1}(end).keyword,'autoscale'))
    h  = 1+1/m;
    msec = msec(:)'*(m/(m - ncomp - 1)); %Stdized Mean Squared Error of Calibration
  else
    h  = 1;
    msec = msec(:)'*(m/(m - ncomp));
  end
end

% This uses Eqn 9 of Faber, N.M. and Bro, R., Chemomem. and Intell.
% Syst., 61, 133-149 (2002).
if predictmode
  h    = h+pred.detail.leverage(:); %Sample Leverage
  este = h*msec(:)' - pred.detail.dy.^2;
else
  h    = h+model.detail.leverage(:);
  este = h*msec(:)' - model.detail.dy.^2;
end
este(este<0) = 0;
este = sqrt(este);


%see what kind of output we should supply
switch char(options.outputformat)
case 'model'
  if predictmode
    model = pred;     %pass back prediction structure if we had it
  end

  %insert values into model structure
  model.detail.esterror.pred{2} = este;

  %add note to "info" field of model
  i1   = strmatch('Estimation error',model.info);
  if isempty(i1)
    %not yet said anything about estimation error? Add it to info
    model.info = char(model.info,info);
  else
    %note already in there? replace to reflect the current calculation
    model.info = strvcat(model.info(1:i1-1,:),info,model.info(i1+1:end,:));
  end
  varargout = {model info};

otherwise
  %raw output
  varargout = {este info};
end

