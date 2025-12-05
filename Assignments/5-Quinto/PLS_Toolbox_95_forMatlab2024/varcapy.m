function vc = varcapy(model,options);
%VARCAPY Calculate percent y-block variance captured by a PLS regression model.
% Given a PLS or PCR regression model, VARCAPY calculates the percent of
% y-block variance captured by each latent variable of the model for each
% column of the y-block.
% Input is a standard PLS or PCR model structure. Outupt is a matrix
% containing the variance captured by each latent variable (rows) for each
% column of y (columns).
%
% Optional input (options) is a options structure containing the field:
%    plots : [ 'none' |{'final'}] Governs plotting of results
%
%I/O: vc = varcapy(model,options)
%
%See also: ANALYSIS, DATAHAT, PCR, PLS, VARCAP

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%03/9/06 jms

if nargin == 0; model = 'io'; end
if ischar(model);
  options = [];
  options.plots = 'final';
  if nargout==0; evriio(mfilename,model,options); else; vc = evriio(mfilename,model,options); end
  return; 
end

if ~ismodel(model) | ~ismember(lower(model.modeltype),{'pls' 'plsda' 'pcr'})
  error('Input must be a standard model structure containing a PCR, PLS, or PLSDA model');
end

if nargin<2
  options = [];
end
options = reconopts(options,'varcapy');

if model.datasource{2}.size(2)==1;
  %SHORTCUT - if this is a univariate y, we already have the values we need
  %in the model.detail.ssq field (column 4). Just return those.
  vc = model.detail.ssq(1:size(model.loads{2,2},2),4);

else
  
  %get y-data (preprocessed)
  y = preprocess('apply',model.detail.preprocessing{2},model.detail.data{2});
  y = y.data(y.include{1},y.include{2});
  ssqy = sum(y.^2,1);  %total variance in y

  switch lower(model.modeltype)
    case {'pls' 'plsda'}
      if strcmpi(model.detail.options.algorithm,'robustpls')
        %doesn't work with robustPLS
        vc = model.loads{2,2}'*nan;
      else
        %all other algorithms
        %grab important items from model
        T = model.loads{1,1}(model.detail.includ{1,1},:);    %x-block scores
        Q = model.loads{2,2};    %y-block loadings
        
        %Adjust nipals-based model for variance captured in X and inner-relation
        %values (bin)
        if strcmpi(model.detail.options.algorithm,'nip')
          Q = Q*diag(model.detail.bin.*sqrt(sum(T.^2)));
        end
        %calculate variance captured
        vc = (Q'.^2)*diag(1./ssqy)*100;
      end
      
    case {'pcr'}
      %grab important items from model
      T = model.loads{1,1}(model.detail.includ{1,1},:);    %x-block scores
      P = model.loads{2};    %x-block loadings
      b = model.reg;          %regression vector
      r = P\b;                %calculate inner-relation coefficients
      
      %calculate variance captured
      vc = diag(sum(T.^2))*r.^2*diag(1./ssqy)*100;
  end

end

if strcmp(options.plots,'final')
  figure
  bar(vc','stacked');
  if size(vc,2)==1;
    ylabel('Percent variance captured')
    xlabel('Latent variable number')
  else
    ylabel('Percent variance captured per latent variable')
    xlabel('Y-block variables')
  end
end
