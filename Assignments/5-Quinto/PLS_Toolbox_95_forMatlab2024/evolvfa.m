function [egf,egr] = evolvfa(x,options,tdat)
%EVOLVFA Evolving Factor Analysis (forward and reverse).
%  EVOLVFA calculates singular values (square roots of the eigenvalues
%  of the covariance matrix) of sub-matrices of input (x).
%
%  If compression is used (see options.usepca below), the algorithm runs
%  much faster but there is a risk that minor factors could be missed. 
%  In this case it is recommended to a) not use compression or
%  b) increase the maximum number of PCs (see options.maxpc below).
%
%  INPUT:
%       x = data matrix (MxN, 2-way array or DataSet Object).
%
%  OPTIONAL INPUT:
%    options = structure array with the following fields:
%       plots: [ 'none' | {'final'} ]  governs level of plotting.
%     waitbar: ['off' | {'on'}]  governs display of waitbar.
%      usepca: [ {false} | true ] governs the use of compression. If
%              true then compression is used.
%       maxpc: 40 maximum number of PCs to display, if compression is
%              used (options.usepca = true) then it is also the number
%              of principal components used to approximate the data.
%
%  OUTPUTS:
%     egf = forward analysis results and
%     egr = reverse analysis results.
%
%  Optional input (plots) allows the user to supress plotting results
%  ({default plots = 1}, plots = 0 suppresses plotting results), and
%  optional input (tdat) is a vector to plot the results against.
%
%  See: Keller, H. R., Massart, D. L., "Evolving factor analysis,"
%        Chemom. Intell. Lab. 1992, 12, 209-224.
%
%I/O: [egf,egr] = evolvfa(x,options);
%I/O: [egf,egr] = evolvfa(x,plots,tdat);
%I/O: evolvfa demo
%
%See also: EWFA, MCR, MPCA, PCA, PCAENGINE, WTFA

% Copyright © Eigenvector Research, Inc. 1995
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified BMW April 1998, NBG June 2019

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1})
  options         = [];
  options.name    = 'options';
  options.plots   = 'final'; %[ 'none' | {'final'} ]
  options.waitbar = 'on';    %['off' | {'on'}]
  options.usepca  = false;   %[{false} | true ]
  options.maxpc   = 40;
  if nargout==0; evriio(mfilename,varargin{1},options); else
    egf = evriio(mfilename,varargin{1},options); end
  return
end

m           = size(x);    %original number of rows by cols
if nargin<2
  options   = evolvfa('options');
else
  if isstruct(options)
    options = reconopts(options,'evolvfa');
  else
    plots   = options;
    options = evolvfa('options');
    if plots==1
      options.plots = 'final';
    else
      options.plots = 'none';
    end
  end
end
if nargin<3
  tdat      = 1:m(1);
end

if isa(x,'dataset')
  if isempty(x.axisscale{1})
    x.axisscale{1}     = tdat;
  end
  if isempty(x.axisscalename{1})
    x.axisscalename{1} = 'Sample Number';
  end
else
  x         = dataset(x);
  x.axisscale{1}       = tdat;
  x.axisscalename{1}   = 'Sample Number';
end
       
mi          = size(x.data.include);    %non-Nan rows in egx
k           = x.include{1};
mmax        = min([options.maxpc,mi]); %max singular values

if options.usepca
  [i,j,p,t] = pcaengine(x.data(x.include{1},x.include{2}), ...
                        mmax,struct('display','off')); %i,j,p are not used
  mi        = size(t);
  mmax      = min([options.maxpc,mi]); %max singular values
  egf       = NaN(m(1),mmax); 
  egr       = egf;
  for i=1:mi(1)
    if i<mmax
      s         = svd(t(1:i,:)',0);
    else
      s         = svd(t(1:i,:), 0);
    end
    j           = 1:min(i,mmax);
    egf(k(i),j) = s(j);
  end
  
  t         = flipud(t);
  k         = fliplr(k);
  for i=1:mi(1)
    if i<mmax
      s         = svd(t(1:i,:)',0);
    else
      s         = svd(t(1:i,:), 0);
    end
    j           = 1:min(i,mmax);
    egr(k(i),j) = s(j);
  end
else
  egf       = NaN(m(1),mmax); 
  egr       = egf;
  for i=1:mi(1)
    if length(k(1:i))<mmax
      s         = svd(x.data(k(1:i),x.include{2})',0);
    else
      s         = svd(x.data(k(1:i),x.include{2}), 0);
    end
    j           = 1:min(i,mmax);
    egf(k(i),j) = s(j);
  end
  
  k         = fliplr(k);
  for i=1:mi(1)
    if i<mmax
      s         = svd(x.data(k(1:i),x.include{2})',0);
    else
      s         = svd(x.data(k(1:i),x.include{2}), 0);
    end
    j           = 1:min(i,mmax);
    egr(k(i),j) = s(j);
  end
end

if strcmpi(options.plots,'final')
  figure('Name','Evloving Factor Analysis')
  subplot(2,1,1)
  semilogy(x.axisscale{1}(x.include{1}),egf(x.include{1},:),'-')
  ylabel('Singular Value')
  xlabel(x.axisscalename{1})
  title('Forward Analysis')
  subplot(2,1,2)
  semilogy(x.axisscale{1}(x.include{1}),egr(x.include{1},:),'-')
  ylabel('Singular Value')
  xlabel(x.axisscalename{1})
  title('Reverse Analysis')
end

