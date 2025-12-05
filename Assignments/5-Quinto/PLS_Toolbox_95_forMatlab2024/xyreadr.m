function out = xyreadr(varargin)
%XYREADR Reads one or more ASCII XY or XY... files into a DataSet object.
% Reads standard XY ASCII files in which the first column is a column of
% axisscale values (wavelengths, retention times, etc) and the second and
% possibly subsequent column(s) are values measured at the corresponding
% axisscale values. Returns a DataSet object with the X as the axisscale in
% the file and all Y columns (both in the same file and in multiple files)
% concatenated and transposed as rows.
% It is REQUIRED that, if multiple files are being read, they must all have
% the same X range. If this is not true, the import may fail.
%
% Inputs:
%   file = One of the following identifications of files to read:
%            a) a single string identifying the XY file to read
%                     ('example')
%            b) a cell array of strings giving multiple XY files to read
%                     ({'example_a' 'example_b' 'example_c'})
%            c) an empty array indicating that the user should be prompted
%               to locate the file(s) to read
%                     ([])
%   delim = An optional delimiter used in the file. If omitted, the
%           delimiter will be detected automatically. See TEXTREADR for more
%           information.
%   options = An optional options structure containing one or more of the
%             following fields:
%     commentcharacter : [''] any line that starts with the given character
%                  will be considered a comment and parsed into the
%                  "comment" field of the DataSet object. Deafult is no
%                  comment character. Example: '%' uses % as a comment
%                  character.
%     headerrows : [{0}] number of header rows to expect in each file.
%     parsing    : [ 'manual' | 'automatic' | {'gui'} ] determine how to
%                   process CSV files. 'manual' is fastest but does not
%                   support labels in the file. 'automatic' handles labels
%                   but is slower. 'gui' prompts user if the file has
%                   labels and, if so, selects 'automatic'.
%     waitbar    : [ 'off' |{'on'}] Governs use of waitbars to show progress
%
% Outputs:
%   out = a DataSet object with the first column of the file(s) stored as
%         the axisscale{2} values and all subsequent column(s) stored as
%         rows of data.
%
%I/O: out = xyreadr(file,delim,options)
%
%See also: AUTOIMPORT

% Copyright © Eigenvector Research, Inc. 2007
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS 3/07

%handle evriio calls
if nargin>0 & ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics'));
  options = [];
  options.commentcharacter = '';
  options.headerrows = [0];
  options.waitbar = 'on';
  options.parsing = 'gui';
  if nargout==0; clear out; evriio(mfilename,varargin{1},options); else; out = evriio(mfilename,varargin{1},options); end
  return;
end

%parse out inputs
file = [];
delim = [];
options = [];
switch nargin
  case 1
    % (file)
    file = varargin{1};
  case 2
    % (file,delim)
    % (file,options)
    file = varargin{1};
    if ~isstruct(varargin{2})
      delim = varargin{2};
    else
      options = varargin{2};
    end
  case 3
    file    = varargin{1};
    delim   = varargin{2};
    options = varargin{3};
end
options = reconopts(options,mfilename);

%force a couple of settings in here (for TEXTREADR)
options.axisscalecols = 1;
options.rowlabels = 0;
options.collabels = 0;
if strcmp(options.parsing,'gui')
  if ~iscell(file) & ~isempty(file)
    [pth,fle,ext] = fileparts(file);
  else
    ext = '.???';
  end
  if strcmp(ext,'.xls') | strcmp(ext,'.xlsx')
    %excel files always use automatic parsing
    options.parsing = 'automatic';
  else
    %other file types, ask user
    lbl = evriquestdlg('Does your file contain any labels you want to keep?','XY Reader','Yes','No','No');
    if isempty(lbl);
      out = [];
      return
    end
    switch lbl
      case 'Yes'
        options.parsing = 'automatic';
      otherwise
        options.parsing = 'manual';
    end
  end
end
options.transpose = 'yes';

%do the actual read using textreadr
out = textreadr(file,delim,options);

