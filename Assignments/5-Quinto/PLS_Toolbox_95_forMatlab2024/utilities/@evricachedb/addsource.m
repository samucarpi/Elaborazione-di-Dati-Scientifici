function val = addsource(obj,item,cacheID)
%EVRICACHEDB/ADDSOURCE Add source data for a cache item.
% 

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%NOTE: This could be made generic to deal with any structure.

val = [];
dbo = obj.dbobject;

sourceitems = checksource(obj,item);%Source table.
myatts = fieldnames(item.source);

for i = 1:size(myatts,1)
  sid = sourceitems{ismember(sourceitems(:,2),myatts{i}),1};
  myval = item.source.(myatts{i});
  if isempty(myval)
    continue
  end
  
  if isnumeric(myval)
    if numel(myval)==1
      if isnan(myval)
        val = dbo.runquery(['INSERT INTO evri_cache_db.sourceData (cacheID,sourceAttributesID,valNum) VALUES (' num2str(cacheID) ',' num2str(sid) ',null)']);
      else
        val = dbo.runquery(['INSERT INTO evri_cache_db.sourceData (cacheID,sourceAttributesID,valNum) VALUES (' num2str(cacheID) ',' num2str(sid) ',' sprintf('%0.14f',myval) ')']);
      end
      %val = dbo.runquery(['INSERT INTO evri_cache_db.sourceData (cacheID,sourceAttributesID,valNum) VALUES (' num2str(cacheID) ',' num2str(sid) ',' sprintf('%0.14f',myval) ')']);
    elseif isvector(myval)
      sqlstr = ['INSERT INTO evri_cache_db.sourceData (cacheID,sourceAttributesID,valNum) VALUES (?,?,?)'];
      if size(myval,2)>1
        myval = myval';
      end
      pdata = num2cell([repmat(cacheID,length(myval),1) repmat(sid,length(myval),1) myval]);
      val = jpreparedstatement(dbo,sqlstr,pdata,{'Int','Int','Double'});
    else
      %Can't handle matrix in fast form so use xml.
      myval = encodexml(myval,myatts{i});
      if length(myval)>3000
        myval = '';
      end
      sqlstr = ['INSERT INTO evri_cache_db.sourceData (cacheID,sourceAttributesID,valChar) VALUES (?,?,?)'];
      val = jpreparedstatement(dbo,sqlstr,{cacheID sid myval},{'Int','Int','String'});
      %val = dbo.runquery(['INSERT INTO evri_cache_db.sourceData (cacheID,sourceAttributesID,valChar) VALUES (' num2str(cacheID) ',' num2str(sid) ',''' sprintf('%s',myval) ''')']);
    end
  else
    if iscell(myval)
      %Probably preprocessing.
      myval = encodexml(myval,myatts{i});
    end
    %String, check to make sure it's not an array.
    if size(myval,1)>1
      myval = str2cell(myval);
      myval = sprintf('%s\n',myval{:});
    end
    if length(myval)>3000
      %toobig
      myval = '';
    end
    sqlstr = ['INSERT INTO evri_cache_db.sourceData (cacheID,sourceAttributesID,valChar) VALUES (?,?,?)'];
    val = jpreparedstatement(dbo,sqlstr,{cacheID sid myval},{'Int','Int','String'});
    %val = dbo.runquery(['INSERT INTO evri_cache_db.sourceData (cacheID,sourceAttributesID,valChar) VALUES (' num2str(cacheID) ',' num2str(sid) ',''' sprintf('%s',myval') ''')']);
  end
end

%------------------------
function out = checksource(obj,item)
%Check for existing source items and add them if they're not there.

%Keep lists of frequent queries so we can do quick compares and keep things
%speedy.
persistent  sourceitems
out = [];
val = [];
dbo = obj.dbobject;
tempty = false;

myatts = fieldnames(item.source);

if isempty(sourceitems)||isempty(sourceitems{1})
  sourceitems = dbo.runquery(['SELECT * FROM evri_cache_db.sourceAttributes']);
  if isempty(sourceitems)||isempty(sourceitems{1})
    %Add for first time.
    mydt = '';
    for i = 1:length(myatts)
      if isnumeric(item.source.(myatts{i}))
        mydt{end+1,1} = 'numeric';
      elseif ~ischar(item.source.(myatts{i}))
        mydt{end+1,1} = 'xml';
      else
        mydt{end+1,1} = 'string';
      end
    end
    sqlstr = ['INSERT INTO evri_cache_db.sourceAttributes (name,dataType) VALUES (?,?)'];
    val = jpreparedstatement(dbo,sqlstr,[myatts mydt],{'String','String'});
    sourceitems = dbo.runquery(['SELECT * FROM evri_cache_db.sourceAttributes']);
    count = 1;
    while isempty(sourceitems{1})
      %Table not updated yet.
      evripause(.1);
      sourceitems = dbo.runquery(['SELECT * FROM evri_cache_db.sourceAttributes']);
      count = count+1;
      if count>100
        %Something wrong so error out.
        error('Can''t add source data to database.')
      end
    end
    out = sourceitems;
    return
  end
end

%Check to see if all attributes are in the table.
sidx = ismember(myatts,sourceitems(:,2));

if ~all(sidx)
  %Refresh the list.
  sourceitems = dbo.runquery(['SELECT * FROM evri_cache_db.sourceAttributes']);
  sidx = ismember(myatts,sourceitems(:,2));
  if ~all(sidx)
    %Add the items to the table.
    addatts = myatts(~sidx);
    %Make datatype array.
    mydt = '';
    for i = 1:length(addatts)
      if isnumeric(item.source.(addatts{i}))
        mydt{end+1,1} = 'numeric';
      elseif ~ischar(item.source.(addatts{i}))
        mydt{end+1,1} = 'xml';
      else
        mydt{end+1,1} = 'string';
      end
    end
    sqlstr = ['INSERT INTO evri_cache_db.sourceAttributes (name,dataType) VALUES (?,?)'];
    val = jpreparedstatement(dbo,sqlstr,[addatts mydt],{'String','String'});
  end
end

sourceitems = dbo.runquery(['SELECT * FROM evri_cache_db.sourceAttributes']);
out = sourceitems;


