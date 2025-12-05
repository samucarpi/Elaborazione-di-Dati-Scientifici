
%MAKEGRID Make full factorial grid of input 1xN cell arrays.
%   Create a full factorial grid of all input 1xN cell arrays. Each input
%   argument is to be arranged as a cell array, where each cell array has
%   unique values that are to be used and varied in the grid. The size of
%   the final grid will be MxN, where M is the product of the the size of
%   each of the input cell arrays, and N is the number of cell arrays.
%
%   Example:
%    >> a = {'I' 'You'}         % size = 2
%    >> b = {'hate' 'love'}     % size = 2
%    >> c = {'MATLAB' 'Python'} % size = 2
%    >> d = {'times'}           % size = 1
%    >> e = {10 50}             % size = 2
%    >> thegrid = makegrid(a,b,c,d,e);
%    >> thegrid =
%      16×5 cell array
%
%        {'I'  }    {'hate'}    {'MATLAB'}    {'times'}    {[10]}
%        {'You'}    {'hate'}    {'MATLAB'}    {'times'}    {[10]}
%        {'I'  }    {'love'}    {'MATLAB'}    {'times'}    {[10]}
%        {'You'}    {'love'}    {'MATLAB'}    {'times'}    {[10]}
%        {'I'  }    {'hate'}    {'Python'}    {'times'}    {[10]}
%        {'You'}    {'hate'}    {'Python'}    {'times'}    {[10]}
%        {'I'  }    {'love'}    {'Python'}    {'times'}    {[10]}
%        {'You'}    {'love'}    {'Python'}    {'times'}    {[10]}
%        {'I'  }    {'hate'}    {'MATLAB'}    {'times'}    {[50]}
%        {'You'}    {'hate'}    {'MATLAB'}    {'times'}    {[50]}
%        {'I'  }    {'love'}    {'MATLAB'}    {'times'}    {[50]}
%        {'You'}    {'love'}    {'MATLAB'}    {'times'}    {[50]}
%        {'I'  }    {'hate'}    {'Python'}    {'times'}    {[50]}
%        {'You'}    {'hate'}    {'Python'}    {'times'}    {[50]}
%        {'I'  }    {'love'}    {'Python'}    {'times'}    {[50]}
%        {'You'}    {'love'}    {'Python'}    {'times'}    {[50]}
%
%  INPUTS:
%        varargin = cell arrays of elements to be used throughout the grid.
%
%  OUTPUT:
%        thegrid  = cell array of full factorial grid.
%
% I/O: [thegrid] = makegrid(a,b,c,d,e)  % variables a,b,c,d,e from example above
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
