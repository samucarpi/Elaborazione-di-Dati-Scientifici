function out = isclassification(obj)
%EVRIMODEL/ISCLASSIFICATION Is the given model a classification model?
% Returns true if the given model object is a classification model.
% Otherwise, returns false.
%
%I/O: out = isclassification(obj)

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = isfieldcheck(obj.content,'model.classification');
