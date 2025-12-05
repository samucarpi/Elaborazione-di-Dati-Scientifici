function mydata = getdata(obj,fromtable)
%ETABLE/GETDATA Get data from etable object.
% Pull data from dataset object and add row label column if necessary.
%  If fromtable = 1 then data is retrieved via java table (model), not via data in object. 

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<2
  fromtable = 0;
end

mydata = [];

if fromtable
  %Get data from jtable model.
  jt = obj.java_table;
  m  = jt.getModel;
  tv = m.getDataVector;
  tv = tv.toArray;
  for i = 1:length(tv)
    mydata = [mydata; cell(tv(i).toArray)'];
  end
else
  %Get data and make it into cell array for uitable.
  mydata = obj.data;
end

if isdataset(mydata)
  mydata = mydata.data;
end

%Can't display more than 2 dims.
if ~iscell(mydata) && ndims(mydata)>2
  mydata = mydata(:,:,1);
end

%Needs to be cell so we can trap columns that don't have numeric data if
%that is the case.
if ~iscell(mydata)
  mydata = num2cell(mydata);
end

%Apply any formatting.
if ~isempty(obj.table_format) || ~isempty(obj.column_format)
  fdata = {};
  mycols = size(mydata,2);
  tfm = obj.table_format;%Table format.
  cfm = obj.column_format;%Column format.
  if isempty(tfm)
    %Need some kind of default in case column format isn't available.
    tfm = '%6.4g';
  end
  for i = 1:mycols
    %Get column format if available.
    if ~isempty(cfm) && length(cfm)>=i
      myfrmt = cfm{i};
    else
      myfrmt = tfm;
    end
    
    %If data is string format, just dump it in and continue.
    if strcmp(myfrmt,'%s')
      fdata = [fdata mydata(:,i)];
      continue
    end
    
    try
      emcells = cellfun('isempty',mydata(:,i));
      if any(emcells)
        %If any cells are empty we need to add NaNs to the cell2mat call
        %doesn't truncate the column.
        thisdata = mydata(:,i);
        if any(~emcells) & ischar(mydata{min(find(~emcells)),i})
          thisdata(emcells) = {''};
          fdata = [fdata thisdata];
          continue;
        else
          thisdata(emcells) = {nan};
          thisdata = cell2mat(thisdata);
        end
      elseif all(cellfun('isclass',mydata(:,i),'char'))
        fdata = [fdata mydata(:,i)];
        continue;
      elseif all(cellfun('isclass',mydata(:,i),class(mydata{1,i})))
        thisdata = cell2mat(mydata(:,i));
      else
        fdata = [fdata mydata(:,i)];
        continue;
      end
    catch
      fdata = [fdata mydata(:,i)];
      continue
    end

    if ~isempty(myfrmt)
      if strcmp(myfrmt,'bool')
        bdat = false(size(thisdata,1),1);
        bdat(thisdata) = true;
        thisdata = num2cell(bdat);
      else
        if ~isempty(obj.replace_nan_with)
          thisdata = str2cell(num2str(thisdata,myfrmt));
          thisdata = strrep(thisdata,'NaN',obj.replace_nan_with);
        else
          thisdata = str2cell(num2str(thisdata,myfrmt));
        end
      end
      fdata = [fdata thisdata];
    else
      %Apply no format.
      fdata = [fdata str2cell(num2str(thisdata))];
    end
  end
  mydata = fdata;
end

%Must hand cell to uitable.
if ~iscell(mydata)
  mydata = num2cell(mydata);
end

if strcmp(obj.add_row_labels,'on')
  %Insert column of labels.
  [rhead, rowlbls] = getrowlabels(obj);
  mydata = [rowlbls mydata];
end
