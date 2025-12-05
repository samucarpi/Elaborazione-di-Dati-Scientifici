function obj = warningtoggle(obj,state)
%ETABLE/WARNINGTOGGLE Turn off all warnings here.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<2
  state = 'off';
end

%Turn off warning that is triggered by MouseClickedCallback.
warning(state,'MATLAB:hg:JavaSetHGProperty')
