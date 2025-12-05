function setbackground(obj,newcolor)
%EVRITREE/SETBACKGROUND Change background color of tree.
% INPUTS:
%   obj      : EVRITREE object.
%   newcolor : '' string of common color or RGB vector.

% Copyright © Eigenvector Research, Inc. 2013
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get Java table.
jt = obj.java_tree;

if nargin<2
  newcolor = uisetcolor;
end

if ischar(newcolor)
  newcolor = colorlookup(newcolor);
end

newc = java.awt.Color(newcolor(1), newcolor(2), newcolor(3));%new color

%Don't make color change a fatal error.
try
  jt.setBackground(newc)
end
try
  jt.repaint;
end

%------------------------------------------
function out = colorlookup(in)
%COLORLOOKUP - Look up color from table.

ctbl = {'black'       [0 0 0];
  'white'       [1 1 1];
  'red'         [1 0 0];
  'green'       [0 1 0];
  'blue'        [0 0 1];
  'yellow'      [1 1 0];
  'magenta'     [1 0 1];
  'cyan'        [0 1 1];
  'gray'        [.5 .5 .5];
  'light gray'  [.8 .8 .8];
  'dark red'    [.5 0 0]};

idx = ismember(ctbl(:,1),in);
out = ctbl{idx,2};

if isempty(out)
  out = [1 1 1];
end
