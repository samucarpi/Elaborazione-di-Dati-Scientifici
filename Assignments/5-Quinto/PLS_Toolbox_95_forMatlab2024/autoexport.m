function varargout = autoexport(data,filename,format)
%AUTOEXPORT Exports a DataSet object to a file of the specified format.
% Automatically exports the given DataSet (or other object) to a file of
% the specified type. If only a file format is given, the user is prompted
% to name the output file. If only a filename is given, the extension of
% the file is used to identify the file format. If both a filename and a
% file format are given, the specified file format is used no matter what
% the extension of the filename.
%
% File format can be one of:
%    Format     Description
%     csv        Comma-Separated Values file
%     mat        Matlab MAT file
%     asf        Analect Spectral File
%     spc        Galactic SPC multifile
%     xml        eXtended Markup Language file
%     m          Matlab m-file
%
% If both filename and format are omitted, the user is prompted for a file
% name and format to save to.
%
%I/O: autoexport(data)
%I/O: autoexport(data,format)
%I/O: autoexport(data,filename)
%I/O: autoexport(data,filename,format)
%
%See also: AUTOIMPORT, EDITDS, ENCODEXML, WRITEASF, WRITECSV

%Copyright © Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  data = 'io';
end
if ischar(data) & ismember(data,evriio([],'validtopics'))
  options = [];
  options.validtypes = {
  '*.csv' 'Comma-Separated Values (*.csv)' 
  '*.asf' 'Analect Spectral File (*.asf)' 
  '*.spc' 'Galactic SPC (*.spc)'
  '*.xml' 'XML eXtended Markup Language (*.xml)' 
  '*.m'   'Matlab m-file (*.m)'
  '*.mat' 'Matlab MAT file (*.mat)'
  };%create list of valid filetypes (ONLY used when no filename is passed)
  if nargout==0; evriio(mfilename,data,options); else; varargout{1} = evriio(mfilename,data,options); end
  return
end

%NOTE: Options are not parsed on input yet but used to get list for flyout menu
%in browse.
opts = autoexport('options');
validtypes = opts.validtypes;

if nargin<2
  % (data)
  %ask user for filename
  [filename,pth,filter] = uiputfile(validtypes,'Save as...');
  if isnumeric(filename)
    return;
  end
  filename = {fullfile(pth,filename)};
  format = validtypes{filter,1};
  format = format(3:end);
elseif nargin<3
  % (data,format)
  % (data,filename)
  %check if full filename was given
  [pth,base,ext] = fileparts(filename);
  if isempty(pth) & isempty(ext);
    % (data,format)
    %format only - empty filename
    format = filename;
    filename = {};
  else
    % (data,filename)
    %use extension as format
    filename = {filename};
    format = ext(2:end);  %drop period and take remainder as format
  end
elseif ~iscell(filename)
  % (data,filename,format)
  %note: convert to cell because code below expects empty cell (as trigger
  %to called export function where no filename = empty cell = ask user)
  filename = {filename};
end
format = lower(format);

%locate appropriate function
switch format
  case 'xml'
    encodexml(data,'data',filename{:});
  case 'm'
    if isempty(filename)
      [filename,pth] = uiputfile({'*.m' 'Matlab M-file (*.m)'},'Save as...');
      if isnumeric(filename); return; end
      filename = {fullfile(pth,filename)};
    end
    [fid,msg] = fopen(filename{:},'w');
    if fid<3;
      error(msg);
    end
    fwrite(fid,encode(data));
    fclose(fid);
  case 'mat'
    if isempty(filename)
      [filename,pth] = uiputfile({'*.mat' 'Matlab MAT file (*.mat)'},'Save as...');
      if isnumeric(filename); return; end
      filename = {fullfile(pth,filename)};
    end
    save(filename{:},'data');
  otherwise
    %check for "write___" m-file
    % this covers writecsv and writeasf at least, but also will cover
    % others when then are written (if they meet this naming convention)
    if ~ismember(class(data),{'dataset' 'logical'}) & ~isnumeric(data)
      %check for bad classes
      error('Cannot export data type "%s" to format "%s"',class(data),format);
    end
    targ = ['write' format];
    if exist(targ,'file')
      feval(targ,data,filename{:});
    else
      error('Unrecognized file format "%s"',format)
    end
end
