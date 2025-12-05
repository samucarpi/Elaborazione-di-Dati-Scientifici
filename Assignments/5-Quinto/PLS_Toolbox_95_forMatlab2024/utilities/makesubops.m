function out = makesubops(optsfields)
%MAKESUBOPS make sub-options structure for options GUI.
%  Called in optiondefs subfunction of parent function.
%
%I/O: out = makesubops(optsfields)
%
%See also: GETSUBSTRUCT, RECONOPTS, SETSUBSTRUCT

% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%rsk 10/31/05

fields = {'name' 'tab' 'datatype' 'valid' 'userlevel' 'description'};

out = [];
temp = [];
for i = 1:size(optsfields,1)
  for j = 1:6
    %temp = setfield(temp, fields{j}, optsfields{i,j});
    out = setfield(out, {i,1},fields{j}, optsfields{i,j});
  end
  %out = setfield(out, {i,1},optsfields{i,1}, temp);
end
