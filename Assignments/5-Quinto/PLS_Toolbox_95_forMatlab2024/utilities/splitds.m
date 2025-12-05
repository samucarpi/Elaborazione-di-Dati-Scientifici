function dsoutcell = splitds(dsin,field,dim,set)
%SPLITDS Splits a DSO based on unique values in field, mode (dim), and set.
%  
%
%I/O: dsoutcell = splitds(mydso,'class',dim,set);
%I/O: dsoutcell = splitds(mydso,'class',1,3);
%
%See also: COPYDSFIELDS, DATASET, SQUEEZE

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  error('2 inputs required.')
end
if nargin<3
  dim = 1;
end
if nargin<4
  set = 1;
end

dsoutcell = {};

if strcmp(field,'classid')
  field = 'class';
end

try
  %Pull out vector and sort.
  indxstr = substruct('.',field,'{}',{dim set});
  myvec = subsref(dsin,indxstr);
  if isempty(myvec)
    error('Can''t split on empty field.')
  end
  
  if ischar(myvec);
    %Change char array (labels) to cell array.
    myvec = str2cell(myvec);
  end
  
  %Get unique values.
  uniqueval = unique(myvec);
  %Make generic indexing cell.
  myindex         = cell(1,ndims(dsin));
  [myindex{:}]    = deal(':');
  
  for i = 1:length(uniqueval)
    %Add logical to indexing cell where specified by inputs.
    myindex{dim} = ismember(myvec,uniqueval(i));
    %Index into dso.
    dsoutcell{i} = dsin(myindex{:});
  end
catch
  error(['Can''t split by "' field '" field.']);
end


