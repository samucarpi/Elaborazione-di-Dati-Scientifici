function obj = warningtoggle(obj,state)
%EVRITREE/WARNINGTOGGLE Turn off all warnings here.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<2
  state = 'off';
end

warning(state,'MATLAB:hg:PossibleDeprecatedJavaSetHGProperty')
warning(state,'MATLAB:hg:JavaSetHGProperty')
warning(state,'MATLAB:uitreenode:DeprecatedFunction')
warning(state,'MATLAB:uitree:DeprecatedFunction')
warning(state,'MATLAB:hg:Root')
