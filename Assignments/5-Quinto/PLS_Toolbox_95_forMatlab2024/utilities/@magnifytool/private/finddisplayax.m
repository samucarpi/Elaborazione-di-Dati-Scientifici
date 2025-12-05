function dax = finddisplayax(figh)
%FINDDISPLAYAX Find display axis.
% Use this function in case tag is lost.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dax = findobj(figh,'tag','magnify_display');
if isempty(dax)
  %Try looking for deletefcn in case plotgui got rid of tag.
  axlist = findobj(figh,'type','axes');
  dax = findobj(axlist,'DeleteFcn','%magnify_display');
end
