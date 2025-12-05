function lbl = legendname(h,lbl)
%LEGENDNAME Assign or retrieve legend tags for object handles.
% Assigns or retrieves appropriate fields of graphical objects identified
% by handles (h) so that they will be labeled correctly by the Matlab
% legend command. If (lbl) is omitted, the legend names for the given
% object(s) will be returned. If (lbl) is supplied, it will be used to set
% the legend names.
%
% Labels (lbl) should be either a single string, which will be used for all
% handles passed in (h) or a cell or multi-row string matrix of appropriate
% length for the number of handles in (h).
%
%I/O: legendname(h,lbl)
%I/O: lbl = legendname(h)

% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS 8/05

if nargin>1;
  %SET legend name for object(s)
  
  if ~iscell(lbl);
    if isempty(lbl);
      lbl = {' '};
    else
      lbl = str2cell(lbl);
    end
  end
  
  if size(lbl)==1 & length(h)>1;
    lbl = lbl(ones(1,length(h)));
  end
  
  for j = 1:min(length(h),length(lbl));
    mylbl = char(lbl{j});
    if isempty(get(h(j),'tag'))
      set(h(j),'tag',mylbl);
    end
    if checkmlversion('>=','7') && isprop(h(j),'DisplayName');
      set(h(j),'DisplayName',mylbl);
    end
  end
  clear lbl
else
  %GET legend name for object(s)
  
  lbl = get(h,'tag');
  if ~iscell(lbl)
    lbl = {lbl};
  end
  for j = 1:length(h);
    if checkmlversion('>=','7') && isprop(h(j),'DisplayName');
      lbl{j} = get(h(j),'DisplayName');
    else
    end
  end
  
end
