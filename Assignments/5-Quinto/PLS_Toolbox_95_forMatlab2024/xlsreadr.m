function [out,usedoptions] = xlsreadr(file,sheets,options)
%XLSREADR Reads .XLS files from MS Excel and other spreadsheets.
%  This function reads Microsoft XLS files, parses the contents into a
%  DataSet object. If called with no input a dialog box allows the user to
%  select a file to read from the hard disk.
%  Optional input (sheets) is a cell array containing the names of one or more
%  sheets in XLS file to read. Or it can be a string specifying a single
%  sheet to read, or it can be an integer vector specifying which sheets to
%  read. If sheets contains any invalid names or index values then those
%  invalid names or indices are removed from the requested sheets.
%  Note that the primary difference between this function and the Mathworks
%  function xlsread is the parsing of labels and output of a dataset
%  object.
%
% OPTIONAL INPUTS:
%      file = text string with name of excel file to read
%    sheets = integer or integer vector specifying which sheets to read
%             text string specifying which sheet to read
%             cell array of text strings specifying which sheets to read.
%   options = structure array with the following fields:
%             For details on these options, see PARSEMIXED.
%
% OUTPUTS:
%          out = output dataset object containing contents of file
%  usedoptions = options structure actually used when parsing (includes any
%                options modified by the user in the graphical selection
%                interface). Can be used to repeat an import with the same
%                user-selected file parsing.
%
%I/O: [out,usedoptions] = xlsreadr(file,sheets,options);
%
%See also: AREADR, DATASET, PARSEMIXED, TEXTREADR, WRITECSV, XCLGETDATA, XLSFINFO

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS 02/2004
%jms 4/04 -added multiple sheets support
%  -fixed no column labels bug
%jms 6/04 -added second input of sheet name to read.
%jms 2/05 -do not require labels for empty rows/cols (only included rows/cols)

persistent noexcel

out = [];
if nargin == 1 & ischar(file) & ismember(file,evriio([],'validtopics'));
  options = [];
  options = reconopts(parsemixed('options'),options,0);
  if nargout==0; clear out; evriio(mfilename,file,options); else; out = evriio(mfilename,file,options); end
  return;
end

switch nargin
  case 0
    file = '';
    sheets = '';
    options = [];
  case 1
    if ~isstruct(file)
      %(file)
      options = [];
      sheets = '';
    else
      %(options)
      options = file;
      file = '';
      sheets = '';
    end
  case 2
    if isstruct(sheets)
      %(file,options)
      options = sheets;
      sheets = '';
    else
      %(file,sheets)
      options = [];
    end
end
options = reconopts(options,'xlsreadr');
usedoptions = options;

%first time called in the session? check for excel
if isempty(noexcel)
  if ispc
    try
      ExObj = actxserver ( 'Excel.Application' );  %can we open it?
      ExObj.Quit % Quit Excel
      noexcel = false;  %yes - we're good
    catch
      noexcel = true;  %error creating excel, not available
    end
  else
    noexcel = true;  %mac or linux, not available
  end
end

if isempty(file);
  [file,pathname] = evriuigetfile({'*.xls;*.xlsx;*.xlsm;*.xlsb;','Readable Files';'*.*','All Files (*.*)'});
  if file == 0
    return
  end
  file = [pathname,file];
end

% handle requested Excel workbook filename
if iscell(file)
  [out,usedoptions] = textreadr(file,options);
  return;
end
if isempty(fileparts(file))
  file = evriwhich(file);
  if isempty(fileparts(file))
    error('Please include the full path in the name of the Excel file');
  end
end

% use activeX workaround if matlab ver in [R2009a to R2011a], inclusive
if ~noexcel & ispc & checkmlversion('>=','7.8') & checkmlversion('<','7.13')
  % 7.8 == R2009a, 7.13 == R2011b
  availsheets = excelsheetnames(file);
else
  if ~noexcel  %if we've got excel...
    [type, availsheets]=xlsfinfo(file);
  else %no excel? special rules
    [junk,junk,ext] = fileparts(file);
    if strcmpi(ext,'.xls')
      [type, availsheets]=xlsfinfo(file);
    else
      %don't even TRY to use xlsfinfo
      type = '';
      availsheets = {};
      %Try xlsx.
      if strcmpi(ext,'.xlsx')
        try
          [type, availsheets]=xlsfinfo(file);
        end
      end
    end
  end
end

%Need sheet index for use with poixlsread on Mac.
sheet_idx = 1;

if isempty(sheets)
  if ischar(availsheets) & ~isempty(strfind(availsheets,'Unreadable Excel file'))
    availsheets = {};
  end
  if length(availsheets)>1;
    sheet_idx = listdlg('ListString',availsheets,'ListSize',[160 180],'SelectionMode','multiple','PromptString','Import From Worksheet:','Name','Choose Worksheet');
    sheets = availsheets(sheet_idx);
    if isempty(sheets); return; end   %cancel out of dialog
  elseif isempty(availsheets);
    %no sheets? fake name
    sheets = {''};
  end
else
  % find index of requested sheets in availSheets
  if isnumeric(sheets)
    % exclude any sheets values greater than numel(availsheets)
    sheets = sheets(sheets<=numel(availsheets));
    sheets = availsheets(sheets);
    [tf, sheet_idx] = ismember(sheets, str2cell(availsheets));
  elseif ischar(sheets)
    sheets = str2cell(sheets);
    [tf, sheet_idx] = ismember(str2cell(sheets), str2cell(availsheets));
  elseif iscell(sheets)
    [tf, sheet_idx] = ismember(sheets, str2cell(availsheets));
  else
    error('Names of excel sheets requested are neither cell, string, or integer');
  end
  % ignore sheets entry which not exist in availsheets
  sheets = sheets(tf);
  sheet_idx = sheet_idx(tf);
end

if ~iscell(sheets);
  sheets = {sheets};
end

augmentmode = 2;
augmenttext = 'Columns';
mustmatch = 'Rows';
if length(sheets)>1;
  augmenttext = evriquestdlg('Augment sheets together in which direction? Make it new:', ...
    'Augment Data', ...
    'Rows','Columns','Slabs',augmenttext);
  
  switch augmenttext
    case 'Rows'
      augmentmode = 1;
      mustmatch = 'Columns';
    case 'Slabs';
      augmentmode = 3;
      mustmatch = 'Rows and Columns';
    otherwise
      augmentmode = 2;
      mustmatch = 'Rows';
  end
end

for ind = 1:length(sheets);
  
  % apache POI jar files were built with Java 1.6, so require Java 1.6+
  javaversionstr = version('-java'); % looks like: 'Java 1.6.0_17-b04 with...'
  if (noexcel | ismac) & str2double(javaversionstr(6:8))>1.5999
    % use Apache POI package to read .xls/.xlsx on mac
    [a,b] = getxlsdata(file,sheet_idx(ind),noexcel);
  else
    [a,b] = getxlsdata(file,sheets{ind},noexcel);
  end
  try
    %usedoptions.compactdata='no'; % Make the data import uncompact
    [data,usedoptions] = parsemixed(a,b,usedoptions);
  catch % Attempt to import using poixlsread
    [a,b] = poixlsread(file,sheet_idx(ind));
    [data,usedoptions] = parsemixed(a,b,usedoptions);
  end
  usedoptions.useimporttool = 'no';
  usedoptions.parsing = 'automatic';
  
  if ~isempty(data)
    
    if isdataset(data)
      [pathstr,fname,fext] = fileparts(file);
      data.name = [fname fext];
      data.author = 'Created by XLSREADR';
      if length(sheets)>1 & augmentmode<3
        data.label{augmentmode} = repmat(sheets{ind},size(data,augmentmode),1);
      end
    end
    
    if isempty(out);
      out = data;
    else
      if augmentmode==1 & ndims(data)==2
        %joining 2way data as new rows? use matchvars
        if ~iscell(out)  % switch out to be a cell array (on second file)
          out = {out};
        end
        out{1,end+1} = data;  %add new data to end of cell
      else
        %joining in 2nd or higher-order dim, use standard cat (if we can)
        try
          out = cat(augmentmode,out,data);
        catch
          error(['Data in different sheets must match in number of ' mustmatch ' (sheet: ' sheets{ind} ' was size [' num2str(size(data)) '])'])
        end
      end
    end
  end
end

if iscell(out)
  %cell array of items? we're matching 2D tables as new samples
  out = matchvars(out);
end

if augmentmode==3 & isdataset(out)
  out.label{3} = sheets;
  out = permute(out,[3 1 2]);
end

if isdataset(out)
  out = addsourceinfo(out,file);
end
%--------------------------------------------------------------------------
function [a,b] = poixlsread(filename, sheetId)
% Use apache POI to read .xls or .xlsx files, returning same as xlsread
reader = evri.apachepoi.ReadXls;
javaSheetId = sheetId-1;  % account for matlab-java 1/zero diff
reader.readxls(filename, javaSheetId);

a   = reader.getNumericValues;
b   = cell(reader.getStringValues);

%--------------------------------------------------------------------------
function SheetsNames=excelsheetnames(Path_File)
%SheetsNames=ExcelSheetsNames(Path_File)
% Use activeX to read the sheet names. This alternative works in matlab ver
% R2009b where [ftype, sheets] = xlsfinfo(file) has a bug

% Get Sheets Names
ExObj = actxserver ( 'Excel.Application' ); % Start Excel
ExObj.Visible = 0; % Make it visible
AllBooksObj = ExObj.Workbooks; % No idea what this does, but it's required
WkBkObj = AllBooksObj.Open(Path_File);% Open workbook
AllSheetsObj = WkBkObj.Sheets; % Object containing all the sheets
NumSheets = AllSheetsObj.Count; % Get the number of sheets in workbook

for n= 1:NumSheets
  
  SheetObj = get( AllSheetsObj, 'Item', n );% Get sheet #n
  SheetsNames{n}=get(SheetObj,'Name');
  
end
% clearvars -except SheetsNames
WkBkObj.Close( false );
ExObj.Quit % Quit Excel

%--------------------------------------------------------------------------
function [a,b] = getxlsdata(file,mysheets,noexcel)
%Run xlsread as best as possible.

try
  % apache POI jar files were built with Java 1.6, so require Java 1.6+
  javaversionstr = version('-java'); % looks like: 'Java 1.6.0_17-b04 with...'
  if (noexcel | ismac) & str2double(javaversionstr(6:8))>1.5999
    % use Apache POI package to read .xls/.xlsx on mac
    [a,b] = poixlsread(file,mysheets);
  else
    % Avoid using 'basic' mode because datetime stamps will not be
    % converted from Excel format to Matlab format (on Windows systems). 
    [a,b,c] = xlsread(file,mysheets);
    %Recreate labels because xlsread.m was changed after R2011b and in some occasions, it will
    % produce different results. Based on our tests when this occurs, the
    % result from R2011b is correct.
    % See: http://undocumentedmatlab.com/blog/xlsread-functionality-change-in-r2012a
    isTextMask = cellfun('isclass',c,'char');
    b = cell(size(c));
    b(:) = {''};
    anyText = any(isTextMask(:));
    
    % Place text cells in text array
    if anyText
      b(isTextMask) = c(isTextMask);
    end
    
  end
catch
  error(lasterr)
end


