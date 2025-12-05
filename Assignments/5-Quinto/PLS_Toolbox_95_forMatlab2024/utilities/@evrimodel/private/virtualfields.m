function virtual = virtualfields(model)
%VIRTUALFIELDS List of virtual fields which are simple indexes

%Copyright (c) Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent intv

if isempty(intv)
  v = {
    'scores'    substruct('.', 'loads', '{}', {1 1})
    'loadings'  substruct('.', 'loads', '{}', {2 1});
    'yhat'      substruct('.', 'pred', '{}', {2});
    'x'         substruct('.', 'detail', '.', 'data', '{}', {1});
    'y'         substruct('.', 'detail', '.', 'data', '{}', {2});
    };
  intv = v;
else
  v = intv;
end
  
%NOTE:  'xhat'         substruct('.', 'pred', '{}', {1})
% was moved manually into subsref and subasgn because it calls datahat if
% no xhat present in model
%NOTE:
%    't2'        substruct('.', 'tsqs', '{}', {1});
%    'q'         substruct('.', 'ssqresiduals', '{}', {1});
% were moved into subsref so that we can do reduced stats if requested

if strcmpi(model.content.modeltype,'batchmaturity') | strcmpi(model.content.modeltype,'batchmaturity_pred')
  v{ismember(v(:,1),{'scores'}),2} = substruct('.', 'submodelpca', '.', 'content', '.', 'loads', '{}', {1 1});
end

%convert from structure into cell array with fieldnames in first column and
%substruct info in second (the way all the callers are expecting this to be output
virtual = v;

