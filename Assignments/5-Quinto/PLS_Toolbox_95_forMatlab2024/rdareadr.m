function data = rdareadr(fname, options)
%RDAREADR reads in a Siemens .rda file into a DataSet Object
% Input is the filename of a RDA file to read. If omitted, the user is
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
%I/O: dso = rdareadr(filename)
%I/O: dso = rdareadr(filename,options)
%
% The readrdafile function was created by referencing the work done by Chen Chen
% at the Sir Peter Mansfield Imaging Centre (SPMIC) at the University of
% Nottingham.
%
%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


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
      options = rdareadr('options');
    end
  case 2
    % (filename,options)
end
options = reconopts(options,mfilename);

if isempty(fname)
  %no filename passed (or empty), prompt user
  [nm,pth]=evriuigetfile('*.rda','please select a .rda file to load','multiselect','on');
  if isnumeric(nm)
    return
  end
else
  nm = fname;
  pth = '';
end
if isempty(nm) | isnumeric(nm)
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
      [filename,nm{j}, base{j}] = testopen(nm{j},pth,cl);
      [onefile, info{j}]        = readrdafile(filename);
      info{j}.Filename = base{j};
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
      data{j}.userdata       = info{j};
      
      if ishandle(h)
        waitbar(j/length(nm),h);
      elseif ~isempty(h) & ~ishandle(h)
        error('User cancelled operation')
      elseif strcmp(options.waitbar,'on') & (now-start)>1/60/60/24
        h = waitbar(0,'Loading RDA Files...');
      end
    end
    if strcmp(options.nonmatching, 'matchvars')
      data          = matchvars(data);
      data          = addsourceinfo(data,nm);
      data.name     = 'Multiple RDA files';
      data.userdata = info;
    end
    if ishandle(h)
      delete(h);
    end
    return
  end
end

        
[filename, nm, base] = testopen(nm,pth,cl);
[data, info]          = readrdafile(filename);
info.Filename        = base;
if ~isempty(data)
  data.name           = nm;
  data.description    = ['Read from: ' filename];
  data                = addsourceinfo(data,filename);
  data.label{1,1}     = base;
  data.labelname{1,1} = 'Filename';
  data.userdata       = info;
end

%---------------------------------------------------
function [filename,nm,base] = testopen(nm,pth,cl)
%reconciles path on input filename and additional path info (if present)
%tests file to make sure it is readable
%OUTPUTS:
%  filename = fully qualified filename appropriate to put into rda reader
%  nm = input nm filename stripped of any path

[fpth,base,ext] = fileparts(nm);
%check that input is rda file
if ~strcmp(ext,'.rda')
  if cl
    error('Cell array must only contain RDA Files') %error message if input is a cell array
  else
    error('Input must be an RDA File')
  end
end
nm = [base ext];
if isempty(fpth)
  %no path on filename? use pth or pwd
  if isempty(pth)
    pth = pwd;
  end
else
  %use path on the filename if present
  pth = fpth;
end
filename = fullfile(pth,nm);
[fid,msg] = fopen(filename,'r');
if fid<0
  error(['Unable to open file - ' msg]);
end
fclose(fid);

%---------------------------------------------------
function [dso, info] = readrdafile(fname)
fid   = fopen(fname);
tline = fgets(fid);
%beginning of get header information
while isempty(strfind(tline,'End of header'))
  tline = fgets(fid);
  if isempty(strfind(tline,'Begin of header')) & isempty(strfind(tline, 'End of header'))
    tline_split = strsplit(tline, ':');
    variable    = tline_split{1}; % tline before the ":"
    value       = strtrim(tline_split{2}); % tline after the ":"
    bracket_loc = regexp(variable, '\['); % find if there is a "["
    if any(bracket_loc)
      variable_cleaned = variable(1:bracket_loc-1); % clean up variable name
      % line has create an array in rda_info structure
      if ~isnan(str2double(value)) & any(regexp(variable,'\[\d\]'))
        n = variable(bracket_loc+1);
        n = str2double(n);
        n = n+1;
        value_cleaned                  = str2double(value); 
        rda_info.(variable_cleaned)(n) = value_cleaned;
      else
        variable            = variable_cleaned;
        rda_info.(variable) = value;
      end
    else
      if any(strfind(variable, 'FoV')) | any(strfind(variable,'Pixel')) |...
          any(strfind(variable, 'NumberOf')) | any(strfind(variable, 'VectorSize'))
        value = str2double(value);
      end
      rda_info.(variable) = value;
    end
  end
end
%end of get header info
rda_info      = orderfields(rda_info);
rda_info.size = [rda_info.PixelSpacingRow rda_info.PixelSpacingCol rda_info.PixelSpacing3D];
rda_info.FOV  = [rda_info.FoVHeight rda_info.FoVWidth rda_info.FoV3D];

if (sum(rda_info.size==rda_info.FOV)==3)
    rda_info.csi=0; % single voxel spectroscopy
else
    rda_info.csi=1;
end
rda_info.dynamics = 0; % ???   

data_f  = fread(fid , rda_info.NumberOfRows * rda_info.NumberOfColumns * rda_info.NumberOf3DParts * rda_info.VectorSize * 2 , 'double');  
fclose(fid);
data_f  = reshape(data_f, 2, rda_info.VectorSize, rda_info.NumberOfRows, rda_info.NumberOfColumns, rda_info.NumberOf3DParts);
data_f  = complex(data_f(1,:,:,:,:),data_f(2,:,:,:,:));
data_f  = reshape(data_f, rda_info.VectorSize, rda_info.NumberOfRows, rda_info.NumberOfColumns, rda_info.NumberOf3DParts);


%perform FFT
[~, xs, ys, zs]=size(data_f);
for x = 1:xs
  for y=1:ys
    for z=1:zs
      spectra(:,x,y,z)=fftshift(fft(data_f(:,x,y,z)));
    end
  end
end

[samples,~]   = size(spectra);
BW            = 10^6/str2double(rda_info.DwellTime);
transmit_freq = str2double(rda_info.MRFrequency)*10^6;

%spectra to Hz
spectra_Hz  = (spectra-1)./(samples-1) .* BW-BW/2;
%spectra to ppm
spectra_ppm = spectra_Hz./transmit_freq.*10^6;
%axis to Hz
axis_Hz     = (0:samples-1)./(samples-1) .* BW-BW/2;
%axis to ppm
axis_ppm    = axis_Hz./transmit_freq.*10^6;
axis_ppm    = 4.7+axis_ppm; % adjust axis based on know response of water
axis_ppm    = fliplr(axis_ppm); % flip axis so that 0 is on the right

dso                     = dataset(real(spectra_ppm)');
dso.axisscale{2,1}      = axis_ppm;
dso.axisscalename{2,1}  = 'ppm';
dso.axisscale{2,2}      = axis_Hz;
dso.axisscalename{2,2}  = 'Hz';
info = rda_info;





