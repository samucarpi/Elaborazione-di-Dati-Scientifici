function [mcx,mx,msg] = mncn(x,options)
%MNCN Centers a matrix to mean zero.
%  Mean centers matrix (x), returning a matrix with mean zero 
%  columns (mcx) and a vector of means (mx) used in the centering. 
%  Output (msg) returns any warning messages.
%  Optional structure input (options) can contain any of the fields:
%
%    display   [ {'off'} | 'on']   Governs screen display.
%    matrix_threshold {0.15}  Error threshold based on fraction of 
%                              missing data in whole matrix
%    column_threshold {0.25}  Error threshold based on fraction of 
%                              missing data in single column
%
%I/O: [mcx,mx,msg] = mncn(x,options);
%
%See also: AUTO, CLASSCENTER, GSCALE, GSCALER, MEDCN, NORMALIZ, NPREPROCESS, POLYTRANSFORM, REGCON, RESCALE, SCALE

% Copyright © Eigenvector Research, Inc. 1991
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified 11/93
%Checked on MATLAB 5 by BMW  1/4/97
%Added support for non-doubles (do by rows) by JMS 6/21/2001
%JMS 6/6/02 -Incorporated missing data support
%  -standard IO mods
%JMS 2/7/03 -Do missing data calculation on ONLY those columns that need it
%JMS 5/10/04 -fixed one-row bug

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];

  options.display = 'off';
  options.matrix_threshold = .15;    %Thresholds for "too much missing data"
  options.column_threshold = .25;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; mcx = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin < 2 | isempty(options);
  options = mncn('options');
else
  options = reconopts(options,'mncn');
end

msg     = '';

pctmd = mdcheck(x);
if pctmd > options.matrix_threshold;
  error(['Too much missing data to analyze'])
end
if pctmd > 0
  msg = strvcat(msg,'Missing data found. Using missing data logic.');
  if strcmp(options.display,'on')
    disp(msg(end,:));
  end
end


%check for DataSet object
originaldso = [];
if isdataset(x)
  originaldso = x;
  incl = x.include;
  %extract data from x for initial calculation.
  x = originaldso.data(incl{:});
else
  incl = {1:size(x,1) 1:size(x,2)};
end

[m,n] = size(x);
if isa(x,'double')
  
  mx    = mean(x,1);
  rvect = ones(m,1);
  mcx    = (x-rvect*mx);
  
  if pctmd > 0;
    %redo columns with missing data
    [junk,mxmdmap] = mdcheck(mx);
    for loop = find(mxmdmap);
      onecolumn    = x(:,loop);
      [pctmd_c,mapmd_c] = mdcheck(onecolumn);
      if pctmd_c == 0; mapmd_c = zeros(m,1); end;
      if pctmd_c > options.column_threshold;
        
        error(['Too much missing data in column ' num2str(incl{2}(loop)) ' to analyze'])
      end
      mx(1,loop)    = mean(onecolumn(~mapmd_c));
      mcx(:,loop)   = onecolumn-mx(1,loop);
    end    
  end
else  %other than double convert one column at a time

  mcx = feval(class(x),zeros(m,n));
  for loop = 1:n;
    onecolumn    = double(x(:,loop));
    [pctmd_c,mapmd_c] = mdcheck(onecolumn);
    if pctmd_c == 0; mapmd_c = zeros(m,1); end;
    if pctmd_c > options.column_threshold;
      error(['Too much missing data in column ' num2str(incl{2}(loop)) ' to analyze'])
    end
    mx(1,loop)   = mean(onecolumn(~mapmd_c));
    mcx(:,loop)   = feval(class(x),(onecolumn-mx(1,loop)));
  end    
  
end


if isdataset(originaldso);
  %if we started with a DSO, re-insert back into DSO
  if anyexcluded(originaldso)
    originaldso.data(:) = nan;  %block out all data
    originaldso.data(incl{:}) = mcx;  %insert scaled data (included columns only)
  else
    originaldso.data = mcx;
  end
  mcx = originaldso;
end


% %NOTE: calling auto with an offset of "inf" disables scaling, thus doing JUST a mean-centering
% % this way, we can use the same routine for both mncn and auto.
% 
% options.offset  = inf;        %turn off scaling
% [mcx,mx,sd,msg] = auto(x,options);  %use auto for call
% 
