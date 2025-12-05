function out = jascoeemreadr(file,options)
%JASCOEEMREADR Reads Jasco EEM files with Rayleigh removal.
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
%       scattercorrection [{'off'}| 'on'] calls FLUCUT.M for Rayleigh
%                correction.
%        flucut: FLUCUT options field for governing calls to FLUCUT.
%       LowMiss: Input (LowMiss) to FLUCUT.
%       TopMiss: Input (TopMiss) to FLUCUT.
%     textreadr: TEXTREADR options field for governing calls to TEXTREADR.
%   nonmatching: [{'error'}| 'cell' ] if dso don't match either throw an
%                error, or return it as a cell array.
%
% Output:
%    out = A DataSet object with date, time, info (data from cell (1,1)),
%          variable names (vars), sample names (samps), and data matrix (data).
%
%I/O: out = jascoeemreadr(file,options);
%
%See also: AQUALOGREADR, AREADR, DATASET, FLUCUT, SPCREADR, TEXTREADR, XLSREADR

% Copyright © Eigenvector Research, Inc. 2015
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

x = []; out = [];
if nargin==0 | isempty(file)
  [file,pathname] = evriuigetfile({'*.csv','Jasco EEM files (*.CSV)'; ...
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
  varargin{1} = file;
  options   = [];
  options.scattercorrection       = 'off';
  options.flucut                  = flucut('options');
  options.flucut.plots            = 'none';
  options.flucut.LowZero          = 'on';
  options.flucut.TopZero          = 'off';
  options.LowMiss                 = [13 8];
  options.TopMiss                 = [24 24];
  options.textreadr               = textreadr('options');
  options.textreadr.headerrows    = 17;
  options.textreadr.axisscalecols = 1;
  options.textreadr.axisscalerows = 1;
  options.waitbar                 = 'on';
  options.nonmatching = 'error';
  if nargout==0
    clear out; evriio(mfilename,varargin{1},options);
  else
    out       = evriio(mfilename,varargin{1},options);
  end
  return;
elseif ischar(file)
  file      = {file};
end

if nargin<2
  options = jascoeemreadr('options');
end
options     = reconopts(options,'jascoeemreadr');

nfiles = length(file);
if nfiles>1 & strcmp(options.waitbar,'on');
  wh = waitbar(0,'Loading Jasco EEM Files (Close to Cancel)');
  options.textreadr.waitbar = 'off';
else
  wh = [];
  options.textreadr.waitbar = options.waitbar;
end
axisscale = {};
axisscalename = {};
out = cell(nfiles,1);
for i1=1:nfiles
  try
    temp       = textreadr(file{i1},'',options.textreadr);
  catch
    erdlgpls({'Error loading file:'  file{i1},lasterr},'Import Error');
    return;
  end
  
  data             = zeros(1,size(temp,1), size(temp,2));
  axisscale{2}     = temp.axisscale{1};
  axisscale{3}     = temp.axisscale{2};
  if i1==1
    axisscalename{2} = 'Emission (nm)';
    axisscalename{3} = 'Excitation (nm)';
  end
  data(1,:,:)           = temp.data;
  [directory, fn, fext]  = fileparts(file{i1});
  file{i1}               = [fn fext];
  
  if ~(isempty(wh))
    if ~(ishandle(wh))
      error('User aborted import');
    end
    waitbar(i1/nfiles,wh);
  end
  
  %assemble dataset object
  x           = dataset(data);
  x.label{1}  = file{i1};
  x.axisscale{2} = axisscale{2};
  x.axisscale{3} = axisscale{3};
  x.axisscalename{2} = axisscalename{2};
  x.axisscalename{3} = axisscalename{3};
  %x = permute(x, [1 3 2]);
  x.name = file{i1};
  x.author = 'Created By JASCOEEMREADR';
  
  % add the info about imported source file(s)
  x = addsourceinfo(x, file, directory);
  
  % Perform Scatter correction
  if strcmpi(options.scattercorrection,'on')
    x = flucut(x,options.LowMiss,options.TopMiss,options.flucut);
  end
  
  out{i1} = x;
end

if (nfiles==1)
  out = out{1};
else % Check DSO dimensions 2 & 3 all agree.
  file1szs = [size(out{1},2),size(out{1},3)];
  combine = true;
  for (i=2:nfiles)
    if (file1szs(1)~=size(out{i},2) | file1szs(2)~=size(out{i},3))
      combine = false;
      break;
    end
    for j=2:(length(axisscale))% Check axisscales
      if ~(all(out{1}.axisscale{j}==out{i}.axisscale{j}))
        combine = false;
        break;
      end
    end
    if ~(combine) % if combine is false, terminate the loop.
      break;
    end
  end
  if (combine) % Combine DSOs
    temp = out{1};
    try
      for (i=2:length(out))
        temp = [temp;out{i}];
      end
      temp.name = 'Multiple Jasco EEM Files';
      out = temp;
    catch % could not combine DSOs, use original out variable.
    end
  else % either throw an error or return a cell array.
    if strcmpi(options.nonmatching,'error')
      error('Data in files do not match (Dimensions and/or axisscale). Cannot combine data in files into a single Dataset object.');
    elseif ~(strcmpi(options.nonmatching,'cell'))
      error('Unrecignized option set in .nonmatching field of the options structure.');
    else % proceed with the cell array.
    end
  end
end

if ~(isempty(wh)) & ishandle(wh)
  close(wh)
end

end
