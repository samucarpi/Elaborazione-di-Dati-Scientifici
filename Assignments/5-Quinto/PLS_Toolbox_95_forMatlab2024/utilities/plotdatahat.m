function [toplot,sel] = plotdatahat(model,data,default)
%PLOTDATAHAT Extract and display data estimates and residuals from a model.
% Given a standard model structure and the original calibration data,
% PLOTDATAHAT creates a DataSet object (DSO) containing various information
% from the model including, possibly, the original data, the fit of the
% model to the data, and residuals. Unless specified in the inputs, the
% user is prompted for which of the items to include in the output.
% 
%INPUTS:
%  model = standard model structure to use to calculate fit and residuals
%   data = original calibration data used to create model (if empty, model
%          will be interrogated for data in model.detail.data field)
%OPTIONAL INPUT:
%    default = boolean vector indicating which items should be checked in the
%              GUI by default. [data  datahat  residuals]
%  selection = (passed in place of default) Overrides the presentation of a
%              GUI to select item(s) to plot, this structure must contain
%              the fields: 
%                .data
%                .datahat
%                .residuals
%              with a boolean value indicating if each should be included
%              in the assembled DSO.
%OUTPUT:
%   toplot = DSO of all items to plot (concatenated in first mode). If no
%            outputs are requested, a plot of the DSO will be created.
%
%I/O: toplot = plotdatahat(model,data)            %user-selected to plot
%I/O: toplot = plotdatahat(model,data,default)    %user-selected w/default
%I/O: toplot = plotdatahat(model,data,selection)  %specified which to plot
%
%See also: ANALYSIS, DATAHAT, PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0;
  model = 'io';
end
if ischar(model)
  options = [];
  if nargout==0; evriio(mfilename,model,options); else; toplot = evriio(mfilename,model,options); end
  return
end

if nargin<3;
  default = [];
end
if nargin<2;
  data = [];
end
toplot = [];

if isempty(data) & isfieldcheck(model,'model.detail.data')
  data = model.detail.data{1};
end

%get user-selected items to show
if isempty(data)
  %no data? nothing but datahat is available
  sel = struct('data',0,'datahat',1,'residuals',0);
elseif ~isstruct(default) | (isfield(default,'defaults') & default.defaults)
  %user passed a vector of booleans... use those as default for GUI
  sel = displaydatagui(default);
else
  %input was structure? Assume it is a pre-selected structure of selections
  sel = reconopts(default,struct('data',0,'datahat',0,'residuals',0),0);
end
if isempty(sel); return; end
if ~any([sel.data sel.datahat sel.residuals]); return; end

if ~isempty(data)
  %grab data and calculate datahat and residuals
  [xhat,res] = datahat(model,data);

  data = data(:,model.detail.includ{2,1});  %apply model include field to data
  if ndims(data)>2
    %Apply include to ND data.
    incl = model.detail.includ;
    data = data(:,:,incl{3:end,1});
  end
  data.data = xhat+res;
  
else
  %calculate datahat ONLY
  xhat = datahat(model);
  sel.data = false;
  sel.residuals = false;
  data = dataset(xhat);
  data = copydsfields(model,data,1:ndims(data),1);
  res = [];
end
%   error('Data must be provided or present in the model details.')
% end

if strcmpi(model.modeltype,'parafac2')
  data = permute(data,[3 1 2]);
  xhat = permute(xhat,[3 1 2]);
  if ~isempty(res)
    res = permute(res,[3 1 2]);
  end
end

%create appropriate labels
lbls = data.label{1};  %get labels
if isempty(lbls)
  lbls = num2str([1:size(data,1)]');
  data.label{1} = lbls;
end

%build mass DSO
toplot = [];
names  = {};
cls    = [];
if sel.data
  toplot = data;
  names = {data.name};
  cls   = ones(1,size(toplot,1));
end
if sel.datahat
  xhat = copydsfields(data,dataset(xhat));
  if exist('inheritimage','file')
    xhat = inheritimage(xhat,model);
  end
  xhat.label{1} = [lbls repmat(' fit',size(xhat,1),1)];
  toplot = [toplot;xhat];
  cls    = [cls ones(1,size(xhat,1))*2];
  if isempty(names)
    names = {[data.name ' fit']};
  else
    names{end+1} = '+fit';
  end
end
if sel.residuals
  res  = copydsfields(data,dataset(res));
  if exist('inheritimage','file')
    res = inheritimage(res,model);
  end
  res.label{1} = [lbls repmat(' residuals',size(res,1),1)];
  toplot = [toplot;res];
  cls    = [cls ones(1,size(res,1))*3];
  if isempty(names)
    names = {[data.name ' residuals']};
  else
    names{end+1} = '+residuals';
  end
end
toplot.name = [names{:}];

if ~isempty(cls) & any(cls~=cls(1))
  %if there are classes (and DIFFERENT classes)
  clsset = 1;
  while clsset<=size(toplot.class,2) & ~isempty(toplot.class{1,clsset})
    clsset = clsset+1;
  end
  toplot.classlookup{1,clsset} = {1 'Data'; 2 'Fit'; 3 'Residuals'};
  toplot.class{1,clsset} = cls;
  toplot.classname{1,clsset} = 'DataHat Type';
end
  

%if no outputs were requested, do a plot
if nargout == 0;
  if ndims(data)==3;
    plottype = 'surface';
  else
    plottype = '';
  end
  addinfo = {'new'};
  plotgui(toplot,'rows',addinfo{:},'tag','datahatfig','noinclude',1,'plottype',plottype);
  clear toplot
end
