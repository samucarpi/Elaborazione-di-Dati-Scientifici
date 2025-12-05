function obj = findmobj(obj)
%MAGNIFYTOOL/FINDMOBJ Find magnifytool object on a given figure.
% Object is stored in appdata of display axis but there is some (hard to
% confirm) problems with plotgui interactions so use finddisplayax. The
% most up-to-date object should be the one stored in display axis so it
% will take precedence.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Try to find display axis.
dax = finddisplayax(obj.parent_figure);
if isempty(dax)
  %No obj to find.
  return
end

thisobj = getappdata(dax,'magnifytool');
if isempty(thisobj)
  %We're in a bad state with the axis created but no object saved. Try to
  %proceed with object that was passed in.
  return
else
  obj = thisobj;
end
