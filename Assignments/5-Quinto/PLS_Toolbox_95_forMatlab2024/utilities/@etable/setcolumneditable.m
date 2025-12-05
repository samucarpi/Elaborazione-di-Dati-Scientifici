function setcolumneditable(obj,mycolumn,val)
%ETABLE/SETCOLUMNEDITABLE Set column editable. 
% Input 'val' is boolean.
%

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%NOTE: Need to use Matlab table to do this. Not sure if this works on all
%platforms/version so wrap in try/catch. Requires 

ht = obj.table;

try
  ht.setEditable(mycolumn,val)
catch
  warning('EVRI:TabelSetColumnEditable','Could not set editable value for column.')
end

%Old code to set column look to be disabled but could actually disable
%without overriding table model isCellEditable method.
% jt = obj.java_table;
% mycellrenderer = getcustomcellrenderer(obj,mycolumn);
% 
% if strcmp(val,'on')
%   mycellrenderer.setDisabled(false);%Need to tell custom renderer to remove this column from list, this is probably a bug in render that needs to get fixed.
%   mycellrenderer.setEnabled(true);
% else
%   mycellrenderer.setDisabled(true);
% end
% 
% jt.repaint

