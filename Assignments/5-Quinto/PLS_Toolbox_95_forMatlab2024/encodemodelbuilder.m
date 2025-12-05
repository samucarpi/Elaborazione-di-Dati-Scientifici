function varargout = encodemodelbuilder(model,filename)
%ENCODEMODELBUILDER Create MATLAB m-code which will regenerate a given model.
% Given the input of a standard model structure, this function creates a
% file which can be used to regenerate a model with the exact options and
% conditions used to create the model.
%
% The resulting function can be used to document how a model was built, or
% can be used to build new models from new or otherwise modified data. The
% function is written to take only the inputs required for data blocks for
% the modeling method (e.g. PCA requires 1, PLS requires 2). For example,
% if the output file is called "mymodel" and was a PLS model, a new model
% could be built using: 
%    model = mymodel(x,y)
%
% Remember that the performance of two models built using the same
% preprocessing and meta-parameter choices but different input data will
% give different results. Such model building "formulas" should be used
% with care. Validation of all models is highly recommended.
%
% INPUTS:
%      model = A standard PLS_Toolbox model structure.
% OPTIONAL INPUTS:
%   filename = An optional filename to which the build code should be
%               written. If omitted, the user will be prompted for a
%               filename and folder.
%
% I/O: encodemodelbuilder(model,filename)

%Copyright Eigenvector Research 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS

if nargin==0; model = 'io'; end
if ischar(model)
  options = [];
  if nargout==0; evriio(mfilename,model,options); else; varargout{1} = evriio(mfilename,model,options); end
  return;
end

%check model input
if ~ismodel(model) | ~isempty(findstr(lower(model.modeltype),'_pred'))
  error('Input must be a valid standard model structure');
end

%make sure we can convert this model type
modeltype = lower(model.modeltype);
if ismember(modeltype,{'purity'})
  error('A model builder function cannot be created for this model type.')
end

%no filename given? ask user for one
if nargin<2 
  if nargout==0
    [filename,pth] = uiputfile({'*.m' 'MATLAB m-file'},'Write build script as...');
    if isnumeric(filename)
      return
    end
    filename = fullfile(pth,filename);
  else
    filename = '';
  end
end

%generate valid filename and function information
[pth,fn,ext] = fileparts(filename);
fn(fn==' ') = '_';
filename = fullfile(pth,[fn,ext]);

%prepare options
options = model.detail.options;
if isfield(options,'preprocessing');
  pp = options.preprocessing;
else
  pp = {};
end

%remove some fields from options
toremove = {'preprocessing' 'definitions' 'rawmodel' 'functionname' 'name'};
for f = toremove;
  if isfield(options,f{:})
    options = rmfield(options,f{:});
  end
end


%-------------------------------------------------
%generate I/O information
nblocks = length(model.datasource);
switch nblocks
  case 1
    inputs = 'x';
  case 2
    inputs = 'x,y';
  otherwise
    error('Unable to generate function for this model type (unrecognized number of blocks)')
end

%check if this was a PLSDA model built using classes and possibly with groups
plsda_class2logical = false;
if strcmp(modeltype,'plsda') & strcmp(model.detail.data{2}.author,'class2logical') & isfield(model.detail.data{2}.userdata,'groups')
  plsda_class2logical = true;
end

%-------------------------------------------------
%build header and help
[vers,prod] = evrirelease;
modldesc = modlrder(model);
s = {
  sprintf('function model = %s(%s)',fn,inputs)
  sprintf('%%%s Automatically build model using previously-specified conditions.',upper(fn))  
  sprintf('%% This function generates a model based on the conditions used to create a')
  sprintf('%% previous model developed to these specifications:')
  [sprintf('%%   %s\n',modldesc{1:end-1}) '%']
  sprintf('%% Remember: different data will give different performance (e.g. RMSEC/CV)')
  sprintf('%% even when using the same model building conditions.')
  sprintf('%%');
  sprintf('%% INPUTS:')
  sprintf('%%     x  = X-block (predictor block) class "double" or "dataset"')
  };
if nblocks>1;
  s = [s
    {
    sprintf('%%     y  = Y-block (predicted block) class "double" or "dataset"')
    }];
end
s = [s
  {
  sprintf('%% OUTPUT:')
  sprintf('%%    model = A standard model structure for use in PLS_Toolbox or Solo')
  sprintf('%% ')
  sprintf('%% This function was automatically generated using %s %s',prod,vers)
  sprintf('%% ')
  sprintf('%%I/O: model = %s(%s)',fn,inputs)
  sprintf(' ')
  }];

%---------------------------------------
%determine meta-parameters needed

addinputs = {'getoptions'};

%number of components?
ncomp = [];
switch modeltype
  case 'lwr'
    ncomp = model.detail.lvs;
    npts = model.detail.npts;
  case 'knn'
    ncomp = model.k;
  otherwise
    %something else - try standard teset for loads field
    if isfield(model,'loads');
      if iscell(model.loads) & ~isempty(model.loads)
        temp = size(model.loads{1});
        ncomp = temp(end);  %generic way to get # of components
      end
    end
end
if strcmp(modeltype, 'lwr') & ~isempty(npts)
  addinputs = [num2str(npts) addinputs];
end
if ~isempty(ncomp)
  addinputs = [num2str(ncomp) addinputs];
end

if plsda_class2logical
  %if a PLSDA model built using classes
  %  x classes, []
  %  x classes, {...}
  s = [s
    {
    sprintf('if nargin<2')
    sprintf('  y = %s;',encode(model.detail.data{2}.userdata.groups,''))
    sprintf('end');
    }];
end    

%generate model-building code
s = [s
  {
  [sprintf('model = %s(%s',modeltype,inputs) sprintf(',%s',addinputs{:}) ');']
  sprintf(' ');
  }];

%---------------------------------------
%add options sub-function

s = [s
  {
  sprintf('%%---------------------------------------------------------------')
  sprintf('function options = getoptions')
  sprintf('%% creates options structure')
  sprintf(' ');
  encode(options,'options')
  sprintf('options.preprocessing = getpreprocessing;   %%call sub-function to get preprocessing')
  sprintf(' ');
  }];

%---------------------------------------
%add preprocessing sub-function

s = [s
  {
  sprintf(' ');
  sprintf('%%---------------------------------------------------------------')
  sprintf('function pp = getpreprocessing')
  sprintf('%% creates preprocessing structure')
  sprintf(' ');
  encode(pp);
  sprintf(' ');
  }];


%---------------------------------------

if ~isempty(filename)
  [fid,message] = fopen(filename,'w');
  if fid<1
    error(message)
  end
  fprintf(fid,'%s\n',s{:});
  fclose(fid);
  
  if nargin<2
    evrimsgbox(sprintf('Build function written to file "%s".',filename),'Build function written','help','modal');
  end
else
  varargout = {sprintf('%s\n',s{:})};
end
