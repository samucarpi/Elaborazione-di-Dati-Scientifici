function disp(item,varargin)
%EVRIGUI_fcn/DISP Display command for EVRIGUI_fcn object.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = {
  sprintf('    interface = ')
  };
list = validmethods(item);
for j=1:length(list)
  out{end+1} =  sprintf('         .%s',list{j});
end

disp(char(out));
