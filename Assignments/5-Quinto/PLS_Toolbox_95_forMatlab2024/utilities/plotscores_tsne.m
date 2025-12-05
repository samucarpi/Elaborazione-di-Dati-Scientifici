function a = plotscores_tsne(modl,test,options)
%PLOTSCORES_ANN Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms


a = makescores(modl,options);


%get rid of all-NAN columns
%allnan = all(isnan(a.data),1);
%if any(allnan)
%  a = a(:,~allnan);
%end


%---------------------------------------------------------------------
function a = makescores(modl,options)

if ischar(modl);
  options = [];
  %options.sammon       = 0;
  %options.addcalfields    = '';
  %options.autoclass    = false;
  if nargout==0; clear a; evriio(mfilename,modl,options); else;  a = evriio(mfilename,modl,options); end
  return; 
end
if nargin<2; options = []; end
%options = reconopts(options,mfilename,0);



a = [];
lbl = {};

a = modl.detail.tsne.embeddings;
%a = [a data];
%lbl = [lbl labels];

%{
if options.sammon>0
    if modl.ncomp>1
      options.sammon = min(modl.ncomp-1,options.sammon);
      sm = sammon(modl.scores,modl.scores(:,1:options.sammon));
      options.sammon = size(sm,2);      
      a = [a sm];
    else
      options.sammon = 0;
    end
end
%}

%create dataset
a          = dataset(a);
a          = copydsfields(modl,a,1);
a.name     = modl.datasource{1}.name;
if isfield(modl.detail,'originalinclude') & ~isempty(modl.detail.originalinclude) & ~isempty(modl.detail.originalinclude{1})
    a.include{1} = modl.detail.originalinclude{1};
end

eb               = size(modl.detail.tsne.embeddings,2);
  
  alabel = {};
for ii=1:eb
  alabel{ii}   = sprintf('Embeddings for Component %i',ii);
end
a.label{2,1}   = char(alabel);
a.title{1}   = 'TSNE Embeddings Plot';
