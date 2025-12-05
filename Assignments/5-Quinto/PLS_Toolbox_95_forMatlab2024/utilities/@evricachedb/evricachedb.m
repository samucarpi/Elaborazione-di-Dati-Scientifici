classdef evricachedb < matlab.mixin.SetGet
  %EVRICACHEDB EVRI [model] cache object.
  %  Manage creation and query of model cache database. Accepts evridb object
  %  connected to cache database. See @evricachedb/createcachedb.m for table
  %  structure. If no existing cache is located then one is created in
  %  'evridir' directory.
  %
  %  PROPERTIES:
  %
  %     .dbobject      : evridb object that connects to cache database.
  %     .date_source   : [{'cachedate'} | 'moddate'] what type of date to use
  %                      when constructing tree nodes.
  %
  %I/O: obj = evricachedb
  %
  %See also: @EVRIDB

  %Copyright Eigenvector Research, Inc. 2010
  %Licensee shall not re-compile, translate or convert "M-files" contained
  % in PLS_Toolbox for use with any software other than MATLAB®, without
  % written permission from Eigenvector Research, Inc.

  %VERSION 2 NOTES
  %  1) Use SQL dates.
  %  2) Move single attributes (mod date and cahce date, name, etc.) to cache table to help speed and simplify.

  properties
    dbobject
    date_source (1,:) char {mustBeMember(date_source,{'moddate' 'cachedate'})} = 'cachedate'
    date_sort (1,:) char {mustBeMember(date_sort,{'ascend' 'descend'})}  = 'descend'
  end

  properties(GetAccess='public', SetAccess='private')
    version (1,1) double {mustBePositive} = 2.0
  end

  methods
    function obj = evricachedb(varargin)
      saved_obj = getappdata(0,'evri_cache_object');
      if ~isempty(saved_obj)
        %Return stored object.
        obj = saved_obj;
        return
      end

      if (nargin > 0)
        % Use set() on name value pairs.
        try
          set(obj, varargin{:});
        catch exception
          delete(obj);
          throw(exception);
        end
      end

      if isempty(obj.dbobject)
        %Need a db object.
        obj.dbobject = getdatabaseobj(obj);
      end

      try
        %Create database if it's not already there.
        createcachedb(obj);
      catch
        return
      end

      setappdata(0,'evri_cache_object',obj)

    end

  end
end
