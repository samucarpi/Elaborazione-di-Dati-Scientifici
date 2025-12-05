function varargout = ssqtable(ssq,ncomp)
%SSQTABLE Displays variance captured table for model.
%  SSQTABLE prints the variance captured table (ssq) from
%  regression or pca models to the command window.
%
%  The optional input (ncomp) is the number of latent
%  variables or principal components to print in the table.
%  If (ncomp) is not included the routine will print the entire
%  table to the command window. If (ssq) is a standard model
%  structure as output from REGRESSION or DECOMPOSE, then model
%  information is displayed along with the SSQ table.
%
%Example: for a regression model from REGRESSION called (modl)
%    ssqtable(modl.detail.ssq,5)
%  will print the variance captured table for the first 5
%  latent variables to the command window.
%
%I/O: ssqtable(ssq,ncomp)
%I/O: ssqtable demo
%
%See also: ANALYSIS, MODLRDER, MPCA, PCA, PCR, PLS

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%jms 6/7/02 -updated for new model structure.
% -also now calls MODLRDER for model display
%jms 3/26/04 -added support for MCR
%rsk 05/03/04 -add plsda
%jms 5/3/04 -added fix to parafac code
%nbg 8/09 -added PAF and PDF under PCA

if nargin == 0; ssq = 'io'; end
varargin{1} = ssq;
if ischar(varargin{1})
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

txt = cell(0);

if ismodel(ssq)
  mdldesc   = modlrder(ssq);
  modeltype = ssq.modeltype;
  switch lower(modeltype)
    case {'parafac' 'parafac2' 'parafac_pred' 'parafac2_pred'}
      numcomp = length(ssq.detail.ssq.percomponent.data(:,1));
      ssq     = [(1:numcomp)' ssq.detail.ssq.percomponent.data(:,2:3) ssq.detail.ssq.percomponent.data(:,5:6)];
    otherwise
      ssq     = ssq.detail.ssq;
  end
else
  mdldesc    = {};
  switch size(ssq,2)
    case 5
      modeltype = 'reg';
    case 4
      modeltype = 'pca';  %assume pca
    otherwise
      disp('Error - ssq not of proper format')
      error(' e.g. see outputs from REGRESSION or DECOMPOSE')
  end
end
if nargin<2
  ncomp = size(ssq,1);
end

if ncomp>size(ssq,1)
  ncomp = size(ssq,1);
end

trigger = lower(modeltype);
trigger = strrep(trigger,'_pred','');
switch trigger
  case {'reg','pls','pcr','npls','plsda','lwr'}
    txt{end+1} = ('    Percent Variance Captured by Regression Model');
    txt{end+1} = ('  ');
    txt{end+1} = ('           -----X-Block-----    -----Y-Block-----');
    txt{end+1} = ('   Comp     This      Total      This      Total ');
    txt{end+1} = ('   ----    -------   -------    -------   -------');
    format = '   %3.0f     %6.2f    %6.2f     %6.2f    %6.2f';
    for ii=1:ncomp
      txt{end+1} = sprintf(format,ssq(ii,:));
    end
    txt{end+1} = ('  ');
  case {'pca' 'mpca' 'maf' 'mdf' 'lda'}
    txt{end+1} = (['        Percent Variance Captured by ' upper(modeltype) ' Model']);
    txt{end+1} = ('  ');
    txt{end+1} = ('Principal     Eigenvalue     % Variance     % Variance');
    txt{end+1} = ('Component         of          Captured       Captured');
    txt{end+1} = (' Number         Cov(X)        This  PC        Total');
    txt{end+1} = ('---------     ----------     ----------     ----------');
    format = '   %3.0f         %3.2e        %6.2f         %6.2f';
    for ii=1:ncomp
      txt{end+1} = sprintf(format,ssq(ii,:));
    end
  case {'mcr' 'purity' 'als_sit'}
    txt{end+1} = ('        Percent Variance Captured by MCR Model');
    txt{end+1} = ('  ');
    txt{end+1} = ('Component        Fit            Fit         Cumulative');
    txt{end+1} = (' Number        (%Model)         (%X)         Fit (%X)');
    txt{end+1} = ('---------     ----------     ----------     ----------');
    format = '   %3.0f         %6.2f          %6.2f         %6.2f';
    for ii=1:ncomp
      txt{end+1} = sprintf(format,ssq(ii,:));
    end
  case {'cls'}
    txt{end+1} = ('        Percent Variance Captured by CLS Model');
    txt{end+1} = ('  ');
    txt{end+1} = ('Component        Fit            Fit         Cumulative');
    txt{end+1} = (' Number        (%Model)         (%X)         Fit (%X)');
    txt{end+1} = ('---------     ----------     ----------     ----------');
    format = '   %3.0f         %6.2f          %6.2f         %6.2f';
    for ii=1:ncomp
      txt{end+1} = sprintf(format,ssq(ii,:));
    end
  case {'parafac' 'parafac2'}
    txt{end+1} = ('    Percent Variance Captured by PARAFAC Model');
    txt{end+1} = ('  ');
    txt{end+1} = ('           -------Fit-------    ---Unique Fit---');
    txt{end+1} = ('   Comp     (%X)     (%Model)    (%X)     (%Model)');
    txt{end+1} = ('   ----    -------   -------    -------   -------');
    format = '   %3.0f     %6.2f    %6.2f     %6.2f    %6.2f';
    for ii=1:ncomp
      txt{end+1} = sprintf(format,ssq(ii,:));
    end
  otherwise
    error('Can not interpret SSQ table for given model format')
end

if nargout == 0
  disp(sprintf('%s\n',mdldesc{1:end-1}));
  disp(sprintf('%s\n',txt{:}));
else
  varargout = {txt,mdldesc};
end

