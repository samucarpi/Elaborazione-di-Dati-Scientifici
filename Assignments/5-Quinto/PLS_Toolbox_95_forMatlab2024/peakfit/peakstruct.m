function peakdef = peakstruct(fun,n)
%PEAKSTRUCT Makes an empty peak definition structure.
%  The output is a standard peak structure, or multi-
%  record peak structure. No input is required.
%
%  OPTIONAL INPUTS:
%    fun = Peak function name {default = 'Gaussian'}. (fun) can
%          be empty ''. Available peak names (shapes) are:
%           'Gaussian', 'Lorentzian', 'PVoigt2', 'PVoigt1', and
%           'GaussianSkew'.
%      n = Number of records to include in (peakdef).
%
%  OUTPUT:
%    peakdef = A structure array with the following fields:
%       name: 'Peak', indentifies (peakdef) as a peak definition
%              structure.
%         id: integer or character peak identifier.
%        fun: peak function name {e.g. = 'Gaussian'}
%      param: 1xP vector of parameters for each peak function
%        fun = 'Gaussian',   param = [height, position, width].
%        fun = 'Lorentzian', param = [height, position, width].
%        fun = 'PVoigt1',  param = [height, position, width, fraction Gaussian],
%               where 0<fraction Gaussian<1.
%        fun = 'PVoigt2',    param = [height, position, width, fraction Gaussian],
%               where 0<fraction Gaussian<1.
%        fun = 'GaussianSkew', param = [height, position, width, skew parameter]
%
%        Descriptions of the functions and parameters are given in the 
%        Algorithm section of the FITPEAKS entry in the reference manual.
%               
%         lb: 1xP vector of lower bounds on (param).
%      penlb: 1xP vector of penalties for lower bounds (e.g. a 0
%               implies that the lower bound is not active).
%         ub: 1xP vector of upper bounds on (param).
%      penub: 1xP vector of penalties for upper bounds (e.g. a 0
%               implies that the lower bound is not active).
%
%Example:
%   peakdef = peakstruct('',3);
%   disp(peakdef(2))
%
%   peakdef(2) = peakstruct('PVoigt2');
%   peakdef(2).id = '2';
%   disp(peakdef(2))
%
%I/O: peakdef = peakstruct(fun,n);
%
%See also: FITPEAKS, PEAKFUNCTION, TESTPEAKDEFS

% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 6/05
%nbg 9/05 added input (n) and changed some of the defaults
%nbg 10/05 allowed for fun to be empty, modified help
%nbg 12/05 added voigt, 12/06 fixed typos in help
%nbg 6/07 removed GaussLoerentz from the help

if nargin<1 | isempty(fun)
  fun         = 'Gaussian';
end
if nargin<2
  n           = 1;
end

peakdef.name  = 'Peak';
peakdef.id    = 1;
peakdef.fun   = fun;

switch lower(fun)
case {'gaussian','lorentzian'}
  peakdef.param = [1 1 1];        %coef, position, spread
  peakdef.lb    = [0 0 1e-4];     %lower bounds on param
  peakdef.penlb = [1 1 1];
  peakdef.ub    = [10 100 100];   %upper bounds on params
  peakdef.penub = [1 1 1];
case {'pvoigt1','pvoigt2','gaussianskew'}
  peakdef.param = [1 1 1 0.5];    %coef, position, spread, fraction gaussian
  peakdef.lb    = [0 0 1e-4 0];   %lower bounds on param
  peakdef.penlb = [1 1 1 1];
  peakdef.ub    = [10 100 100 1]; %upper bounds on params
  peakdef.penub = [1 1 1 1];
otherwise
  error('Input (fun) not recognized.')
end
peakdef.area    = [];
if n>1
  peakdef(1:n)  = peakdef;
  for i1=2:n
    peakdef(i1).id = i1;
  end
end
