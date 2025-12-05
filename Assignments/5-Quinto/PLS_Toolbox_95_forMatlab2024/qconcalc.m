function qcon = qconcalc(newx,model)
%QCONCALC Calculate Q residuals contributions for predictions on a model.
% Inputs are the new data (newx) and the 2-way PCA or regression model for
% which Q contributions should be calculated (model). 
%
% If the model was created using the "blockdetails = 'all'" option in PLS
% or PCA (or whatever function was used to create the model), then (newx)
% can be omitted to retrieve the Q contributions for the calibration data.
% Note that this option is not the default so it is unlikely this call will
% work unless you have specifically created the model with the appropriate
% call.
%
%I/O: qcon = qconcalc(newx,model);
%I/O: qcon = qconcalc(model);  %requires that model contains residuals
%
%See also: DATAHAT, PCA, PCR, PLS, TCONCALC

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS

if nargin == 0; newx = 'io'; end
varargin{1} = newx;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear qcon; evriio(mfilename,varargin{1},options); else; qcon = evriio(mfilename,varargin{1},options); end
  return; 
end

%if they didn't pass data, look if there is sufficient info in the model to
%use that... (will probably require that the user used "blockdetails=all"
%when the model was created)
if nargin<2 & isfieldcheck('model.detail.res',newx)
  model = newx;
  qcon = model.detail.res{1};
  if ~isempty(qcon)
    return;  %use residuals in model
  else
    %residuals were empty? look for data
    if isfieldcheck('model.detail.data',model) & ~isempty(model.detail.data{1})
      newx = model.detail.data{1};
    else
      error('Insufficient detail in model - Original calibration data or data for new samples must be passed along with this model.');
    end
  end
end

%got the model and the data, do the calculation - this is all done in
%datahat...
[xhat,qcon] = datahat(model,newx);
