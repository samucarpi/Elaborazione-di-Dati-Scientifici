function val = checkdataname(obj)
%EVRICACHEDB/CHECKDATANAME Make sure all items of type 'data' have name attribute.
% If items don't have name they's be assigned "unnamed".
% This is needed for when the cache is sorted by lineage and also looks
% better when displayed as opposed to blank.


%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbo = obj.dbobject;

myqry = ['SELECT evri_cache_db.cache.cacheID FROM evri_cache_db.cache LEFT JOIN evri_cache_db.sourceData '...
  'ON evri_cache_db.cache.cacheID = evri_cache_db.sourceData.cacheID AND  evri_cache_db.sourceData.sourceAttributesID '...
  '= 1 WHERE evri_cache_db.cache.type = ''data''  AND evri_cache_db.sourceData.sourceAttributesID is null'];

myids = dbo.runquery(myqry);

if ~isempty(myids)
  for i = 1:length(myids)
    %Insert names for orphan data.
    item.source.name = 'unnamed';
    addsource(obj,item,myids{i});
  end
end
