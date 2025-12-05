function dtable = createtable(data, labels, format, filterrows)
%CREATETABLE Transforms binary data into text columns.
% Creates a table (character array) from row data extracted from a figure for
% display in databox or for export to the clipboard.
%
%  INPUTS:
%        data   = Data (y row) from figure as matrix or cell array.
%        labels = Tag data from figure as character array.
%  OPTIONAL INPUT:
%        format = Sprintf format description (including %). Default is
%                 automatic determiniation of appropriate format.
%    filterrows = Boolean flag indicating [1] if rows containing all NaN
%                 should be filtered out. [0] will return all rows of data,
%                 whether or not the rows contain all NaNs. Default is [1].
%
%  OUTPUT:
%        dtable = Charater array of data and labels.
%
%I/O: [dtable] = createtable(data, labels, format, filterrows);
%
%See also: DATABOX.

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 02/02/04 initial coding
%jms 02/04/04 speed revisions
%rsk 02/17/04 change direction of column for loop for use with tabledata.m
%rsk 02/26/04 revise data handling, remove NaN's, allow matrix input
%jms 03/01/04 transpose expected data (thus, column matrix gives column
%     text in table)
%jms 03/26/04 convert data to double before creating table

%Check inputs, if z axis used then now header data comes through
%only check for data.
if isempty(data)% | isempty (labels)
  %Missing data, show error.
  error('Missing data for table creation.')
end

if ~iscell(data) & ~isnumeric(data)
  error('Wrong datatype for createtable.m, must be cell or numeric.')
end

if nargin<3;
  format = '';
end
if nargin<4;
  filterrows = 1;
end

%If cell is given transform into numeric array.
if iscell(data)
  
  %Check for equal length.
  if min(cellfun('length',data))~=max(cellfun('length',data))
    error('Length of data in cells must be equal.')
  end

  dataArray = [];
  for i = 1 : length(data)
    %If cell is a row transpose to column.
    if size(data{i},1)>size(data{i},2)
      dataArray = [dataArray data{i}];
    else
      dataArray = [dataArray data{i}'];
    end
    
  end
  data = dataArray;
end

if filterrows
  %Remove rows of NaN's (but only for multi-column data)
  nanRows = all(isnan(data),2) & size(data,2)>1;
  data(nanRows,:) = [];
end

%Deal with no labels.
if nargin == 1
  noLabels = 1;
elseif isempty(labels)
  noLabels = 1;
else
  if size(data,2) ~= size(labels,1)
    error('Number of labels must equal number of data columns.')
  end
  %make sure labels are a char array
  if iscell(labels)
    if size(labels,2)>size(labels,1);
      labels = labels';  %transpose to column cell array
    end
    labels = char(labels);
  end 
  noLabels = 0;
end

%Initialize dtable.
dtable = '';
for k = 1:size(data,2)
  
  tempTable = createcolumn(data(:,k),format);
  
  if noLabels ~= 1
    %Deblank labels, headers may have variable ' ' padding.
    lenLabel = length(deblank(labels(k,:)));
    
    %Create correct padding.
    if lenLabel < 12
      %       padLabel = '';
      %       for j = 1:(14 - lenLabel)
      %         padLabel = [padLabel ' '];
      %       end
      padLabel = blanks(14-lenLabel);
      tempTable = char([deblank(labels(k,:)) padLabel], tempTable);
    else
      tempTable = char([deblank(labels(k,:)) '  '], tempTable);
    end
  end
  %Append columns laterally  for correct display in databox.
  dtable = [dtable, tempTable repmat(char(9),size(tempTable,1),1)];
end  


%------------------------------------------------
function tbl = createcolumn(dat,format)
% create a single column of text for the vector (dat)

dat = double(dat);
%don't allow nan's or Infs through
nanloc = isnan(dat);  %identify bad points
infloc = isinf(dat);
dat(nanloc | infloc) = 0;  %replace with zero

if isempty(format)
  if all(abs(dat-round(dat))<1e-11);  %integer
    format = '% 12i  ';
    dat = round(dat);
    ext = 2;  %how many non-croppable spaces are on the end of this format
  elseif min(abs(dat(dat~=0)))>1e-1 & max(abs(dat))<1e5;  %lowest non-zero number > 1e-1 and largest < 10000? do regular notation
    format = '% 18.12f  ';
    ext = 2;  %how many non-croppable spaces are on the end of this format
  else
    format = '% 0.12E  ';
    ext = 7;  %how many non-croppable spaces are on the end of this format
  end
else
  %user-defined format
  format = [format '  '];
  ext = 2;
end

%create table
tbl = sprintf(format,dat);   %form row of text of numbers
try
  tbl = reshape(tbl,length(tbl)/length(dat),length(dat));  %split into separate columns
catch
  %error reshaping? probably a precision issue. Just use exponential format
  tbl = sprintf('% 0.13E',dat);   %form row of text of numbers
  tbl = reshape(tbl,length(tbl)/length(dat),length(dat));  %split into separate columns
end
nonspace = ~all(tbl==' ',2);
tokeep   = min(size(tbl,1)-5,max(1,min(find(nonspace))-1)):size(tbl,1);
tbl = tbl(tokeep,:);
nonspace = nonspace(tokeep);
allzero  = all(tbl(1:end-ext,:)=='0',2);
if sum(allzero)>1;
  nonzero = max(find(~allzero));
  tbl = tbl([1:nonzero end-ext+1:end],:);
  nonspace = nonspace([1:nonzero end-ext+1:end]);
end
allperiod  = max(find(all(tbl(1:end-ext,:)=='.',2)));
if ~isempty(allperiod) & allperiod==max(find(nonspace))
  tbl(allperiod,:) = [];
  nonspace(allperiod) = [];
end
tbl = tbl';  %transpose to make rows of text

%QUICKLY - replace each row with appropriate "non-number" text
if any(nanloc)
  tbl(nanloc,:) = ' ';
  tbl(nanloc,end-4) = 'N';
  tbl(nanloc,end-3) = 'a';
  tbl(nanloc,end-2) = 'N';  
end
if any(infloc)
  tbl(infloc,:) = ' ';
  tbl(infloc,end-4) = 'I';
  tbl(infloc,end-3) = 'n';
  tbl(infloc,end-2) = 'f';  
end
