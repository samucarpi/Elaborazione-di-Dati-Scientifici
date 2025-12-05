function varargout = pcrengine(varargin);
%PCRENGINE Principal Component Regression computational engine.
%  Inputs are an x-block (x), y-block (y), optional number of
%  components (ncomp) {default = rank of x-block}, and optional options
%  structure containing the field:
%     display : [ 'off' |{'on'}]  governs display to command window
%   sortorder : [{'x'} | 'y' ]  governs order of factors in outputs. 'x'
%                is standard PCR sort order (ordered in terms of X block
%                variance captured). 'y' is Correlation PCR sort order
%                (ordered in terms of Y block variance captured).
%
%  Outputs are the matrix of regression vectors (reg), the sum of squares
%  captured (ssq), x loadings (loads), x scores (scores), and the PCA ssq
%  table (pcassq).
%
%I/O: [reg,ssq,loads,scores,pcassq] = pcrengine(x,y,ncomp,options);
%I/O: pcrengine demo
%
%See also: ANALYSIS, PCR, PLS

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 5/7/04 added output of pca SSQ table too

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name = 'options';
  options.display = 'on';
  options.sortorder = 'x';
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

switch nargin
  case 1
    error('Insufficient inputs')
  case 2
    % (x,y)
    varargin{3} = [];
    varargin{4} = [];
  case 3
    % (x,y,ncomp)
    % (x,y,options)
    if isa(varargin{3},'double');
      varargin{4} = [];
    else
      varargin{4} = varargin{3};
      varargin{3} = [];
    end
  case 4
    % (x,y,ncomp,options)
end

%parse out inputs
% x,y,ncomp,options
x       = varargin{1};
y       = varargin{2};
ncomp   = varargin{3};
options = reconopts(varargin{4},'pcrengine',0);

if isempty(ncomp); ncomp = min(size(x)); end
if ncomp <1 | ncomp~=fix(ncomp);
  error('NCOMP must be a positive integer');
end

if any(min(y)==max(y));
  error('Regression not possible when all y values are the same (i.e. range=0).');
end

[mx,nx] = size(x);
[my,ny] = size(y);

if strcmp(options.sortorder,'x')
  pcs = ncomp;
else
  %sort order on y requires us to calculate ALL PCs
  pcs = inf;
end

opts         = pcaengine('options');
opts.display = 'off';
opts.norecon = 'on';  %fast options reconcile
[pcassq,datarank,loads,scores] = pcaengine(x,pcs,opts);

newncomp   = min([datarank ncomp]);

ssq     = zeros(ncomp,2);
ssqy    = sum(sum(y.^2)');
ssqty   = zeros(ncomp,1);
reg     = zeros(ncomp*ny,nx)*inf;

if strcmp(options.sortorder,'y')
  %re-order terms in order of y-variance captured

  %calculate y variance captured for each PC
  r = scores\y;
  ycaptured = sum(diag(sum(scores.^2))*r.^2,2)/ssqy*100;
  
  %   [junk,order] = sort(ycaptured,'descend');
  [junk,order] = sort(-ycaptured); %(use - to get descend order even with 6.5)
  order = order(1:ncomp);
  loads = loads(:,order);
  scores = scores(:,order);
  pcassq(1:size(ssq,1),2:end) = pcassq(order,2:end);
  pcassq(:,end) = cumsum(pcassq(:,end-1));
end

wrn = warning;
warning('off');
try
  for ii=1:newncomp
    r     = inv(scores(:,1:ii)'*scores(:,1:ii))* ...
      scores(:,1:ii)'*y;
    reg(ny*(ii-1)+1:ny*ii,:) = (loads(:,1:ii)*r)';
    dif   = y-scores(:,1:ii)*r;
    ssqty(ii,1) =  ((ssqy - sum(sum(dif.^2)))/ssqy)*100;
  end
  %in-fill missing factors with last regression vector (same answer for all
  %higher-order models as last calculable regression vector(s))
  if newncomp>1
    for ii=newncomp+1:ncomp
      reg(ny*(ii-1)+1:ny*ii,:) = reg(ny*(newncomp-1)+1:ny*newncomp,:);
    end
  end
catch
  le = lasterror;
  warning(wrn);
  rethrow(le)
end
warning(wrn)

ssqy      = zeros(ncomp,1);
ssqy(1,1) = ssqty(1,1);
for ii=1:newncomp-1
  ssqy(ii+1,1) = ssqty(ii+1,1)-ssqty(ii,1);
end
ssq = [[1:ncomp]' zeros(ncomp,2)*0 ssqy ssqty];
ssq(1:newncomp,2:3) = pcassq(1:newncomp,3:4);
if newncomp>0
  ssq(newncomp:ncomp,3) = ssq(newncomp,3);
  ssq(newncomp:ncomp,5) = ssq(newncomp,5);
end

switch options.display
case {'on', 1}
  ssqtable(ssq)
%   ssqtable(ssq(1:newncomp,:))
end

varargout = { reg ssq loads scores pcassq};
% varargout = { reg(1:newncomp,:) ssq(1:newncomp,:) loads scores(1:newncomp,:) pcassq};

