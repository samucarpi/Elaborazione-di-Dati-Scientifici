function [data,lotinfo] = mtfreadr(filename,combine)
%MTFREADR Read AdventaCT Multi-Trace Format (MTF) files.
% Generic reader for AdventaCT Multi-Trace Format (MTF) files. Input is an
% optional filename (filename) If omitted, user is prompted to locate file.
% An optional input (combine) is a string instructing how to combine
% multiple traces found in the mtf file:
%   'none'     : returns a cell array containing datasets formed from each
%                of the separate traces located in the MTF file. 
%   'truncate' : {default} truncates all traces to the shortest trace's
%                length. 
%   'pad'      : pads all traces with NaN's to the longest trace's length.
%   'stretch'  : uses linear interpolation to stretch all traces to the
%                longest trace's length.
% The output (data) is either a DSO (3-way DSO if multiple traces were
% found) or a cell array containing all the trace DSOs. Note that if a
% given trace does not have a sufficient number of columns in all rows,
% column contents may be scrambed from the dropped point down. In this
% situation, a warning will be given. Output (lotinfo) holds lot
% information. 
%
%I/O: data = mtfreadr(filename,combine);
%I/O: [data,lotinfo] = mtfreadr(filename,combine) 
%
%See also: AREADR, SPCREADR, TEXTREADR, XCLGETDATA, XCLPUTDATA

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin == 0 | isempty(filename)
  [file,pathname] = evriuigetfile({'*.mtf','Adventa Multi-Trace Files (*.mtf)';'*.*','All Files (*.*)'});
  if file == 0
    data = [];
    lotinfo = [];
    return
  end
  filename = [pathname,file];
else
  if ismember(filename,evriio([],'validtopics'));
    options = [];
    if nargout==0; clear data; evriio(mfilename,filename,options); else; data = evriio(mfilename,filename,options); end
    return; 
  end
end

if nargin<2;
  combine = 'truncate';
end

[fid,message] = fopen(filename,'r');
if fid<1;
  disp(message)
  error('Unable to open specified MTF file');
end

%first two lines are keys and values for lot information
lotinfo = textscan(fgetl(fid),'%s','delimiter',',');
lotinfo = lotinfo{1};
temp = textscan(fgetl(fid),repmat('%s ',1,length(lotinfo)),'delimiter',',');
temp = cat(1,temp{:});
if length(temp)<size(lotinfo,1);
  temp(end+1:size(lotinfo,1)) = {''};
end
lotinfo(:,2) = temp;

%convert to strings
lotinfo = lotinfo';
lotinfo = sprintf('%s = %s\n',lotinfo{:});

%get variable labels (i.e. id)
varlabels = textscan(fgetl(fid),'%s','delimiter',',');
varlabels = varlabels{1};
nvars = length(varlabels);

%identify if any of the variables is "time"
istime = ismember(lower(varlabels),'time');

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
%read all the traces
trace = 0;
traceinfo = cell(0);
data = cell(0);
while ~feof(fid);
  trace = trace+1;
  
  keys = textscan(fgetl(fid),'%s','delimiter',',');
  keys = keys{1};
  temp = textscan(fgetl(fid),repmat('%s ',1,length(keys)),'delimiter',',');
  temp = cat(1,temp{:});
  temp(end+1:size(keys,1)) = {''};
  keys(:,2) = temp;
  keys      = keys';
  traceinfo{trace} = sprintf('%s = %s\n',keys{:});

  fgetl(fid);  %drop ----- line
  
  %   data(trace,1) = textscan(fid,'%n','delimiter',',');
  temp = textscan(fid,repmat('%n ',1,nvars),'delimiter',',');
  for j=1:nvars;
    sz(j) = size(temp{j},1);
  end
  if ~all(sz==sz(1));
    warning('EVRI:MtfreadrNonSquare',['Truncating trace ' num2str(trace) ' to make it square. One or more rows do not contain sufficient variables.'])
    sz = min(sz);
    for j=1:nvars;
      temp{j} = temp{j}(1:sz);
    end
  end
  data{trace,1} = cat(2,temp{:});
  
  fgetl(fid);  %drop ----- line
end

fclose(fid);

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
%rearrange data into arrays and put into dataset objects
for trace = 1:length(data);
  temp = data{trace};

  if size(temp,2)==1;
    %if we have a vector, try to matricize it based on nvars
    %(This is actually old code that should never be run because we're now
    %always reading matrices, but instead of removing it, we leave it here
    %in case we need it later)
    nvals = length(temp);
    if mod(nvals,nvars)>0
      warning('EVRI:MtfreadrNonSquare',['Truncating trace ' num2str(trace) ' to make it square. One or more rows do not contain sufficient variables.'])
      temp = temp(1:end-mod(nvals,nvars));
      nvals = length(temp);
    end

    %reshape into array
    temp = reshape(temp,nvars,nvals./nvars)';
  end
  
  if any(istime);
    %convert any "time" columns to Matlab-based time-stamp
    temp(:,istime) = temp(:,istime)/60/60/24+datenum('1/1/1970');
  end

  %convert to dataset and add labels
  temp = dataset(temp);
  temp.name = sprintf('%s : Trace %i',filename,trace);
  temp.author = [mfilename];
  temp.label{2} = varlabels;

  %copy traceinfo into description
  temp.description = [lotinfo,traceinfo{trace}];
  
  %put back into data array
  data{trace} = temp;

end

%do we need to try to combine these into a single 3-way array?
if strcmp(combine,'none')
  for j=1:length(data);
    data{j} = addsourceinfo(data{j},filename);
  end
else
  
  sz = [];
  for trace=1:length(data);
    sz(trace) = size(data{trace},1);
  end
  
  switch combine
    case 'truncate'
      mlen = min(sz);
      for trace = 1:length(data);
        data{trace} = data{trace}(1:mlen,:);
      end
      data = cat(3,data{:});
    case 'pad'
      error('PAD method not currently implemented');
    case 'stretch'
      mlen = max(sz);
      for trace = 1:length(data);
        if sz(trace)~=mlen;
          temp = interp1(1:sz(trace),data{trace}.data,1:mlen,'linear');
          temp = dataset(temp);
          data{trace} = copydsfields(data{trace},temp,2);
        end
      end
      data = cat(3,data{:});
    case 'alignmat'
      error('ALIGNMAT method not currently implemented');
        
  end      

  data = addsourceinfo(data,filename);

end
