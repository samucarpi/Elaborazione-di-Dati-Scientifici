function [data,options] = coadd(data,binsize,options)
%COADD Reduce resolution through combination of adjacent variables or samples.
% COADD is used to combine ("bin") adjacent variables, samples, or slabs of
% a matrix. Unpaired values at the end of the matrix are padded with the 
% least-biased value to complete the bin. Missing data (NaN) and excluded 
% data are also replaced with the least-biased value. Unlike DERESOLV,
% COADD reduces the size of the data matrix by a factor of 1/binsize for
% the dimension defined by (dim).
%
% INPUTS:
%     data = data array to be binned.
%  binsize = the number of elements to combine together {default = 2}.
%
% OPTIONAL INPUTS:
%      dim = mode (dimension) to coadd (scalar integer {default = 2}).
%  options = structure array with the following fields:
%       dim: Dimension in which to do combination {default = 2},
%      mode: [ 'sum' | {'mean'} | 'prod' | 'var'| 'std'] method of combination.
%    labels: [ {'all'} | 'first' | 'middle' | 'last' ] method of combining
%             labels (if any exist). Each method labels a new object using
%             one of the following rules:
%              'all'    = concatenate all labels for the combined items
%                         {default}.
%              'first'  = use only the label from the first object in each
%                         set of combined objects. 
%              'middle' = use only the label from the "middle" object in
%                         each set of combined objects.
%              'last'   = use only the label from the last object in each
%                         set of combined objects. 
%   binsize: [2] default binsize to use if no binsize is provided in the
%             input.
%  maxitems: [1000] maximum number of items to operate on at a time. Allows
%             operating on much larger arrays without out-of-memory issues.
%             Only this many rows/columns/etc will be co-added in one
%             block. Set to inf to disable windowing and to zero to do one
%             binsize at a time.
%  classset:  Class set to use for binning. Default is empty. If assigned
%             then will use instead of binsize.
%
%OUTPUTS
%  databin = the coadded / binned data. 
%  options = an options structure that can be used with new data to
%            bin with the same settings.
%
%I/O: [databin,options] = coadd(data,binsize,options);
%I/O: [databin,options] = coadd(data,binsize,dim);
%I/O: [databin,options] = coadd(data,options);
%I/O: [databin,options] = coadd(data); %user is prompted for settings to use
%
%See also: DERESOLV, REGISTERSPEC

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 2/5/03
%JMS 4/03 - modified help
%JMS 12/03 - added intermediate dataset support
%jms 10/04 - added support for axisscale co-adding in dataset objects
%jms 12/05 -better handling of exclded data and missing data (both now
%           imputed so that co-add is not effected by values)

if nargin == 0; 
  data = lddlgpls('doubdataset','Choose data to coadd'); 
  if isempty(data)
    options = [];
    return;
  end
end
if ischar(data);
  options = [];
  options.dim = 2;
  options.mode = 'mean'; % [ 'sum' | 'mean' | 'prod' | 'var' | 'std' ] 
  options.labels = 'all';   % [ 'all' | 'middle' | 'first' | 'last' ]
  options.binsize = 2;   
  options.maxitems = 1000; %maximum number of items to coadd over without looping
  options.classset = [];
  if nargout==0; evriio(mfilename,data,options);clear data; else; data = evriio(mfilename,data,options); end
  return; 
end

if nargin<3;
  if nargin>1;
    if isstruct(binsize);
      options = binsize;
      binsize    = [];
    else
      options = [];
    end
  else
    %one input? prompt user for information (NOTE: old behavior was to do a
    %co-add of 2, but I doubt anybody used that)
%     settings = coaddset(data);
%     drawnow;
    myGUIInstance = CoaddSettings(data);
    waitfor(myGUIInstance.fig);
    settings = myGUIInstance.settings;
    if isempty(settings) || ~settings.OK
      data = [];
      options = [];
      return
    end
    %move settings to appropriate inputs
    options = [];
    options.mode = lower(settings.action);
    if strcmpi(options.mode,'product')
      options.mode = 'prod';
    end
    if strcmpi(options.mode,'variance')
      options.mode = 'var';
    end
    if strcmpi(options.mode,'std dev')
      options.mode = 'std';
    end
    options.dim  = settings.mode;
    binsize      = settings.binsize;
    options.classset     = settings.classSet;
  end
else
  if isstruct(binsize);
    temp    = binsize;
    binsize    = options;
    options = temp;
  end
end
if ~isstruct(options) & prod(size(options))==1;
  dim = options;
  options = [];
  options.dim = dim;
end
options = reconopts(options,'coadd');

if ~any(strcmp(options.mode,{'sum','mean','prod', 'var', 'std'}));
  error(['Unrecognized MODE in options']);
end

if isempty(binsize) && isempty(options.classset)
  binsize = options.binsize;
end
if binsize==1; return; end      %special case, bin of 1 is just the data returned!

sz   = size(data);
if options.dim>length(sz) | options.dim<1;
  error('Dimension to bin does not exist.');
end

origdata = data;
if isa(origdata,'dataset')
  if strcmp(data.type,'image') & exist('coadd_img','file') & options.dim==data.imagemode
    %image data type and we have the image-version of this function? use it
    data = coadd_img(data,repmat(binsize,1,length(data.imagesize)),options);
    return
  end
    %non-image or not doing image mode
    incl = data.include;
    
    %**The following excludes the data first then co-ads (not great)
    %   ind  = cell(1,ndims(data));
    %   [ind{:}] = deal(':');
    %   ind{options.dim} = incl{options.dim};
    %   data = data.data(ind{:});
    
    %** Fill in NaN's for excluded values
    inclmap = zeros(1,sz(options.dim));
    inclmap(incl{options.dim}) = 1;
    data.data = nassign(data.data,nan,find(~inclmap),options.dim);
    
    if isempty(options.classset)
      %make a new "exclude" map where any window with all excluded
      %points is exlcuded in the output
      inclmap = coadd(inclmap,binsize,struct('dim',2,'mode','mean', 'classset',[]));
      newincl = find(inclmap);   %only false if all in a window were excluded
      data    = data.data;
      
      sz = size(data);
    end
end

if isdataset(data) && ~isempty(options.classset)
  options.labels = 'class';
  data = operateOnClasses(data,options,options.classset);
  data.history = origdata.history;
  data.history = 'Coadd-Modified Data. Original data history above.';
  options.binsize = [];
  return;
end

if isempty(options.classset)
  options.maxitems = max(options.maxitems,binsize);  %maxitems must be at least binsize
  if sz(options.dim)<=options.maxitems
    %not too many to do at once
    
    %pad dim to bin to make appropriate length
    over = mod(sz(options.dim),binsize);
    if over>0;
      ind    = cell(0);
      [ind{1:length(sz)}] = deal(':');
      ind{options.dim}    = sz(options.dim)-over+1:sz(options.dim);
      val                 = domath(data(ind{:}),options,1);  %get "slab" to pad with
      for i = sz(options.dim)+1:sz(options.dim)+(binsize-over);
        ind{options.dim}    = i;
        data(ind{:})        = val;  %augment slab till we can split by "binsize"
      end
    end
    
    %Do binning
    sz      = size(data);
    sz      = [sz(1:options.dim-1) binsize sz(options.dim)/binsize sz(options.dim+1:end)];  %split dim of interest
    
    flattened = reshape(data,sz);
    %handle missing data first
    ismissing = isnan(data);
    if any(ismissing(:));
      flatorder = [options.dim setdiff(1:length(sz),options.dim)];
      [junk,flatreorder] = sort(flatorder);
      flattened = permute(flattened,flatorder);
      fsz       = size(flattened);
      flattened = reshape(flattened,fsz(1),prod(fsz(2:end)));
      ismissing = isnan(flattened);
      
      missingopt = options;
      missingopt.dim = 1;  %special dim because we've reshaped
      for j = find(any(ismissing,1))
        val = domath(flattened(~ismissing(:,j),j),missingopt,1);
        flattened(ismissing(:,j),j) = val;
      end
      flattened = reshape(flattened,fsz);
      flattened = permute(flattened,flatreorder);
    end
    
    data    = reshape(domath(flattened,options),[sz(1:options.dim-1) sz(options.dim+1:end)]);
    
  else
    %too many to do at once, use looped method
    data = loopedbin(data,binsize,options);
    over = 0;
  end
end

if isa(origdata,'dataset');
  %reinsert back into DSO
  data = dataset(data);
  data.history = origdata.history;
  data.history = 'Coadd-Modified Data. Original data history above.';
  data.include{options.dim} = newincl;
  data = copydsfields(origdata,data,setdiff(1:ndims(origdata),options.dim));

  data.type = origdata.type;
  if strcmp(data.type,'image')
    %image DSO? copy imagemode and other info as possible
    data.imagemode = origdata.imagemode;
    if options.dim~=data.imagemode
      %if they didn't compress the image mode, copy size and axisscale
      data.imagesize = origdata.imagesize;
      for j=1:size(origdata.imageaxisscale,1)
        data.imageaxisscale{j} = origdata.imageaxisscale{j};
      end
    end
  end
      
  %handle other fields
  %do axisscale
  for setind = 1:size(origdata.axisscale,2);
    axisscale = origdata.axisscale{options.dim,setind};
    if ~isempty(axisscale)
      temp = axisscale.*nan;
      temp(incl{options.dim}) = axisscale(incl{options.dim});
      axoptions = options;
      axoptions.dim = 2;
      axoptions.mode = 'mean';
      data.axisscale{options.dim,setind} = coadd(temp,binsize,axoptions);
    end
  end
  %do labels
  for setind = 1:size(origdata.label,2);
    lbl = str2cell(char(origdata.label{options.dim,setind}));
    if ~isempty(lbl);
      switch options.labels
        case 'first'
          %choose only the first label of each object set
          newlbl = lbl(1:binsize:end);
        case 'middle'
          %choose only the "middle" label of each object set
          newlbl = lbl(ceil(binsize/2):binsize:end);
          if over>0
            if length(newlbl)==size(data,options.dim);
              newlbl = newlbl(1:end-1);
            end
            newlbl = [newlbl; lbl(end-ceil(over/2)+1)];
          end
        case 'last'
          %choose only the last label of each object set
          newlbl = lbl(binsize:binsize:end);
          if over>0
            newlbl = [newlbl;lbl{end}];
          end
        otherwise  %probably 'all'
          %concatenate all items into single strings
          newlbl = str2cell(sprintf(['%s' repmat(',%s',1,binsize-1) '\n'],lbl{:}));
          if over>0
            newlbl{end} = newlbl{end}(1:end-1);  %drop ending ,
          end          
      end
      data.label{options.dim,setind} = newlbl;
    end
  end  
end

options.binsize = binsize;

%----------------------------------------------
function databin = domath(databin,options,pad);
%pad is flag to indicate that we're doing a padding operation 
% (requires slightly different math)

if nargin<3;
  pad = 0;
elseif pad
  if isempty(databin)
    databin = nan;
    return
  end
end

switch options.mode
  case 'sum'
    if pad
      databin = mean(databin,options.dim);
    else
      databin = sum(databin,options.dim);
    end
  case 'mean'
    databin = mean(databin,options.dim);
  case 'prod'
    if pad
      databin = prod(databin,options.dim)/size(databin,options.dim);
    else
      databin = prod(databin,options.dim);
    end
  case 'var'
    if pad      
      databin = var(databin,0,options.dim)/size(databin,options.dim);
    else
      databin = var(databin, 0,options.dim);
    end
  case 'std'
    if pad
      databin = std(databin,0,options.dim)/size(databin,options.dim);
    else
      databin = std(databin,0,options.dim);
    end
end

%----------------------------------------------
function out = loopedbin(data,binsize,options)
%COADDBIG Co-addition for large matrices

sz       = size(data);
dim      = options.dim;
maxitems = options.maxitems;

options.maxitems = inf;  %make ABSOLUTELY SURE we don't cycle back into here!

%prepare target
tsz      = sz;
tsz(dim) = ceil(sz(dim)/binsize);
out      = zeros(tsz);

%create subscripting indexes
[indxs{1:ndims(data)}] = deal(':');
indx    = substruct('()',indxs);
outindx = substruct('()',indxs);

bigbinsize = floor(maxitems/binsize)*binsize;
nbins = ceil(sz(dim)/bigbinsize);
for j=1:nbins
    bigoffset   = (j-1)*bigbinsize;
    smoffset    = (j-1)*bigbinsize/binsize;
    indx.subs{dim}    = (1+bigoffset):min(bigbinsize+bigoffset,sz(dim));
    outindx.subs{dim} = (1+smoffset):min(bigbinsize/binsize+smoffset,tsz(dim));
    subresult         = coadd(subsref(data,indx),binsize,options);
    out               = subsasgn(out,outindx,subresult);
end

%----------------------------------------------
function databin = operateOnClasses(data, options, classset)
uniqueClasses = unique(data.class{options.dim,classset});
classLookup = data.classlookup{options.dim,classset};
classLookupNums = cell2mat(classLookup(:,1));
dataSize = size(data);

if ndims(data)>2 & options.dim ~= 1
  data = permute(data,[options.dim setdiff(1:ndims(data),options.dim)]);
elseif options.dim ~= 1
  data = data';
end
databin = [];
finalIncld = 1:size(uniqueClasses,2);
for i = uniqueClasses
%   tinds = data.class{options.dim,classset}==uniqueClasses(i);
  tinds = data.class{1,classset}==i;
  classNameInd = classLookupNums==i;
  className = classLookup{classNameInd,2};
  thisData = data(tinds,:);
  incld = thisData.include;
  thisData_incld = thisData(incld{1});
  if all(all(isnan(thisData_incld.data)))
    %all samples in class are excluded
    myData = nan(1,size(thisData_incld,2));
    finalIncld(i) = [];
  else
    switch options.mode
      case 'sum'
        myData = sum(thisData_incld.data,1);
      case 'prod'
        myData = prod(thisData_incld.data,1);
      case 'mean'
        myData = mean(thisData_incld.data,1);
      case 'var'
        myData = var(thisData_incld.data,0);
      case 'std'
        myData = std(thisData_incld.data,0);
    end
  end
  myDSO = dataset(myData);
  myDSO.label{1,1} = ['Samples from Class ' className];
    %do axisscale
  for setind = 1:size(thisData.axisscale,2)
    axisscale = thisData.axisscale{1,setind};
    if ~isempty(axisscale)
      temp = axisscale.*nan;
      temp(incld{1}) = axisscale(incld{1});
%       axoptions = options;
%       axoptions.dim = 2;
%       axoptions.mode = 'mean';
%       data.axisscale{options.dim,setind} = coadd(temp,binsize,axoptions);
      myDSO.axisscale{1,setind} = mean(temp,2, 'omitnan');
    end
  end
  databin = cat(1,databin, myDSO);
end
databin = copydsfields(data,databin,2);
databin.include{1,1} = finalIncld;
if ndims(data)>2 & options.dim ~= 1
   %databin = permute(databin, [2 setdiff(1:ndims(databin),options.dim)]);
  databin = ipermute(databin,[options.dim setdiff(1:ndims(databin),options.dim)]);
elseif options.dim ~= 1
  databin = databin';
end

