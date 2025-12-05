function x = aqualogabsreadr(file,options)
%AQUALOGABSREADR Reads Horiba Aqualog absorbance files.
%  INPUT:
%   file = One of the following identifications of files to read:
%            a) a single string identifying the file to read
%                  ('example')
%            b) a cell array of strings giving multiple files to read
%                  ({'example_a' 'example_b' 'example_c'})
%            c) an empty array indicating that the user should be prompted
%               to locate the file(s) to read
%                  ([])
%
%  OPTIONAL INPUT:
%     options = structure array with the following fields:
%       waitbar: [ 'off' |{'on'}] Governs use of waitbars to show progress.
%      textreadr: TEXTREADR options field for governing calls to TEXTREADR.
%
% Output:
%    out = A DataSet object with a data matrix (data), spectral axis scale,
%    and labels indicating the names of the originating files
%
%I/O: out = aqualogabsreadr(file,options);
%
%See also: AREADR, DATASET, AQUALOGREADR, TEXTREADR, XLSREADR

% Copyright © Eigenvector Research, Inc. 1998
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

x = [];
if nargin==0 | isempty(file)
  [file,pathname] = evriuigetfile({'*.dat','HORIBA A-TEEM Absorbance Files (*ABS.DAT)'; ...
    '*.*','All Files (*.*)'},'multiselect','on');
  if isnumeric(file) & file == 0
    return
  end
  if iscell(file)
    for j=1:length(file);
      file{j} = [pathname file{j}];
    end
  else
    file    = {[pathname,file]};
  end
elseif ischar(file) & ismember(file,evriio([],'validtopics'));
  varargin{1}                     = file;
  options   = [];
  options.textreadr               = textreadr('options');
  options.textreadr.axisscalecols = 1;
  options.textreadr.transpose     = 'yes';
  options.waitbar                 = 'on';
  if nargout==0
    clear x; evriio(mfilename,varargin{1},options);
  else
    x       = evriio(mfilename,varargin{1},options);
  end
  return;
elseif ischar(file)
  file      = {file};
end

if nargin<2
  options = aqualogabsreadr('options');
end
options     = reconopts(options,'aqualogabsreadr');

nfiles = length(file);
if nfiles>1 & strcmp(options.waitbar,'on');
  wh = waitbar(0,'Loading Aqualog ABS Files (Close to Cancel)');
  options.textreadr.waitbar = 'off';
else
  wh = [];
  options.textreadr.waitbar = options.waitbar;
end
axisscale = {};
axisscalename = {};
for i1=1:nfiles
  try
  out       = textreadr(file{i1},'',options.textreadr);
  catch    
    error(sprintf('Error loading file %s - %s', file{i1}, lasterr));
    return
  end
  if ~isequal(size(out,1), 1)
    error(sprintf('Data from file %s is the wrong size', file{i1}))
    return
  end
      
  if isequal(i1, 1)
    npts             = size(out,2);
    data             = zeros(length(file),npts);
    axisscale{2}     = out.axisscale{2,1};
    axisscalename{2} = 'Absorbance (nm)';
    data(i1,:)       = out.data;
  else
    cur_meas         = matchvars(axisscale{2}, out);
    if all(isnan(cur_meas.data))
      error(sprintf('File %s does not match', file{i1}));
    end
    data(i1,:)       = cur_meas.data;
  end
  [directory, fn, fext]  = fileparts(file{i1}); 
  file{i1}               = [fn fext];
  
  if ~isempty(wh);
    if ~ishandle(wh)
      error('User aborted import');
    end
    waitbar(i1/nfiles,wh);
  end
end

if ~isempty(wh) & ishandle(wh)
  close(wh)
end

%assemble dataset object
x           = dataset(data);
x.label{1}  = file;
x.axisscale{2} = axisscale{2};
x.axisscalename{2} = axisscalename{2};

if nfiles==1
  x.name = file{1};
else
  x.name = 'Multiple Aqualog Files';
end
x.author = 'aqualogabsreadr';

%Make sure there's a directory.
if isempty(directory)
  directory = pwd;
end

if length(file)>1
  x.history = ['Import Multiple Files From: ' directory];
else
  % last, add the info about imported source file(s)
  x = addsourceinfo(x, file, directory);
end

