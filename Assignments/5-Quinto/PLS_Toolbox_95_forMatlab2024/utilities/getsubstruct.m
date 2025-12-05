function outstruct = getsubstruct(instruct, fieldstr, icell)
%GETSUBSTRUCT Utility for returning contents of nested substructures. 
% Input is original structure 'instruct', and string of nested substructure
% 'fieldstr'. Input icell is optional and will only act on last field in
% 'fieldstr'.
%
%I/O: outstruct = getsubstruct(instruct, fieldstr)
%I/O: outstruct = getsubstruct(instruct, fieldstr, icell)
%
%See also: ADOPTDEFINITIONS, GETFIELD, ISFIELDCHECK, MAKESUBOPS, SETSUBSTRUCT

%Copyright Eigenvector Research 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 09/19/2005

%TODO: Add indexing support similar to getfield.m.

if nargin < 2
  error('GETSUBSTRUCT: needs at least 2 inputs.')
elseif nargin == 2
  icell = {};
end

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

outstruct = instruct;

for i = 1:length(fields)-1
  outstruct = getfield(outstruct,fields{i});
end

if ~isempty(icell)
  outstruct = getfield(outstruct,fields{end},icell);
else
  outstruct = getfield(outstruct,fields{end});
end
