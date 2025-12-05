function [ out ] = cytospecreadr( files, options)
%CYTOSPECREADR is used to import cytospec formatted .cyt file and
%saves it as a DSO.
%
%  INPUT:
%   files = One of the following identifications of files to read:
%            a) a single string identifying the file to read
%                  ('example')
%            b) a single element cell array of a string of a file to read
%                  ({'example_a'})
%            c) an empty array indicating that the user should be prompted
%               to locate the file(s) to read
%                  ([])
%
%  OPTIONAL INPUT:
%     options = structure array with the following fields:
%     ***Empty for now***
%
% Output:
%    out = A DataSet imported from the CytoSpec (.cyt) file.
%
%I/O: out = cytospecreadr(files);
%I/O: out = cytospecreadr();
%
% Copyright © Eigenvector Research, Inc. 1998
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

out=[];

% Input check
if nargin==0 | isempty(files) % No input? prompt user for a file.
  [files,pathname] = evriuigetfile({'*.cyt','CytoSpec Files (*.cyt)'; ...
    '*.*','All Files (*.*)'},'multiselect','off'); % left off for now (may be enabled later?)
  if isnumeric(files) & (files == 0)
    return
  end
   % Format files to be a cell array with the path & filename 
  if iscell(files)
    for (j=1:length(files))
      files{j} = [pathname files{j}];
    end
  else
    files = {[pathname,files]};
  end
% If input is 'options' return options struct.
elseif ischar(files) & ismember(files,evriio([],'validtopics'))
  varargin{1} = files;
  options = [];
  if (nargout==0)
    clear out; evriio(mfilename,varargin{1},options);
  else
    out = evriio(mfilename,varargin{1},options);
  end
  return;
elseif ischar(files)
  files = {files};
end
if (nargin<2)
  options = cytospecreadr('options');
end
options = reconopts(options,'cytospecreadr');

% Import file as a cell array
for (i=1) %(i=1:nfiles)
  try
    xtemp = textreadr(files{i}); % use textreadr for now, may be optimized later.
    xtemp = xtemp.data;
  catch
    erdlgpls({'Error loading file: ' files{i},lasterr},'Import Error');
    return;
  end
  
  [directory, fn, fext] = fileparts(files{i});
  files{i} = [fn fext];
  
  % Set the appropriate mode to use.
  switch size(xtemp,2)
    case (1) % 1 col
      mode = 1;
    case (2) % 2 col
      mode = 2;
    case (4) % 4 col
      mode = 3;
    otherwise % matrix format
      mode = 4;
  end
  
  tempdata=[];
  axisscale=[];
  xco=[];
  yco=[];
  
  % Extract axisscale, dso, & other data.
  switch (mode)
    case (1) % 1 col spectrum, (no axisscale)
      tempdata = xtemp';
    case (2) % 2 col: axisscale, spectrum
      axisscale = xtemp(:,1);
      tempdata = xtemp(:,2)';
    case (3) % 4 col: x-co, y-co axisscale, spectrum
      xco = xtemp(:,1);
      yco = xtemp(:,2);
      axisscale = xtemp(:,3);
      tempdata = xtemp(:,4);
    case (4) % data matrix
      xco = xtemp([2:end],1);
      yco = xtemp([2:end],2);
      tempdata = xtemp([2:end],[3:end]);
      axisscale = xtemp(1,[3:end]);
    otherwise
      error('Unrecignized mode.');
  end
  
  if (isempty(xco) & isempty(yco))
    out = dataset(tempdata);
  else  
    if (intCheck(xco) & intCheck(yco) & posCheck(xco) & posCheck(yco))
      % xco & yco can be treated as indexes.
      out = createDsoWithCoord(xco,yco,tempdata);
    else % they're an axisscale, which complicates things...
      error('x y coordinates must be indexes (positive, non-zero integers');
    end    
  end
  
  % Add metadata
  if ~(isempty(axisscale))
    switch (mode)
      case (2)
        out.axisscale{2} = axisscale;
      case 3
        % sort out axisscale & adjust the order if nessisary.
        tempaxis = unique(axisscale);
        if (tempaxis(1) ~= axisscale(1))
          tempaxis = sort(tempaxis,'descend');
        end
        axisscale = tempaxis;
        out.axisscale{2} = axisscale;
      case 4
        out.axisscale{3} = axisscale;
      otherwise
    end
  end
end
end

function tf = intCheck(ar)
temp = floor(ar);
tf = true;
for i=1:size(ar,1)
    if (temp(i) ~= ar(i))
        tf = false;
        break;
    end
end
end

function tf = posCheck(ar)
tf = true;
for i=1:size(ar,1)
    if (ar(i) <= 0)
        tf = false;
        break;
    end
end
end

function dsoOut = createDsoWithCoord(xco, yco, data)
temp = zeros(max(xco),max(yco),size(data,2));
for i=1:length(xco)
  temp(xco(i),yco(i),:) = data(i,:);
end
dsoOut = dataset(temp);
end
