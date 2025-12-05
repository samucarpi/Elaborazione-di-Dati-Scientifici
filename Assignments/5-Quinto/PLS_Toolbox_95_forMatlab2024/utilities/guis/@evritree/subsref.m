function val = subsref(varargin)
%EVRITREE/SUBSREF Retrieve fields of EVRITREE objects.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = varargin{1};
index = varargin{2};
feyld = index(1).subs; %Field name.
val = [];

if length(index)>1;
  switch feyld
    otherwise
      error(['Index error, can''t index into field: ' feyld '.'])
  end
  
else
  %Index into data table. Using code from DSO.
  if ~strcmp(index(1).type,'.')
    if strcmp(index(1).type,'()')
      x = obj.data;
      for dim = 1:length(index(1).subs)
        %convert logical to double so we can test for out of range
        if isa(index(1).subs{dim},'logical')
          index(1).subs{dim} = find(index(1).subs{dim});
        end
        %interpret doubles as indexing into data.
        if isa(index(1).subs{dim},'double')
          if max(index(1).subs{dim}) > size(x,dim);
            error('  Invalid subscript')
          end
          if dim <= ndims(x)   %don't try this if we don't have the dim
            inds = index(1).subs{dim};
            x = nindex(x,inds,dim);
          end
        end
      end
      index(1) = [];
      if isempty(index);    %nothing other than indexing into main object? just return reduced object
        val = x;
        return
      end
    end
  else
    switch feyld
      case 'isvalid'
        if ishandle(obj.tree)
          val = true;
        else
          val = false;
        end
      case ''
        
      otherwise
        val = obj.(feyld);
    end
  end
end
