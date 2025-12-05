
%PRETTYPRINTPP Display preprocessing structure description with commas.
%   Print out the description for a preprocessing structure. This will
%   comma-delimit the description if the preprocessing structure size is
%   greater than 1. One also has the option to display the description
%   without the parameters that go into a parameters using the 'clean'
%   argument (eg, 'savgol (window=15, order=2), mean center' VS.
%   'savgol, mean center'.
%
%  INPUTS:
%        ppstruct  = struct for preprocess function.
%
% OPTIONAL INPUT:
%        terse     = char indicating level of terseness. If terse='clean',
%                    then no parameters will be displayed.
%
%  OUTPUT:
%        desc      = parsed preprocessing description.
%
% I/O: [desc] = prettyprintpp(ppstruct)
% I/O: [desc] = prettyprintpp(ppstruct,'clean')
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
