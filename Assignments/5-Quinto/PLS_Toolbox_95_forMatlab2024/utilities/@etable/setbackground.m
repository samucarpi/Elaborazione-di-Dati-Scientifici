function setbackground(obj,target,location,newcolor)
%ETABLE/SETBACKGROUND Change background color of table.
% INPUTS:
%   obj      : ETABLE object.
%   target   : {'cell' 'row' 'column' 'table'} target of font change.
%   location : [] Empty if target = 'table', scalar if 'row' or 'column'
%              and 2 elements if 'cell'.
%   name     : '' name of font.
%   newcolor : '' string of common color or RGB vector or RGB(nx3) for each row or coloumn.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%NOTE: getcustomcellrenderer takes a long time so try to minimize calls to
%it.

%Get Java table.
jt = obj.java_table;

if nargin<4
  newcolor = uisetcolor;
end

if ischar(newcolor)
  newcolor = colorlookup(newcolor);
end

ccell = 0;
if size(newcolor,1)>1
  ccell = 1;
  for i = 1:size(newcolor,1)
    newc(i) = java.awt.Color(newcolor(i,1), newcolor(i,2), newcolor(i,3));
  end
else
  newc = java.awt.Color(newcolor(1), newcolor(2), newcolor(3));%new color
end

%Don't make color change a fatal error.
try
  switch target
    case 'table'
      %Renderer controls all coloring so have to loop through it.
      ccount = jt.getColumnCount;
      for i = 1:ccount
        setbackground(obj,'column',i,newcolor)
      end
    case {'column' 'columns'}
      mycellrenderer = getcustomcellrenderer(obj,location);
      rcount = jt.getRowCount;
      for i = 1:rcount
        if ccell
          mycellrenderer.setCellBgColor(i-1,location-1,newc(i));
        else
          mycellrenderer.setCellBgColor(i-1,location-1,newc);
        end
      end
    case {'row' 'rows'}
      ccount = jt.getColumnCount;
      for i = 1:ccount
        mycellrenderer = getcustomcellrenderer(obj,i);%This will be slow.
        if ccell
          mycellrenderer.setCellBgColor(location-1,i-1,newc(i));
        else
          mycellrenderer.setCellBgColor(location-1,i-1,newc);
        end
      end
    case {'cell' 'cells'}
      %NOTE: getcustomcellrenderer takes a long time so might be worth
      %adding code here to allow multiplw cells be colored. 
      mycellrenderer = getcustomcellrenderer(obj,location(2));
      mycellrenderer.setCellBgColor(location(1)-1,location(2)-1,newc);
  end
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

%For reference:
%clr = jt.getSelectionBackground;
%jt.setSelectionBackground(clr.GREEN)
