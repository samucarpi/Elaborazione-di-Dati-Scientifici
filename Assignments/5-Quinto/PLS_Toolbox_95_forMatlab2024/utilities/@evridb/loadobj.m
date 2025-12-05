function new_obj = loadobj(old_obj)
%EVRIDB/LOADOBJ - Load database object.

% Copyright © Eigenvector Research, Inc. 2024
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%NOTE: When swtich to using classdef() syntax, loadobj is always called
%with input as a struct. EVRIDB has makeFromStruct() sub function.

this_version = old_obj.evridb_version;
new_obj = old_obj;

if this_version<=2.0
  %Changes for v2
  %  .persistent field name changed to .keep_persistent
  %  Added uniqueid and date fields.
  %
  % Not sure if old version will ever come in as
  % object so check for both a property or struct field.
  new_obj.keep_persistent = new_obj.persistent;
  new_obj = rmfield(new_obj,'persistent');

  new_obj.uniqueid = char(java.util.UUID.randomUUID());
  new_obj.date = datevec(datetime);

  if isstruct(new_obj)
    new_obj = evridb(new_obj);
  else
    new_obj.evridb_version = 2.0;
  end

end

end

