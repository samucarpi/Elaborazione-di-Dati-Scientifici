function settablealignment(obj,myalign,mycol)
%ETABLE/SETTABLEALIGNMENT Set Horizontal Alignment for column or table.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<3
  mycol = [];
end

%Get Java table.
jt = obj.java_table;

ccount = jt.getColumnCount;

if isempty(mycol)
  %Need to make sure we're using custom renderer for all columns.
  for i = 1:ccount
    setHorizontalAlignment(obj,i,myalign,jt);
  end
else
  setHorizontalAlignment(obj,mycol,myalign,jt);
end

%------------------------------------------
function setHorizontalAlignment(obj,col,myalign,jt)
%Set alignment for given column.

%Don't make change a fatal error.
try
  %Check for cell renderer and set to new renderer if needed.
  mycellrenderer = getcustomcellrenderer(obj,col);
  
  switch myalign
    case 'center'
      thisalign = javax.swing.SwingConstants.CENTER;
    case 'left'
      thisalign = javax.swing.SwingConstants.LEFT;
    case 'right'
      thisalign = javax.swing.SwingConstants.RIGHT;
    otherwise
      thisalign = javax.swing.SwingConstants.CENTER;
  end
  mycellrenderer.setHorizontalAlignment(thisalign)
  try
    jt.repaint;
  end
catch
  %No warning because this will likely be called in a loop.
end
