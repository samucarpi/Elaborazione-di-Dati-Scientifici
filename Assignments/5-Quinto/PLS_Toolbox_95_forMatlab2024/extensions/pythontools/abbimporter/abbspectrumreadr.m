function [data] = abbspectrumreadr(fname,options)
%ABBSPECTRUMREADR Reads a SPECTRUM file into a DataSet object
% Input is the filename of a SPECTRUM file to read. If omitted, the user is
% prompted for a file. This importer uses Python source code provided by
% ABB. The imported files are returned in a Dataset Object, or a cell array if 
% they have differing variable axisscales, or number of variables AND the 
% nonmatching option = 'cell'.
%
% OPTIONAL INPUTS:
%  filename = either a string specifying the file to read, a cell
%             array of strings specifying multiple files to read, or the
%             output of the MATLAB DIR command specifying one or more files
%             to read. If (fname) is empty or not supplied, the user is
%             prompted to identify files to load.
%   options = an options structure containing the following fields:
% nonmatching : [ 'error' |{'matchvars'} 'cell'] Governs behavior 
%               when multiple files are being read which cannot be combined
%               due to mismatched types, sizes, etc.
%               'matchvars' returns a dataset object,
%               'cell' returns cell (see outputs, below), 
%               'error' gives an error.
%      display: [{'off'}| 'on' ] Governs display to the command line.
%                Warnings encountered during file load will be supressed if
%                display is 'off'.
%      waitbar: [ 'off' |{'on'}] Governs display of waitbar when doing
%                multiple file reading.
%
% OUTPUTS:
%   data = a DataSet object containing the spectrum or spectra from the
%          file(s), or an empty array if no data could be read. If the input
%          file(s) contain any peaktables these are extracted and returned
%          in the output DataSet object's userdata field.
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
%I/O: data = abbspectrumreadr(filename,options)
%
%See also: SPCREADR, TEXTREADR

%Copyright © Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% parsevarargin
%- - - - - - - - - - - - - - - - - - - - - - - - - - -
%parse inputs
if nargin==1 & ischar(fname) & ismember(fname,evriio('','validtopics'))
  options = [];
  options.nonmatching = 'matchvars';
  options.display = 'off';
  options.waitbar = 'on';
  if nargout==0; clear data; evriio(mfilename,fname,options); else; data=evriio(mfilename,fname,options); end
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
    % (dir(...))
    if isstruct(fname) & ~isfield(fname,'name')
      % (options)
      options = fname;
      fname = [];
    else
      options = abbspectrumreadr('options');
    end
  case 2
    % (filename,options)
end
options = reconopts(options,mfilename);

data = {};  %start with "error" state - only replaced if we get to the end without error
wrn  = {};  %will hold missing header warnings
if isempty(fname)
  %no filename passed (or empty), prompt user
  [nm,pth]=evriuigetfile({'*.spectrum;' 'Readable ABB Spectrum Files (*.spectrum)'},'please select a SPECTRUM file to load','multiselect','on');
  if isnumeric(nm)
    return
  end
elseif isstruct(fname)
  % output from the DIR command (probably)
  if ~isfield(fname,'name')
    error('Input structure must be either options or the output of the "dir" command');
  end
  fname = fname(~[fname.isdir]); %remove directories from structure
  nm = {fname.name};  %convert into cell
  pth = '';
else
  nm = fname;
  pth = '';
end
if isempty(nm) | isnumeric(nm)
  return
end

%- - - - - - - - - - - - - - - - - - - - - - - - - - -
%cell array of names? Multiple files to read
if iscell(nm)
  if length(nm)==1;
    %only one name in a cell? extract and use it as-is
    nm = nm{1};
  else
    %more than one name in cell? concatenate all items
    try
      start = now;
      h = [];
      for j=1:length(nm)
        %read in one file
        [filename,nm{j}] = testopen(nm{j},pth);
        [onefile] = abbspectrumreadr(filename);
        
        if j>1 & size(data{1},2)~=size(onefile,2);
          if strcmp(options.nonmatching,'error')
            error('File "%s" has a different number of variables than the previous file(s) and cannot be combined',nm{j});
          end
        end
        onefile.label{1} = repmat(nm{j},size(onefile,1),1);
        onefile.name = '';

        if strcmp(options.nonmatching, 'cell')
          onefile = addsourceinfo(onefile,nm{j});
        end
        data{j} = onefile;
        
        %show waitbar if it is a long load
        if ishandle(h)
          waitbar(j/length(nm),h);
        elseif ~isempty(h) & ~ishandle(h)
          error('User cancelled operation')
        elseif strcmp(options.waitbar,'on') & (now-start)>1/60/60/24
          h = waitbar(0,'Loading SPECTRUM Files...');
        end
      end
    catch
      le = lasterror;
      if ishandle(h);
        delete(h);
      end
      le.message = [sprintf('Error reading %s\n',nm{j}) le.message];
      rethrow(le)
    end   
    if ishandle(h);
      delete(h);
    end
    
    if ~strcmp(options.nonmatching, 'cell')
      % apply matchvars if not 'cell' case
      data = matchvars(data);
      data = addsourceinfo(data,nm);
      data.name = 'Multiple SPECTRUM files';
    end
    return
  end
end

% check if user has Python enabled
checkpython;

[filename,nm] = testopen(nm,pth);
% make sure Python files are on Python path
abbdir = fileparts(which('abbspectrumreadr.m'));
pythonpath = cellfun(@char,cell(py.sys.path),'UniformOutput',false);
if ~ismember(abbdir,pythonpath)
  py.sys.path().append(abbdir);
  py.sys.path().append([abbdir filesep 'abb_bfs']);
end

% now we can use the Python object from anywhere
bfs = py.abb_bfs.bfs_accessor.BomemFile(filename);

% how many samples?
nsamples = double(bfs.number_of_subfiles);
% how many channels?
firstfile = bfs.get_subfile(py.int(0));
try
  ncolstest = firstfile.get_item_data('Data').value;
  s = py.abb_bfs.bfs_accessor.Spectrum;
  s.open(filename);
  axisscale = double(s.getXAxisData());
catch E
  if strcmpi(E.message,'Python Error: BfsAccessException: The key ''Data'' does not match any entry')
    ncolstest = py.None;
  end
  axisscale = [];
end
if ~isequal(ncolstest,py.None)
  ncols = size(double(ncolstest),2);
else
  ncols = [];
end
data = nan(nsamples,ncols);
map = cell(nsamples,1);

% retrieve data
for i=1:nsamples
  thisdatasample = bfs.get_subfile(py.int(i-1));
  % extract info on data
   % extract data
  if ~isempty(ncols)
    data(i,:) = double(thisdatasample.get_item_data('Data').value);
  end
  keys = arrayfun(@(x) char(thisdatasample.get_item_data(py.int(x-1)).name),1:double(thisdatasample.get_number_of_entries),'UniformOutput',false);
  values = arrayfun(@(x) char(thisdatasample.get_item_data(py.int(x-1)).value),1:double(thisdatasample.get_number_of_entries),'UniformOutput',false);
  map{i} = containers.Map(keys,values);
end

data = dataset(data);
if ~isempty(axisscale)
  data.axisscale{2,1} = axisscale;
end
data.name = nm;
data.description = [newline ...
                    'File Description: ' char(bfs.file_description) newline ...
                    'File Application: ' char(bfs.application) newline ...
                    'File Origin: ' char(bfs.origin) newline ...
                    'File Signature: ' char(bfs.signature) newline ...
                    ];
data.userdata = map;
end
%--------------------------------------------------------------------------

function [filename,nm] = testopen(nm,pth)
%reconciles path on input filename and additional path info (if present)
%tests file to make sure it is readable
%OUTPUTS:
%  filename = fully qualified filename appropriate to put into java reader
%  nm = input nm filename stripped of any path

[fpth,base,ext] = fileparts(nm);
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
end

%--------------------------------------------------------------------------
function checkpython
% check python path

[result,envstatus] = check_pyenv;

if envstatus || isempty(result)
  error('Please configure Python 3 for PLS_Toolbox/Solo to to import ABB spectrum files');
else
  pe = pyenv;
  if ~isempty(pe)
    if pe.Version == ""
      error('Please configure Python 3 for PLS_Toolbox/Solo to to import ABB spectrum files');
    end
    pyvers = arrayfun(@str2num,split(pe.Version,'.'));
    pymajor = pyvers(1);
    pyminor = pyvers(2);
    if pymajor~=3
      error('Python 3 is needed to import ABB spectrum files. Please configure Python for PLS_Toolbox.')
    end
  else
    error('No Python path is saved. Point MATLAB to a particular Python interpreter.')
  end
end
end