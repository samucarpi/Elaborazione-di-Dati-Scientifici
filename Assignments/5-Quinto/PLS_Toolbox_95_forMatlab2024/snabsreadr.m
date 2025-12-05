function data = snabsreadr(filenames,options)
%SNABSREADR Reads one or more Stellarnet ABS XY files into a DataSet object.
% Reads fixed-width XY ABS files in which the first column is a column of
% axisscale values and the second column is the values measured at the
% corresponding axisscale values. Returns a DataSet object with the X as
% the axisscale in the file and all Y columns (both in the same file and in
% multiple files) concatenated and transposed as rows.
%
% It is REQUIRED that, if multiple files are being read, they must all have
% the same X range. If this is not true, the import may fail.
%
% Inputs:
%   filenames = One of the following identifications of files to read:
%            a) a single string identifying the ABS file to read
%                     ('example')
%            b) a cell array of strings giving multiple ABS files to read
%                     ({'example_a' 'example_b' 'example_c'})
%            c) an empty array indicating that the user should be prompted
%               to locate the file(s) to read
%                     ([])
%   options = An optional options structure containing one or more of the
%             following fields:
%     headerrows : [2] number of header rows to expect in each file.
%     startvar   : [] when supplied, defines the first variable to include
%                  in the output (in axisscale units). Empty reads from the
%                  beginning of the data.
%     endvar     : [] when supplied, defines the last variable to include
%                  in the output (in axisscale units). Empty reads to the
%                  end of the data.
% Outputs:
%   data = a DataSet object with the first column of the file(s) stored as
%         the axisscale{2} values and subsequent column stored as row of
%         data.
%
%I/O: data = snabsreadr(filenames,options)

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS 2/11

%handle evriio calls
if nargin>0 & ischar(filenames) & ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.headerrows = 2;
  options.startvar = [];
  options.endvar = [];
  if nargout==0; clear data; evriio(mfilename,filenames,options); else; data = evriio(mfilename,filenames,options); end
  return;
end

%parse inputs
switch nargin
  case 0
    % ()
  case 1
    % (filenames)
    options = [];
  case 2
    % (filenames,options)
    %nothing needed
  otherwise
    error('incorrect input format')
end
options = reconopts(options,mfilename);

%do the actual read
if isempty(filenames)
  [filenames,pathname] = evriuigetfile({'*.abs','Readable Files';'*.*','All Files (*.*)'},'multiselect','on');
  if isnumeric(filenames) & filenames == 0
    data = [];
    return
  end
  if iscell(filenames)
    for j=1:length(filenames);
      filenames{j} = [pathname filenames{j}];
    end
  else
    filenames = [pathname,filenames];
  end
end

if ~iscell(filenames)
  filenames = {filenames};
end
for findx = 1:length(filenames);
  %read each file
  [fid,message] = fopen(filenames{findx});
  if fid<3
    error('Error reading "%s": %s',filenames{findx},message);
  end
  for j=1:options.headerrows
    header{j} = fgetl(fid);  %read header line(s)
  end
  onefile = fscanf(fid,'%f');
  fclose(fid);
  if mod(length(onefile),2)~=0
    error('File format invalid (extra numerical values). Contact instrument vendor.');
  end
  %add data to axisscale and data
  axisscale = onefile(1:2:end)';
  data      = onefile(2:2:end)';
  if length(data)~=length(axisscale)
    error('File format invalid (axis mismatch). Contact instrument vendor.');
  end
  
  if findx==1
    %first file
    targetAxisscale = axisscale;
    alldata         = data;
  else
    %subsequent files
    if length(axisscale)~=length(targetAxisscale) | any(axisscale~=targetAxisscale)
      error('File "%s" axisscale mismatch versus first file. Contact instrument vendor.',filenames{findx});
      %DISABLED:
      %       %axisscale doesn't match? try aligning with matchvars
      %       tempdso = dataset(data);
      %       tempdso.axisscale{2} = axisscale;
      %       tempdso = matchvars(targetAxisscale,tempdso);
      %       data = tempdso.data;
    end
    alldata(end+1,:) = data;
  end
end

%finalize DSO
data = dataset(alldata);
for j=1:length(filenames);
  data = addsourceinfo(data,filenames{j});
end
data.axisscale{2} = targetAxisscale;
data.description = char(header);
if length(filenames)==1
  data.name = filenames{1};
else
  data.name = 'Multiple ABS files';
end
data.author = userinfotag;
base = {};
for findx=1:length(filenames);
  [pth,base{findx}] = fileparts(filenames{findx});
end
data.label{1} = base;

%truncate to specieid start/end values.
if ~isempty(options.startvar) | ~isempty(options.endvar)
  if ~isempty(options.startvar)
    startindx = findindx(data.axisscale{2},options.startvar);
  else
    startindx = 1;
  end
  if ~isempty(options.endvar)
    endindx = findindx(data.axisscale{2},options.endvar);
  else
    endindx = size(data,2);
  end
  data = data(:,startindx:endindx);
end

