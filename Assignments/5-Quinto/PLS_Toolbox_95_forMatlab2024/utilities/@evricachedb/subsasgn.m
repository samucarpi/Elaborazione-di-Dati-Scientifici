function obj = subsasgn(obj,index,val)
%EVRICACHEDB/SUBSASGN Subscript assignment reference for evridb.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

feyld = index(1).subs; %Field name.

if length(index)>1 && ~strcmp(feyld,'arguments');
  error(['Index error, can''t assign into field: ' feyld '.'])
else
  switch feyld
    case 'date_source'
      if ismember(val,{'moddate' 'cachedate'})
        obj.date_source = val;
      else
        error('DATE_SOURCE property must be either "moddate" or "cachedate".')
      end
    case 'date_sort'
      if ismember(val,{'ascend' 'descend'})
        obj.date_sort = val;
      else
        error('DATE_SORT property must be either "ascend" or "descend".')
      end
  end
end

setappdata(0,'evri_cache_object',obj)
