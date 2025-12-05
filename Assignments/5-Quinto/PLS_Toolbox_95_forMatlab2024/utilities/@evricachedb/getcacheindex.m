function cachestruct = getcacheindex(obj,filter,getsource)
%EVRICACHEDB/GETCACHEINDEX Get structure of cache data.
% Input 'filter' can be empty, object type ('model' 'data' 'prediction').
% Input 'getsource' can be 0 or 1. Value of 1 will get the source
% information via (slow) subquery.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent  sourceitems %List of all attribute names.

checkcachedb(obj)

if nargin<2
  filter = '';
end

if nargin<3
  getsource = 0;
end

dbo = obj.dbobject;
prjID = addproject(obj, modelcache('projectfolder'));

switch filter
  case ''
    cdata = dbo.runquery(['SELECT cacheID, projectID, name, description, type, '...
                          'cacheDate FROM evri_cache_db.cache WHERE projectID=' num2str(prjID)]);
  case {'model' 'data' 'prediction'}
    cdata = dbo.runquery(['SELECT cacheID, projectID, name, description, type, '...
                          'cacheDate FROM evri_cache_db.cache WHERE projectID=' num2str(prjID)...
                          ' AND type= ''' filter '''']);
  otherwise
    %Look for specific name.
    cdata = dbo.runquery(['SELECT cacheID, projectID, name, description, type, '...
                          'cacheDate FROM evri_cache_db.cache WHERE projectID=' num2str(prjID)...
                          ' AND name= ''' filter '''']);
end

%sdata = getsourcedata(obj,[cdata{:,1}]);

%Set up queries.
%NOTE: See if prepared statement speeds these up (if they need it).
dataqry = ['SELECT sourceData.* FROM evri_cache_db.sourceData INNER JOIN '...
  'evri_cache_db.cache ON evri_cache_db.sourceData.cacheID=evri_cache_db.cache.cacheID '...
  'WHERE evri_cache_db.cache.cacheID = '];

cachestruct = struct(...
  'name' ,'',...
  'description','',...
  'source','',...
  'type','',...
  'links','',...
  'cachedate','',...
  'filename',''...
  );

if length(cdata)==1 & isempty(cdata{1})
  return
end

csize = size(cdata,1);

if csize>10;
  wh = waitbar(0,['Building Cache for Project: ' modelcache('projectfolder')]);
else
  wh = [];
end

alllinks = getlinks(obj,[cdata{:,1}]);
switch size(alllinks,2)
  case 0
    linkindex = [];
  case 1
    linkindex = cdata{1,1};
  otherwise
    linkindex = [alllinks{:,2}];
end

for i = 1:csize
  cachestruct(i,1).name = cdata{i,3};
  cachestruct(i,1).description = cdata{i,4};
  cachestruct(i,1).type = cdata{i,5};
  cachestruct(i,1).cachedate = cdata{i,6};
  cachestruct(i,1).filename = [cachestruct(i,1).name '.mat'];
  if ~isempty(linkindex)
    use = ismember(linkindex,cdata{i,1});
    mylinks = alllinks(use,1);
    if ~isempty(mylinks)
      mylinks = cell2struct(mylinks,'target',2);
      cachestruct(i).links = shiftdim(mylinks,1);%Make mode match that of orginal returned by modelcache.
    else
      cachestruct(i).links = struct('target',{});
    end
  end
  
  if getsource
    %Parse source items. This can take a long time.
    if isempty(sourceitems)
      sourceitems = dbo.runquery(['SELECT * FROM evri_cache_db.sourceAttributes']);
    end
    
    mysource = [];
    mydata = dbo.runquery([dataqry num2str(cdata{i,1})]);%%%%%%%%%
    mydata_atts_idx = ismember([sourceitems{:,1}],[mydata{:,3}]);
    manditory_fields = gettypefields(cachestruct(i).type);
    actual_fields = unique(sourceitems(mydata_atts_idx,2));
    %Just in case an attribute get's added without being noted in
    %gettypefields, add these to the end of our field list.
    manditory_fields = [manditory_fields setdiff([actual_fields(:)]',manditory_fields)];
    
    for j = 1:length(manditory_fields)
      if ismember(manditory_fields{j},actual_fields)
        %If there's a value in the database use it.
        myid = sourceitems{ismember(sourceitems(:,2),manditory_fields{j}),1};
        mydt = sourceitems{ismember(sourceitems(:,2),manditory_fields{j}),3};
        %There is data for this item so parse it.
        switch mydt
          case 'numeric'
            %TODO: If there are empties in the data this line will lose
            %them. This happens for ANN Pred RMSEP. Could pull into cell
            %maybe and replace with NaN. Fix in cachestruct around line 174
            %for this ANN exception. Example of ANN is [NaN NaN .345]
            %becomes just [.345]. 
            mysource.(manditory_fields{j}) = [mydata{ismember([mydata{:,3}],myid),5}];
          case 'string'
            mysource.(manditory_fields{j}) = [mydata{ismember([mydata{:,3}],myid),4}];
          case 'xml'
            myxml = mydata{ismember([mydata{:,3}],myid),4};
            if ~isempty(myxml)
              myxml = parsexml(myxml);
              mysource.(manditory_fields{j}) = myxml.(manditory_fields{j});
            else
              mysource.(manditory_fields{j}) = '';
            end
        end
      else
        %No value in database so make it empty.
        mysource.(manditory_fields{j}) = [];
      end
    end
    cachestruct(i,1).source = mysource;
  else
    %Make an empty place holder.
    cachestruct(i,1).source = [];
  end
  if mod(i,20)==0 & ~isempty(wh)
    waitbar(i/csize,wh);
  end
end
if ~isempty(wh); close(wh); end

%---------------------------------
function out = gettypefields(type)
%Get fields that should be displayed according to type of object. This
%should be incorporated into the database at some point.

switch type
  case 'data'
    out = {'name' 'type' 'author' 'date' 'moddate' 'size' 'include_size' 'description' 'uniqueid' 'summary'};
  case {'model' 'prediction'}
    out = {'summary' 'modeltype' 'time' 'ncomp' 'preprocessing' 'rmsec' 'rmsecv' 'rmsep' 'cvmethod' 'cvsplit' 'cviter' 'include_size'};
end


