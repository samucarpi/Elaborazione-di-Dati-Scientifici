function [binHFData,LFData,flipinput] = bin2scale(data_hf,data_lf,options)
%BIN2SCALE Bin higher frequency data set to a lower frequency data set.
%  Deresolve incoming high frequency data to a lower frequency scale based
%  on axis scale timestamps. Binning is done using coadd function.
%
%  All occurances of high frequency (HF) data is coadded between each time
%  point in the low frequency (LF) data. 
%
% INPUTS:
%   data_hf      = Higher frequency (HF) data.
%   data_lf      = Lower frequency data or time scale (dataset, vector, or
%                  scalar). If scalar then value is used as interval (in seconds).
%
% OUTPUTS:
%   binHFData    = Binned high frequency data.
%   LFData       = Truncated low frequency (LF) data. Data will be truncated at
%                  either end if it extends farther than limits of HF data. 
%   flipinput    = if data_hf appears to be lower frequency than data_lf
%                  then this flag indicates order of input was flipped and
%                  recursive call made. 
%
% OPTIONAL INPUTS:
%       axisscaleset : [] Set to use for axisscale time. Default = empty
%                      indicates automatic detection. Value can be 2
%                      element vector, first element will be data axisscale
%                      set and second element is scale_new axisscale set.
%       windowoffset : [] (double) Adjust window position with date vector
%                      size (1=one day):
%                      three_secons = datenum(0,0,0,0,0,3)
%                      Note: this is relative to .windowposition.
%         windowsize : [] Size of window in serial date time (1 = 1 day, .5
%                      = 12 hrs). Empty (default) uses largest window for a
%                      given step.
%    windowsizeunits : ['days'|{'seconds'}|'percent'] If window size is
%                      used interpret size in these units. The 'percent'
%                      setting is relative to each window size while
%                      'seconds' and 'days' are not relative.
%    windowerrortime : [1.16e-08] Error allowed prior to time point.
%                      Default is datenum([0,0,0,0,0,.001]) or one micro
%                      second.
%   windowerrorpercent : [0.1] Percent error allowed prior to time point.
%       coadd_labels : [{'first'}|'all'|'middle'|'last'] method of combining
%                      labels (if any exist).
%
%      NOTE: The smaller (min) of .windowerrortime .windowerrorpercent is
%            used when calculating allowed error. This will assure better
%            behavior if time points are very close together.
%
%I/O: [binHFData,LFData] = bin2scale(data_hf,data_lf);
%I/O: [binHFData,LFData] = bin2scale(data_hf,data_lf,options);%Use options.
%
%See also: COADD, DERESOLV, MULTIBLOCK, REGISTERSPEC

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%QUESTIONS:
%  Do we need setting for cuttoff in precision?
%
%TODO: Add classes for each dataset var.
%TODO: Add monotonic scale handling. See multibock.

if nargin == 0; data_hf = 'io'; end

if ischar(data_hf);
  options.axisscaleset    = [];
  options.windowposition  = 'end';
  options.windowoffset    = 0;
  options.windowsize      = [];
  options.windowsizeunits = 'seconds';
  options.windowerrortime = datenum([0,0,0,0,0,.001]);%Allowed error for time point.
  options.windowerrorpercent = 0.1;%Percent error for time point.
  options.coadd_labels = 'first';%Coadd options for labels to use ('all','first','middle','last').
  
  %options.use_edges       = 'off';
  if nargout==0; evriio(mfilename,data_hf,options); else; binHFData = evriio(mfilename,data_hf,options); end
  return; 
end

if ~isdataset(data_hf)
  error('First input must be dataset.')
end

if nargin<2
  error('2 inputs are required.')
end

if nargin<3
  options = bin2scale('options');
end

flipinput = 0;
binHFData = [];

options = reconopts(options,mfilename);

%Get axisscale set to use.
if isempty(options.axisscaleset)
  hf_axset = getAxisscaleSet(data_hf);
  lf_axset = getAxisscaleSet(data_lf);
else
  if length(options.axisscaleset) == 1
    hf_axset = options.axisscaleset;
    lf_axset = options.axisscaleset;
  else
    hf_axset = options.axisscaleset(1);
    lf_axset = options.axisscaleset(2);
  end
end

%Get original scale.
scale_hf = data_hf.axisscale{1,hf_axset};
if isempty(scale_hf)
  error('Axisscale is empty.')
end

%Make low frequency scale.
scale_lf = data_lf;

if isscalar(scale_lf)
  %Make scale at specified intervals.
  scale_lf = scale_hf(1):scale_lf:scale_hf(end);
  data_lf  = scale_lf';
elseif isdataset(scale_lf)
  %Get scale from dataset.
  scale_lf = scale_lf.axisscale{1,lf_axset};
end

if isempty(scale_lf)
  error('Axisscale is empty.')
end

%Get intervals between time points.
lf_intervals = diff(scale_lf);
hf_intervals = diff(scale_hf);

lf_mean = mean(lf_intervals);
hf_mean = mean(hf_intervals);

%If mean of new intervals is smaller and they're both
%DSOs, then switch order of inputs and do recursive call.
if ~isempty(data_lf) & hf_mean>lf_mean
  %Need to flip options.axisscaleset if it has 2 elements.
  if size(options.axisscaleset,2) == 2
    options.axisscaleset = fliplr(options.axisscaleset);
  end
  [binHFData,LFData] = bin2scale(data_lf,data_hf,options);
  flipinput = 1;
  return
end

% %Time point location relative to window.
% winpos = 1;%Time point at end of bin window.
% if strcmp(options.windowposition,'middle')
%   winpos = 2;
% elseif strcmp(options.windowposition,'beginning')
%   winpos = 3;%Time point at beginning of window.
% end

winsz = options.windowsize;
winun = 1;%Days
%Change units into serial date (days).
switch options.windowsizeunits
  case 'seconds'
    winsz = winsz/(60*60*24);
    winun = 2;%Seconds.
  case 'percent'
    winsz = [];
    winun = 3;%Percent.
    if isempty(options.windowsize)
      error('WINDOWSIZE option must be assigned when using "percent" window size units');
    end
end

%Get start, interval, and stop times.
lf_length = length(scale_lf);

%Find first time point in LF scale that's greater than first time point in
%HF scale. Make sure edge offset is used when options is set so beginning
%and end of binned data get calculated in the correct window.
% if strcmp(options.use_edges,'off')
%   %Must have a full window to create a bin.
%   switch options.windowposition
%     case 'beginning'
%       %Bin window is after time point.
%       lf_start_index = find(scale_lf>scale_hf(1),1,'first');
%     case 'middle'
%       %Bin window is centered on time point.
%       lf_start_index = find(scale_lf>scale_hf(1)+(lf_mean/2),1,'first');
%     otherwise
%       %Bin window is before (lagging) time point.
%       lf_start_index = find(scale_lf>scale_hf(1)+lf_mean,1,'first');
%   end
% else
%   %Just use first point, edges will bin over whatever data is available.
%   lf_start_index = find(scale_lf>scale_hf(1)+lf_mean,1,'first');
% end

%Get first position of overlap in both scales.
lf_start_index = find(scale_lf>=scale_hf(1),1,'first');

%DEBUG NOTE:
%In demo data:
%   datestr(scale_hf(1)) = 08-Oct-2008 09:05:02
%   datestr(scale_hf(2)) = 08-Oct-2008 09:05:06
%   ... 4 seconds
%
%   datestr(scale_lf(1)) = 08-Oct-2008 09:04:57
%   datestr(scale_lf(2)) = 08-Oct-2008 09:06:57
%   datestr(scale_lf(3)) = 08-Oct-2008 09:08:56
%   ... 120 seconds

%Make vector of index locations LF>HF so can see what HF indices where
%grouped for LF index.
lf_grouping_index = zeros(1,size(data_hf,1));

%Coadd option for mode, default is 2 but needs to be 1.
opts.dim = 1;
opts.labels = options.coadd_labels;

%Keep track of last valid index so original LF data can be truncated as
%needed.
lastidx = [];

%Loop through index (each row) of new scale. Loop will break if we reach
%the end. 
for i = lf_start_index:lf_length
  thissz = winsz;%This window size in days.
  if isempty(thissz)
    %Use relative window size. This can change if time intervals are not
    %evenly spaced.
    if i<=length(lf_intervals)
      thissz = lf_intervals(i);
    else
      lastidx = i-1;%Use i to truncate to last whole interval.
      break
    end
%     if i==1
%       %At beginning of LF intervals so size is 0 because there is no
%       %interval before the first.
%       thissz = 0;
%     else
%       thissz = lf_intervals(i-1);
%     end
    if winun==3
      %Percent of interval.
      thissz = thissz*(options.windowsize/100);
    end
  end
  
%   %Check size.
%   if thissz>lf_intervals(i-1)
%     %Window width is too big so reduce size to the interval width.
%     thissz = lf_intervals(i-1);
%   end
  
  %Basis time stamp.
  this_time = scale_lf(i);

  %Apply error offset.
  myerr = min(options.windowerrortime,((options.windowerrorpercent/100)*thissz));
  
  %Apply offset.
  this_time = this_time+options.windowoffset;
  
  %Get positions relative to basis.
  p1 = find(scale_hf>=this_time-myerr,1,'first');
  p2 = find(scale_hf<=this_time+thissz-myerr,1,'last');
  
%   if winpos==1
%     %Window is prior to time point.
%     p1 = find(scale_hf>=this_time-thissz,1,'first');
%     p2 = find(scale_hf>=this_time,1,'first');
%   elseif winpos ==2
%     %Window is centered.
%     p1 = find(scale_hf>=this_time-(thissz/2),1,'first');
%     p2 = find(scale_hf>=this_time+(thissz/2),1,'first');
%   else
%     %Window is after time point.
%     p1 = find(scale_hf>=this_time,1,'first');
%     p2 = find(scale_hf>=this_time+thissz,1,'first');
%   end
  
  %Past edge of data.
  if isempty(p1)
    lastidx = i-1;%Use i to truncate to last whole interval.
    break
  end
  
  %At last interval so try using what's left.
  if isempty(p2)
    p2 = length(scale_hf);
%     if p1==p2
%       %Use i to truncate to last whole interval.
%       lastidx = i-1;%Use i to truncate to last whole interval.
%       break
%     end
  end
    
  %Get data to bin.
  thisdata = data_hf(p1:p2,:);
  
  if isempty(thisdata)
    %Maybe no data for this spot so infill with Nan.
    thisdata = nan(1,size(data_hf,2));
  end
  
  thisdata = coadd(thisdata,size(thisdata,1),opts);
  
  %Change axisscale to match 'this_time' after coadd.
  thisdata.axisscale{1,hf_axset} = this_time;
  
  %Track grouping of LF to HF indices.
  lf_grouping_index(p1:p2) = i;
  
  %Cat the data.
  binHFData = [binHFData; thisdata];
  if iscell(binHFData.userdata) & length(binHFData.userdata)>1
    %User data gets concatenated each time into a cell. Need to replace
    %with second dataset userdata {2}. 
    binHFData.userdata = binHFData.userdata{2};
  end
  
end

%Add options and grouping info to userdata.
ud = [];
ud.options     = options;
ud.LF_grouping = lf_grouping_index;
ud.LF_datasource = getdatasource(data_lf);
ud.HF_datasource = getdatasource(data_hf);

if ~isempty(binHFData)
  if ~isfield(binHFData.userdata,'bin2scale')
    if iscell(binHFData.userdata)
      %When both Datasets of a cat have userdata a cell containing both is
      %added. Replace that here to avoid small memory leak.
      binHFData.userdata = binHFData.userdata{2};
    end
    if isstruct(binHFData.userdata)
      binHFData.userdata.bin2scale = ud;
    else
      %Something strange in userdata, need to replace so we can add bin2scale parameters. 
      binHFData.userdata = [];
      binHFData.userdata.bin2scale = ud;
    end
  else
    binHFData.userdata.bin2scale = [binHFData.userdata.bin2scale ud];
  end
end

if isempty(lastidx)
  lastidx = i;
end

if nargout>1
  LFData=data_lf(lf_start_index:lastidx);
end

%DEBUG for size match, remove later.
if size(LFData,1)~=size(binHFData,1)
  warning('EVRI:Bin2scaleSizeMismatch','Size missmatch in data.')
end

%-----------------------------
function [thisset] = getAxisscaleSet(data)
%Go through mode 1 of dataset and look for the first one that has a time
%stamp.

thisset = gettimeaxisset(data,1);

%-----------------------------
function thisset = gettimeaxisset(data,mymode)
%GETTIMEAXISSET Locate time axis in a dataset.

%NOTE: This is overload of orginal function. May need to update if orginal
%function is added to main toolbox. 

%Go through mode 1 of dataset and look for the first one that has a time
%stamp.
if nargin<2
  mymode = 1;
end

thisset = [];
if ~isdataset(data)
  return
end

modeax = data.axisscale(mymode,:);

for i = 1:size(modeax,2)
  thisaxis = data.axisscale{mymode,i};
  if ~isempty(thisaxis) & thisaxis(1)>datenum('1/1/1900') & thisaxis(end)<datenum('1/1/2300')
    thisset = i;
    break
  end
end


%-----------------------------
function test

load('/Volumes/HD_2/LocalSVNR/Dev_Bob/rtr_mfiles/Lilly apps/align_data/IR and MS data for aligning.mat')

opts = bin2scale('options');

%Basic call.
tic
[msnew,irnew] = bin2scale(ms_ds,ir_ds);
toc 

%Change window position.
opts.windowposition = 'beginning';
[msnew,irnew] = bin2scale(ms_ds,ir_ds,opts);

opts.windowposition = 'middle';
[msnew,irnew] = bin2scale(ms_ds,ir_ds,opts);

%Flip inputs (both must be dataset).
[msnew,irnew] = bin2scale(ir_ds, ms_ds);

%Change width.
opts.windowsize = .005;
opts.windowsizeunits = 'days';
[msnew,irnew] = bin2scale(ms_ds,ir_ds,opts);

opts.windowsize = 432;
opts.windowsizeunits = 'seconds';
[msnew,irnew] = bin2scale(ms_ds,ir_ds,opts);

opts.windowsize = 50;
opts.windowsizeunits = 'percent';
[msnew,irnew] = bin2scale(ms_ds,ir_ds,opts);


%Try equal spaced.
[msnew,irnew] = bin2scale(ms_ds,.005);

%Crop the ms data.
[msnew,irnew] = bin2scale(ms_ds(1:100),ir_ds);

%Crop the ir data.
[msnew,irnew] = bin2scale(ms_ds,ir_ds(1:30));

%Try offset.
opts.windowposition = 'end';
opts.windowoffset   = 0.00031131;

[msnew,irnew] = bin2scale(ms_ds,ir_ds,opts);

ms_ds2 = ms_ds;

irax = ir_ds.axisscale{1};
msax = ms_ds.axisscale{1};

mydiff = mean(diff(irax));
mydiff2 = mean(diff(msax));
%About 30 MS samples per IR sample. So make first 10 ones then try binning
%with windowoffset and size to test.

ms_ds2.data([1:50],:) = ones(50,45);%Little more than 1/2 bin is ones.

opts.windowposition  = 'end';
opts.windowoffset    = 0;
opts.windowsize      = [50];%50 percent has about 15-16 intervals in the bin.
opts.windowsizeunits = 'percent';

[msnew,irnew] = bin2scale(ms_ds2,ir_ds,opts);

msnew.data(1,:)%No offset yet so still has msdata.

opts.windowoffset    = -20*mydiff2;%Move 20 ms time intervals backward (into ones data).

[msnew,irnew] = bin2scale(ms_ds2,ir_ds,opts);

msnew.data(1,:)%Has all ones.

%See what affect different frequencies have with different options.
a = dataset(rand(5));
a.axisscale{1} = [datenum('4/8/2014') datenum('4/9/2014') datenum('4/12/2014') datenum('4/14/2014') datenum('4/15/2014')];

b = dataset(ones(30,1)*[1:30]);
b.axisscale{1} = linspace(datenum('4/8/2014'),datenum('4/15/2014'),30);

[msnew,irnew] = bin2scale(a,b);

%OLD CODE, GET RID OF IT WHEN SURE NOT GOING BACK TO FRACTIONAL BEHAVIOR.

% %Times and indexes on data input.
% data_start_index       = min(find(scale_old>=scale_start_time));%Index of closest start time.
% data_start_time        = scale_old(data_start_index);%Behind closest start time.
% data_end_index         = min(find(scale_old>=scale_end_time));%Index of closest end time.
% data_end_time          = scale_old(data_end_index);%Closest end time.
% data_interval          = scale_old(2) - scale_old(1);%Time between data (smaller) intervals.
% data_remainder_behind  = (scale_start_time - data_start_time)/data_interval;
% data_remainder_ahead   = (scale_end_time - data_end_time)/data_interval;
% data_span              = (data_end_time-data_start_time)/data_interval;%Full steps that span the scale_new interval.
% 
% c = matchscale(ms_ds,ir_ds,opts);

%Test identical scales.
x1 = dataset([1:20]');
x1.axisscale{1} = now+[0:19]/24/60;
[x1b,x2b] = bin2scale(x1,x1);
x1b.data

%Test same scale with offset.
x1 = dataset([1:20]');
x1.axisscale{1} = now+[0:19]/24/60;
x2 = x1;
x2.axisscale{1} = x1.axisscale{1}+1/24/60;
%NOTE: x2.axisscale{1}(1) matches x1.axisscale{1}(2)!!!
[x1b,x2b] = bin2scale(x1,x2);
x1b.data

%Simple tests

hf = dataset([1 1 1 1 1 5 5 5 5 5]');%High frequency data.
ts = now+[0:19]/24/60;%20 time points.
hf.axisscale{1} = ts(5:14);%10 time points in middle.

lf = dataset([10 20 30]');%Low frequency data.

%LF time points completely inside of HF range.
lf.axisscale{1} = [ts(7) ts(10) ts(12)];
[a,b] = bin2scale(lf,hf);
a.data%Answer is [1 5]

%First LF starts before HF so drop first interval.
lf.axisscale{1} = [ts(1) ts(10) ts(12)];
[a,b] = bin2scale(lf,hf);
a.data%Answer is [5]

%Last LF outside of HF range so takes all available HF data.
lf.axisscale{1} = [ts(7) ts(10) ts(19)];
[a,b] = bin2scale(lf,hf);
a.data%Answer is [1 5]

%Only first LF is overlap with HF data.
lf.axisscale{1} = [ts(13) ts(17) ts(19)];
[a,b] = bin2scale(lf,hf);
a.data%Answer is [5]

%No overlap, return empty.
lf.axisscale{1} = [ts(17) ts(18) ts(19)];
[a,b] = bin2scale(lf,hf);
a %Answer is []

%No overlap, return empty.
lf.axisscale{1} = [ts(1) ts(2) ts(3)];
[a,b] = bin2scale(lf,hf);
a %Answer is []

lf.axisscale{1} = [ts(2) ts(5) ts(8)]

[a,b] = bin2scale(lf,hf);
a.data

%Test order of join. Should be 1 1 2 2 3 3 and A,B,C
a = dataset(rand(50,2));
b = dataset(rand(90,2));
c = a;
a.axisscale{1} = now+[0:49]/24/60;
b.axisscale{1} = now+linspace(0,49,90)/24/60;
c.axisscale{1} = now+linspace(4,53,50)/24/60;
a.name = 'A';
b.name = 'B';
c.name = 'C';
[mod,joined] = multiblock({a b c});
joined.class{2}
joined.name



