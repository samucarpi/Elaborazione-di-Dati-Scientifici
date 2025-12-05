function out = fieldnames(obj)
%EVRIGUI/FIELDNAMES Returns the valid fieldnames for an EVRIGUI object.
% Generates a context-sensitive list of fields available for an EVRIGUI
% object.
%
%I/O: out = fieldnames(obj)

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%start with a basic list of methods and properties that should always be
%there no matter what the state of the object

out = {};

remove = {};

%get basic top-level fields
out = [out;fieldnames(struct(obj))];

if isvalid(obj);
  %get interface fields
  vm = validmethods(obj.interface);
  out = [out(:);vm(:)];
end

%get methods...
mt = methods(obj);
out = [out(:);mt(:)];

%REMOVE these methods
remove = [remove;{
  'subsasgn'
  'subsref'
  'ne'
  'eq'
  'disp'
  'encodexml'
  'display'
  'evrigui'
  'fieldnames'
  'evriguiversion'
  }];

%always remove these fields
remove{end+1} = 'downgradeinfo';

%remove and sort out
out = setdiff(out,remove);

