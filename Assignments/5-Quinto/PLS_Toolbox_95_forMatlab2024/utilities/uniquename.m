function name = uniquename(obj,type)
%UNIQUENAME Returns a unique string which describes the given object only.
% The name returned by this function is a unique identifier for the given
% object. For example, for a dataset object, this is the uniqueID and the
% moddate date stamp. For a model, this is the model type, author, and
% timestamp.
%
% Optional input (type) specifies the type of object ('data', 'model',
% 'prediction') being passed. If not specified, the object's type is
% inferred from the contents.
%
%I/O: name = uniquename(obj,type)
%
%See also: ENCODEDATE, EVRIVARNAME

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  if isdataset(obj)
    type = 'data';
  elseif ismodel(obj)
    if isempty(findstr(lower(obj.modeltype),'_pred'))
      type = 'model';
    else
      type = 'prediction';
    end
  else
    type = 'unknown';
  end
end

switch type
  case {'model' 'prediction'}
    %it is a model or a prediction
    switch type
      case 'prediction'
        if ~ismodel(obj)
          name = 'unknown_pred';
        else
          name = lower([obj.modeltype]);
        end

      case 'model'
        if ~ismodel(obj)
          name = 'unknown_model';
        else
          name = lower([obj.modeltype '_model']);
        end

    end
    if isfield(obj,'author')
      name = [name obj.author];
    end
    if isfield(obj,'time');
      %use date in model to determine time
      name = lower([name '_' encodedate(obj.time)]);
    else
      %no date in model, assume it is "now"
      name = lower([name '_' encodedate]);
    end

  case 'data'
    %most likely a DSO datasource block
    if all(obj.size==0)
      %empty DSO? return empty name
      name = '';
      return
    elseif isdataset(obj) | isfield(obj,'uniqueid')
      name = [obj.uniqueid '_' encodedate(obj.moddate)];
    elseif ~isempty(obj.name)
      name = [obj.name '_' encodedate(obj.moddate)];
    else
      name = ['unnamed' '_' encodedate(obj.moddate)];
    end

  otherwise
    %something else we can't figure out...
    name = ['unnamed' '_' encodedate];

end

