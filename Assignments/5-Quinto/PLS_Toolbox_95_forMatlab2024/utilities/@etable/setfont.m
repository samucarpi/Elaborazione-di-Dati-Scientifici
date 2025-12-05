function setfont(obj,target,location,name,style,size)
%ETABLE/SETTABLEFONT Change font of table.
% INPUTS: 
%   obj      : ETABLE object.
%   target   : {'cell' 'row' 'column' 'table'} target of font change.
%   location : [] Empty if target = 'table', scalar if 'row' or 'column' 
%              and 2 elements if 'cell'.
%   name     : '' name of font.
%   style    : {'plain' 'bold' 'italic'} style of font.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get tables.
jt = obj.java_table;

myfont = jt.getFont;

if isempty(name)
  name = char(myfont.getName);
end

mystyle = lookupstyle(myfont,style);

if isempty(size)
  size = double(myfont.getSize);
end

thisfont = java.awt.Font(name, mystyle, size);

switch target
  case 'table'
    ccount = jt.getColumnCount;
    for i = 1:ccount
      setfont(obj,'column',i,name,style,size)
    end
  case 'column'
    mycellrenderer = getcustomcellrenderer(obj,location);
    rcount = jt.getRowCount;
    for i = 1:rcount
      mycellrenderer.setCellFont(i-1,location-1,thisfont);
    end
  case 'row'
    ccount = jt.getColumnCount;
    for i = 1:ccount
      mycellrenderer = getcustomcellrenderer(obj,i);
      mycellrenderer.setCellFont(location-1,i-1,thisfont);
    end
  case 'cell'
    mycellrenderer = getcustomcellrenderer(obj,location(2));
    mycellrenderer.setCellFont(location(1)-1,location(2)-1,thisfont);
end

try
  jt.repaint;
end
%Can't set font on column header as far as I know.

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
