function [result] = isclassification(args)

%Copyright Eigenvector Research, Inc. 2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

result = false;
if isfield(args, 'xgbtype')
  switch lower(args.xgbtype)
    case {'xgbc'}
      result = true;
    case {'xgbr'}
      result = false;
    otherwise
      %unsupported xgb type;
  end
end