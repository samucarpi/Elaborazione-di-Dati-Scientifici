function data = spxreadr(fname)
%SPXREADR reads in a Bruker Tracer .spx file into a DataSet Object
% Input is the filename of a SPX file to read. If omitted, the user is
% prompted for a file.
%
% The imported files are returned in a Dataset Object, or a cell array if 
% they have differing variable axisscales, or number of variables AND the 
% nonmatching option = 'cell'. The header information from the rda file is
% put in the .userdata field.
%
% OPTIONAL INPUTS:
%  filename = either a string specifying the file to read or a cell
%             array of strings specifying multiple files to read. 
%             If (fname) is empty or not supplied, the user is
%             prompted to identify files to load.
%   options = an options structure containing the following fields:
% nonmatching : ['error'|{'matchvars'}|'cell'] Governs behavior 
%               when multiple files are being read which cannot be combined
%               due to mismatched types, sizes, etc.
%               'matchvars' returns a dataset object,
%               'cell' returns cell (see outputs, below), 
%               'error' gives an error.
%      waitbar: [ 'off' |{'on'}] Governs display of waitbar when doing
%                multiple file reading.
%
% OUTPUTS:
%   data = a DataSet object containing the spectrum or spectra from the
%          file(s), or an empty array if no data could be read.
% OUTPUT:
%   data = takes one of two forms:
%       1) If input is a single file, or multiple files containing data that
%          can be combined (same number of data points, same x-axis range,
%          same type of data), the output is a dataset object
%       2) If the input consists of multiple files containing data that
%          cannot simply be combined (different number of data points, 
%          differing x-axis ranges, etc), the output is either:
%          a cell array with a dataset object for each input file if the
%          'nonmatching' option has value 'cell', or
%          a dataset object containing the input data combined using the
%          MATCHVARS function if the 'nonmatching' option has value 
%          'matchvars'.
%
%I/O: dso = spxreadr(filename)
%I/O: dso = spxreadr(filename,options)
%
%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

evriwarndlg('SPXREADR is currently under development and is not designed for routine use.', 'SPXREADR ERROR');
return

if nargin==1 & ischar(fname) & ismember(fname,evriio('','validtopics'))
  options = [];
  options.nonmatching = 'matchvars';
  options.waitbar = 'on';
  if nargout==0
    clear data; 
    evriio(mfilename,fname,options); 
  else 
    data=evriio(mfilename,fname,options); 
  end
  return
end

switch nargin
  case 0
    % ()
    fname = [];
    options = [];
  case 1
    % (filename)
    % (options)
    if isstruct(fname)
      options = fname;
      fname = [];
    else
      options = spxreadr('options');
    end
  case 2
    % (filename,options)
end
options = reconopts(options,mfilename);

if isempty(fname)
  %no filename passed (or empty), prompt user
  [nm,pth]=evriuigetfile('*.spx','please select a .spx file to load','multiselect','on');
  if isnumeric(nm)
    data = [];
    return
  end
else
  nm = fname;
  pth = '';
end
if isempty(nm) | isnumeric(nm)
  data = [];
  return
end
cl = 0;
if iscell(nm)
  if length(nm)==1
    nm = nm{1};
  else
    cl = 1;
    start = now;
    h = [];
    %more than one name in cell? concatenate all items
    for j=1:length(nm)
      %read in one file
      n = nm{j};
      [onefile,base{j}]       = readspxfile(n);
      if isempty(onefile)
        data = [];
        return;
      end
%       info{j}.Filename = base{j};
      if j>1 & size(data{1},2)~=size(onefile,2)
        if strcmp(options.nonmatching, 'error')
          error('File "%s" has a different number of variables than the previous file(s) and cannot be combined',nm{j});
        end
      end
      
      if strcmp(options.nonmatching, 'cell')
        onefile = addsourceinfo(onefile, nm{j});
      end
      onefile.label{1}      = repmat(base{j},size(onefile,1),1);
      onefile.name          = '';
      data{j}                = onefile;
      data{j}.labelname{1,1} = 'Filename';
%       data{j}.userdata       = info{j};
      
      if ishandle(h)
        waitbar(j/length(nm),h);
      elseif ~isempty(h) & ~ishandle(h)
        error('User cancelled operation')
        data = [];
        return;
      elseif strcmp(options.waitbar,'on') & (now-start)>1/60/60/24
        h = waitbar(0,'Loading SPX Files...');
      end
    end
    if strcmp(options.nonmatching, 'matchvars')
      data          = matchvars(data);
      data          = addsourceinfo(data,nm);
      data.name     = 'Multiple SPX files';
%       data.userdata = info;
    end
    if ishandle(h)
      delete(h);
    end
    return
  end
end


dso = readspxfile(nm);
data = dso;

%---------------------------------------------------
function [d, base] = readspxfile(fname,cl)
[fpth,base,ext] = fileparts(fname);

if ~strcmp(ext,'.spx')
  if cl
    error('Cell array must only contain SPX Files') %error message if input is a cell array
  else
    error('Input must be an SPX File')
  end
end


try
  pfile = parsexml(fname);
catch
  d = [];
  error('PARSEXML failed')
end

vals_for_ax = pfile.TRTSpectrum.ClassInstance.ClassInstance;
if iscell(vals_for_ax)
  vals_for_ax = vals_for_ax{1,1};
end

caliblin = str2double(vals_for_ax.CalibLin);
numchnls = str2double(vals_for_ax.ChannelCount);
axLength = 1:numchnls;
ax = caliblin*(axLength-1);

chnlVals = pfile.TRTSpectrum.ClassInstance.Channels;
chnlVals_fix = strsplit(chnlVals, ',');
dat = str2double(chnlVals_fix);

datDSO = dataset(dat);
datDSO.axisscale{2,1} = ax;
datDSO.label{1,1} = base;
datDSO.axisscalename{2,1} = 'Energy (keV)';

d = datDSO;


