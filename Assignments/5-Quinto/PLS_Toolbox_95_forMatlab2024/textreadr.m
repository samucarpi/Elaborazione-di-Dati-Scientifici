function [out,usedoptions] = textreadr(file,delim,options)
%TEXTREADR Reads an ASCII or .XLS file in as a DataSet Object.
%  This function reads tab, space, comma, semicolon or bar delimited
%  text files or Microsoft XLS files with names on the columns (variables)
%  and/or rows (samples).
%  Inputs:
%   file = One of the following identifications of files to read:
%            a) a single string identifying the file to read
%                  ('example')
%            b) a cell array of strings giving multiple files to read
%                  ({'example_a' 'example_b' 'example_c'})
%            c) an empty array indicating that the user should be prompted
%               to locate the file(s) to read
%                  ([])
%   delim = An optional string used to specify the delimiter character.
%            Supported delimiters include:
%             'tab' or '\t' or sprintf('\t')
%             'space' or ' '
%             'comma' or ','
%             'semi'  or ';'
%             'bar'   or '|'
%           If (delim) is omitted, the file will be searched for a
%           delimiter common to all rows of the file and producing an equal
%           number of columns in the result.
%  options = An optional options structure with one or more of the
%             following fields: 
%     parsing    : [ 'manual' | {'automatic'} | 'auto_strict' | 'stream' | 'importtool' | 'gui'] 
%          determines the type of file parsing to perform:
%           'automatic' : the file is automatically parsed for labels and
%              header information. This works on many standard arrangements
%              with different numbers of rows and column labels. May take
%              some time to complete with larger files. See note below
%              regarding additional options available with 'automatic'
%              parsing.
%           'auto_strict' : faster automatic parsing which does not handle
%              header lines, and expects that all row labels will be on the
%              left-hand side of the data and all column labels will be on
%              the top of the columns. If this returns the wrong result,
%              try 'automatic'.
%           'manual' : the options below are used to determine the number
%              of labels and header information. 
%           'stream' : basically the same as 'automatic' but reads the file
%              as separate "pieces". This may permit reading larger files
%              than would otherwise be possible.
%           'importtool' : Show import tool during parsemixed to
%              manually designate data,label,class,... columns and rows. 
%           'graphical_selection' : Same as 'importtool' 
%           'gui' : allows selection of standard options using a GUI.
%         Note that when the file type is XLS, 'automatic' parsing is always
%         performed.
%     commentcharacter : [''] any line that starts with the given character
%                  will be considered a comment and parsed into the
%                  "comment" field of the DataSet object. Deafult is no
%                  comment character. Example: '%' uses % as a comment
%                  character.
%                  NOTE: Only used with 'automatic' and 'manual' parsing,
%                        NOT with 'auto_strict' parsing.
%     headerrows : [{0}] number of header rows to expect in the file. If
%                  value is -1, and no delimiter is passed, the number of
%                  header rows is inferred from the rows at the top of the
%                  file that do not contain a standard number of delimiter
%                  characters.
%                  NOTE: Only used with 'automatic' and 'manual' parsing,
%                        NOT with 'auto_strict' parsing.
%     rowlabels  : [{1}] number of row labels to expect in the file
%                  NOTE: Only used with 'manual' parsing.
%     collabels  : [{1}] number of column labels to expect in the file
%                  NOTE: Only used with 'manual' parsing.
%     waitbar    : [ 'off' |{'on'}] Governs use of waitbars to show progress
%     catdim     : [ 0 ] specifies the dimension that multiple text files
%                  should be joined on. 1 = rows, 2 = columns, 3 = slabs,
%                  0 = automatically select based on sizes. Automatic mode
%                  joins in rows or columns if the other mode doesn't match
%                  in size, in the 3rd mode if BOTH dimensions match, and
%                  throws an error if no sizes match. 
%     autobuild3d : [{false}| true ] Governs automatic joining of equal
%                  sized files as slabs in a 3-way array. When true,
%                  multiple files which contain data that match in both
%                  rows and columns will be combined as separate slabs of a
%                  3-way array. Often used with the autopermute function.
%     autopermute : [ false | {true} ] When true, multiple files joined in
%                  the 3rd dimension are also permuted so that multiple
%                  files form the ROWS of the output and the original rows
%                  and columns are moved into columns and slabs. This
%                  option is most often used for multiway data where each
%                  file is a separate sample and, thus, should be separate
%                  rows of the output.
%
%  In addition to the above options, if option parsing is set to
%  'automatic', any option used by the PARSEMIXED function can be input to
%  TEXTREADR. These options will be passed directly to PARSEMIXED for use in
%  parsing the file. See PARSEMIXED for details.
%
% Output:
%  out = A DataSet object with date, time, info (data from cell (1,1))
%          the variable names (vars), sample names (samps), and data matrix
%          (data).  Note that the primary difference between this function
%          and the Mathworks function xlsread is the parsing of labels and
%          output of a dataset object.
%  usedoptions = the options structure that was actually used including
%          modifications made during import (including when using the
%          import tool to define columns/etc).
%
%I/O: [out,usedoptions] = textreadr(file,delim,options);
%
%See also: AREADR, DATASET, SPCREADR, XCLGETDATA, XCLPUTDATA, XLSREADR

% Copyright © Eigenvector Research, Inc. 1998
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified BMW 11/2000
% 8/02 bmw converted output to dataset object
% 8/02 jms added error checking for missing delimiter, strange line
% lengths, etc.
% 11/03 jms -close file if errors occur
%   -automatic detection of delimiter
%   -added ability to read from microsoft XLS files using xlsread
% 2/04 jms -moved xls read code into separate file
%   -fixed one-column-of-data bug
%   -added row/col lables options
% 3/2/04 jms -fixed zero-input bug
% 6/5/04 bmw -added conversion for time and date variables
% 2/3/04 jms -added headerrows option to read off non-delimited rows on top

if nargin == 0 | isempty(file)
  [file,pathname] = evriuigetfile({'*.csv;*.txt;*.xls;*.xlsx;*.xlsm;*.xlsb;','Readable Files';'*.*','All Files (*.*)'},'multiselect','on');
  if isnumeric(file) & file == 0
    out = [];
    return
  end
  if iscell(file)
    for j=1:length(file);
      file{j} = [pathname file{j}];
    end
  else
    file = [pathname,file];
  end
else
  if ischar(file) & ismember(file,evriio([],'validtopics'));
    varargin{1} = file;
    options = [];
    options.parsing = 'automatic';
    options.commentcharacter = '';
    options.headerrows = 0;
    options.rowlabels = 1;
    options.collabels = 1;
    options.waitbar   = 'on';
    options.catdim    = 0;
    options.autobuild3d = false;  
    options.autopermute = true;
    options = reconopts(parsemixed('options'),options,0);
    if nargout==0; clear out; evriio(mfilename,varargin{1},options); else; out = evriio(mfilename,varargin{1},options); end
    return; 
  end
end

%parse inputs
switch nargin
  case {0,1}
    if ~isstruct(file)
      % (file)
      delim = [];
      options = [];
    else
      options = file;
      file = '';
      delim = [];
    end
  case 2
    if isa(delim,'struct');
      % (file,options)
      options = delim;
      delim = [];
    else
      % (file,delim)
      options = [];
    end
end
options = reconopts(options,'textreadr');

if strcmpi(options.parsing,'gui')
  options.delimiter = delim;
  options = textreadrgui(options);
  if isempty(options);
    if nargout>0; out = []; end
    return;
  end
  delim = options.delimiter;
end
usedoptions = options;

%if file is a cell, loop over each file separately
if iscell(file) & length(file)==1
  file = file{1};  % one file? just treat as single
end
if iscell(file)
  out = [];
  newlbls = {};
  
  if strcmp(options.waitbar,'on');
    wbh = waitbar(0,'Importing Multiple Files...');
  else
    wbh = [];
  end
  options.waitbar = 'off'; %now turn off (we'll handle it here if they wanted it)
  options.compactdata = 'false';  %do NOT compact data with multi-file mode (will most likely cause mismatch of rows/cols)

  try
    %loop over all files in the cell
    permute_order = [];  %don't permute unless we have a 3D matrix
    usedoptions = options; %start out with user-submitted options
    cellmode = false;   %trigger for storing as cell array
    celldata = {};      %storage for files
    for j=1:length(file)
      [onefile,usedoptions] = textreadr(file{j},delim,usedoptions);
      if strcmpi(usedoptions.useimporttool,'yes')
        %if we used the importtool on the first file, repeat same options
        %automatically on subsequent files
        usedoptions.parsing = 'automatic';
        usedoptions.useimporttool = 'no';
      end
      if isempty(onefile)
        if nargout>0; out = []; end
        if ishandle(wbh); delete(wbh); end
        return;
      end
      onefile.name = 'Multiple Files';
      if isempty(out)
        out = onefile;
      elseif ~cellmode
        if options.catdim==0
          %auto-selection
          if options.autobuild3d & size(out,2)==size(onefile,2) & size(out,1)==size(onefile,1) & size(out,1)>1 & comparevars(out.axisscale{2},onefile.axisscale{2}) & comparevars(out.axisscale{1},onefile.axisscale{1})
            %BOTH dims match? cat in 3rd dim
            dim = 3;
            options.catdim = 3;
          elseif size(out,2)==size(onefile,2) & size(out,2)>1
            %only second dim matches, cat in 1st dim (new samples)
            if ~comparevars(out.axisscale{2},onefile.axisscale{2})
              %axisscales do not match
              dim = 0;
            else
              dim = 1;
              options.catdim = 1;
            end
          else  %dim 2 doesn't match 
            dim = 0; %triggers matchmvars mode
          end
        else
          %force join in a given dim
          dim = options.catdim;
          szout = size(out);
          szone = size(onefile);
          szout(end+1:dim) = 1;
          szone(end+1:dim) = 1;
          szout(dim) = [];
          szone(dim) = [];
          if any(szout~=szone) | ~comparevars(out.axisscale{2},onefile.axisscale{2})
            dim = 0; %triggers error or matchvars call
          end
        end        
        if dim==0
          %switch to cell mode and use matchvars call
          if options.catdim~=0 & options.catdim~=1
            %if not automatic mode and we're forcing to join as something
            %other than samples, throw error
            error('File %s cannot be combined with previous files (size of data does not match)',file{j});
          end
          cellmode = true;
        else
          %have a specific dim to join on
          if dim==3 & options.autopermute
            permute_order = [3 1 2];  %and set to permute 3rd dim to 1st (samples)
          end
          
          out = cat(dim,out,onefile);
          
          %create labels to note the file these items came from
          if j==2;
            %this is the SECOND file, create labels from the first file (now
            %that we know which way we're concatenating)
            [pth,filename,ext] = fileparts(file{1});
            newlbls = repmat({[filename ext]},1,size(out,dim)-size(onefile,dim));
          end
          [pth,filename,ext] = fileparts(file{j});
          newlbls = [newlbls repmat({[filename ext]},1,size(onefile,dim))];
        end
        
      end
      
      if cellmode
        dim = 1;
        if isempty(celldata)
          %first item added
          celldata = {out};
          if j==2;
            %this is the SECOND file, create labels from the first file
            %(note, if first few files COULD be joined, than we've done
            %this already, above. ONLY needed here if the second file
            %didn't match the first)
            [pth,filename,ext] = fileparts(file{1});
            newlbls = repmat({[filename ext]},1,size(out,1));
          end
        end
        %add latest data to cell
        celldata{end+1} = onefile;
        %add labels for new onefile
        [pth,filename,ext] = fileparts(file{j});
        newlbls = [newlbls repmat({[filename ext]},1,size(onefile,1))];
      end
      
      if ishandle(wbh)
        waitbar(j/length(file),wbh);
      end
    end
    
    if cellmode
      out = matchvars(celldata);
    end

    %add source info
    out = addsourceinfo(out,file);
    
    if length(file)>1
      %locate first empty label set in dim
      set = size(out.label,2)+1;  %default is to create new set
      for j=1:size(out.label,2);
        if isempty(out.label{dim,j})
          set = j;  %this set is empty, use it instead
          break;
        end
      end
      out.label{dim,set} = newlbls;
    end
    
    if ~isempty(permute_order)
      out = permute(out,permute_order);
    end
    
  catch
    if ishandle(wbh)
      delete(wbh)
    end
    rethrow(lasterror);
  end
  
  if ishandle(wbh)
    delete(wbh)
  end

  return
end

if ~isempty(delim)
  switch delim
    case {'tab', '\t'}
      delim = sprintf('\t');
    case 'space'
      delim = ' ';
    case 'comma'
      delim = ',';
    case 'semi'
      delim = ';';
    case 'bar'
      delim = '|';
  end
end

%check for extension
[pathstr,name,ext] = fileparts(file);
if ~exist(file,'file');
  error(['Unable to locate file (''' file '''). Please specify file using full path']);
end

if ismember(lower(ext),{'.xls' '.xlsx' '.xlsm' '.xlsb'}) & isempty(delim);
  %Looks like excel from the extension - check contents
  [fid,message] = fopen(file,'r');
  if fid<0
    error(message)
  end
  uc = unique(double(fread(fid,200,'char')))';
  fclose(fid);
  isbinary = any(~ismember(uc,[0 1 9 13 10 32:254]));
  if isbinary
    if strcmpi(options.parsing,'graphical_selection') | strcmpi(options.parsing,'importtool')
      options.useimporttool = 'yes';
    end
    [out,usedoptions] = xlsreadr(file,options);  %defer to xlsreadr
    return
  end
end

if isempty(delim);  %if not specified but is CSV, assume comma or ;
  [fid,message] = fopen(file,'r');
  if fid<0
    error(message)
  end
  index = 0;
  data = {};
  while index<50 & ~feof(fid);
    index = index+1;
    data{index} = fgetl(fid);
  end
  fclose(fid);

  if index == 0;
    error('File appears to be empty.');
  end
  [delim,headerrows] = inferdelim(data);
  if options.headerrows==-1
    options.headerrows = headerrows;
  end
  tab   = char(9);
  space = ' ';
  if ~ismember(double(delim),double([',' ';' '|' tab space]))  %list of delimiters we support for CSV files
    %Unexpected delmiiter, Probably had a problem parsing. use comma
    delim = ',';
  end
end

%----------------------------------------------
%perform automatic parsing

if ismember(lower(options.parsing),{'automatic' 'auto' 'auto_strict' 'stream' 'graphical_selection' 'importtool'})
  
  switch lower(options.parsing)
    case {'stream'}
      [fid,message] = fopen(file,'r');
      if fid<0
        error(message)
      end

      %get length of file
      fseek(fid,0,'eof');
      epos = ftell(fid);
      frewind(fid);

      info = getheader(fid,options.headerrows);
      bufferedparsing;  %clear comments accumulated from file
      fn = @( ) bufferedparsing(fid,options.commentcharacter,epos);
      try
        [out,usedoptions] = parsemixed(fn,delim,options);
      catch
        %errors during parsing - CLOSE FILE then rethrow error
        le = lasterror;
        try
          fclose(fid);
        catch
        end
        rethrow(le)
      end
      fclose(fid);
      
      info = [info bufferedparsing];  %get accumulated comments from file
      out.description = strvcat(out.description,info{:});
      
    case {'automatic' 'auto' 'graphical_selection' 'importtool'}
      [fid,message] = fopen(file,'r');
      if fid<0
        error(message)
      end

      fseek(fid,0,'eof');
      epos = ftell(fid);
      frewind(fid);

      %read off header rows first
      info = getheader(fid,options.headerrows);
      
      %read remainder of file
      text = cell(100,1);
      ind = 0;
      if strcmp(options.waitbar,'on');
        wbh = waitbar(0,'Reading File (Close to abort)');
      else
        wbh = [];
      end
      while ~feof(fid);
        oneline = fgetl(fid);
        oneline([oneline==0])=[];
        if isnumeric(oneline) | isempty(oneline); continue; end  %skip empty lines
        if strcmp(oneline(1),options.commentcharacter)
          %comment character? (if any)? add to info
          info{end+1} = oneline;
        else
          %real line, add to text to parse
          ind=ind+1;
          text{ind,1} = oneline;
        end
        if ~isempty(wbh);
          if ~ishandle(wbh); error('Aborted by user'); end
          if mod(ind+length(info),100)==0
            waitbar(ftell(fid)./epos);
            text = [text; cell(100,1)];
          end
        end
      end;
      if ishandle(wbh); close(wbh); end
      fclose(fid);
      text = text(1:ind);  %drop unneeded extra cells on end
      
      if strcmpi(options.parsing,'graphical_selection') | strcmpi(options.parsing,'importtool')
        options.useimporttool = 'yes';
      end
      
      [out,usedoptions] = parsemixed(text,delim,options);
      
      if isdataset(out);
        out.description = strvcat(out.description,info{:});
      end
      
    case {'auto_strict'}
      
      if strcmp(options.waitbar,'on');
        wbh = waitbar(1,'Reading File - Please wait...');
      else
        wbh = [];
      end
      try
        if ~isempty(delim)
          raw = importdata(file,delim);
        else
          raw = importdata(file);
        end
        if isstruct(raw);
          [out,usedoptions] = parsemixed(raw.data,raw.textdata,options);
        elseif ~isnumeric(raw)
          [out,usedoptions] = parsemixed(raw,delim,options);
        elseif ~isdataset(raw)
          out = dataset(raw);
        else
          out = raw;
        end
      catch
        if ishandle(wbh); close(wbh); end
        error('Unable to parse - try using generic automatic parsing instead of "strict" parsing')
      end
      if ishandle(wbh); close(wbh); end
  end
  
  if isdataset(out);
    [pathstr,fname,fext] = fileparts(file);
    out.name = [fname fext];
    out.author = 'Created by TEXTREADR';
    out = addsourceinfo(out,file);
  end
  return
end  

%----------------------------------------------
%manual parsing

[fid,message] = fopen(file,'r');
if fid<0
  error(message)
end

fseek(fid,0,'eof');
epos = ftell(fid);
frewind(fid);

%read header (if any)
info = getheader(fid,options.headerrows);

%check for delimiter (if not specified)
if isempty(delim)
  index = 0;
  data = {};
  while index<50 & ~feof(fid);
    index = index+1;
    data{index} = fgetl(fid);
  end
  frewind(fid);
  
  if index == 0;
    fclose(fid);
    error('File appears to be empty.');
  end
  delim = inferdelim(data);
  if isempty(delim);
    fclose(fid);
    error('Unable to locate delimiter common to all lines - check file format');
  end
end

%start parsing with top rows of labels
vars = cell(1,options.collabels);
lineindex = 0;
while ~feof(fid) & lineindex<options.collabels;
  line = fgets(fid);

  if isempty(line); continue; end  %skip empty lines
  if strcmp(line(1),options.commentcharacter)
    %comment character? (if any)? add to info
    info{end+1} = line;
    continue  %and skip to next line
  end
  
  lineindex = lineindex + 1;
  z = find(line==delim);
  if isempty(z)
    fclose(fid);
    error('Specified delimiter not found - check file format');
  end

  colindex = 0;
  while ~isempty(line)
    colindex = colindex + 1;
    if line(1)==',';
      %check for empty item
      item = '';
      line = line(2:end);
    else
      [item,line] = strtok(line,delim);
      line = line(2:end);  %drop delim (if any)
    end
    %save as label
    if colindex<=options.rowlabels;
      %in a cell above row labels? add contents to info
      info{end+1} = item;
    else
      vars{lineindex} = strvcat(vars{lineindex},item);
    end
  end
  
end

wbh = [];
if strcmp(options.waitbar,'on');
  wbh = waitbar(0,'Parsing file (Close to abort)');
end
samps = cell(1,options.rowlabels);
data = [];
while ~feof(fid)
  line = fgets(fid);
  
  if isempty(line); continue; end  %skip empty lines
  if strcmp(line(1),options.commentcharacter)
    %comment character? (if any)? add to info
    info{end+1} = line;
    continue  %and skip to next line
  end

  lineindex = lineindex + 1;

  vect = [];
  colindex = 0;
  while ~isempty(line)
    colindex = colindex + 1;
    if line(1)==',';
      %check for empty item
      item = '';
      line = line(2:end);
    else
      [item,line] = strtok(line,delim);
      line = line(2:end);  %drop delim (if any)
    end
    %save as label if we're still in the labels columns
    if colindex<=options.rowlabels;
      samps{colindex} = strvcat(samps{colindex},item);
    else
      if isempty(item);
        item = nan;
      else  
        if any(item==':') %Assume its a time
          item = datenumplus(item);
        elseif any(item=='/') %Assume its a date
          item = datenumplus(item);
        else
          item = str2num(item);
        end
        if isempty(item);
          item = nan;
        end            
      end
      vect(end+1) = item;
    end      
  end
  if ~isempty(vect)
    if size(data,1)>1 & length(vect) ~= size(data,2);
      vect = ones(1,size(data,2))*nan;
    end
    data = [data; vect];
  end
  
  if ~isempty(wbh);
    if ~ishandle(wbh);
      error('Stopped by user');
    end
    if mod(lineindex,100)==0
      waitbar(ftell(fid)./epos);
    end
  end

end
if ishandle(wbh); close(wbh); end
fclose(fid);

if ~isempty(data)
  try
    ds = dataset;
    
    axisscales = {};
    if ~isempty(options.axisscalecols)
      axisscales{1} = data(:,options.axisscalecols)';  %grab axisscale columns
      data(:,options.axisscalecols) = [];  %and remove from data
    end
    if ~isempty(options.axisscalerows)
      axisscales{2} = data(options.axisscalerows,:);  %grab axisscale rows
      data(options.axisscalerows,:) = [];     %and remove from data
      if ~isempty(axisscales{1})
        axisscales{1}(options.axisscalerows,:) = [];    %and remove from other axisscale if present
      end
    end    
    
    ds.data = data;
    if ~isempty(samps);
      try
        for ind=1:length(samps)
          ds.label{1,ind} = samps{ind};
        end
      catch
        warning('EVRI:TextreadrLabelsSkipped','Unable to use sample labels (missing/extra labels?) - skipped')
      end
    end
    if ~isempty(vars);
      try
        for ind=1:length(vars)
          ds.label{2,ind} = vars{ind};
        end
      catch
        warning('EVRI:TextreadrLabelsSkipped','Unable to use variable labels (missing/extra labels?) - skipped')
      end
    end
    if ~isempty(axisscales)
      try
        for mode = 1:length(axisscales);
          for iset = 1:size(axisscales{mode},1)
            ds.axisscale{mode,iset} = axisscales{mode}(iset,:);
          end
        end
      catch
        warning('EVRI:TextreadrLabelsSkipped','Unable to use axisscales (missing/extra values?) - skipped')
      end
    end      
    ds.description = info;
    
    [pathstr,fname,fext] = fileparts(file);
    ds.name = [fname fext];
    ds.author = 'Created by TEXTREADR';
    
    if strcmp(options.compactdata,'yes')
      %drop all-excluded rows or columns
      bad = all(isnan(ds.data),2);
      if any(bad)
        ds = delsamps(ds,find(bad),1,2);
      end
      bad = all(isnan(ds.data),1);
      if any(bad)
        ds = delsamps(ds,find(bad),2,2);
      end
    end
    
    out = ds;
    if strcmp(options.transpose,'yes')
      out = out';
    end
    out = addsourceinfo(out,file);
  catch
    error(['Can not create dataset from data - ' lasterr])
  end
else
  out = dataset;
  out = addsourceinfo(out,file);
end

%--------------------------------------------------------
function header = getheader(fid,nrows)

header = {};
for j=1:nrows;
  if feof(fid);
    break;
  end
  header{j} = fgetl(fid);
end

%-------------------------------------------------------
function [line,complete] = bufferedparsing(fid,commentchar,filelength)
%reads a fileID one line at a time, setting aside lines that start with the
%indicated comment character

%create buffer to hold comments
% persistent comments
% if isempty(comments) & ~iscell(comments)
  comments = {};
% end

%no inputs? clear and/or retrieve comments stored in "comments"
if nargin==0
  if nargout==1
    %asked for output, return comments
    line = comments;
  end
  comments = {};  %and clear comments
  return;
end

%determine how much of the file we've read
complete = ftell(fid)/filelength;

%read one non-empty, non-comment line
line = [];
while isempty(line) & ~feof(fid)
  line = fgetl(fid);
  if ~isempty(line) & strcmp(line(1),commentchar)
    %comment character? (if any)? add to comments
%     comments{end+1} = line;
    line = [];  %and force to read another line
  end
end

