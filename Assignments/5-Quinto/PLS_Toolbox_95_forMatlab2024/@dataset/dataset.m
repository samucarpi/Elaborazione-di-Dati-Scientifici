classdef dataset
  %DATASET DataSet object class constructor.
  % Creates a DataSet object which can contain data along with related
  %  informational fields including:
  %
  %    name           : name of data set.
  %    author         : authors name.
  %    date           : date of creation.
  %    moddate        : date of last modification.
  %    type           : either 'data', 'batch' or 'image'.
  %    size           : size vector of data.
  %    sizestr        : string of size.
  %    imagesize      : size of image modes for type 'image' data. Should be
  %                     used to unfold/refold image data in .data field.
  %    imagesizestr   : string of imagesize.
  %    foldedsize     : size of folded image data returned by .imagedataf.
  %    foldedsizestr  : string of foldedsize.
  %    imagemode      : mode where spatial data has been unfolded to.
  %    imageaxisscale : axis scales for each image mode.
  %    imageaxisscalename  : descriptive name for each set of image axis scales.
  %    imageaxistype  : type of imageaxisscale to use with each mode of data, values
  %                     can be 'discrete' 'stick' 'continuous' 'none'.
  %    imagemap       : reference for included pixels of an image. Calls
  %                     function to display data.
  %    imagedata      : reference for image data, holds no data but will call
  %                     function to display folded data.
  %    data           : actual data consisting of any Matlab array of class
  %                     double, single, logical, or [u]int8/16/32.
  %    label          : text labels for each row, column, etc of data.
  %    labelname      : descriptive name for each set of labels.
  %    axisscale      : axes scales for each row, column, etc of data.
  %    axisscalename  : descriptive name for each set of axis scales.
  %    axistype       : type of axisscale to use with each mode of data, values
  %                     can be 'discrete' 'stick' 'continuous' 'none'.
  %    title          : axis titles for each row, column, etc of data.
  %    titlename      : descriptive name for each axis title.
  %    class          : class indentifiers for each row, column, etc of data.
  %    classname      : descriptive name for each set of class identifiers.
  %    classlookup    : lookup table for text names for each numeric class.
  %    classid        : a reference that assigns/returns a cell array of stings
  %                     based on the .classlookup table.
  %    include        : indices of rows, columns, etc to use from data (allows
  %                     "exclusion" of data without hard-deletion)
  %    userdata       : user defined content.
  %    description    : text description of DataSet content.
  %    history        : text description of modification history.
  %    uniqueid       : a unique identifier given to this DataSet.
  %    datasetversion : dataset object version.
  %
  % For more information on working with DataSet objects, see the methods:
  %    DATASET/SUBSREF and DATASET/SUBSASGN
  % For more detail on DataSet functionality, see the DataObject documentation.
  %
  %I/O: data = dataset(a);
  %
  %See also: DATASET/EXPLODE, DATASET/SUBSASGN, DATASET/SUBSREF

  %Copyright Eigenvector Research, Inc. 2000

  %nbg 8/3/00, 8/16/00, 8/17/00, 8/30/00, 10/05/00, 10/09/00
  %nbg added 5/11/01  b.includ = cell(nmodes,2); (this is different from
  %    the previous version which used b.includ = cell(ndims) which didn't
  %    follow the convention of different modes on different rows
  %jms 5/30/01 added transposition of row-vector batch cell to column-vector
  %nbg 10/07/01 changed version from 2.01 to 3.01
  %jms 8/30/02 added validclasses string
  %    added empty dataset construction
  %jms 11/06/02 change version to 3.02
  %    updated help
  %jms 4/24/03 modified help (includ->include)
  %    -renamed "includ" to "include"
  %rsk 09/08/04 add image size and mode.
  %rsk 06/13/23 update to use classdef



  %NOTES:
  %  * Use uuid = char(matlab.lang.internal.uuid()) for unique id instead or
  %    makeuniqueid.
  %  * Needed to overload 'horzcat' and 'vertcat' to make [] concatenation
  %    work.
  %  * Need to follow these guidelines for DSO, all methods should be
  %    overloaded for things to work correctly:
  %    https://www.mathworks.com/help/matlab/matlab_oop/methods-that-modify-default-behavior.html
  %  * See note in overloaded end.m about indexing updates for :, we may
  %    want to update all indexing soon.
  %  * Can use https://www.mathworks.com/help/matlab/customize-object-indexing.html
  %    to better organize our indexing code. Current subsref and subsassign
  %    are gigantic and hard to understand.
  %  * See TMW dataset object for example of more unified storage, meta
  %    data is in one container.

  properties
    %Description data
    name (1,:) char = ''
    type (1,:) char {mustBeMember(type,{'data','image','batch'})} = 'data'
    moddate (1,6) double %Last modification date (output from clock)
    author (1,:) char = ''
    description (:,:) char = ''

    %Raw data (numeric or cell-for batch)
    data

    %Primary set data
    label (:,2,:) cell = cell(2,2,1)
    axisscale (:,2,:) cell = cell(2,2,1)
    class (:,2,:) cell = cell(2,2,1)
    include (:,2,:) cell = cell(2,2,1)

    %Image data
    imagemode (1,:) double
    imagesize (1,:) double
    imageaxisscale (:,2,:) cell = cell(2,2,1)

    %Other meta data
    %NOTE: Loop in constructor adds default values.
    title (:,2,:) cell = cell(2,2,1)
    classlookup (:,:) cell = cell(2,1)
    axistype (:,:) cell = cell(2,1)
    imageaxistype (:,:) cell = cell(2,1)
    userdata = []
    history (:,1) cell = cell(1,1)
  end

  properties(Dependent)
    size
    sizestr
    imagesizestr
    foldedsize
    foldedsizestr
    classid
  end

  properties(GetAccess='public', SetAccess='private')
    date (1,6) double %Date of creation
    uniqueid (1,:) char = '' %Not shown in disp
    datasetversion (1,:) char = '7.0' %Not shown in disp
  end

  methods
    function a = dataset(varargin)
      %Main constructor.
      %Note that 'a' is instantiated automatically as a dataset object
      %unlike old syntax that required code to class the structure before
      %output.

      %Class of array that can to into .data field.
      validclasses = {'double','single','logical','int8','int16','int32','uint8','uint16','uint32'};


      if nargin==0
        nmodes    = 2;
      elseif nargin>0
        if nargin>1;
          try
            rawdata = cat(2,varargin{:});
          catch
            error('Cannot combine these items into a single DataSet object')
          end
        else
          rawdata = varargin{1};
        end
        if isempty(rawdata)
          nmodes  = 2;
          a.type  = 'data';        %default
        elseif any(strcmp(class(rawdata),validclasses))
          nmodes  = ndims(rawdata);
          a.type  = 'data';
          a.data  = rawdata;
        elseif isa(rawdata,'cell')
          if (size(rawdata,1)>1)&(size(rawdata,2)>1)
            error('Not set up for multidimensional cells.')
          else
            if size(rawdata,2)>1; rawdata=rawdata'; end; %flip to be COLUMN vector
            nmodes  = ndims(rawdata{1});     %number of modes for each cell
            csize   = size(rawdata{1});
            csize   = csize(2:end);    %size of dimensions~=1
            if ~isnumeric(rawdata{1})
              error('Batch DataSet objects can only be created from numeric types.');
            end
            if length(rawdata)>1             %make certain that contents of all
              for ii=2:length(rawdata)       % cells are same size except dim 1
                if ~isnumeric(rawdata{ii})
                  error('Batch DataSet objects can only be created from numeric types.');
                end
                csize2 = size(rawdata{ii});
                csize2 = csize2(2:end);
                if any(csize2~=csize)
                  error('All modes except 1 must be same size.')
                end
              end
            end
            a.type  = 'batch';
            a.data  = rawdata;
          end
        else
          error(['Unable to create a dataset to contain variables of class ' class(rawdata)])
        end
      end

      for ii = 1:nmodes
        a.label{ii,1,1}       = ''; a.label{ii,2,1}     = ''; %'Set 1';
        a.axisscale{ii,1,1}   = []; a.axisscale{ii,2,1} = ''; %'Set 1';
        a.imageaxisscale{ii,1,1}   = []; a.axisscale{ii,2,1} = ''; %'Set 1';
        a.title{ii,1,1}       = ''; a.title{ii,2,1}     = ''; %'Set 1';
        a.class{ii,1,1}       = []; a.class{ii,2,1}     = ''; %'Set 1';
        a.classlookup{ii,1}   = {}; %Assign empty to set 1, additional sets in second mode.
        a.axistype{ii,1}   = 'none'; %Assign empty to set 1, additional sets in second mode.
        a.imageaxistype{ii,1}   = 'none'; %Assign empty to set 1, additional sets in second mode.
      end


      %Populate include field.
      if nargin==0
        a.include       = cell(2,2);  %empty cell with size = ndims x 1  %nbg changed 5/11/01
      elseif ~strcmp(a.type,'batch')
        a.include       = cell(nmodes,2);  %nbg added 5/11/01
        for ii=1:nmodes
          a.include{ii} = [1:size(a.data,ii)];
        end
      else
        a.include       = cell(nmodes,2);  %nbg added 5/11/01
        a.include{1}    = [1:length(a.data)];
        for ii=2:nmodes
          a.include{ii} = [1:size(a.data{1},ii)];
        end
        a.axisscale{1,1,1} = cell(length(a),1);
        a.imageaxisscale{1,1,1} = cell(length(a),1);
      end


      [tstamp,time] = timestamp;
      a.history{1}   = ['Created by ' userinfotag ' ' tstamp];
      if nargin>0
        a.name    = inputname(1);
      end
      a.date = datevec(datetime);
      a.moddate = a.date;

      a.uniqueid = char(java.util.UUID.randomUUID());
    end

    function newobj = horzcat(varargin)
      newobj = cat(2,varargin{:});
    end

    function newobj = vertcat(varargin)
      newobj = cat(1,varargin{:});
    end

  end % ordinary methods

  methods (Static)

    function [out,msg] = struct2dataset(in)
      %This function is long so put it in private folder. Doesn't seem to
      %work as normal method (not in private).
      [out,msg] = struct2ds(in);
    end
    
  end % static methods
end %classdef

