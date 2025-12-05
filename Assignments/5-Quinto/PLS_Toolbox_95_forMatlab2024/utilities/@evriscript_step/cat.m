function chain = cat(dim,obj,varargin)
%EVRISCRIPT_STEP/CAT

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% if nargin==2
%   %do NOT create a chain if only one item
%   chain = obj;
% else
  %more than one object, create a chain
  chain = evriscript;
  chain = add(chain,obj);
  for j=1:length(varargin)
    chain = add(chain,varargin{j});
  end
% end
