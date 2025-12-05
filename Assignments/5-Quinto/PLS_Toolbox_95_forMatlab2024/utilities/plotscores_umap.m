function a = plotscores_umap(modl,test,options)
%PLOTSCORES_UMAP Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms

if isempty(test) %| options.sct==1
  a = makescores(modl);
else
  if options.sct
    a = makescores(modl,test,options); 
    %b = makescores(modl,test,options);
    %cls = [zeros(1,size(a,1)) ones(1,size(b,1))];
    %a              = [a;b]; clear b
    %search for empty cell to store cal/test classes
    j = 1;
    while j<=size(a.class,2);
      if isempty(a.class{1,j});
        break;
      end
      j = j+1;
    end
    %a.class{1,j} = cls;  %store classes there
    %a.classlookup{1,j} = {0 'Calibration';1 'Test'};
    %a.classname{1,j} = 'Cal/Test Samples';

  else
    a = makescores(test,options);
  end
end

%get rid of all-NAN columns
allnan = all(isnan(a.data),1);
if any(allnan)
  a = a(:,~allnan);
end


%a = makescores(modl,test,options);


%get rid of all-NAN columns
%allnan = all(isnan(a.data),1);
%if any(allnan)
%  a = a(:,~allnan);
%end


%---------------------------------------------------------------------
function a = makescores(modl,test,options)


%ny         = size(modl.data.data,2); %number of y variables

if ischar(modl);
  options = [];
  %options.sammon       = 0;
  %options.addcalfields    = '';
  %options.autoclass    = false;
  if nargout==0; clear a; evriio(mfilename,modl,options); else;  a = evriio(mfilename,modl,options); end
  return; 
end
if nargin<3; test = []; end
%options = reconopts(options,mfilename,0);



a = [];
lbl = {};

a = modl.detail.umap.embeddings;


%create dataset
a          = dataset(a);
a          = copydsfields(modl,a,1,1);
a.name     = modl.datasource{1}.name;
if isfield(modl.detail,'originalinclude') & ~isempty(modl.detail.originalinclude) & ~isempty(modl.detail.originalinclude{1})
    a.include{1} = modl.detail.originalinclude{1};
end

eb               = size(modl.detail.umap.embeddings,2);
  
  alabel = {};
for ii=1:eb
  alabel{ii}   = sprintf('Embeddings for Component %i',ii);
end
a.label{2,1}   = char(alabel);
a.title{1}   = 'UMAP Embeddings Plot';

% built a, condition on test
%if nargin==1 test = []; end

if ~isempty(test) %X-block must be present
  
  b      = [];
  blabel = {};
  %{
  ytest = [];

  if length(test.detail.data)>1 & ~isempty(test.detail.data);
      ytest = test.detail.data.data(:,test.detail.includ{2,1});
  elseif options.sct
      ytest = ones(test.datasource{1}.size(1), ny)*nan; % ANN only support one y var
  else
      ytest = [];  %no cal data and no y-block use empty (to skip loop below)
  end
  
  for ii=1:eb
      b = [b, ytest(:,ii)];
      blabel{ii}   = sprintf('Embeddings for Component %i',ii);
  end
%}
  
  
  if ~isempty(test.detail.umap.embeddings)
      for ii=1:eb
          b = [b, test.detail.umap.embeddings(:,ii)];
          blabel{ii}   = sprintf('Embeddings for Component %i',ii);
      end
  end
  %{
  if ~nores
      if length(test.detail.res)>1 & ~isempty(test.detail.res{2});
          yres = test.detail.res{2};
      elseif options.sct
          yres = test.pred{2}*nan;
      else
          yres = [];  %no cal, no val y-block, skip resids by using empty
      end
      if ~isempty(yres)
          for ii=1:ny
              b = [b, yres(:,ii)];
              blabel{end+1} = ['Y Residual ' labelsuffix{ii}];
          end
      end
  end
  
  
  if ~nocvpred & options.sct
    b = [b, zeros(size(b,1),1)*nan];
  end
  
  if ~nocvpredres & options.sct
    b = [b, zeros(size(b,1),1)*nan];
  end
  %}
  %create DSO
  b = dataset(b);
  b = copydsfields(test,b,1,1);
  b.name   = test.datasource{1}.name;
  if options.sct
      if isempty(a.name)&isempty(b.name)
          a.title{1}   = 'Embeddings Plot of Cal & Test';
      elseif isempty(a.name)&~isempty(b.name)
          a.title{1}   = ['Embeddings Plot of Cal &',b.name];
      elseif ~isempty(a.name)&isempty(b.name)
          a.title{1}   = ['Embeddings Plot of ',a.name,' & Test'];
      else
          a.title{1}   = ['Embeddings Plot of ',a.name,' & ',b.name];
      end
  else
      if isempty(b.name)
          b.title{1}   = 'Embeddings Plot of Test';
      else
          b.title{1}   = ['Embeddings Plot of ',b.name];
      end
      %add add column labels
      b.label{2,1} = blabel;
  end
  
  if isempty(a)
    %no cal data? just use test
    a = b;
  else
    %combine cal and test
    cls = [zeros(1,size(a,1)) ones(1,size(b,1))];
    a = [a;b];
    
    %search for empty cell to store cal/test classes
    j = 1;
    while j<=size(a.class,2);
      if isempty(a.class{1,j});
        break;
      end
      j = j+1;
    end
    a.class{1,j} = cls;  %store classes there
    a.classlookup{1,j} = {0 'Calibration';1 'Test'};
    a.classname{1,j} = 'Cal/Test Samples';
  end
  
end






