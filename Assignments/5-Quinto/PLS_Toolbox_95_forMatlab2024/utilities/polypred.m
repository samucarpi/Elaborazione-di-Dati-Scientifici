function [ypred,scores] = polypred(x,b,p,q,w,lv)
%POLYPRED Prediction with POLYPLS models.
%  The inputs are the matrix of predictor variables (x),
%  the POLYPLS model inner-relation coefficients (b),
%  the x-block loadings (p), the y-block loadings (q),
%  the x-block weights (w), and number of latent
%  variables to use for prediction (lv).
%
%  Outputs are the y predictions (ypred) and the scores
%  for each sample in x (scores).
%
%  Note: It is important that the scaling of the new
%  data x is the same as that used to create the model
%  parameters in POLYPLS.
%
%I/O: [ypred,scores] = polypred(x,b,p,q,w,lv);
%
%See also: LWRXY, PLS, POLYPLS

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified BMW 11/93
%Checked on MATLAB 5 by BMW

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear ypred; evriio(mfilename,varargin{1},options); else; ypred = evriio(mfilename,varargin{1},options); end
  return;
end

[mx,nx] = size(x);
[mq,nq] = size(q);
[mw,nw] = size(w);
that = zeros(mx,lv);
ypred = zeros(mx,mq);
if lv > nw
  s = sprintf('Maximum number of latent variables exceeded (Max = %g)',nw);
  error(s)
end
%  Start by calculating all the xblock scores
for i = 1:lv
  that(:,i) = x*w(:,i);
  x = x - that(:,i)*p(:,i)';
end
%  Use the xblock scores and the b to build up the prediction
for i = 1:lv
  ypred = ypred + (polyval(b(:,i),that(:,i)))*q(:,i)';
end

scores = that;
