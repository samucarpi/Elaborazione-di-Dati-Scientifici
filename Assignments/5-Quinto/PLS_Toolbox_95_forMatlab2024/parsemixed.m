function [data,options] = parsemixed(a,b,options)
%PARSEMIXED Parse numerical and text data into a DataSet Object.
% Parses out numerical and textual/label data from a text and/or numerical
% array and outputs results as a DataSet Object. Inputs can be in three
% forms: 
%    1) Two inputs containing a numerical array (a) and a matching cell
%       array containing text (b)
%       a = numerical array containing the numerical portion of the data to
%           parse (NOTE: NaN's are OK) OR a text or cell array of data to
%           parse (see (delim) below).
%       b = a cell array of the same size as (a) but containing any strings
%           which were not interpretable as numbers
% or 2) A cell array (a) of strings of delimited values and/or labels to
%       parse for numerical and label information. In this form of call,
%       the second input can be (delim) = a delimiter to use to parse plain
%       text of (a). If omitted, (a) will be searched for a common
%       delimiter in nearly all lines.
% or 3) A function handle (fn) which, when called with no inputs, returns
%       two outputs: 
%          myrow = one row of text to parse (return an empty string when
%                  complete), and  
%          complete = fraction completion of reading of content
%       A typical function caled here will keep a file open using
%       persistent variables. The caller to parsemixed should expect to
%       have to trap errors and close any open files.
%
% OPTIONAL INPUTS:
%   options = an options structure containing one or more of the following
%        fields:
%
%     labelcols : [] Specifies one or more columns of the file which should be
%        interpreted as text labels for rows even if parsable as numbers.
%     labelrows : [] Specifies one or more rows of the file which should be
%        interpreted as text labels for columns even if parsable as numbers.
%
%     includecols : [] Specifies one or more columns of the file which should be
%        interpreted as the "include" field for ROWS of the matrix (i.e.
%        this column specifies which rows should be included). Multiple
%        items in this list will be combined using a logical "and" (all
%        must be "1" to include field.
%     includerows : [] Specifies one or more rows of the file which should be
%        interpreted as the "include" field for COLUMNS of the matrix (see
%        above notes about includecols).
%
%     classcols : [] Specifies one or more columns of the file which should be
%        interpreted as classes for rows of the data.
%     classrows : [] Specifies one or more rows of the file which should be
%        interpreted as classes for columns of the data.
%
%     axisscalecols : [] Specifies one or more columns of the file which should be
%        interpreted as axisscales for rows of the data.
%     axisscalerows : [] Specifies one or more rows of the file which should be
%        interpreted as axisscales for columns of the data.
%
%     ignorecols : [] Specifies one or more columns of the file which should be
%        ignored and not imported.
%     ignorerows : [] Specifies one or more rows of the file which should be
%        ignored and not imported.
%
%     parseengine : [ 'simple' |{'regexp'}] Governs which text parse engine to use.
%       'regexp' supports far more formats including double-quoted strings
%       and the delimiter and format options below. 'simple' is a
%       less-featured parser which gives the behavior of older PARSEMIXED
%       versions. Setting 'regexp' is not supported in Matlab 6.5.
%     multipledelim : [ 'single' |{'multiple'}] Governs how to handle
%        consecutive delimiters with no content between them. 'multiple'
%        considers each delimiter as sequence of empty elements (NaNs).
%        'single' considers multiple successive delimiters as a single
%        delimiter.
%     leadingdelim : [ 'ignore' |{'missing'}] Governs handling of
%        delimiters which appear at the beginning of a line. If 'ignore'
%        any leading delimiters are ignored. If 'missing', all leading
%        delimiters are considered as indicating a missing value and NaN
%        will be placed into the given element.
%     euformat : [{'off'}| 'on' ] Governs the use of European Union
%        format for decimals. 'on' expects decimal values to be specified
%        using a comma to separate the whole and fraction parts of a
%        number. e.g:  3,23 = 3.23. NOTE: cannot be used with comma
%        delimiters.
%     maxpreviewcols : [48] Number of columns to show in visual mode.
%     maxpreviewrows : [50] Number of rows to show in visual mode.
%
%     compactdata : [ 'no' | {'yes'} ]  Specifies if columns and rows which
%        are entirely excluded should be permanently removed from the table.
%     transpose : [ {'no'} | 'yes' ]  Specifies if the parsed data is
%       transposed (samples are columns) and that the resulting DataSet
%       needs to be transposed after parsing.
%     waitbar : [ 'off' | {'on'} ] Specifies whether waitbars should be
%       shown while the data is being processed.
%     useimporttool : [ 'no' | {'yes'} ] Use GUI to identify
%       label/class/axis rows and columns. 
% 
% OUTPUTS:
%   data = a DataSet object with a "logical" interpretation of the
%          numerical and text data. It identifies contiguous block of
%          numbers and then attempts to interpret text as labels and label
%          names for that block of data.
%  options = the options structure that was passed in with any
%          modifications made during import (including when using the
%          import tool to define columns/etc).
%
%I/O: data = parsemixed(a,b,options);
%I/O: data = parsemixed(a,delim,options);
%I/O: data = parsemixed(a,options);
%I/O: data = parsemixed(fn,options);
%
%See also: AREADR, DATASET, TEXTREADR, XLSREADR

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS 02/2004
%jms 4/04 -added multiple sheets support
%  -fixed no column labels bug
%jms 6/04 -added second input of sheet name to read.
%jms 2/05 -do not require labels for empty rows/cols (only included rows/cols)

if nargin==0; a = 'io'; end
if isstr(a) & ismember(a,evriio([],'validtopics'))
  options = [];
  options.defaultdelim  = [];
  options.labelcols = [];
  options.labelrows = [];
  options.includecols = [];
  options.includerows = [];
  options.classcols = [];
  options.classrows = [];
  options.axisscalecols = [];
  options.axisscalerows = [];
  options.ignorecols = [];
  options.ignorerows = [];
  options.useimporttool = 'no';
  options.maxpreviewcols = 48;
  options.maxpreviewrows = 50;

  if checkmlversion('<=','7.2')
    options.parseengine = 'simple';
  else
    options.parseengine = 'regexp';
  end
  options.multipledelim = 'multiple';
  options.leadingdelim = 'missing';
  options.euformat      = 'off';
  options.compactdata = 'yes';
  options.transpose   = 'no';
  options.waitbar     = 'on';
  if nargout==0; evriio(mfilename,a,options); else; data = evriio(mfilename,a,options); end
  return;
end

emptymap = [];
%didn't get two inputs (or second one isn't a cell)? Try parseing
if nargin==1 | (nargin>1 & ~iscell(b));
  if nargin==2; 
    if isstruct(b);
      options = b;
      delim = [];
    else
      delim = b;
      options = [];
    end
  elseif nargin==1
    delim = [];
   options = [];
  else
    delim = b;
  end
  options = reconopts(options,'parsemixed',0);

  b = [];
  if ~isa(a,'function_handle') & ~isa(a,'char') & ~isa(a,'cell')
    error('Incorrect format for input (must be cell or string)');
  end

  if isa(a,'char')
    %parse into cells
    a = str2cell(a,true);
  end
  
  if any(size(a)==1);
    if iscell(a)
      %cell of strings needing parsing
      a = a(:); %create column vector
      if isempty(delim)
        if ~isempty(options.defaultdelim)
          delim = options.defaultdelim;
        else
          delim = inferdelim(a);
        end
      end
    end
    
    if isnumeric(delim)
      delim = char(delim);
    end
    options.defaultdelim = delim;  %store in case caller wants to know what was used
    
    if strcmpi(options.euformat, 'on') & strcmp(delim, ',')
      error('Cannot use comma delimiter with EU format')
    end
    
    if numel(delim)>1
      error('Delimiter must contain only one element')
    end
    
    switch options.parseengine
      case 'regexp'
        if checkmlversion('<=','7.2')
          error('''regexp'' parseengine is not supported for Matlab versions prior to 2006b');
        end
        parser = @parserowreg;
      case 'simple'
        if strcmpi(options.euformat,'on')
          error('EU Format not supported with "simple" parseengine option')
        end
        if strcmpi(options.multipledelim,'single')
          error('Option Multiple Delimiters = ''single'' not supported with "simple" parseengine option')
        end
        parser = @parserow;
      otherwise
        error('Unrecognized setting for parseengine option')
    end
    
    if ~strcmp(options.waitbar,'off');
      wbh = waitbar(0,'Parsing lines for numerical data (Close to abort)');
    else
      wbh = [];
    end
    parseda = zeros(length(a),1)*nan;
    parsedb = cell(length(a),1);
    emptymap = false(length(a),1);  %note - logic inverted below

    looping = true;
    j = 0;
    estrows = [];
    while looping
      if isa(a,'function_handle')
        %function handle to read from file
        [myrow,complete] = feval(a);  %get one row from file
        if isempty(myrow);
          break;
        end
        j = j+1;
        updatecycle = 50;
        if isempty(estrows) & complete>0.05
          %now we've read a few lines, see what the likely # of rows is
          estrows = floor(j/complete);
          sz = size(parseda);
          if sz(1)<estrows
            %size up matrices to speed up reading
            parseda = [parseda; nan(estrows-sz(1),sz(2))];
            parsedb{estrows,end} = [];
            emptymap(estrows,end) = 0;
          end
        end
      else
        %standard matrix of strings
        j = j+1;
        estrows = j;
        if j>length(a);
          break;
        end        
        myrow = a{j};
        complete = j/length(a);
        updatecycle = 200;
      end
      
      options.alllabels = any(options.labelrows==j);
      try
        [newa,newb,notemptymaprow] = feval(parser,myrow,delim,options);
      catch
        if ishandle(wbh); close(wbh); end
        error('Unrecognized numerical format in line %i: %s',j,lasterr)
      end
      
      parseda(:,end+1:length(newa)) = NaN;  %pre-infill with NaNs if we're expanding
      parseda(j,1:length(newa)) = newa;
      parseda(j,length(newa)+1:end) = NaN;  %infill NaN for missing
      parsedb(j,1:length(newb)) = newb;
      emptymap(j,1:length(notemptymaprow)) = notemptymaprow;
      if j/updatecycle==fix(j/updatecycle) & ~isempty(wbh);
        waitbar(complete);
      end
      if ~ishandle(wbh); error('Aborted by user'); end
    end

    if ishandle(wbh); close(wbh); end
    if j<estrows
      %if we padded with too many rows, drop them now
      parseda = parseda(1:j,:);
      parsedb = parsedb(1:j,:);
      emptymap = emptymap(1:j,:);
    end
    a = parseda;
    b = parsedb;
    emptymap = ~emptymap;  %invert logic (thus non-specified are considered empty)
    clear parseda parsedb
  else
    %try parsing into numeric and strings
    b = a;
    a = ones(size(b))*nan;
    %TODO: use cellfun to replace code below.
    for j=1:size(b,1);
      for k=1:size(b,2);
        element = b{j,k};
        if isnumeric(element) & ~isempty(element)
          a(j,k) = double(element);
          b{j,k} = [];
        end
      end
    end
  end
  
else
  %got a and b pre-parsed
  if nargin<3
    options = [];
  end
  options = reconopts(options,'parsemixed');

  if  any(size(a)~=size(b))
    a = alignab(a,b);
  end

  %adjust numeric array (a) to match size of strings (b) so that logic
  %below works to extract rows and columns as needed
  if any(size(a)<size(b)) & ~any(size(a)>size(b))
    %as long as b is bigger in any dimension (and a is smaller or equal in
    %all dims)pad beginning with necessary rows and columns to match up
    %with first numeric position in b
    emptymap = ~cellfun('isclass',b,'char');
    if ~any(any(emptymap));
      emptymap = cellfun('isempty',b);
    end

    %add rows and cols at END to match size of b
    if size(a,1)<size(b,1);
      a = [a;zeros(size(b,1)-size(a,1),size(a,2))*nan];
    end
    if size(a,2)<size(b,2);
      a = [a zeros(size(a,1),size(b,2)-size(a,2))*nan];
    end    
  end

  %if b (string cell array) is too SMALL, make sure it has appropriate rows
  %and columns 
  if ~isempty(a) && any(size(b)<size(a))
    if isempty(b)
      b = cell(size(a));
    else
      [b{1:end,end+1:size(a,2)}] = deal('');
      [b{end+1:size(a,1),1:end}] = deal('');
    end
  end  
end

%determine if we got emptymap while parsing (some parsing methods don't
%return this so we'll have to figure out what is empty or not later)
%We have to generate this now because the tests below need to block out
%some of the points if they are grabbed for other purposes
if isempty(emptymap)
  %don't have it, create one now to fill in later
  if ~isempty(b)
    emptymap = ~cellfun('isclass',b,'char') | cellfun('isempty',b);
  else
    emptymap = [];
  end
end


%identify first column(s) of completely empty values and no lables - remove
%if found. This handles when files have multiple delimiters and leading
%delimiters at the beginning of each line
allempty = all(cellfun('isempty',b),1) & all(~emptymap,1);
a = a(:,~allempty);
b = b(:,~allempty);
emptymap = emptymap(:,~allempty);

if strcmp(options.useimporttool,'yes')
  %Use GUI to identify label/class/axis rows and columns.
  tempdata = b(1:min(end,options.maxpreviewrows),1:min(end,options.maxpreviewcols));
  tdm      = 1:size(tempdata,1);
  tdn      = 1:size(tempdata,2);
  emsub    = emptymap(tdm,tdn);
  asub     = a(tdm,tdn);
  tempdata(emsub) = num2cell(asub(emsub));
  %Pass in inferred labels, don't use options already defined because
  %presumably we're using the manual gui because those are not being used.
  itopts = importtool('options');
  lblmap = emsub & ~isnan(asub);
  if size(tempdata,1)>5
    cdat.Label = find(~any(lblmap,1));
  else
    cdat.Label = [];
  end
  if size(tempdata,2)>5
    rdat.Label = find(~any(lblmap,2));
  else
    rdat.Label = [];
  end
  try
    [cdat, rdat] = importtool(tempdata,itopts,cdat,rdat);
    if isempty(cdat)
      data = [];
      return
    end
  catch
    %errors when calling the tool? just skip using it
    cdat = [];
    rdat = [];
  end
  clear tempdata;%Save mememory if this is big data.
  if ~isempty(cdat)
    optionsfields = {'Label','Include','Class','Axisscale','Ignore'};
    for i = optionsfields%Option fields
      options.([lower(i{:}) 'cols']) = cdat.(i{:});
      options.([lower(i{:}) 'rows']) = rdat.(i{:});
    end
  end
end

%Identify rows/cols specifically identified to be ignored and cut them out.
if ~isempty(options.ignorecols)
  cols = options.ignorecols;
  cols = cols(cols<=size(a,2));%Remove any cols that are out of domain.
  a(:,cols) = [];
  emptymap(:,cols) = [];
  b(:,cols) = [];
  
  %correct for lost cols in other parameters
  optionsfields = {'Label','Include','Class','Axisscale'};
  for i = optionsfields%Option fields
    item = options.([lower(i{:}) 'cols']);
    item = setdiff(item,cols);
    for j=1:length(item);
      item(j) = item(j)-sum(cols<item(j));
    end
    options.([lower(i{:}) 'cols']) = item;
  end

end
if ~isempty(options.ignorerows)
  rows = options.ignorerows;
  rows = rows(rows<=size(a,1));%Remove any rows that are out of domain.
  a(rows,:) = [];
  emptymap(rows,:) = [];
  b(rows,:) = [];
  
  %correct for lost rows in other parameters
  optionsfields = {'Label','Include','Class','Axisscale'};
  for i = optionsfields%Option fields
    item = options.([lower(i{:}) 'rows']);
    item = setdiff(item,rows);
    for j=1:length(item);
      item(j) = item(j)-sum(rows<item(j));
    end
    options.([lower(i{:}) 'rows']) = item;
  end
  
end

%identify rows/cols specifically identified as labels and convert to strings
for indx = 1:length(options.labelcols)
  col = options.labelcols(indx);
  use = ~isnan(a(:,col));
  if ~any(use); continue; end
  b(use,col) = str2cell(num2str(a(use,col)));
  a(use,col) = nan;
  if ~isempty(emptymap)
    emptymap(use,col) = 0;
  end
end  
for indx = 1:length(options.labelrows)
  row = options.labelrows(indx);
  use = ~isnan(a(row,:));
  if ~any(use); continue; end
  b(row,use) = str2cell(num2str(a(row,use)'));
  a(row,use) = nan;
  if ~isempty(emptymap)
    emptymap(row,use) = 0;
  end
end

%move "include" rows/cols into temporary include cells
include = {ones(1,size(a,1)) ones(1,size(a,2))};
for indx = 1:length(options.includecols)
  col = options.includecols(indx);
  use = ~isnan(a(:,col));
  incl = use';
  incl(use) = a(use,col)~=0;
  include{1} = include{1} & incl;
  a(use,col) = nan;
  if ~isempty(emptymap)
    emptymap(use,col) = 0;
  end
end
for indx = 1:length(options.includerows)
  row = options.includerows(indx);
  use = ~isnan(a(row,:));
  incl = use;
  incl(use) = a(row,use)~=0;
  include{2} = include{2} & incl;
  a(row,use) = nan;
  if ~isempty(emptymap)
    emptymap(row,use) = 0;
  end
end

%move "class" rows/cols into temporary class cell
classes = {[];[]};
classname = {'';''};
for indx = 1:length(options.classcols)
  col = options.classcols(indx);
  classes{1,indx} = a(:,col);
  if all(isnan(classes{1,indx}))
    %no numeric values in this column? grab labels to convert to class
    if size(b,2)>=col
      classes{1,indx} = forcestring(b(:,col));
    end
  end
  a(:,col) = nan;
  if ~isempty(emptymap)
    emptymap(:,col) = 0;
  end
  %see if we can locate a class name for this set
  classname{1,indx} = '';
  if size(b,2)>=col
    for row=1:size(b,1);
      if ~isempty(b{row,col}) %first non-empty text in this column
        classname{1,indx} = b{row,col};
        break;
      end
    end
  end
end
for indx = 1:length(options.classrows)
  row = options.classrows(indx);
  classes{2,indx} = a(row,:);
  if all(isnan(classes{2,indx}))
    %no numeric values in this column? grab labels to convert to class
    if size(b,1)>=row
      classes{2,indx} = forcestring(b(row,:));
    end
  end
  a(row,:) = nan;
  if ~isempty(emptymap)
    emptymap(row,:) = 0;
  end
  %see if we can locate a class name for this set
  classname{2,indx} = '';
  if size(b,1)>=row
    for col=1:size(b,2);
      if ~isempty(b{row,col}) %first non-empty text in this row
        classname{2,indx} = b{row,col};
        break;
      end
    end
  end
end

%move "axisscale" rows/cols into temporary cell
axisscale = {[];[]};
axisscalename = {'';''};
for indx = 1:length(options.axisscalecols)
  col = options.axisscalecols(indx);
  axisscale{1,indx} = a(:,col);
  if all(isnan(axisscale{1,indx})) & size(b,2)>=col
    %not numeric? see if its date/time in the strings
    [temp,ok] = datenumplus(b(:,col));
    if ok & length(temp)==size(a,1)
      %got good date/time
      axisscale{1,indx} = temp;
      [b{:,col}] = deal('');
    end
  end
  a(:,col) = nan;
  if ~isempty(emptymap)
    emptymap(:,col) = 0;
  end
  %see if we can locate a name for this set
  axisscalename{1,indx} = '';
  if size(b,2)>=col
    for row=1:size(b,1);
      if ~isempty(b{row,col}) %first non-empty text in this column
        axisscalename{1,indx} = b{row,col};
        b{row,col} = '';
        break;
      end
    end
  end
end
for indx = 1:length(options.axisscalerows)
  row = options.axisscalerows(indx);
  axisscale{2,indx} = a(row,:);
  if all(isnan(axisscale{2,indx})) & size(b,1)>=row
    %not numeric? see if its date/time in the strings
    [temp,ok] = datenumplus(b(row,:));
    if ok & length(temp)==size(a,2)
      %got good date/time
      axisscale{2,indx} = temp;
      [b{row,:}] = deal('');
    end
  end
  a(row,:) = nan;
  if ~isempty(emptymap)
    emptymap(row,:) = 0;
  end
  %see if we can locate a name for this set
  axisscalename{2,indx} = '';
  if size(b,1)>=row
    for col=1:size(b,2);
      if ~isempty(b{row,col}) %first non-empty text in this row
        axisscalename{2,indx} = b{row,col};
        b{row,col} = '';
        break;
      end
    end
  end
end

%-----------------------------------------------------
%drop rows or columns which are all NaN
notmissingmap = ~isnan(a);
rthreshold = min(3,max(1,size(notmissingmap,2)-4));  %must have at least 1 value in 1:5, 2 in 6, or 3 in 7+
cthreshold = min(3,max(1,size(notmissingmap,1)-4));
rthreshold = min(rthreshold,max(sum(notmissingmap,2)));  %reset thresholds if they would mean not taking ANY data
cthreshold = min(cthreshold,max(sum(notmissingmap,1))); 
cutat = [min(find(sum(notmissingmap,2)>=rthreshold)) min(find(sum(notmissingmap,1)>=cthreshold))];
cutathigh = [max(find(sum(notmissingmap,2)>=rthreshold)) max(find(sum(notmissingmap,1)>=cthreshold))];
if length(cutat)<2 | length(cutathigh)<2
  %no contiguous block of data? return as cell array
  data = b;
  return; 
end
a = a(cutat(1):cutathigh(1),cutat(2):cutathigh(2));
notmissingmap = notmissingmap(cutat(1):cutathigh(1),cutat(2):cutathigh(2));

if all(all(isnan(a))) | isempty(a)
  error('No numerical data could be found in the file');
end
data = dataset(a);
data.name = 'New Data';
data.include{1} = find(any(notmissingmap,2)' & include{1}(cutat(1):cutathigh(1)));
data.include{2} = find(any(notmissingmap,1) & include{2}(cutat(2):cutathigh(2)));

%check for useful labels
if ~isempty(b) 
  wasused = emptymap;
  
  %try to itendify how many RIGHT SIDE labels we have
  ncolvals    = sum(emptymap,1);
  needcolvals = sum(~isnan(a),1);
  endcol      = size(a,2);
  while endcol<size(b,2) & any(ncolvals(endcol-size(a,2)+1:endcol)<needcolvals); 
    endcol = endcol+1; 
  end

  %try to itendify how many BOTTOM SIDE labels we have
  nrowvals    = sum(emptymap,2);
  needrowvals = sum(~isnan(a),2);
  endrow      = size(a,1);
  while endrow<size(b,1) & any(nrowvals(endrow-size(a,1)+1:endrow)<needrowvals); 
    endrow = endrow+1; 
  end

  %find labels for rows
  rowlabels = [];
  userows = [];
  if size(b,1) >= size(a,1)
    userows = endrow-size(a,1)+1:endrow;
    good = sum(~emptymap(userows,:),1)>=max(min(5,length(data.include{1})),length(data.include{1})*.1);  % 10% of rows have labels? use it
    if any(good);
      rowlabels = find(good);
      setindex = 0;
      for j=1:length(rowlabels);
        lblset = forcestring(b(userows,rowlabels(j)));
        %lblset = fixlabelset(lblset);
        if ~all(cellfun('isempty',lblset));
          setindex = setindex+1;
          data.label{1,setindex} = lblset;
          wasused(userows,rowlabels(j)) = 1;
          %check for labelname
          for ri = min(userows)-1:-1:1
            lblname = b{ri,rowlabels(j)};
            if ~wasused(ri,rowlabels(j)) & ~isempty(lblname)
              data.labelname{1,setindex} = lblname;
              wasused(ri,rowlabels(j)) = 1;
              break;
            end
          end
        else
          rowlabels(j) = nan;  %mark as not really usable labels (so we ignore labelname below)
        end
        %TODO: add test for "is date/time" and "is include flag"
      end
    end
  end

  %find labels for columns
  collabels = [];
  usecols = [];
  if size(b,2) >= size(a,2)
    usecols = endcol-size(a,2)+1:endcol;
    good = sum(~emptymap(:,usecols),2)>=max(min(5,length(data.include{2})),length(data.include{2})*.1);
    if any(good);
      collabels = find(good);
      setindex = 0;
      for j=1:length(collabels);
        lblset = forcestring(b(collabels(j),usecols));
        %lblset = fixlabelset(lblset);
        if ~all(cellfun('isempty',lblset));  %as long as it isn't all empty...
          setindex = setindex+1;
          data.label{2,setindex} = lblset;
          wasused(collabels(j),usecols) = 1;
          %check for labelname
          for ci = min(usecols)-1:-1:1
            lblname = b{collabels(j),ci};
            if ~wasused(collabels(j),ci) & ~isempty(lblname)
              data.labelname{2,setindex} = lblname;
              wasused(collabels(j),ci) = 1;
              break;
            end
          end
        else
          collabels(j) = nan;   %mark as not really usable labels (so we ignore labelname below)
        end
        %TODO: add test for "is include flag"
      end
    end
  end

  %look at labels and see if there are any timestamps - if so, convert to
  %axisscales for the same mode:
  for m = 1:ndims(data);
    for setind = 1:size(data.label,2);
      onelabel = data.label{m,setind};
      if ~isempty(onelabel);
        if isempty(setdiff(lower(unique(onelabel))',['0':'9' ':/- ,.ampabcdefghijlmnoprstuvy']))  %"abcdefghijlmnoprstuvy" is the letters used in month names
          %try just converting to date without reordering elements
          try
            ts = datenumplus(onelabel);
          catch
            ts = [];
          end
          if isempty(ts)
            if size(onelabel,2)>=16 & all(all([onelabel(:,5)=='-' onelabel(:,8)=='-' onelabel(:,11)==' ']))
              %format: yyyy-mm-dd HH:MM:SS  (or similar)
              % try reordering columns for appropriate parsing
              reord = [12:size(onelabel,2) 11 6:10 5 1:4];
              onelabel = onelabel(:,reord);
              ts = datenumplus(onelabel);
            end
          end
            
          if size(ts,1)==size(data,m) & size(ts,2)==1;
            %this one appears to be a valid timestamp, add as axisscale for
            %this mode
            ts = ts(:)';
            done = 0;
            for tosetind = 1:size(axisscale,2);
              if isempty(axisscale{m,tosetind});
                axisscale{m,tosetind} = ts;
                axisscalename{m,tosetind} = data.labelname{m,setind};
                done = 1;
                break;
              end
            end
            if ~done
              axisscale{m,end+1} = ts;
              axisscalename{m,end+1} = data.labelname{m,setind};
            end
          end
        end
      end
    end
  end

  %clear out used items
  [b{wasused}] = deal(''); %clear out used items
  
  %concatente the remainder into a coherent textblock
  bempty = cellfun('isempty',b);  %identify empty elements
  droprows = all(bempty,2);
  b(droprows,:) = [];   %drop rows which are all used
  bempty(droprows,:) = [];
  temp = {};
  for j=1:size(b,1);
    bsub = forcestring(b(j,~bempty(j,:)));
    temp{j,1} = sprintf('%s ',bsub{:,:});
  end
  data.description = char(temp);
end

%copy relevent portions of classes (from user-identified columns/rows) into DSO
for m = 1:ndims(data);
  for setind = 1:size(classes,2);
    if ~isempty(classes{m,setind});
      temp = classes{m,setind}(cutat(m):cutathigh(m));
      data.class{m,setind} = temp;  %cell or double will work here
      data.classname{m,setind} = char(classname{m,setind});
    end
  end
end

%copy relevent portions of axisscales (from user-identified columns/rows) into DSO
for m = 1:ndims(data);
  for setind = 1:size(axisscale,2);
    temp = axisscale{m,setind};
    if length(temp)>size(data,m); temp = temp(cutat(m):cutathigh(m)); end
    data.axisscale{m,setind} = temp;
    data.axisscalename{m,setind} = char(axisscalename{m,setind});
  end
end


if strcmp(options.compactdata,'yes')
  %drop interspersed rows/columns excluded becuase they were all missing
  data = data(any(notmissingmap,2),any(notmissingmap,1));
end

if strcmp(options.transpose,'yes')
  data = data';
end

%----------------------------------------------
function [a,b,notemptymap] = parserow(string,delim,options)
%parse a string into multiple cells using delim as a delimiter
%inputs are (string) the string to parse, (delim) the known delimiter

emptyfirst = ~isempty(string) & string(1)==delim;
if emptyfirst
  %Prepend space character so code works correctly below.
  % this represents an empty first cell
  string = ['""' string];
end

if ~isempty(delim);
  dpos  = find(string==delim);
else
  dpos  = [];
end

%drop delimiters between quotes
quotes = find(string=='"');
if mod(length(quotes),2)==1;
  quotes = [quotes length(string)+1];
end
for j=1:2:length(quotes);
  dpos(dpos>quotes(j) & dpos<quotes(j+1)) = [];
end

%parse for numbers
b     = cell(1,length(dpos)+1);
notemptymap = zeros(size(b));
bad   = ~ismember(string,['0':'9' '.Ee+- ' delim]); %mark bad chars as bad
bad(dpos(dpos(1:end-1)+1==dpos([2:end]))) = 1; %mark double delimiters (empty cells) as "bad"
bad(regexpi(string,'\De')+1) = 1;  %mark e not following a number as "bad" (string, not exp notation)
if strcmpi(string(1),'e'); bad(1) = 1; end;  %first character as E is also "bad" (string, not exp notation)
if emptyfirst; bad(1) = 1; end    %empty first cell handled in above code
if ~isempty(dpos) & dpos(end)==length(string); bad(end) = 1; end  %empty last cell

isbad = max(find(bad));
while ~isempty(isbad)
  sdelim = max(dpos(dpos==isbad));
  if ~isempty(sdelim)
    %a delimiter is bad? that says it is an empty segment
    cellindex   = max(find(dpos==isbad))+1;
    b{cellindex} = '';
    bad(sdelim) = 0;
    string      = [string(1:sdelim) 'NaN' string(sdelim+1:end)];
    notemptymap(cellindex) = 1;
  else
    %not an exact match, find enclosing brackets
    [sdelim,cellindex] = max(dpos(dpos<isbad));
    edelim = min(dpos(dpos>isbad));
    if isempty(edelim);
      edelim    = length(string)+1;
    end
    if isempty(sdelim)
      sdelim = 0;
      cellindex = 0;
    end
    cellindex = cellindex +1;
    bad(sdelim+1:edelim-1) = 0;
    item = string(sdelim+1:edelim-1);
    if ~isempty(item) & item(1)=='"' & item(end)=='"'
      %drop enclosing quotes (if on both ends)
      item = item(2:end-1);
    end
    b{cellindex} = item;
    string       = [string(1:sdelim) 'NaN' string(edelim:end)];
    notemptymap(cellindex) = 1;
  end
  isbad = max(find(bad));
end
if ~isempty(delim);
  string(string==delim) = ',';  %replace remaining delimiters with commas
end
a = str2num(string);
if isempty(a) && ~isempty(string)
  %a ended up empty even though something was in string? probably a serious
  %flaw in the string. Try (as a last attempt) to dump all space
  %characters and see if we can convert then.
  string(string==' ') = [];
  a = str2num(string);
  if isempty(a)
    %still empty? throw error
    error('Unrecognized numerical format')
  end
end

%------------------------------------------------------------------

function [a,b,c] = parserowreg(in_str, delim, options)

pat.beg       = '^[\s]{0,}\001';
pat.end       = '\001[\s]{0,}$';
pat.items     = '(?<=\001).{0,}?(?=\001)'; %make this match lazy instead of greedy
pat.dblqutrep = '"\s{0,}"';
pat.numeric   = '^\s{0,}[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s{0,}$';
pat.nan       = '^\s*NaN\s*$';
pat.ack       = '\006';
pat.dblqutstr = '(?<=\001").{0,}?(?="\001)'; %make this lazy, too
%the following assignment for pat.dblqutstr is for later development -
%formatting where all entries are contained within double quotes and
%additional spaces
%pat.dblqutstr = '(?<=\001\s{0,}"\s{0,}).{0,}?(?=\s{0,}"\s{0,}\001)'
in_str_copy = in_str ;

try
  com_inds = findstr(in_str, '"')';
  com_inds = reshape(com_inds, 2, numel(com_inds)/2);
  starts   = com_inds(1,:);
  ends     = com_inds(2,:);
catch
  error('Error - uneven number of double quotes in string')
end

dbl_qut_str = cell(1,length(starts));
for j=1:length(starts);
  dbl_qut_str{j} = in_str(starts(j)+1:ends(j)-1);
  in_str(starts(j):ends(j)-1) = char(7);  %these will be deleted
  in_str(ends(j)) = char(6);  %this will be retained
end
in_str(in_str==char(7)) = [];

in_str = regexprep(in_str, delim, char(1)); %replace all delimiters in line with ASCII SOH

if isempty(regexp(in_str, pat.beg, 'once'))
  in_str = [char(1) in_str];
elseif strcmpi(options.leadingdelim,'missing')
  in_str = [char(1) 'NaN' in_str];
end

if isempty(regexp(in_str, pat.end, 'once'))
  in_str = [in_str char(1)];
else
  in_str = [in_str 'NaN' char(1)];
end

if strcmpi(options.euformat, 'on')
  in_str = regexprep(in_str, ',', '.');
end

switch options.multipledelim
  case 'multiple'
    switch delim
      case char(32)
        pat.dbldlm = '\001(?=\001)';
      otherwise
        pat.dbldlm = '\001(?=[\s]{0,}\001)';
    end
    in_str = regexprep(in_str, pat.dbldlm, [char(1) 'NaN']);
  case 'single'
    pat.dbldlm = '[\001]{2,}';
    in_str = regexprep(in_str, pat.dbldlm, [char(1)]);
end


in_str_cell = regexp(in_str, pat.items, 'match');
n_cols      = length(in_str_cell);

a = NaN(1, n_cols);
b = cell(1, n_cols);

cell_nums_srch = regexp(in_str_cell, pat.numeric, 'match');
cell_nums_inds = ~cellfun('isempty', cell_nums_srch);

cell_nums_inds(options.labelcols(options.labelcols<length(cell_nums_inds))) = false;   %do NOT convert explicitly noted labels
switch options.alllabels
  case true
    cell_nums_inds = false(size(cell_nums_inds));
end
cell_nums_srch    = cell_nums_srch(cell_nums_inds)';
cell_nums_srch    = [cell_nums_srch{:}];
cell_nums_srch    = char(cell_nums_srch);
cell_nums_vals    = str2num(cell_nums_srch)';
a(cell_nums_inds) = cell_nums_vals;

nan_inds    = ~cellfun('isempty', regexp(in_str_cell, pat.nan));
str_inds    = ~(nan_inds | cell_nums_inds);
b(str_inds) = in_str_cell(str_inds);

inf_inds = ~cellfun('isempty', regexp(in_str_cell, pat.ack));
if any(inf_inds)
  b(inf_inds) = dbl_qut_str(1:sum(inf_inds));
end

c = double(~cell_nums_inds);

if ~any(cell_nums_inds) & ~options.alllabels
  %didn't find ANY numeric values? check if there are numeric values
  %embedded inside quotes
  
  num_str = ~cellfun('isempty',regexp(b, pat.numeric));
  num_str(options.labelcols(options.labelcols<length(cell_nums_inds))) = false;   %do NOT convert explicitly noted labels
  
  a(num_str)  = str2num(char(b(num_str)'))';
  b(num_str) = {''};
  c(num_str) = 0;
  
end


%------------------------------------------------------------
function b = forcestring(b)

[b{cellfun('isempty',b)}] = deal('');

%------------------------------------------------------------
function a = alignab(a,b)

notemptymap = cellfun('isclass',b,'char') & ~cellfun('isempty',b);
notmissingmap = ~isnan(a);

[m,n] = size(notmissingmap);
match = compare(notemptymap,notmissingmap);
if match
  return;
end
count = 0;
while ~match & count<max(m,n) & count<30

  count = count+1;
  ind = genindex(count);
  for indindex=1:size(ind,1);
    
    addrows = ind(indindex,1);
    addcols = ind(indindex,2);
    
    match = compare(notemptymap,[false(addrows,n+addcols);false(m,addcols) notmissingmap]);
    if match
      break;
    end
  end

end

if match
  a = [nan(addrows,n+addcols);nan(m,addcols) a];
end


%----------------------------------------------
function result = compare(a,b)
[ma,na] = size(a);
[mb,nb] = size(b);

if ma<mb
  a = [a;false(mb-ma,na)];
  ma = mb;
end
if mb<ma
  b = [b;false(ma-mb,nb)];
  mb = ma;
end
if na<nb
  a = [a false(ma,nb-na)];
  na = nb;
end
if nb<na
  b = [b false(mb,na-nb)];
  nb = na;
end

result = ~any(any(a&b));

%----------------------------------------------
function ind = genindex(count)
[r,c]=find(fliplr(diag(ones(1,count),0)));
ind = [r c];
[junk,order] = sort(sum(ind.^2,2));
ind = ind(order,:)-1;

%----------------------------------------------
function fixed_lblset = fixlabelset(lblset)
fixed_lblset = lblset;

for i = 1:length(lblset)
  if length(lblset) == size(lblset,1)
    lbl = fixed_lblset{i,1};
    dm=1;
  else
    lbl = fixed_lblset{1,i};
    dm=2;
  end
  fixed_lbl = '';
  ind = 1;
  
  for j = 1:length(lbl)
    % take out <nwln> for now, but need to remove other unacceptable ones later 
    if lbl(1,j) == char(10) 
      % check if we should remove or replace.
      if ((j-1) > 0) & ((j+1) <= length(lbl))
        if (lbl(j-1) == char(32)) | (lbl(j+1) == char(32))
          continue;
        else
          fixed_lbl(1,ind) = char(32);
          ind = ind + 1;
        end
      else
        continue;
      end
    else
      fixed_lbl(1,ind) = lbl(1,j);
      ind = ind + 1;
    end
  end
  if (dm == 1)
    fixed_lblset{i,1} = fixed_lbl;
  else
    fixed_lblset{1,i} = fixed_lbl;
  end
end
