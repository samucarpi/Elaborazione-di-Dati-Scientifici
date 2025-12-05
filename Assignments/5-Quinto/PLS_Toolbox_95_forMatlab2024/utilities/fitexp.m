function [error,newbeta]=fitexp(param,beta,varargin)
%FITEXP Calculates an exponential curve and its fit to points.
%  FITEXP is an example on a userdefined function for fitting MCR,
%  PARAFAC etc. with functional constraints on the columns of the loading
%  matrices. The function must have output as here: the sum of squares of
%  fit to input beta and the actual curve given input parameters. The
%  inputs must be the parameters of the function as first input (vector)
%  and a vector that the calculated curve will be compared to.
%
%  INPUTS: 
%        param  = vector of parameters for the function
%        beta   = a vector that is used to calculate the fit of the
%                 functional curve.
%
%  OPTIONAL INPUT:
%   additional  = if needed, a set of extra parameters can be given in a
%                 cell or struct which will be the third input.
%
%  OUTPUT:
%     error     = sum of squares of (newbeta-beta)
%     newbeta   = the curve calculated using the input parameters
%
%I/O: [error,newbeta]=fitexp(param,beta);
%
%See also: CONSTRAINFIT

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


id = [1:length(beta)]'/length(beta);
newbeta = param(1)*exp(id*param(2));
error = sum( (beta(:) - newbeta(:)).^2);

% add error for loading vectors not being norm one in order to help keep
% the scale reasonable

error = error*max(norm(newbeta),1);
