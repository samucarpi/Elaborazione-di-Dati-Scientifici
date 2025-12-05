function [yprdn,resn,tsqn,scoresn] = modlpred(newx,modl,plots,q,w,lv,p)
%MODLPRED Predictions using standard model structures.
%  MODLPRED makes Y-block predictions based on an X-block and and
%  existing regression model created using REGRESSION (PLS or PCR).
%  INPUTS:
%     newx = X-block in the units of the original data
%            (class "double" or "dataset"), and
%     modl = structure variable that contains the regression model.
%
%  OPTIONAL INPUT: 
%    plots = suppresses plotting when set to 0 {default = 1}.
%
%  OUTPUTS
%    yprdn = Y-block predictions,
%     resn = X-block residuals,
%     tsqn = X-block T^2 values, and
%  scoresn = X-block scores.
%
%  NOTE: (newx) will be scaled in MODLPRED using scaling
%        information contained in (modl).
%
%I/O: [yprdn,resn,tsqn,scoresn] = modlpred(newx,modl,plots); %model predictions
%
%MODLPRED can also make predictions based on an existing PLS model
%  constructed with the NIPALS algorithm from the PLS function.
%  Inputs are the matrix of predictor variables (newx), the PLS model
%  inner-relation coefficients (bin), the x-block loadings (p), the
%  y-block loadings (q), the x-block weights (w), the number of latent
%  variables to use in prediction (lv), and an optional variable (plots)
%  which suppresses the plots when set to 0.
%  Outputs are the Y-block predictions (yprdn), residuals (resn), and the 
%  scores (scoresn). Note that T^2 are not calculated.
%
%I/O: [yprdn,resn,scoresn] = modlpred(newx,bin,p,q,w,lv,plots);
%
%See also: ANALYSIS, EXPLODE, MATCHVARS, MODLRDER, PCA, PCAPRO, PCR, PLS, REGCON

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg, 11/98, 12/98
%jms 6/01    - revised for preprocess preprocessing (v3)
%jms 8/27/01 - fixed typo in preprocessing code
%jms 9/04/01 - changed call to preprocess (order of inputs)
%nbg 10/31/01 - added yblock preprocessing undo
%jms 11/08/01 - converted to allow dataset for newx
%  - added verification that yblock preprocessing undo can be done
%jms 11/16/01 - converted ypred back to double after "undo" of preprocessing
%jms 2/26/01 - updated for new model format
%jms 3/19/02 -revised calls to preprocess
%jms 3/23/02 - converted pred from model to direct calls to originating routines
%jms 2/10/03 - send plots to new figure
%jms 3/24/03 number of components in model from LOADS not SCORES

if nargin == 0; newx = 'io'; end
varargin{1} = newx;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; yprdn = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<2
  error('Error - Insufficient number of inputs to MODLPRED.')
end
if ismodel(modl) | isa(modl,'struct')  
  %NOTE: allowing struct's which don't look like models into here so we can
  %reach the backwards-compatibility code below (updatemod converting
  %really old models to correct format)
  if nargin < 3
    plots = 1;
  end

  %do updatemod to assure the model is up-to-date (and let any errors
  %throw)
  modl = updatemod(modl);
  
  switch lower(modl.modeltype)
  case 'pca'
    error('Use PCA to make predictions with this model type');
  case 'pcr'
    opts  = pcr('options');
    opts.plots   = 'none';
    opts.display = 'off';
    modl = pcr(newx,[],modl,opts);
  case 'pls'
    opts  = pls('options');
    opts.plots   = 'none';
    opts.display = 'off';
    modl = pls(newx,[],modl,opts);
  case {'par', 'parafac'}
    error('Use PARAFAC to make predictions with this model type');
  otherwise
    error(['Modeltype not recognized by ' upper(mfilename) '.'])
  end

  yprdn   = modl.pred{2};
  resn    = modl.ssqresiduals{1};
  tsqn    = modl.tsqs{1};
  scoresn = modl.loads{1,1};

  mx = size(yprdn,1);
  
  if plots
    figure
    plot(1:mx,yprdn,'+-')
    xlabel('Sample Number')
    ylabel('Predicted Value')
    title('New Sample Predictions') 
    pause

    plot(1:mx,resn,'+-r')
    hline(modl.detail.reslim{1},'--g')
    xlabel('Sample Number')
    ylabel('Q Residual')
    title('Q Residuals with 95 Percent Limit')
    pause

    plot(1:mx,tsqn,'+-b')
    hline(modl.detail.tsqlim{1},'--g')
    xlabel('Sample Number')
    ylabel('T^2')
    title('T^2 with 95 Percent Limit')
    pause

    plot(resn,tsqn,'+r')
    hline(modl.detail.tsqlim{1},'--g'), vline(modl.detail.reslim{1},'--g')
    if mx < 50;
      s    = ' '; s = [s(ones(mx,1),:),int2str([1:mx]')];
      text(resn,tsqn,s)
    end
    xlabel('Q Residual for New Sample')
    ylabel('T^2 for New Sample')
    title('T^2 vs Q for with 95 Percent Limits')
  end
  
else
  %--------------------------------------------------------------------
  % Backwards compatibility code from here down
  % (handles non-model structure calls)
  
  if nargin < 6
    error('Error - insufficient number of inputs to MODLPRED')
  end
  if nargin < 7
    p     = 1;
  end
  if nargout > 3
    error('Error - T^2 not calculated for non-structure input')
  end
  bin     = modl; modl = plots; plots = p; p = modl; clear modl
  [mx,nx] = size(newx);
  [mq,nq] = size(q);
  [mw,nw] = size(w);
  that    = zeros(mx,lv);
  yprdn   = zeros(mx,mq);
  if lv>nw
    error(sprintf('Maximum number of latent variables exceeded (Max = %g)',nw));
  end
  x       = newx;
  for ii=1:lv
    that(:,ii) = x*w(:,ii);
    x  = x - that(:,ii)*p(:,ii)';
  end
  for ii=1:lv
    yprdn = yprdn + bin(1,ii)*that(:,ii)*q(:,ii)';
  end
  if plots ~= 0

    figure
    plot(1:mx,yprdn,'+-')
    xlabel('Sample Number')
    ylabel('Predicted Value')
    title('New Sample Predictions') 
    pause

  end
  if nargout>1
    tsqn = newx*w*inv(p'*w);  %tsqn = scoresn for NIPALS pieces input
    resn = (newx-tsqn*p').^2;  
    if nx>1
      resn = sum(resn')';
    end
    if plots~=0

      plot(1:mx,resn,'+-r')
      xlabel('Sample Number')
      ylabel('Q Residual')
      title('Q Residuals')
      pause

    end
  end
end
