function D = cooksd(model)
%COOKSD Calculates Cooks Distance based on regression model.
%  Cooks distance measures how much the model would change if the sample
%  was left out. Only PLS models allowed currently.
%
%      Distance > 0.5, ith sample is worthy of further 
%                      investigation as it may be influential.
%
%      Distance > 1,   ith sample is quite likely to be influential.
%  Inputs:
%    model : a standard model object for regression analysis (PLS only)
% Outputs:
%        D : Cook's distance vector (or matrix for multivariate y)
%
%I/O: Distance = cooksd(model); Only PLS models allowed currently
%
%See also: FIGMERIT, LEVERAG

% Copyright © Eigenvector Research, Inc. 2016
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%% What it is 
% In a normal influence plot, it can be difficult to assess which samples
% are actual influential. Which samples would change the model if they  
% were not there?
% 
% Cooks distance measures how much all of the fitted values change when the
% ith observation is deleted. A data point having a large Di indicates that 
% the data point strongly influences the fitted values 
% See: 
% http://onlinecourses.science.psu.edu/stat501/node/340
% http://data.library.virginia.edu/diagnostic-plots

if nargin==0; model = 'io'; end

if ischar(model);
  options = [];
  if nargout==0; evriio(mfilename,model,options); else; D = evriio(mfilename,model,options); end
  return; 
end

if ~ismember(lower(model.modeltype), {'pls', 'pcr', 'pls_pred', 'pcr_pred'})
  error('Only PCR, PLS models allowed currently.')
end

F=model.ncomp;
s2=model.detail.res{2}.^2;
lev=model.detail.leverage;

% See https://en.wikipedia.org/wiki/Cook%27s_distance
% The following for loop can be replaced with one line once Solo is built
% with Matlab R2015a or later and 'omitnan' parameter is available for mean
% D = (s2./(F*mean(s2, 'omitnan'))).*(lev./((1-lev).^2));
D = nan(size(s2));
for i=1:size(s2,2)
  s2i = s2(:,i);
  s2i = s2i(~isnan(s2i));
  D(:,i) = s2(:,i)./(F*mean(s2i)).*(lev./((1-lev).^2));
end

