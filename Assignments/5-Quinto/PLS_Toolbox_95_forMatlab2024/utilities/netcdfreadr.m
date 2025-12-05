function [out, varargout] = netcdfreadr(filenames, options)
%NETCDFREADR Reads in netCDF files and outputs a DataSet and or structure.
%  If no file is given (filenames) then prompts user for filename/s.
%
%  NOTE: This function uses netCDF Library Functions available in
%        Matlab 2009a and newer.
%
%  INPUTS:
%       filename : a text string with the name of an CDF file or
%                  a cell of strings of CDF filenames.
%  OUTPUTS:
%        rawdata : Genereic structure of all data.
%                   .varname    = variable name.
%                   .xtype      = variable datatype.
%                   .varDimsIDs = dimensions IDs.
%                   .varAtts    = number of attributes.
%                   .varID      = variable ID.
%                   .data       = variable data.
%                   .attributes(j).attname  = attribute name.
%                   .attributes(j).attval   = attribute value.
%      datastruct : Structure of data with variable names as field names.
%          mydso : Dataset Object (only when .getms = yes).
%
%  OPTIONS:
%         output :[{'dso'}|'rawdata'|'datastruct'|'all'] What output to pass.
%                  Matchvars is applied to output dso.
%          getms : [{'yes'}|'no'] Get Mass Spec dataset from file.
%     massoffset : [0] Shift point for round-off (when using .getms).
%      chunksize : [1.5] Divide data into chunks of chunksize*1,000,000
%                        elements when contructing a MS dataset. Value of
%                        1.5 million is good default for 32bit systems.
%        massres : [1.0] desired output resolution in m/z units (when using
%                        .getms)
%  massresprompt : ['yes|{'no'}] prompt user for value for massres
%
%I/O: x = netcdfreadr(filenames, options);
%
%See also: ASFREADR, EDITDS, JCAMPREADR, SPCREADR, XCLREADR

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%
%RSK 11/03/2010

%NOTE: No (speed) optimization has been done on this function.

if nargin == 1 & ischar(filenames) & ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.output     = 'dso';
  options.getms      = 'on';
  options.massoffset = 0;
  options.chunksize  = 1.5;
  options.massres    = 1.0;
  options.massresprompt = 'off';
  
  if nargout==0;
    clear str;
    evriio(mfilename,filenames,options);
  else
    out = evriio(mfilename,filenames,options);
  end
  return;
end

if checkmlversion('<','7.7')
  %netcdf library not available.
  error('NETCDF Library not available for this version of Matlab.');
end

%Filename.
if nargin==0;
  filenames = '';
end
%Options.
if nargin<2
  options = [];
end
options = reconopts(options,mfilename);

%Initialize outputs.
out = [];
varargout = {[]};

% if no file list was passed
if isempty(filenames)
  switch class(filenames)
    case 'char'
      % was filelist an empty string? get one filename
      multiselect = 'off';
    otherwise
      % otherwise? get filenames
      multiselect = 'on';
  end
  %do actual read for filename
  [filenames, pathname, filterindex] = evriuigetfile({'*.cdf; *.CDF', 'Network Common Data Form (*.cdf)'; '*.*', 'All files'}, 'Import CDF Files','MultiSelect', multiselect);
  if filterindex==0
    out = [];
    return
  else
    %got one or more filenames, add path to each
    if ~iscell(filenames)
      filenames = {filenames};
    end
    for lll = 1:length(filenames)
      filenames{lll} = fullfile(pathname,filenames{lll});
    end
  end
end
if ~iscell(filenames)
  filenames = {filenames};
end

% now check each entry of filenames; those that don't have a path will be
% prepended with the current working directory

[pn,fn,ext] = cellfun(@fileparts, filenames, 'uniformoutput', false);
inds        = find(cellfun(@isempty, pn));
pn(inds)    = {pwd};
fn          = cellfun(@fullfile, pn, fn, 'uniformoutput', false);
filenames   = cellfun(@(x,y)cat(2,x,y),fn, ext, 'uniformoutput', ...
  false);


if strcmpi(options.massresprompt,'on') & strcmpi(options.getms,'on')
  %ask user for new resolution
  try
    res = [];
    warn = '';
    while isempty(res)
      res = inputdlg(['Desired output resolution (in m/z units)' warn],'Output Resolution',1,{num2str(options.massres)});
      if isempty(res)
        out = [];
        return;
      end
      res = str2num(res{1});
      if isempty(res) | length(res)~=1 | ~isfinite(res) | res<=0
        warn = [10 '(Invalid resolution)'];
        res = [];
      else
        options.massres = res;
      end
    end
      
  catch
    %ignore errors here
  end   
end

%Start reading in files.
try
  h = waitbar(0,'Reading CDF Files');
  for j = 1:length(filenames)
    waitbar(j/length(filenames))
    
    ncid         = netcdf.open(filenames{j},'NC_NOWRITE');
    [rawd,datas] = getinfo(ncid);
    netcdf.close(ncid);%Close file before getdso so errors don't leave file open.
    
    if strcmp(options.getms,'on')
      myd             = getdso_ms(datas,options);
      myd.description = strvcat(myd.description,...
        sprintf('netCDF import from %s', filenames{j}));
      myd = addsourceinfo(myd,filenames{j});
    else
      myd = [];
    end
    
    %Build cell output.
    rawdata{j}    = rawd;
    datastruct{j} = datas;
    mydso{j}      = myd;
  end
  if j==1
    %Pull out of cell if just one output.
    rawdata    = rawdata{j};
    datastruct = datastruct{j};
    mydso      = mydso{j};
  else
    switch options.output
      case {'dso' 'all'}
        mydso = matchvars(mydso);
        mydso = addsourceinfo(mydso,filenames);
    end
  end
  switch options.output
    case 'dso'
      out = mydso;
    case 'rawdata'
      out = rawdata;
    case 'datastruct'
      out = datastruct;
    case 'all'
      out = mydso;
      varargout{1} = rawdata;
      varargout{2} = datastruct;
  end
  close(h)
catch
  myerr = lasterr;
  if ishandle(h)
    delete(h)
  end
  try
    netcdf.close(ncid)
  end
  error(['NETCDFREADR: Encountered error reading CDF file (' myerr ')'])
end

%----------------------------------------
function [allstruct, datastruct] = getinfo(ncid)
%Put all data into two flavors of struct.

%Grab file info.
[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid);

%Get the name of the first variable.
out = [];
data = [];
for i = 1:nvars
  [varname, xtype, varDimIDs, varAtts] = netcdf.inqVar(ncid,i-1);%zero indexing
  out(i).varname = varname;
  out(i).xtype = xtype;
  out(i).varDimsIDs = varDimIDs;
  out(i).varAtts = varAtts;
  out(i).varID = netcdf.inqVarID(ncid,out(i).varname);
  mydata = [];
  try
    mydata = netcdf.getVar(ncid,out(i).varID);
  end
  out(i).data = mydata;
  if out(i).varAtts>0
    for j = 1:out(i).varAtts
      % Get attribute name, given variable id.
      out(i).attributes(j).attname = netcdf.inqAttName(ncid,out(i).varID,0);
      % Get value of attribute.
      out(i).attributes(j).attval = netcdf.getAtt(ncid,out(i).varID,out(i).attributes(j).attname);
    end
  end
  datastruct.(varname) = out(i).data;
end

%Get globals.
mygatts = [];
for i = 1:ngatts
  gattname = netcdf.inqAttName(ncid,netcdf.getConstant('NC_GLOBAL'),i-1);
  mygatts(i).(gattname) = netcdf.getAtt(ncid,netcdf.getConstant('NC_GLOBAL'),gattname);
end

%Assemble outputs.
datastruct.globals = mygatts;
allstruct.data     = out;
allstruct.globals  = mygatts;

%----------------------------------------
function cdfdso = getdso_ms(mydata,options)
%Build DSO from mass spec cdf file.

cdfdso = [];

%Use Willem code.
n_scans        = length(mydata.total_intensity);%Total number of data points (number of rows or spectra).
n_datapoints   = length(mydata.mass_values);%Total number of massess (number of columns).
row_array      = zeros(n_datapoints,1);%Init the array.
inv_res        = 1./options.massres;
column_array   = round(inv_res.*(mydata.mass_values-options.massoffset))./inv_res;%Apply offset and bin
mass_axis      = unique(column_array);
num_masses     = length(mass_axis);

%CREATE ROW_ARRAY WITH ROW INDICES FOR SPARSE
index1=1;
for i=1:n_scans
  if mydata.point_count(i);
    %a=repmat(i,mydata.point_count(i),1);
    a                        =ones(mydata.point_count(i),1)*i;
    %Use ones() instead of repmat helps speed by 25%.
    index2                   = index1+length(a)-1;%Offset in raw vector.
    row_array(index1:index2) = a;%Row number.
    index1                   = index2+1;
  end;
end;

% row_array        = [row_array; n_scans];
% % column_array=double([column_array; column_array(end)]);
% column_array     = [column_array; column_array(end)];
% intensity_values = double([mydata.intensity_values ; 0]);

intensity_values = double(mydata.intensity_values);

%Iterate through data using sparse to be memory friendly.
data     = zeros(n_scans, num_masses);%Create initial array.
%iter = floor(length(intensity_values)/options.chunksize);%Cut data into 1/chunksize chuncks. 
startidx = 1;

while startidx<=length(intensity_values)
  endidx = startidx+options.chunksize*1000000;
  if endidx>length(intensity_values)
    endidx = length(intensity_values);%Make last iteration to the end of the data.
  end
  cur_masses          = column_array(startidx:endidx);
  [~, mass_axis_inds] = ismember(cur_masses, mass_axis);
  subdata             = sparse(row_array(startidx:endidx), ...
    mass_axis_inds,intensity_values(startidx:endidx),n_scans, num_masses);
  data                = data+subdata;
  startidx            = endidx+1;
end

%Comment out this old code, it can be memory inefficient.
%   data=dataset(full(sparse(row_array,column_array,intensity_values)));
cdfdso                    = dataset(data);

cdfdso.axisscale{1,1}     = mydata.scan_acquisition_time/60;
cdfdso.axisscalename{1,1} = 'elapsed time, mins.';

cdfdso.axisscale{2,1}       = double(mass_axis);
cdfdso.axisscalename{2,1}   = 'm/z, amu';

%Add globals to description field.
mydescription = '';
fn = fieldnames(mydata.globals);
for i = 1:length(fn)
  sp            = {mydata.globals.(fn{i})};
  %ind           = find(~cellfun(@isempty, sp));
  sp            = sp{i};
  %sp            = sp{ind};
  if isnumeric(sp)
    sp = num2str(sp);
  end
  if isempty(sp)
    continue
  end
  mydescription = strvcat(mydescription,[fn{i} ' = ' sp]);
end
cdfdso.description = mydescription;

desc_cell = str2cell(cdfdso.description);
pat{1}    = 'experiment_date_time_stamp';
%pat{2}    = '([0-9]{14})([+-]0{0,})([1-9])';
pat{2}    = '([0-9]{14})([+-][0-9]{2}){0,1}([0-9]{2}){0,1}';
ind        = find(~cellfun('isempty', regexp(desc_cell, pat{1})));
if ~isempty(ind)
  cur_str    = desc_cell{ind};
  strtoks    = regexp(cur_str, pat{2}, 'tokens');
  strtoks    = [strtoks{:}];
  expt_start = datenum(strtoks{1}, 'yyyymmddHHMMSS');
  
  dt_num     = expt_start + cdfdso.axisscale{1,1}/(24*60);
  hrs_offset = str2num(strtoks{2});
  min_offset = str2num(strtoks{3});
  
  if ~any(isempty([hrs_offset min_offset]))
    
    cdfdso.axisscale{1,2}     = dt_num;
    cdfdso.axisscalename{1,2} = 'date and time, local';
    
    dt_num                    = arrayfun(@(x)addtodate(x, -hrs_offset, 'hour'), dt_num);
    dt_num                    = arrayfun(@(x)addtodate(x, ...
      -sign(hrs_offset)*min_offset, 'minute'), dt_num);
    cdfdso.axisscale{1,3}     = dt_num;
    cdfdso.axisscalename{1,3} = 'date and time, GMT';
  end
end

% remove any columns that have response of zero for all samples
zero_inds    = find(sum((cdfdso.data==0),1)==n_scans);
cdfdso       = delsamps(cdfdso, zero_inds, 2, 2);
