function setfont(obj,name,style,size)
%EVRITREE/SETTABLEFONT Change font of tree.
% INPUTS: 
%   obj      : EVRITREE object.
%   name     : '' name of font.
%   style    : {'plain' 'bold' 'italic'} style of font.
%   size     : [scalar] size of font.

% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get tree.
jt = obj.java_tree;

myfont = jt.getFont;

if isempty(name)
  name = char(myfont.getName);
end

mystyle = lookupstyle(myfont,style);

if isempty(size)
  size = double(myfont.getSize);
end

thisfont = java.awt.Font(name, mystyle, size);

jt.setFont(thisfont);

try
  jt.repaint;
end


%----------------------------
function out = lookupstyle(myfont,mystyle)
%Look up style.

out = java.awt.Font.PLAIN;

switch lower(mystyle)
  case ''
    out = myfont.getStyle;
  case 'plain'
    out = java.awt.Font.PLAIN;
  case 'bold'
    out = java.awt.Font.BOLD;
  case 'italic'
    out = java.awt.Font.ITALIC;
end
