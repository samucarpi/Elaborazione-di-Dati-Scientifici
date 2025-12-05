function outstruct = setsubstruct(instruct, fieldstr, icell, val)
%SETSUBSTRUCT Utility for setting contents of nested substructures. 
% Input is original structure 'instruct', string of nested substructure
% 'fieldstr', and a value 'val'. If not empty, 'icell' will act on last field of
% 'filedstr'.
%
%I/O: outstruct = setsubstruct(instruct, fieldstr, {}, val)
%
%See also: ADOPTDEFINITIONS, GETFIELD, GETSUBSTRUCT, ISFIELDCHECK, MAKESUBOPS

%Copyright Eigenvector Research 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 09/19/2005

%TODO: Add indexing support similar to setfield.m.

if ~isstruct(instruct);
  error('Input (instruct) must be a structure');
  return
end

if ~isstr(fieldstr)
  error('Input (fieldstr) must be a string');
  return
end

if ~isfieldcheck(['instruct.' fieldstr], instruct)
  error('Input (fieldstr) can''t be located in the structure (instruct).');
  return
end

%Get list of nested field names.
rem = fieldstr;
fields = '';
while (any(rem))
  [S1, rem] = strtok(rem, '.');
  fields = [fields {S1}];
end

tstructs{1} = instruct;%temporary structures
lgth = length(fields);%length
if lgth>1
  for i = 1:lgth-1
    %Parse through each level and save.
    tstructs = [tstructs {getfield(tstructs{i},fields{i})}];
  end
  %Set the nested value.
  if ~isempty(icell)
    tstructs{end} = setfield(tstructs{end},fields{end},icell,val);
  else
    tstructs{end} = setfield(tstructs{end},fields{end},val);
  end
  for i = lgth:-1:2
    %Reconstruct the structure.
    tstructs{i-1} = setfield(tstructs{i-1},fields{i-1},tstructs{i});
  end
  outstruct = tstructs{1};
elseif lgth ==1
  if ~isempty(icell)
    outstruct = setfield(tstructs{1},fields{1},icell,val);
  else
    outstruct = setfield(tstructs{1},fields{1},val);
  end
end

