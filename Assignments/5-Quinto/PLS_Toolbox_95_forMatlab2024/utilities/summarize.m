function txt = summarize(obj)
%SUMMARIZE Create single-line text description of data, a model or a prediction.
%
%
%I/O: txt = summarize(obj)
%
%See also: MODELCACHE

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%RSK 7/2009

if isdataset(obj);
  %summarize like DSO
  info = getdatasource(obj);
  txt = [sprintf('%s [%i',info.name,info.include_size(1)) sprintf(',%i',info.include_size(2:end)) ']'];
  if info.include_size(2)==1
    lbl = obj.label{2};
    if ~isempty(lbl);
      txt = [txt ' "' lbl(obj.include{2},:) '"'];
    end
  end
  return
elseif isnumeric(obj) || ischar(obj) || iscell(obj)
  myclass = class(obj);
  mysize = '';
  mysize = sprintf('%ix',size(obj));
  mysize = mysize(1:end-1);
  txt = ['<' mysize ' ' myclass '>'];
  return
else
  %summarize like model or prediction
  modl = obj;
end

txt = [modl.modeltype];
if isfieldcheck(modl,'modl.detail.options.algorithm')
  txt = sprintf('%s (%s)',txt,modl.detail.options.algorithm);
end
if isfield(modl,'loads');
  nlvs = size(modl.loads{2,1},ndims(modl.loads{2,1}));
else
  nlvs = 0;
end

mt = lower(modl.modeltype);
ispred = ~isempty(findstr(mt,'_pred'));
if ispred
  %drop _pred from model type
  mt(findstr(mt,'_pred'):end) = [];
end
switch mt
  case {'pls' 'plsda'};
    txt   = [txt ' ' num2str(nlvs) ' LVs'];
  case {'pcr' 'pca' 'mpca'}
    txt   = [txt ' ' num2str(nlvs) ' PCs'];
  case 'knn'
    nlvs = modl.k;
    txt   = [txt ' (' num2str(nlvs) ')'];
  case {'mlr' 'simca' 'svm'}
    %nothing extra...
  otherwise
    if nlvs>0
      txt   = [txt ' ' num2str(nlvs) ' comp'];
    end
end
predesc  = '';
predescy = '';
if isfieldcheck('modl.detail.preprocessing',modl);
  if ~isempty(modl.detail.preprocessing{1})
    ppi = modl.detail.preprocessing{1};
    predesc = [ppi(1).description];
    for i = 2:length(ppi)
      predesc = [predesc ' , ' ppi(i).description];
    end
  end

  if length(modl.detail.preprocessing)>1;
    predesc = ['X: ' predesc ' ] [ '];
    if isempty(modl.detail.preprocessing{2})
      predescy = 'Y: none';
    else
      ppi = modl.detail.preprocessing{2};
      predescy = ['Y: ' ppi(1).description];
      for i = 2:length(ppi)
        predescy = [predescy ' , ' ppi(i).description];
      end
    end
  end
end

txt = [txt ' [' predesc predescy ']'];

if isfield(modl,'time');
  txt = [txt '  ' encodedate(modl.time,31)];
end
