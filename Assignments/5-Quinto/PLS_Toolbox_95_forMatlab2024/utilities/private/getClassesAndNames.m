function [classes, classids] = getClassesAndNames(model)
% identify the classes when input a classifier model or pred structure.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isempty(model)
  error('Input model is empty')
elseif ~ismodel(model)
  error('Input is not a model')
end
switch lower(model.modeltype)
  case {'knn' 'plsda' 'plsda_pred' 'svmda' 'knn_pred' 'svmda_pred' ...
      'simca' 'simca_pred' 'xgbda' 'xgbda_pred' 'annda' 'annda_pred' ...
      'lregda' 'lregda_pred' 'anndlda' 'anndlda_pred' 'lda' 'lda_pred'}
    classids = model.classification.classids;
    classes  = model.classification.classnums;
  otherwise
    error('Cannot operate on this model type ("%s")',model.modeltype);
end

tf = ismember(0, classes);
classes1 = [];
classids1 = {};
if tf
  icount=0;
  for ic=1:length(classes)
    if classes(ic)~=0                % skip class 0
      icount = icount+1;
      classids1{icount} = classids{ic};
      classes1(icount) = classes(ic);
    end
  end
  classes = classes1;
  classids = classids1;
end
