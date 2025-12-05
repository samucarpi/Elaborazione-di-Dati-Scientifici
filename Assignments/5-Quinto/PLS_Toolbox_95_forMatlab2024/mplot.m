function [rows,cols] = mplot(varargin)
%MPLOT Automatic creation of subplots and plotting.
% Inputs can be one of four forms:
%  (1) the number of subplots requested (n), 
%  (2) the number of rows and columns for the subplot array ([rows cols])
%  (3) or data to plot (y) with or without reference data for the x-axis
%      (x). Each column of (y) is plotted in a single subplot on the figure.
%
% Optional input options can contain any of the fields:
%      center : [ {'no'} | 'yes' ] governs centering of "left-over" plots at
%                bottom of figure
%    axismode : [ {''} | 'tight' ] governs axis settings
%       plots : [ 'none' | {'final'} ] governs creation of axes. If set to
%                 'none', no axes are created and mplot only returns the
%                 rows and columns which would be used if axes were
%                 created.
%
% Outputs are the number of rows (rows) and columns (cols) used for the
% subplots.
%
%I/O: [rows,cols] = mplot(n,options)
%I/O: [rows,cols] = mplot([rows cols],options)
%I/O: [rows,cols] = mplot(rows,cols,options)
%I/O: [rows,cols] = mplot(y,options)
%I/O: [rows,cols] = mplot(x,y,options)
%
%See also: PLOTGUI, SUBPLOT

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 2/03
%jms 7/03 added help

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name     = 'options';
  options.center   = 'no';
  options.plots    = 'final';
  options.axismode = '';    %'','tight'
  if nargout==0; evriio(mfilename,varargin{1},options); else; rows = evriio(mfilename,varargin{1},options); end
  return; 
end

options  = [];
xaxis    = [];
y        = [];
number   = [];

switch nargin
  case 1
    % (y)
    % (number)
    % ([rows,cols])
    if all(size(varargin{1})==[1 2])
      % ([height width]
      number = inf;
      rows = varargin{1}(1);
      cols = varargin{1}(2);
    elseif prod(size(varargin{1}))>1;
      % (y)
      y = varargin{1};
    else
      % (number)
      number = varargin{1};
    end        
  case 2
    % (n,options)
    % ([rows,cols],options)
    % (y,options)
    % (x,y)
    if isstruct(varargin{2})
      if all(size(varargin{1})==[1 2])
        % ([height width]
        number = inf;
        rows = varargin{1}(1);
        cols = varargin{1}(2);
      elseif prod(size(varargin{1}))>1;
        y      = varargin{1};
      else
        number = varargin{1};
      end
      options  = varargin{2};
    else
      % (x,y)
      % (rows,cols)
      if all(size(varargin{1})==1) && all(size(varargin{2})==1)
      % (rows,cols)
        number = inf;
        rows = varargin{1};
        cols = varargin{2};
      else
      % (x,y)
        xaxis = varargin{1};
        y     = varargin{2};
      end
    end
  case 3
    %(x,y,options)
    %(rows,cols,options)
    if all(size(varargin{1})==1) && all(size(varargin{2})==1)
      % (rows,cols,options)
      number = inf;
      rows = varargin{1};
      cols = varargin{2};
    else
      % (x,y)
      xaxis = varargin{1};
      y     = varargin{2};
    end
    options  = varargin{3};
end
options = reconopts(options,'mplot');

if sum(size(xaxis)>1)>1;
  error('input X must be a vector')
end

if isempty(number);
  if isempty(xaxis);
    mydim = length(size(y));
    number = size(y,mydim);
  else
    mydim  = max(find(size(y)~=length(xaxis)));
    number = size(y,mydim);
  end
end

if ~isinf(number)
  
  if ~isempty(y);
    ndims = length(size(y));
    ind = cell(1,ndims);
    [ind{:}] = deal(':');
  end
  
  if number>49;
    error('Too many plots');
  end
  
  rows=fix(number./round(sqrt(number))+.9);
  cols=round(sqrt(number));
  
%   if number==3; rows=3; cols=1; end; %with this one exception
  
else
  number = rows*cols;
end

if strcmp(options.plots,'final')
  clf;%Clear all axes off figure because some can remain. For example, going from 5 to 4 seems to leave an axes (3) on the figure. 
  for j=1:number;
    if j>(rows-1)*cols & strcmp(lower(options.center),'yes');
      offset = (rows*cols-number)/2;
    else
      offset = 0;
    end
    
    try
      %Wrap in try/catch because warning and errors (missing handel) were
      %being generated due to latency (on Mac). Also disabled warning in
      %evriwarningswitch.m
      subplot(rows,cols,j+offset);
    end
    
    if ~isempty(y);
      ind{mydim} = j;
      if ~isempty(xaxis);
        plot(xaxis,y(ind{:}));
      else
        plot(y(ind{:}));
      end
    end
    if ~isempty(options.axismode);
      axis(options.axismode);
    end
  end
end

if nargout==0
  clear rows cols
end
