function [vari,uniqvari,varip,uniqvarip]=parafdiag(loads,plots);
%PARAFDIAG Calculates the (unique) variance of parafac components.
% 
% [vari,uniqvari,varip,uniqvarip]=parafdiag(loads);
%
% The input loads, is a cell array holding the loadings of the 
% model, 
%
% vari      'variance' of each component
% uniqvari  unique 'variance' of each component
% varip     as vari but in % of 'variance' of model
% uniqvarip as uniqvari but in % of 'variance' of model
%
% Note that mean sums of squares are used rather than variances
% because, there is no offset in the terms unless the data 
% are centered (in which case the mean sums of squares will 
% automatically be equal to variances)
% 
% Note also that percentages are in terms of the model not the data
% so that even though the percentages may sum to 100, the model may 
% still be bad overall. 
%
% Set additional input plots to zero to avoid plot

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

warning off backtrace

model = outerm(loads);

model = model(:);
Z = outerm(loads,0,1);
vari = mean(Z.^2);
for i=1:size(Z,2);
   zi = Z(:,i);
   zr = Z(:,[1:i-1 i+1:end]);
   uniqvari(i) = mean((zi-zr*pinv(zr'*zr)*(zr'*zi)).^2);
end
varip = 100*vari/mean(model.^2);
uniqvarip = 100*uniqvari/mean(model.^2);

if nargin<2 | (nargin==2&plots~=0)
   if size(Z,2)==1
      warning('EVRI:ParafdiagNoUniqueVariance','No plot produced as there is no unique variance for one-component models')
   else
      
   bar([varip;uniqvarip]')
   xlabel('Component number')
   ylabel('Percentage of variation')
   legend({'Total for comp';'Unique for comp'})
   end
end
