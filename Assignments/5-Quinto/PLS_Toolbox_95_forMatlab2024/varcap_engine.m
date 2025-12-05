function [ssq,vc,includ1] = varcap_engine(x,c,s)
%VARCAP_ENGINE Variation captured for each factor and variable for 2-way models.
%  Calculates percent variation (sum-of-squares) captured in a 2-way 
%  factor-based model for each factor and variable. Valid models include: PCA,
%  PCR, PLS, CLS and LWR. For non-orthogonal models, VARCAP_ENGINE splits
%  variation into unique variation for each component (1:K) plus a row for
%  common variation and another for total variation captured by the model
%  where K is the number of components.
%
%  INPUTS:
%         x = properly processed and scaled data [MxN, class double].
%         c = corresponding scores [MxK, class double] and
%         s = corresponding loadings [NxK, class double].
%
%  OUTPUTS:
%       ssq = variation captured table[ (K+2)x4, class double].
%             Column 1 is the factor number,
%             Column 2 is the mean(sum-of-squares)=mean(variation),
%             Column 3 is percent variation of the totalvariation in the data, and
%             Column 4 is the cumulative percent variation of the total
%                      variation in the data.
%             Rows 1:K is the UNIQUE variation where the common variation
%                      has been removed.
%             Row K+1 is the common variation, and
%             Row K+2, the last row, is the total variation in the model.
%        vc = matrix of % variance captured [(K+2)xN, class double].
%             Rows 1:K is the percent of UNIQUE variation for each variable
%             on each component where the common variation has been removed.
%             Row K+1 is the percent common variation, and
%             Row K+2, the last row, is the percent total variation
%             captured by the model.
%  include2 = indices of variables for which (vc) could be reliably
%             calculated. Variables with any (vc)<0 or sum(vc(1:K))> the
%             modeled variance were excluded - this can happen due to
%             numerical inaccuracy for variables with low signal-to-noise.
%
%I/O: [ssq,vc,include2] = varcap_engine(x,c,s);

%Copyright Eigenvector Research, Inc. 2020
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

M     = size(x);                     %size of X
K     = size(c,2);                   %number of components
ssx   = sum(x.^2);                   %total sum of squares down the columns
ssm   = sum((c*s').^2);              %total sum of squares of model down the columns
z     = zeros(prod(M),K);            %vec(Khatri-Rao)
for k=1:K
  a         = c(:,k)*s(:,k)';        %Khatri-Rao (temporary variable)
  z(:,k)    = a(:);                  %vec(Khatri-Rao)
end
ssf   = sum(spltvar(z).^2);          %total sum of squares unique by factor
ssc   = max(sum(ssm)-sum(ssf),0);    %total sum of squares common (in model)
ssq   = zeros(K+2,4);                %SSQ table
ssq(1:K,1)  = (1:K)';                % Factor number
ssq(1:K,2)  = ssf'/M(1);             % mean sum-of-squares unique
ssq(K+1,2)  = ssc/M(1);              % mean sum-of-squares common
ssq(K+2,2)  = sum(ssm)/M(1);         % mean sum-of-squares total
ssq(:,3)    = 100*ssq(:,2)*M(1)/sum(ssx);% percent variation captured
ssq(1:K+1,4)  = cumsum(ssq(1:K+1,3));% cum percent variation captured
ssq(K+2,4)  = ssq(K+2,3);

if nargout>1
  a     = max(ssx)/1e8;              %lower threshold to avoid divide by zero
  includ1     = find(ssx<a);
  ssx(includ1)      = a;
  z     = reshape(z,[M,K]);
  vc    = zeros(K+2,M(2));
  for n=1:M(2)
    vc(1:K,n) = sum(spltvar(squeeze(z(:,n,:))).^2);
  end
  for k=1:K                          %vc(1:K,:) cannot be <0
    vc(k,vc(k,:)<0) = 0;
  end
  a           = find(sum(vc(1:K,:))>ssm);
  if ~isempty(a)                     %sum(vc(1:K,:)) cannot be >ssm
    vc(1:K,a) = vc(1:K,a)*spdiag(ssm(a)./sum(vc(1:K,a)));
  end
  includ1     = setdiff(1:M(2),union(includ1,a));
  vc(K+1,:)   = 100*max((ssm-sum(vc(1:K,:)))./ssx,zeros(1,M(2)));
  vc(1:K,:)   = 100*vc(1:K,:)./ssx(ones(K,1),:);
  vc(K+2,:)   = 100*ssm./ssx;
end
