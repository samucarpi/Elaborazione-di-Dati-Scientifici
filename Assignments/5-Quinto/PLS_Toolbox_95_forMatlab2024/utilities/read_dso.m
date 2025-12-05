function [values,root_name] = read_dso(filename);
%READ_DSO Reads a single dataset object from a MAT file.
%INPUT:
%    filename : MAT file to be read
%OUTPUT:
%      values : the first located DSO in the file
%   root_name : the original name of the variable in the MAT file
%
%I/O: [values,root_name] = read_dso(filename)

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

allvars    = load(filename);
root_names = fieldnames(allvars);

root_name = [];
values    = [];
for j=1:length(root_names);
  onevar = getfield(allvars,root_names{j});
  if isa(onevar,'dataset');   %take first dataset object we find
    root_name = root_names{j};
    values    = onevar;
    break
  end
end
