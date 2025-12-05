function [xdata,ydata,unmapx,unmapy] = matchvars(target,xdata,ydata,options,varargin)
%MATCHVARS Align variables of two objects (datasets or models).
% Align the variables of a DataSet object to either a model or a specific
% set of labels or axisscales. Also permits joining multiple datasets to a
% uniform axisscale or label set.
%
% Given a standard model structure, dataset, array of strings, or vector
% (target) MATCHVARS uses either the labels or axisscale in the target to
% rearrange or interpolate the variables of the dataset object (xdata) so
% that it will match the target (e.g. if target is a model, the data will
% be rearranged so that the model can be applied to the data.) If (target)
% is a regression model, both an X and a Y block may be passed for
% alignment. A Y block is not required, however.
%
% MATCHVARS WITH LABELS: When variable labels exist in both the target and
% the data, or an array of strings (cell or char) are passed as target, the
% variables in (xdata) are rearranged to match the variable order in
% (target). Any variables required by (target) that do not exist
% in (data) are returned as NaN (Not a Number). These will usually be
% automatically replaced by the prediction routine using REPLACE.
%
% When no labels exist in the supplied target, the axisscale is used to
% interpolate the data based on the setting of options.axismode (see
% below). Axis regions which require extrapolation are returned as NaN (Not
% a Number). These will usually be automatically replaced by the prediction
% routine using REPLACE.
%
% If neither labels nor axisscales can be used to align variables, the
% dataset object is passed back without modification and unmap will be
% empty.
%
% An ordinary cell or character array of strings representing labels to
% match or an ordinary vector representing an axisscale may be passed in
% place of (target). Such labels or axisscale can only be used with a
% single dataset (i.e. xdata).
%
% MATCHVARS ON MULTIPLE DATASETS: Given a cell array of DataSet objects, a
% common acceptable axisscale or label set is dervied and used to align all
% the DataSets. For axisscale joining, the target will be the lowest
% resolution and widest variable range (i.e. minimize "end-clipping" and do
% not attempt to increase resolution). Note that merging DataSets with
% different resolutions will be approximate due to the extremely
% complicated nature of resolution- changing effects. Rules for merging
% labels are as described above.
%
% Inputs are:
%    target : a standard model structure OR a cell or character array of
%             labels to match labels in xdata OR a vector of axisscale
%             (e.g. wavelength, wavenumber, etc) to match xdata using
%             axisscale OR a dataset with either labels or axisscales.
%             OR a cell-array of DataSet objects to merge.
%              (model,...)
%              ([axisscale],...)
%              ({labels},...)
%              ({DataSet DataSet  DataSet...},...)
%    xdata  : a dataset object containing the X-block data (can be omitted
%             if target is a cell array of DataSet objects)
%
% Optional inputs are:
%    ydata  : a second dataset containing the Y-block data
%    unmap  : Used only when performing an "undo" of a previous MATCHVARS
%             call. This is a vector describing how to reorder the columns
%             back to the original order, as output by the previous call to
%             MATCHVARS. Can be used to re-order the outputs from a model,
%             such as the T- or Q-contributions, back to the original data
%             order.
%
%    options: a standard options structure containing the following field:
%
%      axismode: [ 'discrete' |{'linear'}| 'spline' ] a string defining the
%                interpolation method to use for matching variables using
%                axisscale. If 'discrete', axisscale values must be matched
%                exactly by data. Any other axismode will be passed to
%                interp1 to perform interpolation. See INTERP1 for
%                interpolation options.
%
% Outputs are:
%   mxdata  : adjusted ("matched") x-block data
%   mydata  : adjusted ("matched") y-block data (not returned if no y-data
%              passed)
%   unmapx  : a vector describing how the original variable order can be
%             obtained from the reordered data. This can be used on other
%             model outputs such as residuals and T contributions
%             rearranging them to be like the original data. Any column
%             discarded from the original data will have an NaN in unmap.
%             See the "reorder" type of call in I/O below.
%   unmapy : same as unmapx but for the y-block (ydata) variable.
%   rdata  : reverted data - output only when matchvars is called with
%             unmap as input.
%
% Note: if axisscale was used to interpolate new variables for mxdata or
% mydata, the unmap variable(s) will be linear vectors which simply return
% the original data.
%
%I/O: joined = matchvars({dso1, dso2, dso3, ...},options)
%I/O: [mxdata, unmap] = matchvars(model,xdata,options)
%I/O: [mxdata, unmap] = matchvars(labels,xdata,options)
%I/O: [mxdata, unmap] = matchvars(axisscale,xdata,options)
%I/O: [mxdata, mydata, unmapx, unmapy] = matchvars(model,xdata,ydata,options)
%I/O: rdata = matchvars(mdata,unmap);  %reorder mdata back to original order
%
%See also: INTERP1, MATCHROWS, MODLPRED, PCAPRO, REPLACE, STR2CELL

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS
% jms 8/26/05 -test for labels and axisscale already aligned and skip
%     alignment if not necessary
% jms 10/28/05 -added unmap call (reorder back to original order if
%     possible) and modified help.
% jms 11/30/05 -added number-of-variables test to alignbykey
%     -allowed multiple references to same variable

if nargin == 0; target = 'io'; end
if ischar(target) & ismember(target,evriio([],'validtopics'));
  options = [];
  options.name     = 'options';
  options.axismode = 'linear';
  if nargout==0; evriio(mfilename,target,options); else; xdata = evriio(mfilename,target,options); end
  return;
end

switch nargin
  case 1
    if ~isdsocell(target)
      error('Two inputs or cell array of datasets required.');
    end
    options = reconopts([],'matchvars');
    xdata = multimatch(target,options);
    return;
  case 2
    % (xdata,unmap) read here as (model,xdata)
    if ~isa(xdata,'dataset') & ~iscell(target)
      unmap = xdata;
      xdata = target;
      %use "unmap" (passed as xdata) to reorder back
      xdata = reorder(xdata,unmap);
      return
    elseif isdsocell(target)
      if ~isstruct(xdata)
        error('Unrecognized input format');
      end
      % ({dso dso dso},options)
      options = reconopts(xdata,'matchvars');
      xdata = multimatch(target,options);
      return;
    else
      % (model      ,xdata)
      % ({labels}   ,xdata)
      % ([axisscale],xdata)
      options = [];
      ydata   = [];
    end
  case 3
    % (model,xdata,options)
    % (model,xdata,ydata)
    if isa(ydata,'struct');
      % (model,xdata,options)
      options = ydata;
      ydata   = [];
    else
      % (model,xdata,ydata)
      options = [];
    end
  case 4
    % (model,xdata,ydata,options)
    %nothing need be done
end
options = reconopts(options,mfilename);

%- - - - - - - - - - - -
if ~ismodel(target)
  if isnumeric(target);
    %axisscale for reordering
  elseif iscell(target)
    %convert char array to cell array
    target = char(target);
  elseif isdataset(target)
    %Dataset as first input? assume we're going to match it like we would a
    %model created from it...
    matchdso = target;  %make copy of DSO
    target = modelstruct('pls');  %create fake model
    target.datasource = {getdatasource(matchdso)};
    target = copydsfields(matchdso,target);
  elseif ~ischar(target)
    error('Invalid input for model');
  end
end

%- - - - - - - - - - - -
%do matching on x-block
block = 1;
if ismodel(target)
  if strcmpi(target.modeltype, 'caltransfer')
    if strcmpi(target.transfermethod, 'osc')
      %OSC requires Y block and that data is stored in model.datasource{2} so
      %take expected size from model.datasource{1}.
      block = 1;
    else
      %All other calt methods have secondary instrument data in .datasource{2}
      block = 2;
    end
  end
end
[xdata,unmapx] = domatch(xdata,target,block,options.axismode);
if ~isempty(ydata)
  unmapy = [];  %we've got a y-block, make sure there is SOMETHING for ummapy
  if length(target.datasource)>1;
    if ~ismodel(target);
      error('ydata may not be passed when model input is a cell or string array')
    end
    %y-block supplied and one used by model?
    [ydata,unmapy] = domatch(ydata,target,2,options.axismode);
  end
else
  ydata = unmapx;  %move unmapx up in output sequence (outputs now: [xdata,unmapx] )
end

%-------------------------------------------------
function [data,unmap] = domatch(data,model,block,interpolation)
%main routine - matches the data to the information in the given block of
%the model. Interpolation can be either 'discrete' (indicating that
%axisscale must match EXACTLY to the axisscale in the model) or any string
%valid as interpolation method for interp1

unmap = [];
if isempty(model)
  return
end

if ismodel(model)
  %model was standard model structure
  if strcmpi(model.modeltype,'mpca')
    %we cannot do MPCA model alignments (because data is unfolded)
    %maybe we can add something in the future to handle this (e.g. calling
    %batchalign), but for now we'll just exit with no changes.
    return
  end
  axisscalem = model.detail.axisscale{2,block};
  labelm     = model.detail.label{2,block};
elseif ischar(model) | iscell(model)
  %model was character array
  labelm      = char(model);
  axisscalem  = [];
elseif isnumeric(model) & any(size(model)==1)
  %model was numeric array
  labelm      = {};
  axisscalem  = model;
else
  %this is probably caught by main function logic, but do so here too, for safety
  error('Unrecognized input for model')
end

if iscell(data)
  datad      = data{1};
  axisscaled = data{2};
  labeld     = data{3};
  data       = datad;
else
  axisscaled = data.axisscale{2};
  labeld     = data.label{2};
  datad      = data.data;
end

odims = ndims(datad);
osz = size(datad);
unfd = 1;
for i = 2:length(osz)
  unfd = unfd*osz(i);
end

%decide how we're going to match the model
if ~isempty(axisscalem) & ~isempty(axisscaled) & ~all(isnan(axisscalem)) & ~all(isnan(axisscaled)) %we've got an axisscale in both
%   if ndims(datad)>2
%     error(['Multiway (ndims>2) data cannot be matched via axisscale. Try clearing axisscale before calling matchvars.'])
%   end
    
  if length(axisscalem)~=length(axisscaled) | any(axisscalem~=axisscaled)
      if (odims > 2)
        % Unfold the data
        datad = reshape(datad,[osz(1) unfd]);
        data = reshape(data,[osz(1) unfd]);
      end
      
    %if the axes don't match, try to match them
    if ~strcmp(interpolation,'discrete');
      %continuous values - use interpolate
      wrn = warning;
      warning off;
      use = diff(axisscaled)~=0;
      if ~all(use)
        axisscaled = axisscaled(use);
        datad = datad(:,use);
      end
      if (odims > 2)
        data_new = interp1(axisscaled,datad,axisscalem(:),interpolation);
      else
        data_new = interp1(axisscaled,datad',axisscalem(:),interpolation)';
      end
      warning(wrn);
      
      % Refold the data
      if (odims > 2)
        data = reshape(data,osz);
        datad = reshape(data,osz);
        data_new = reshape(data,osz);
      end
      
      if isdataset(data)
        if ~isdataset(data_new)
          data_new = dataset(data_new);
        end
        if ismodel(model);
          data_new = copydsfields(model,data_new,2, block);
        else
          data_new.axisscale{2} = axisscalem;
        end
        data_new = copydsfields(data,data_new,1);
      end
      unmap = 1:size(data_new,2);
      data  = data_new;
    else
      %discrete values - do not interpolate
      [data,unmap] = alignbykey(axisscalem,axisscaled,data);
    end
  end
  
elseif ~isempty(labelm) & ~isempty(labeld)  %we've got labels in both
  
  labelm  = str2cell(labelm);
  labeld  = str2cell(labeld);
  [data,unmap] = alignbykey(labelm,labeld,data);
  
end

%--------------------------------------------------------
function [data,unmap] = alignbykey(target,present,data)
% Rearrange columns in (data) to match order of keys in (target) using keys
% in (present) as the order of columns in (data). Keys can be numerical or
% cells of strings. Any column in (target) that is not found in (present)
% will be infilled with NaN. Any column in (present) that is not found in
% (target) will be discarded.

[dm,dn] = size(data);
unmap   = 1:dn;                         %default unmap
if ~eqkeys(target,present)
  [utarget,n,p] = unique(target);
  [usource,r,s] = unique(present);
  [found,i,j] = intersect(utarget,usource);     %find where the keys intersect
  
  data    = [data ones(dm,1)*nan];        %add "not found" column
  
  ind     = ones(1,length(target))*dn+1;  %all point to "not found" unless we subsitute below
  ind(i)  = r(j);                         %substitute in the columns which matched up
  ind     = ind(p);                       %map back to whole data (not just unique values)
  data    = data(:,ind);                  %reorder data
  
  unmap    = ones(1,dn)*nan;
  unmap(j) = n(i);                        %note how to look up old vars in results
  unmap    = unmap(s);                    %map back to whole data (not just unique values)
end

%--------------------------------------------------------
function out = eqkeys(target,present)
%returns true if any element of the target and present do not match
% works on cells or vectors

if length(target)~=length(present)
  out = false;
  return
end
if iscell(target)
  %got cells of strings which are equal in length
  for j=1:length(target)
    switch strcmp(target{j},present{j})
      case false
        out = false;
        return
    end
  end
  out = true;
else
  %got vectors
  out = all(target==present);
end

%--------------------------------------------------------
function data = reorder(data,unmap)
%un-rearrange columns based on unmap

if isempty(unmap); return; end  %nothing in unmap? just return current data
[dm,dn] = size(data);
data    = [data ones(dm,1)*nan];        %add "not found" column
unmap(isnan(unmap)) = size(data,2);     %discarded on original reorder? use NaN
data = data(:,unmap);


%--------------------------------------------------------
function joined = multimatch(dsos,options)
%match multiple DSOs to each other in best variable matching mode

ndso = length(dsos);

%cycle through dsos and identify labels or axisscales (mode 2, set 1)
axs = cellfun(@(i) i.axisscale{2},dsos,'uniformoutput',false);%axis scale
axtypes = cellfun(@(d) d.axistype{2},dsos,'uniformoutput',false);%axis type
lbls = cellfun(@(i) i.label{2},dsos,'uniformoutput',false);%label
szs  = cellfun(@(i) size(i,2),dsos,'uniformoutput',true);%size mode 2

nonemptyaxs = ~cellfun('isempty',axs);
nonemptylbls = ~cellfun('isempty',lbls);

if all(nonemptyaxs)   %AXISSCALE matching
  %use axis scales to match becuase there's an axis scale for every dso
  if ~all(szs==szs(1)) | ~all(cellfun(@(ax) all(ax==axs{1}),axs))
    %not all axisscales match - need to do alignment
    if strcmpi(options.axismode,'discrete') | any(ismember(axtypes,{'stick' 'discrete'}))
      %check if any are discrete axis, use superset of all axisscales
      masteraxis = unique([axs{:}]);
      %match each to that list
      opts = options;
      opts.axismode = 'discrete';
      if any(ismember(axtypes,{'stick'}))
        mytype = 'stick';
      else
        mytype = 'discrete';
      end
      
      %matchvars on all and assign new axisscale
      dsos = cellfun(@(d) subsasgn(d,substruct('.','axistype','{}',{2}),mytype),dsos,'uniformoutput',false); %force all to stick/discrete
      dsos = cellfun(@(d) domatch(d,masteraxis,[],'discrete'),dsos,'uniformoutput',false);
      dsos = cellfun(@(d) subsasgn(d,substruct('.','axisscale','{}',{2}),masteraxis),dsos,'uniformoutput',false);
      
    else
      %other axis types
      
      %Get all max/min ranges
      prec = 1e-9;   %level of precision for comparison of spacing and non-linearity
      axmin = cellfun(@(i) min(i),axs);%min of each axis
      axmax = cellfun(@(i) max(i),axs);%max of each axis
      axstd = cellfun(@(i) round(std(diff(i))/prec)*prec,axs);
      axspacing = round((axmax-axmin)./(szs-1)/prec)*prec;
      axrvs = cellfun(@(i) all(diff(i)<0),axs);
      
      %Throw an error if axes are not all increasing in same direction. 
      % We could make this an option to allow forcing a reverse or using
      % first dataset as presedence to swith following datasets
      % ('automatic') but could get complicated so just error if we have a
      % mixed directions for now. 
      if ~all(diff(axrvs)==0)
        error('One or more axis scales are reversed. Check all data axis scales and confirm scales are all in same orientation (increasing or decreasing).')
      end

      %Identify the most common axisscale
      axsets = struct('axisscale',axs{1},'count',size(dsos{1},1),'size',szs(1),'min',axmin(1),'max',axmax(1),'std',axstd(1),'spacing',axspacing(1));
      for j=2:ndso
        minmatch = [axsets.min]==axmin(j);
        maxmatch = [axsets.max]==axmax(j);
        stdmatch = [axsets.std]==axstd(j);
        spcmatch = [axsets.spacing]==axspacing(j);
        szmatch  = [axsets.size]==szs(j);
        ismatch  = (minmatch & maxmatch & stdmatch & spcmatch & szmatch);
        if any(ismatch) & all(axsets(min(find(ismatch))).axisscale==axs{j})
          %matches an existing one, increase count on that one
          %NOTE: the above comparison does a test of the axisscale
          %directly. It is possible that this isn't needed (because all the
          %statistics which we've aready teseted in "ismatch" describe
          %everything we need) but I'm leaving that test in for now. It may
          %be slow for VERY large data sets though, so we could consider
          %removing it if we can confirm we don't need it.
          axsets(min(find(ismatch))).count = axsets(min(find(ismatch))).count+size(dsos{j},1);
        else
          %new axisscale, add to list of sets
          axsets(end+1) = struct('axisscale',axs{j},'count',size(dsos{j},1),'size',szs(j),'min',axmin(j),'max',axmax(j),'std',axstd(j),'spacing',axspacing(j));      
        end
      end
      
      if ~all(axspacing==axspacing(1))
        %not all have the same resolution?
        spacing = [axsets.spacing];
        axsets(spacing<max(spacing)) = [];  %drop any at less than lowest resolution
      end        
      
      %choose the one with the most similar axisscales
      counts = [axsets.count];  %get list of counts
      axsets(counts<max(counts)) = [];  %drop any that have fewer than the max votes
      axsets = axsets(1);  %use first of whatever is left
      
      %extend selected master axisscale out to min and max (starting from
      %end points of selected axisscale and using fixed spacing
      %resolution). Note this does NOT handle non-linear axisscales well.
      %That would need to be handled by somehow fitting the non-linear
      %step sizes
      masteraxis = axsets.axisscale;
      myspacing = axsets.spacing;
      if all(axrvs)
        %Axis scales are reversed.
        masteraxis = [fliplr(max(masteraxis)+myspacing:myspacing:max(axmax)) masteraxis min(masteraxis)-myspacing:-myspacing:min(axmin)];
      else
        masteraxis = [fliplr(min(masteraxis)-myspacing:-myspacing:min(axmin)) masteraxis max(masteraxis)+myspacing:myspacing:max(axmax)];
      end
      
      if anyhas(dsos,'label',1) | anyhas(dsos,'axisscale',1) | anyhas(dsos,'class',1) | anyhas(dsos,'class',2)
        %if there are any non-empty fields in the DSOs, do the slower (but
        %more complete) join based on DSOs
        %matchvars on all and assign new axisscale
        dsos = cellfun(@(d) domatch(d,masteraxis,[],options.axismode),dsos,'uniformoutput',false);
        dsos = cellfun(@(d) subsasgn(d,substruct('.','axisscale','{}',{2}),masteraxis),dsos,'uniformoutput',false);
      else
        %No labels or other info? do it easy/quick way
        data = cellfun(@(d) domatch({d.data d.axisscale{2} ''},masteraxis,[],options.axismode),dsos,'uniformoutput',false);
        joined = dataset(cat(1,data{:}));
        joined.axisscale{2} = masteraxis;
        return;
      end

    end
  end
  
  %join DSOs
  joined = cat(1,dsos{:});
  
elseif all(nonemptylbls)   %LABELS matching
  %use labels to match
  if ~all(szs==szs(1)) | any(cellfun(@(l) ~strcmpi(l,lbls{1}),lbls))
    %some sizes or labels do not match
    %Identify the superset of labels
    nlbl = cellfun(@(l) size(l,1),lbls);
    [junk,order] = sort(-nlbl); %start with DSO with MOST labels
    masterlbl = lbls{order(1)};
    for j=2:ndso
      %add any labels which appear that aren't in list already
      masterlbl = [masterlbl;setdiff(lbls{order(j)},masterlbl)];
    end
    
    %matchvars on all and assign new labels
    dsos = cellfun(@(d) domatch(d,masterlbl,[],options.axismode),dsos,'uniformoutput',false);
    dsos = cellfun(@(d) subsasgn(d,substruct('.','label','{}',{2}),masterlbl),dsos,'uniformoutput',false);
    
  end
  
  %join DSOs
  joined = cat(1,dsos{:});
  
else   %SIZE matching
  %match size in simple manner
  if ~all(szs==szs(1))
    %mismatched sizes pad as needed
    targetsize = max(szs);
    dsos = cellfun(@(d) [d nan(size(d,1),size(d,2)-targetsize)],dsos,'uniformoutput',false);    
  end
  
  %join DSOs
  joined = cat(1,dsos{:});
  
end
%--------------------------------------------------------
function out = anyhas(dsos,feyld,mode)
%returns TRUE if any of the DSOs in the cell array (DSOS) have non-empty
%entries for the given mode and field

out = any(cellfun(@(d) any(~cellfun('isempty',d.(feyld)(mode,:))),dsos));


%--------------------------------------------------------
function out = isdsocell(in)

if iscell(in) & ~isempty(in) & all(cellfun(@(i) isdataset(i),in))
  out = true;
else
  out = false;
end
