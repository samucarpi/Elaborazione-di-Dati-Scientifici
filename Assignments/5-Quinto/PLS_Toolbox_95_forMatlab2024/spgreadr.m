function out = spgreadr(filenames,options)
%SPGREADR Reads Thermo Fisher SPA and SPG files.
% INPUTS:
%   filename = a text string with the name of an SPA file or
%              a cell of strings of SPA filenames.
%     If (filename) is omitted or an empty cell or array, the user will be
%     prompted to select a folder and then one or more files in the
%     identified folder. If (filename) is a blank string '', the user will
%     be prompted to select a single file.
%
% OPTIONAL INPUTS:
%   options = an options structure containing one or more of the following
%        multiselect : [ 'off' | {'on'} ] governs whether file selection
%                      dialog should allow multiple files to be selected
%                      and imported. Setting to 'off' will restrict user to
%                      importing only one file at a time.
%        nonmatching : [ 'error' |{'matchvars'} 'cell'] Governs behavior 
%                      when multiple files are being read which cannot be 
%                      combined due to mismatched types, sizes, etc.
%                      'matchvars' returns a dataset object,
%                      'cell' returns cell (see outputs, below), 
%                      'error' gives an error.
%
% OUTPUT:
%   out  = takes one of two forms:
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
%
%I/O: out = spgreadr    
%I/O: out = spgreadr('filename')
%I/O: out = spgreadr({'filename' 'filename2'})
%
%See also: ASFREADR, EDITDS, JCAMPREADR, SPCREADR, TEXTREADR

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%check for evriio input
if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.multiselect = 'on';
  options.nonmatching = 'matchvars';
  options.spectrumindex = 1; 
  if nargout==0; clear out; evriio(mfilename,filenames,options); else out = evriio(mfilename,filenames,options); end
  return;
end

% parse other possible inputs
% no inputs? set input = '' (to trigger single file read)
if nargin==0;
  filenames = {};
end

%check if there are options and reconcile them as needed
if nargin<2
  %no options!?! use empty
  options = [];
end
options = reconopts(options,mfilename);


% if no file list was passed

if isempty(filenames)
  %do actual read for filename
  [filenames, pathname, filterindex] = evriuigetfile({'*.spg; *.SPG','Omnic data files (*.spg)'; '*.*', 'All files'}, 'Open Omnic SPA file','MultiSelect', options.multiselect);
  if filterindex==0
    out = [];
    return
  else
    %got one or more filenames, add path to each
    if ~iscell(filenames)
      filenames = {filenames};
    end
    % retain only .spg files.
    pattern = cell(1,length(filenames)); % this change is needed to make the check case-insensitive.
    for i=1:length(pattern)
      pattern{i} = '.spg';
    end
    ifilenames =  ~cellfun(@strcmpi,filenames,pattern);%~cellfun(@isempty,strfind(filenames,'.spg'));
    filenames = filenames(ifilenames);
    
    
    for lll = 1:length(filenames)
      filenames{lll} = fullfile(pathname,filenames{lll});
    end
  end
else  
     % retain only .spg files.
    
     if iscell(filenames)
       ifilenames =  ~cellfun(@isempty,strfind(filenames,'.spg'));
       filenames = filenames(ifilenames);
     else
     end
end

if  ~(isa(options.spectrumindex,'char')) & (length(options.spectrumindex)==1)
% Call spareadr to load these .spg files.
out = spareadr(filenames, options);

else  % Multi-samples mode.
  if (isa(options.spectrumindex,'char')) % User inputed a string to options.spectrumindex
    if(strcmpi(options.spectrumindex,'all')) % Only 'all' is accepted.
      if ~(iscell(filenames)) % Only 1 file.
        filenames = cell({filenames});
      end
      out = cell(length(filenames),1); % Initialize out as a cell to store the data (same length as the number of files).
      for (i=1:length(out)) % For each (string) filename in filenames .
        passedlast = false;
        sampidx = 1;
        outsamp = [];
        while ~(passedlast) % Cycle through to the end of the file.
          try
            options.spectrumindex = sampidx; % Set index
            outtemp = spareadr(filenames{i}, options); % Run spareadr()
            if isempty(outsamp) % Store the data into outsamp/update outsamp
              outsamp = outtemp;
            else
              outsamp = [outsamp;outtemp];
            end
            sampidx = sampidx + 1; % Update index.
          catch % Check last error, have we exceeded number of samples available?
            okerror = 'desired spectrum index exceeds number of available spectra'; % WARNING: HARDWIRED!
            spaerror = encode(lasterror);
            if contains(spaerror,okerror) % If yes, terminate loop (move on to the next file)
              passedlast = true;
            else % If no, re-throw the error.
              error(spaerror);
            end
          end
        end
        out{i} = outsamp; % Update variable out.
      end
    else
      error('unrecignized setting for options.spectrumindex');
    end
  elseif isa(options.spectrumindex,'numeric') % We have a vector of indexes, this only works with 1 file.
    if isa(filenames,'cell') & (size(filenames,2)>1) % If more than 1 file, throw an error.
      error('Specifying an array of indexes to be applied to multiple files is currently unsupported');
    end
    out = [];
    opt = options;
    for (i=1:length(options.spectrumindex))
      opt.spectrumindex = options.spectrumindex(i); % Set index
      outtemp = spareadr(filenames, opt); % Run spareadr(), allow error to occur if index exceeds sample dimensions for now.
      [fpath,fname,fext] = fileparts(filenames);
      outtemp.label{1} = sprintf('Sample%d:%s%s',options.spectrumindex(i),fname,fext); % Update sample label to include sample #.
      if (isempty(out)) % Store data in out/update out
        out = outtemp;
      else
        out = [out;outtemp];
      end
    end
  else
    error('incompatible datatype used for options.spectrumindex');
  end
  
  if (length(out)==1) % Single element cell array? extract the one DSO.
    out = out{1};
  end

end
