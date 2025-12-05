function varargout = sortTable_callback(hObj,ev,fh,mytag,type)
% ETABLE/SORTTABLE_CALLBACK Sort table from context menu.
% Use data stored in object, don't pull directly from jtable. This is more
% consistent with how we've implemented sorting in our guis and if data is
% pulled directly from object (and not from table which is harder to do)
% then object sorting will always match with what's displayed.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%FIXME: Menu is available on rows so need to fix.

%Get up-to-date copy of object since the object passed is a from function
%handle.
obj = gettobj(fh,mytag);
%Because some callbacks won't get added until table is rendered add them
%again here so righ-click will select the column under the right-click.
addcallbacks(obj);

%Get row.
jt = obj.java_table;
mycol = jt.getSelectedColumn+1;
if isempty(mycol) || mycol<1
  return
end

mydata = obj.data;
coldata = [];

if isdataset(mydata)
  coldata = mydata.data(:,mycol);
elseif iscell(mydata)
  %Get cell column.
  coldata = mydata(:,mycol);
  eidx    = ~cellfun('isempty',coldata);
  cidx    = find(eidx);
  %Figure out datatype.
  mydt = {''};
  if isnumeric(coldata{cidx(1)})|islogical(coldata{cidx(1)});
    mydt = {0};
  end
  tempcol = repmat(mydt,size(mydata,1),1);
  tempcol(eidx) = coldata(eidx);
  coldata = tempcol;
  clear('tempcol');
  if mydt{1}==0
    coldata = [coldata{:}]';
  end
else
  coldata = mydata(:,mycol);
end

[junk,idx]=sort(coldata);
if strcmp(type,'descend')
  idx = flipud(idx);
end

%Save sorted data into object.
obj.data = mydata(idx,:);
%Update data in table.
updatetable(obj);
%Save object.
setobj(obj);

%Run post sort callback.
if ~isempty(obj.post_sort_callback)
  myfcn = obj.post_sort_callback;
  %Run additional callbacks if needed.
  myvars = getmyvars(myfcn);
  if iscell(myfcn)
    myfcn = myfcn{1};
  end
  if ~isempty(myfcn)
    feval(myfcn,myvars{:});
  end
end

%---------------------------
function myvars = getmyvars(myfcn)
%Get function from object.

myvars = {};
if length(myfcn)>1
  myvars = myfcn(2:end);
  myfcn = myfcn{1};
end

