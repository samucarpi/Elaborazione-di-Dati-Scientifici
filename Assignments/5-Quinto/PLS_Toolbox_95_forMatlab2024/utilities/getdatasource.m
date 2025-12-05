function varargout = getdatasource(varargin)
%GETDATASOURCE Extract summary dataset info.
% Inputs are datasets (any number of datasets may be input). If last input
% is a string and keyword = 'string' or 'cell' then output is transformed
% into different data type.
%
% Outputs are structures with summary information for each of
% the supplied datasets.
%
%I/O: [out1, out2,...] = getdatasource(dataset1, dataset2,...)
%
%See also: DATASET/DATASET, MODELSTRUCT

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
%nbg 8/19/02 added size field (this is the orignal size of varargin.data)

%TODO: Might be able to use the string output from this function in
%analysis and other places where data source info it displayed. 

if nargin > 0 & ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics'))
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

outputtype  = 'struct';
if nargin>=1 & ischar(varargin{end}) & ismember(varargin{end},{'string','cell'})
  %Passed switch for output type.
  outputtype  = varargin{end};
  varargin = varargin(1:end-1);
end

datasource = struct('name','','type','','author','','date',[],'moddate',[],'size',[],'include_size',[],'description','','uniqueid','','source','');

outstr = [];

if isempty(varargin)
  varargout = {datasource};
else
  for k=1:length(varargin)
    varargout{k} = datasource;
    if isa(varargin{k},'dataset')

      %look for source info
      source = '';
      hist = varargin{k}.history;
      [rs,re] = regexp(hist,'Import From:');
      isfrom = find(~cellfun('isempty',re));
      if ~isempty(isfrom)
        isfrom = isfrom(1);
        source = hist{isfrom}(rs{isfrom}:end);
      end
      
      varargout{k}.name    = varargin{k}.name;
      varargout{k}.type    = varargin{k}.type;
      varargout{k}.author  = varargin{k}.author;
      varargout{k}.date    = varargin{k}.date;
      varargout{k}.moddate = varargin{k}.moddate;
      varargout{k}.size    = size(varargin{k}.data);
      varargout{k}.include_size = cellfun('size',varargin{k}.include,2);
      varargout{k}.description  = varargin{k}.description;
      varargout{k}.uniqueid     = varargin{k}.uniqueid;
      varargout{k}.source = source;
      if strcmp(lower(varargin{k}.type), 'image')
        varargout{k}.imagesize    = varargin{k}.imagesize;
        varargout{k}.imagemode    = varargin{k}.imagemode;
      end
    else
      sz = size(varargin{k});
      varargout{k}.size         = sz;
      varargout{k}.include_size = sz;
    end
  end
end

%TODO: Can put all string and cell data in single output if needed but that
%is not done currently, varargout is parsed per input (number inputs equals
%the number of outputs). 

if ~strcmpi(outputtype,'struct')
  for i = 1:length(varargout)
    outstr = struct2str(varargout(i));
    if strcmpi(outputtype,'string')
      varargout{i} = cell2str(outstr,' : ');
    else
      varargout{i} = outstr;
    end
  end
end

function outstr = struct2str(instruct)
%Convert struct to char array. This can handle a multi element struct but
%it's not used right now.

outstr = [];
for j = 1:length(instruct)
  mystruct = instruct{j};
  fnames   = fieldnames(mystruct);
  for i = 1:length(fnames)
    myval = mystruct.(fnames{i});
    if ismember(fnames{i},{'date' 'moddate'})
      myval = datestr(myval);
    elseif isnumeric(myval)
      myval = sprintf('%ix',myval);
      myval = [myval(1:end-1)];
    elseif ismember(fnames{i},{'description'})
      myval = sprintf('%ix',size(myval));
      myval = [myval(1:end-1) ' char'];
    end
    outstr{end+1,1} = fnames{i};
    outstr{end,2} = myval;
  end
  outstr{end+1,1} = '----------';
  outstr{end,2}   = '----------';
end
outstr = outstr(1:end-1,:);
