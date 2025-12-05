function setscrollpanelsizing(obj,item,mysize)
%ETABLE/SETSCROLLPANELSIZING Set size of scroll panel objects (scroll bars, column/row headers).
% The 'size' input can be 2 element vector [width height] or scalar. If
% scalar then existing value is used for shorter dimension (depending on
% orientation, height for the column and width for row).
%
% ITEMS:
%   colheader    - Column header table.
%   rowheader    - Row header table.
%   hscroll      - Horizontal scroll bar at bottom.
%   vscroll      - Vertical scroll bar at right.

% Copyright © Eigenvector Research, Inc. 2013
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get Java table.
jt = obj.java_table;

if nargin<3
  if strcmp(item,'vscroll') | strcmp(item,'hscroll')
    error('Need size value for item')
  end
  mysize = [];
end

%Get scroll pane, parent of all the items.
sp = evrijavaobjectedt(jt.getParent.getParent);

switch item
  case {'colheader' 'hscroll'}
    if strcmp(item,'colheader')
      viewport = evrijavaobjectedt(sp.getColumnHeader);
    else
      viewport = evrijavaobjectedt(sp.getComponent(2));
    end
    newsz = evrijavaobjectedt(viewport.getPreferredSize);
    if isempty(mysize)
      newsz.height = obj.column_header_height;
    else
      if length(mysize)==1;
        newsz.height = mysize;
      else
        newsz.width = mysize(1);
        newsz.height = mysize(2);
      end
    end
  case {'rowheader' 'vscroll'}
    if strcmp(item,'rowheader')
      viewport = evrijavaobjectedt(sp.getRowHeader);
    else
      viewport = evrijavaobjectedt(sp.getComponent(1));
    end
    newsz = evrijavaobjectedt(viewport.getPreferredSize);
    if isempty(mysize)
      newsz.width = obj.row_header_width;
    else
      if length(mysize)==1;
        newsz.width = mysize;
      else
        newsz.width = mysize(1);
        newsz.height = mysize(2);
      end
    end
end

viewport.setPreferredSize(newsz);
sp.revalidate;
