function out = writecsv(x,filename,options)
%WRITECSV Export a DataSet object to a comma-separated values (CSV) file.
% Exports a comma-separated values text file based on the contents of a
% DataSet object. The csv file will include any axisscale, class, label and
% include information contained in the file as well as author, description,
% name and date details.
%
% Required input:
% The dataset to export (x)
%
% Optional inputs: 
% filename = output filename to write CSV file. If filename is omitted, the user 
%            is prompted for an output filename.
% options = an options structure containing the following fields:
%       detailToInclude : [{'full'}|'limited'|'none']. Governs the 
%            amout of detail that is exported. The default is 'full' and 
%            will export all meta data includeding header information. 
%            'limited' will not export header information. Just, label, 
%            class, axisscale, and included meta data.'none' will export 
%            just the data and no meta data.
% 
% 
% Note that although the CSV file output is not directly readable by
% TEXTREADR, an XLS file created by Excel from the CSV file will be readable
% by XLSREADR (i.e. read the CSV file into Excel, then save as XLS. The
% output XLS file will be readable by XLSREADR).
%
%I/O: writecsv(x,filename,options)
%
%See also: AUTOEXPORT, XLSREADR

% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.detailsToInclude = 'full';
  if nargout==0; clear out; evriio(mfilename,x,options); else; out = evriio(mfilename,x,options); end
  return;
end

%parse inputs
switch nargin
  case 1
    options = [];
    filename = [];
  case 2
    %(x,filename), or
    %(x,options)
    if isstruct(filename)
      options = filename;
      filename = [];
    elseif ischar(filename)
      options = [];
    end
  case 3
    
end
options = reconopts(options,mfilename);

if isempty(filename)
  [filename,pth] = evriuiputfile('*.csv');
    if ~isstr(filename) & filename == 0
      return;
    end
    filename = fullfile(pth,filename);
end
  

if ~isa(x,'dataset')
  %not a dataset? write using Matlab's csvwrite if we can
  csvwrite(filename,x)
  return;
end

[fid,message] = fopen(filename,'w');
if fid<1
  disp(['Unable to open ' filename ' for output'])
  error(message);
end

dets = lower(options.detailsToInclude); %details option

%start saving
if any(strcmp(dets, {'full' 'limited'}))
  meta = getmeta(x);
  if strcmp(dets, 'full')
    writeheader(fid, x, meta);
  end
    writemeta(fid, x, meta);
    writedata(fid, x, meta);
elseif strcmp(dets, 'none')
  % just do writedata function
  writedata(fid, x, []);
else
  evrierrordlg('Unrecongized setting for options.detailsToInclude field', 'Options Error');
  return
end
fclose(fid);

%-----------------------------------------------------------
% get meta data
function meta = getmeta(x)
%grab items we're going to keep referring to
lbl   = x.label;
ax    = x.axisscale;
cl    = x.class;
cl_id = x.classid;

%add labels for additional (leading) columns of labels, axisscale and
%classes (note: done in opposite order from file because we're prepending labels)
%check if there are any row lables to show

dolbl = false;
for j=1:size(lbl,2);
  if ~isempty(lbl{1,j});
    dolbl = true;
    break
  end
end
namerow = ',';
extracolumns = 0;
if dolbl;  %if there are, add label for the column
  namerow = [namerow];
  for j=1:size(lbl,2);
    if ~isempty(lbl{1,j});
      name = x.labelname{1,j};
      if isempty(name);
        name = 'Label';
      end
      namerow = [namerow sprintf('"%s",',dblq(name))];  %display ABOVE table
      lbl{1,j} = strtocell(lbl{1,j});
      extracolumns = extracolumns+1;
    end
  end
end

%check if there are any excluded rows and, if so, show include column
showrowincl = length(x.include{1})<size(x.data,1);
if showrowincl
  name = 'Include';
  
  namerow = [namerow sprintf('"%s",',dblq(name))];  %display ABOVE table
  
  extracolumns = extracolumns+1;
end

for j=1:size(ax,2);
  if ~isempty(ax{1,j});
    name = x.axisscalename{1,j};
    if isempty(name);
      name = 'Axisscale';
    end
    namerow = [namerow sprintf('"%s",',dblq(name))];  %display ABOVE table
    
    extracolumns = extracolumns+1;
  end
end

for j=1:size(cl,2);
  if ~isempty(cl{1,j});
    name = x.classname{1,j};
    if isempty(name);
      name = 'Class';
    end
    namerow = [namerow sprintf('"%s",',dblq(name))];  %display ABOVE table
    
    extracolumns = extracolumns+1;
    
  end
end

if length(namerow)==1
  %only the comma?
  namerow = '';
end
meta.lbl          = lbl;
meta.ax           = ax;
meta.cl           = cl;    
meta.cl_id        = cl_id;
meta.namerow      = namerow;
meta.extracolumns = extracolumns;
meta.showrowincl  = showrowincl;

%-----------------------------------------------------------
function writeheader(fid, x, meta)
%add header

extracolumns = meta.extracolumns;

commas = ones(1,size(x,2)+extracolumns)*',';
fprintf(fid,['Name:,"%s"' commas '\n'],dblq(x.name));
fprintf(fid,['Author:,"%s"' commas '\n'],dblq(x.author));
fprintf(fid,['Date:,%s' commas '\n'],datestr(x.date));
fprintf(fid,['Modification Date:,%s' commas '\n'],datestr(x.moddate));

des = dblq(strtocell(x.description));
fprintf(fid,['Description:']);
fprintf(fid,[',"%s"' commas '\n'],des{:});
fprintf(fid,[',' commas '\n']);
fprintf(fid,[',' commas '\n']);

%-----------------------------------------------------------
%print column labels, axisscales, and classes (if present)
function writemeta(fid,x, meta)

%get necessary meta data
lbl = meta.lbl;
ax = meta.ax;
cl = meta.cl;   
cl_id = meta.cl_id;
extracolumns = meta.extracolumns;
namerow = meta.namerow;

if ~isempty(namerow)
  commas = ones(1,size(x,2)+extracolumns)*',';
  fprintf(fid,['%s' commas(1:end-extracolumns) '\n'],namerow);
end

for k=1:size(lbl,2)
  if ~isempty(lbl{2,k})
    name = x.labelname{2,k};
    if isempty(name)
      name = 'Label';
    end
    fprintf(fid,['"' dblq(name) '",']);
    fprintf(fid,repmat(',',1,extracolumns));
    lbl{2,k} = dblq(strtocell(lbl{2,k}));
    fprintf(fid,'"%s",',lbl{2,k}{:});
    fprintf(fid,'\n');
  end
end

if length(x.include{2})<size(x.data,2)
  fprintf(fid,'Include,');
  fprintf(fid,repmat(',',1,extracolumns));
  isincl = ismember(1:size(x.data,2),x.include{2});
  fprintf(fid,'%i,',isincl);
  fprintf(fid,'\n');
end

for k=1:size(ax,2)
  if ~isempty(ax{2,k})
    name = x.axisscalename{2,k};
    if isempty(name)
      name = 'Axisscale';
    end
    fprintf(fid,['"' dblq(name) '",']);
    fprintf(fid,repmat(',',1,extracolumns));
    fprintf(fid,'%.12g,',ax{2,k});
    fprintf(fid,'\n');
  end
end

for k=1:size(cl,2)
  if ~isempty(cl{2,k})
    name = x.classname{2,k};
    if isempty(name)
      name = 'Class ID';
    end
    fprintf(fid,['"' dblq(name) '",']);
    fprintf(fid,repmat(',',1,extracolumns));
    oneset = dblq(cl_id{2,k});
    fprintf(fid,'"%s",',oneset{:});
    fprintf(fid,'\n');
  end
end

%-----------------------------------------------------------
%print data rows
function writedata(fid,x,meta)
  
for j=1:size(x.data,1)
  
  if ~isempty(meta)
    lbl = meta.lbl;
    ax = meta.ax;
    cl = meta.cl;
    cl_id = meta.cl_id;
    showrowincl = meta.showrowincl;
    
    fprintf(fid,',');
    for k=1:size(lbl,2)
      if ~isempty(lbl{1,k})
        fprintf(fid,'"%s",',dblq(lbl{1,k}{j}));
      end
    end
    if showrowincl
      fprintf(fid,'%i,',ismember(j,x.include{1}));
    end
    for k=1:size(ax,2)
      if ~isempty(ax{1,k})
        fprintf(fid,'%.12g,',ax{1,k}(j));
      end
    end
    for k=1:size(cl,2)
      if ~isempty(cl{1,k})
        fprintf(fid,'"%s",',dblq(cl_id{1,k}{j}));
      end
    end
  end

  fprintf(fid,'%.12g,',x.data(j,:));
  fprintf(fid,'\n');

end

%============================================
function clbl = strtocell(lbl)
clbl = {};
for j=1:size(lbl,1)
  temp = deblank(lbl(j,:));
  if isempty(temp)
    temp = ''; 
  end
  clbl{j} = temp;
end
if isempty(clbl)
  clbl = {''}; 
end

%==========================================
function out = dblq(in)
%convert " to "" to avoid accidentally closing a string

out = regexprep(in,'"','""');
