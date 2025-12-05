function display(obj)
%ETABLE/DISPLAY Display etable information.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Data size string.
szstr = sprintf('%ix',size(obj.data));
szstr = szstr(1:end-1);

%Column size string.
cszstr = sprintf('%ix',size(obj.column_labels));
cszstr = cszstr(1:end-1);

%Column size string.
rszstr = sprintf('%ix',size(obj.row_labels));
rszstr = rszstr(1:end-1);



dt = class(obj.data);

disp('ETABLE:');
disp('----------');
disp(['    VERSION:        : ' num2str(obj.etableversion)]);
disp(['    TIMESTAP        : ' datestr(obj.ts)]);
disp([' ']);
disp(['    DATA TYPE       : ' dt]);
disp(['    DATA SIZE       : ' szstr]);
disp(['    COLUMN SIZE     : ' cszstr]);
disp(['    ROW SIZE        : ' rszstr]);
disp([' ']);
disp(['    PARENT FIGURE   : ' num2str(double(obj.parent_figure))]);
disp(['    TAG             : ' obj.tag]);

disp('----------');
fnames = fieldnames(obj);
fnames = fnames(~ismember(fnames,{'data' 'etableversion' 'parent_figure' 'ts' 'column_labels' 'row_labels'}));

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
  if length(val)>40
    %Truncate long values.
    val = [val(1:40) '...'];
  end
  ncol = strvcat(ncol, [upper(fnames{i})]);
  vcol = strvcat(vcol, [' : ' val]);
end

for i = 1:length(ncol)
  disp(['      ' ncol(i,:) vcol(i,:)])
end
