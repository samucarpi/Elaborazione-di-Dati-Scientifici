function val = subsref(varargin)
%EVRICACHEDB/SUBSREF Retrieve evri cache db information.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
%TODO: Make permanent fix for number of inputs and empty () calls.

obj = varargin{1};
index = varargin{2};
feyld = index(1).subs; %Field name.
val = [];
switch feyld
  case 'addcacheitem'
    val = addcacheitem(obj,index(2).subs{:});
  case 'addproject'
    val = addproject(obj,index(2).subs{:});
  case 'addsource'
    val = addsource(obj,index(2).subs{:});
  case 'checkcache'
    val = checkcache(obj,index(2).subs{:});
  case 'checkcachedb'
    checkcachedb(obj,index(2).subs{:});
  case 'checkdataname'
    checkdataname(obj);
  case 'checkproject'
    val = checkproject(obj,index(2).subs{:});
  case 'createcachedb'
    createcachedb(obj,index(2).subs{:});
  case 'date_sort'
    val = obj.date_sort;
  case 'dbobject'
    val = obj.dbobject;
  case 'display'
    display(obj)
  case 'getcacheindex'
    val = getcacheindex(obj,index(2).subs{:});
  case 'getdates'
    if length(index)>1
      val = getdates(obj,index(2).subs{:});
    else
      val = getdates(obj);
    end
  case 'getdates_children'
    val = getdates_children(obj,index(2).subs{:});
  case 'getlinks'
    val = getlinks(obj,index(2).subs{:});
  case 'getsourcedata'
    val = getsourcedata(obj,index(2).subs{:});
  case 'getstats'
    val = getstats(obj);
  case 'gettypes'
    if length(index)>1
      val = gettypes(obj,index(2).subs{:});
    else
      val = gettypes(obj);
    end
  case 'gettype_children'
    val = gettype_children(obj,index(2).subs{:});
  case 'parsecache'
    parsecache(obj,index(2).subs{:});
  case 'removecacheitems'
    val = removecacheitems(obj,index(2).subs{:});
  case 'removeproject'
    val = removeproject(obj,index(2).subs{:});
  case 'renameproject'
    val = renameproject(obj,index(2).subs{:});
  case 'setdescription'
    val = updatedescription(obj,index(2).subs{:});
  case 'test'
    val = testconnection(obj.dbobject);
  case 'clear'
    db = obj.dbobject;
    db.shutdown_derby;
    db.closeconnection_force;
    setappdata(0,'evri_cache_object',[]);
  otherwise
    %Try generic indexing.
    try
      val = obj.(feyld)(index(2).subs{:});
    catch
      error(['Index error, can''t index into field: ' feyld '.'])
    end
end
