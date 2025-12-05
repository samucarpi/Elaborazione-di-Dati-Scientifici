function [Xlda] = lda_engine_apply(model,X)
%lda_engine_apply applies a Linear Discriminant Analysis (LDA) model.
%
%  INPUTS:
%   X(m,n)  = matrix of m samples x n variable
%  OUTPUTS: 
%   Xlda    = scores. X projected into the LDA subspace

% Project data onto LDA subspace

Xlda = X * model.w;

end
