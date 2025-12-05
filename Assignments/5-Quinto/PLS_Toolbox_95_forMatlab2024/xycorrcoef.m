function out = xycorrcoef(xblock, yblock)
%XYCORRCOEF Correlation coefficients between variables in X-block and variables in Y-block.
% XYCORRCOEF produces a DataSet Object of correlation coefficients between
% the variables in X-block and the variables in Y-block.
%
% The inputs are the x-block data and y-block data of class "double" or
% "dataset".
%
% For inputs of class "dataset", any excluded columns will still be used in
% the calculation but will be excluded in out. If the inputs are type
% "double" and the number of rows in X-block and Y-block do not match an 
% error will be triggered. Any rows with NaN's will be removed.
%
% The output is a DataSet Object. If no output is requested then only a
% PlotGUI figure of the correlation coefficients will appear.
%
%I/O: xycorrcoef(xblock, yblock) %produces a plot of correlation coefficients
%I/O: out = xycorrcoef(xblock, yblock); %produces a plot and returns a DataSet Object of correlation coefficients
%I/O: xycorrcoef demo
%
%See also: CORRMAP, AUTOCOR, CLUSTER, CROSSCOR, GCLUSTER, PCA, PCOLORMAP

%Copyright © Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin == 0; xblock = 'io'; end
varargin{1} = xblock;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1}, options); else; out = evriio(mfilename,varargin{1}, options); end
  return;
end

if nargin ~=2
  evrierrordlg('There must be 2 inputs to xycorrcoef');
  if nargout == 1
  out = [];
  end
  return
end

if isa(xblock,'double')
  xblock = dataset(xblock);
elseif ~isa(xblock,'dataset')
  evrierrordlg(['Input X must be class ''double'' or ''dataset''.'])
  if nargout == 1
  out = [];
  end
  return
end

if ndims(xblock.data)>2
  evrierrordlg(['Input X must contain a 2-way array. Input has ',...
    int2str(ndims(xblock.data)),' modes.'])
  if nargout == 1
  out = [];
  end
  return
end

if isa(yblock,'double')
  yblock = dataset(yblock);
elseif ~isa(yblock,'dataset')
  evrierrordlg(['Input Y must be class ''double'' or ''dataset''.'])
  if nargout == 1
  out = [];
  end
  return
end

if ndims(yblock.data)>2
  evrierrordlg(['Input Y must contain a 2-way array. Input has ',...
    int2str(ndims(yblock.data)),' modes.'])
  if nargout == 1
  out = [];
  end
  return
end
if size(xblock.data,1)~=size(yblock.data,1)
  evrierrordlg('Number of samples in X and Y must be equal.')
  if nargout == 1
  out = [];
  end
  return
end

inds = intersect(xblock.includ{1},yblock.includ{1});
if (length(inds)~=length(xblock.includ{1,1}) | ...
    length(inds)~=length(yblock.includ{1,1}))
  evriwarndlg('Number of samples included in X and Y are not equal. Using intersection of included samples.');
  xblock.includ{1,1} = inds;
  yblock.includ{1,1} = inds;
end

numXvars = size(xblock,2);
xdata    = xblock.data(inds,:);
numYvars = size(yblock,2);
ydata    = yblock.data(inds,:);

try
  augData = [xdata ydata];
catch
  evrierrordlg('Incompatible data');
  if nargout == 1
  out = [];
  end
  return
end

allNanVars = sum(isnan(augData), 1)==size(augData,1);
mynan = any(isnan(augData(:, ~allNanVars)'));
% mynan = any(isnan(augData'));
if any(mynan)
  augData = augData(~mynan,:);
end

allCorrCoefs  = corrcoef(augData);
relCorrCoefs  = allCorrCoefs(numXvars+1:numXvars+numYvars, 1:numXvars).^2;
out_temp           = dataset(relCorrCoefs);
out_temp           = copydsfields(xblock, out_temp, 2);
out_temp           = copydsfields(yblock, out_temp, {2 1});
if isempty(out_temp.label{1,1})
  out_temp.label{1,1} = arrayfun(@(x)sprintf('Y variable %d',x), 1:size(out_temp,1),...
    'uni', false);
end
%plot correlation coefficients
plotgui('new','name','Correlation Coefficients',out_temp,'PlotBy', 'rows'); 

if nargout == 1 % return DataSet Object if there is an output argument
  out = out_temp;
end



