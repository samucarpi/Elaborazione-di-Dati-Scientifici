function display(obj)
%EVRITREE/DISPLAY Display evritree information.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

disp('EVRITREE:');
disp('----------');
disp(['    VERSION:        : ' num2str(obj.evritreeversion)]);
disp(['    TIMESTAMP       : ' datestr(obj.time_stamp)]);
disp([' ']);
disp(['    PARENT FIGURE   : ' num2str(double(obj.parent_figure))]);
disp(['    TAG             : ' obj.tag]);
disp('----------');

fnames = fieldnames(obj);
fnames = fnames(~ismember(fnames,{'tree_data' 'evritreeversion' 'parent_figure' 'ts'}));

ncol = '';
vcol = '';

for i = 1:length(fnames)
  val = obj.(fnames{i});
  if strcmpi(class(val),'matlab.ui.container.internal.JavaWrapper')
    continue
  end
  if iscell(val)
    if isempty(val)
      val = '';
    else
      val = val{1};
    end
  end
  if isnumeric(val)
    val = num2str(val);
  end
  if ishandle(val)
    val = char(val.toString);
  end
  if strcmp(class(val),'function_handle')
    val = ['@' char(val)];
  end
  if length(val)>60
    %Truncate long values.
    val = [val(1:60) '...'];
  end
  ncol = strvcat(ncol, [upper(fnames{i})]);
  vcol = strvcat(vcol, [' : ' val]);
end

for i = 1:length(ncol)
  disp(['      ' ncol(i,:) vcol(i,:)])
end
