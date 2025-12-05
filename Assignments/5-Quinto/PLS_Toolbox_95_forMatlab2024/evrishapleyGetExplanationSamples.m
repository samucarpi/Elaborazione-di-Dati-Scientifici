function evrishapleyGetExplanationSamples(varargin)
%EVRISHAPLEYGETEXPLANATIONSAMPLES Subfunction to obtain explanation samples.
%  Strictly used internally by shapleygui.mlapp to obtain the explantion 
%  samples for evrishapley.

%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

h = varargin{1};
if ~isempty(h)
  if ishandle(h)
    set(h,'Visible','off');
  end
end
end

