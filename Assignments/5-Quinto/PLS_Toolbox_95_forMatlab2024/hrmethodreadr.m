function pp = hrmethodreadr(filename,varargin)
%HRMETHODREADR Convert a Kaiser HoloReact band integration methods into a preprocessing structure.
% Converts method files created by Kaiser Optical System's HoloReact
% software into a preprocessing method for use with PLS_Toolbox or Solo.
% Input is a HoloReact Method file (.mat format). If ommitted, the user is
% prompted to locate a valid method file.
%
% The output is a preprocessing structure which can be used with Preprocess
% (through Analysis GUI, Preprocess, or at the command line) that will take
% a spectrum and convert it into discrete variables based on baselining,
% integrating, and/or point measurements.
%
% When a spectrum is processed, each marked region will be converted into a
% single new variable in the output spectrum. These new variables are
% stored starting at the first included variable of the original spectrum.
% All remaining variables are zeroed out. Thus the entire spectrum is
% replaced with the integration results plus many uninteresting (all-zero)
% variables. All excluded variables are zeroed out and ignored.
%
% This converter works with Kaiser Analysis methods:
%    baseline
%    integrate
%    point
% It does not allow the peak height, peak width, PCA, or MCR analysis
% methods in the HoloReact software. Baseline method works with either
% global points and order settings or peak-specific points and order
% settings. No other preprocessing steps are converted from the Method
% file.
%
%OPTIONAL INPUTS:
%  filename = A .mat file saved from the HoloReact software. If omitted,
%             user is prompted for filename.
%OUTPUTS:
%  pp = A preprocessing structure which can be used with preprocess.m or
%      loaded into the preprocessing GUI (e.g. via Analysis)
%
%I/O: pp = hrmethodreadr(filename)
%
%See also: BASELINE, PREPROCESS

% Copyright © Eigenvector Research, Inc. 2009
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Hidden options:
%I/O: pp = hrmethodreadr('default')  %return default preprocessing  
%I/O: pp = hrmethodreadr(pp)         %load NEW file or return existing pp if none loaded or error
%I/O: pdata = hrmethodreadr(data,userdata)  %apply preprocessing to data

if nargin==2;
  %Two items passed, must be (data,userdata) indicating apply preprocessing
  pp = calibrate(filename,varargin{:});
  return
end

if nargin==0 | isempty(filename)
  %no filename? prompt user to load one
  [filename,pth] = evriuigetfile({'*.mat' 'HoloReact Method File (*.mat)'},'Load HoloReact Method File');
  if isnumeric(filename)
    pp = default;
    return
  end
  filename = fullfile(pth,filename);
end

if nargin==1 & isstruct(filename)
  %preprocessing structure passed in - settings call
  pp = filename;
  try
    ppnew = hrmethodreadr('');  %try loading new preprocessing
  catch
    evrierrordlg(lasterr,'Could not load method file');
    ppnew = [];
  end
  %If user clicks cancel return empty structure. 
  if ~isempty(ppnew) & isempty(ppnew.userdata.filename)
    pp = [];
    return
  end
  
  if ~isempty(ppnew) & ~isempty(ppnew.userdata.filename)
    %if they actually completed the load, use it
    pp = ppnew;
    if isempty(pp.userdata.axisscale)
      evriwarndlg(sprintf('The HoloReact file "%s" was converted into preprocessing, however no axisscale information exists.\n\nThis method will not be able to process spectra without an included variable axisscale.\n\nReload from a saved HoloReact data file (rather than a method file) to avoid this problem.',pp.userdata.filename),'HoloReact File Processed');
    else
      evrihelpdlg(sprintf('The HoloReact file "%s" was successfully converted into preprocessing.',pp.userdata.filename),'HoloReact File Processed');
    end
  end
  return
end

if ischar(filename) 
  if strcmp(filename,'default')
    %return default preprocessing structure
    pp = default;
    return
  elseif ismember(filename,evriio('','validtopics'))
    %handle evriio call
    options = [];
    if nargout==0; evriio(mfilename,filename,options);
    else pp = evriio(mfilename,filename,options); end
    return
  end
end

%--------------------------------
%actual load and encoding of file

p = load(filename,'-mat');

%see whether this is a Method file and extract necessary info
if ~isfield(p,'obj');
  if isfield(p,'storedpeaksets')
    p = p.storedpeaksets;
  else
    error('Unrecognized file format. Expected saved HoloReact Data or Method file')
  end
end

if ~ismember(p.obj.Analysis.userdata,{'point', 'baseline','integration'})
  error('Cannot encode this Analysis method type ("%s")',p.obj.Analysis.userdata)
end

%gather general and global information
gpnts  = str2double(p.obj.xrngtext.string);
gorder = p.obj.baselineorder.value;
pnts   = p.currentpoints(1,setdiff(1:end,3:3:end));
nregions = length(pnts)/2;

if size(p.currentpoints,1)>2;
  %manual baseline settings (individualized per region)
  order  = p.currentpoints(3,3:3:end);
  blpnts = p.currentpoints(3,setdiff(1:end,3:3:end));
else
  %global baseline settings for all regions
  order  = gorder.*ones(1,nregions);
  blpnts = gpnts.*ones(1,nregions*2);
end

newregion = struct('integrate',[],'order',[],'baseline',[],'integratemask',[]);
regions   = newregion([]);
for j=1:nregions;
  ind = [j*2-1 j*2];  %determine peak indexing
  
  %copy baseline information
  if strcmp(p.obj.Analysis.userdata,'baseline')
    regions(j).order = order(j);
    regions(j).baseline = [pnts(ind(1))+[0 blpnts(ind(1))]; pnts(ind(2))-[blpnts(ind(2)) 0]];
  end
  
  %store integration region
  if strcmp(p.obj.Analysis.userdata,'point')
    %repeat first point when doing "point" mode (intensity at a given point)
    pnts(ind(2)) = pnts(ind(1));
  end  
  regions(j).integrate = pnts(ind);
end

%create userdata with all flags
pp = default;
pp.userdata.filename    = filename;
pp.userdata.regions     = regions;
if isfield(p,'xaxis');
  pp.userdata.axisscale   = p.xaxis;
end
pp.userdata.ratioed     = p.obj.ratiobox.value;
pp.userdata.normtototal = strcmp(p.obj.normtototal.checked,'on');

%The preprocessing structure to perform this operation:
switch p.obj.Analysis.userdata
  case 'baseline'
    pp.description = 'HoloReact Baseline and Integrate';
  case 'integration'
    pp.description = 'HoloReact Integrate';
  case 'point'
    pp.description = 'HoloReact Point Measurement';
end
[pth,file] = fileparts(filename);
pp.description = sprintf('%s (%s)',pp.description,file);

%===========================================================
function pp = default
%return blank default preprocessing structure

pp.description = 'Kaiser HoloReact Method';
if exist('isdeployed') & isdeployed
  pp.calibrate = {'data = hrmethodreadr(data,userdata);'};
  %can only use the above line if we've compiled this file in with the
  %application. Otherwise, we have to use the next line which has code copied
  %from "calibrate" function below
else
  pp.calibrate = {'temp = data.data.*0;if isempty(data.axisscale{2}); data.axisscale{2} = userdata.axisscale; end;if isempty(data.axisscale{2}); error(''axisscale required''); end;for j=1:length(userdata.regions);  if ~isempty(userdata.regions(j).baseline);    bldata = baseline(data,userdata.regions(j).baseline,struct(''order'',userdata.regions(j).order));  else;    bldata = data;  end;  if ~isempty(userdata.regions(j).integratemask);    temp(:,data.include{2}(j)) = bldata.data(:,data.include{2})*userdata.regions(j).integratemask(data.include{2},:);  else;    inds = findindx(data.axisscale{2}(data.include{2}),sort(userdata.regions(j).integrate));    temp(:,data.include{2}(j)) = sum(bldata.data(:,data.include{2}(min(inds):max(inds))),2);  end;end;if userdata.ratioed;  temp(:,1:end-1) = scale(temp(:,2:end)'',temp(:,1)''.*0,temp(:,1)'')'';  temp(:,end) = 0;end;if userdata.normtototal;  temp = normaliz(temp,[],1);end;data.data = temp;'};  
end
pp.apply = pp.calibrate;
pp.undo = {};
pp.out = {};
pp.settingsgui = 'hrmethodreadr';
pp.settingsonadd = 1;
pp.usesdataset = 1;
pp.caloutputs = 0;
pp.keyword = 'holoreact';
pp.tooltip = 'Baseline and integrate based on Kaiser HoloReact method file';
pp.category = 'Filtering';
pp.userdata = struct('filename','','regions',[],'ratioed',0,'normtototal',0,'axisscale',[]);

%===========================================================
function data = calibrate(data,userdata)
%Apply the preprocessing to some data
%this function is only called when we're deployed (i.e. compiled)
%otherwise, this simply holds the code to be performed during apply and
%calibration. Changes here must be echoed into the "default" function
%above.

temp = data.data.*0;
if isempty(data.axisscale{2}); data.axisscale{2} = userdata.axisscale; end;
if isempty(data.axisscale{2}); error('axisscale required'); end;
for j=1:length(userdata.regions);
  if ~isempty(userdata.regions(j).baseline);
    bldata = baseline(data,userdata.regions(j).baseline,struct('order',userdata.regions(j).order));
  else;
    bldata = data;
  end;
  if ~isempty(userdata.regions(j).integratemask);
    temp(:,data.include{2}(j)) = bldata.data(:,data.include{2})*userdata.regions(j).integratemask(data.include{2},:);
  else;
    inds = findindx(data.axisscale{2}(data.include{2}),sort(userdata.regions(j).integrate));
    temp(:,data.include{2}(j)) = sum(bldata.data(:,data.include{2}(min(inds):max(inds))),2);
  end;
end;
if userdata.ratioed;
  temp(:,1:end-1) = scale(temp(:,2:end)',temp(:,1)'.*0,temp(:,1)')';
  temp(:,end) = 0;
end;
if userdata.normtototal;
  temp = normaliz(temp,[],1);
end;
data.data = temp;

