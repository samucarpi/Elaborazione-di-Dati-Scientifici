function res = alignmatfun(ii,algorithm,a,bt,ms,mt,ns,nt,nocomp)
%ALIGNMATFUN Objective funtion optimized in ALIGNMAT.
%  This function is called by ALIGNMAT and is not intended
%  for general use. Inputs depend on the specific algorithm.
%
%I/O: res = alignmatfun(ii,algorithm,a,bt,ms,mt,ns,nt,nocomp);

%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg (original written 7/01)
%nbg 12/29/05 commented I/O check

%The call from ALIGNMAT is
%itst = fminsearch('alignmatfun',x,optoptions, ...
%  'projection',uloads,bt,imode,lsiz,bsiz,bnds);
%INPUTS for algorithm==projection
%  x, ii     = the initial indice for each mode.
%  uloads, a = prod([size(loads{i},1), ...]) by k matrix of kron(loads).
%  bt        = the original test matrix.
%  imode, ms = 1xnmode vector w/ 0 for unsearched & 1 for searched dims.
%  lsiz, mt  = 1xnmode vector w/ sizes of std matrix.
%  bsiz, ns  = 1xnmode cell with vectors of 1:size(b,ndim).
%  bnds, nt  = 2xnmode matrix w/ bounds on x,ii.
%  nocomp    = #components (input for algorithm = 'SVD').

%The following I/O check was commented out nbg 12/29/05
%to make ALIGNMAT run ~faster. ALIGNMATFUN is a utility
%called by ALIGNMAT and is not intended for general use.
% if nargin == 0; ii = 'io'; end
% varargin{1} = ii;
% if ischar(varargin{1});
%   options = [];
%   if nargout==0; clear res; evriio(mfilename,varargin{1},options); else; res = evriio(mfilename,varargin{1},options); end
%   return; 
% end

switch algorithm
case {'svd(x^T*x)','svd(x)' }
  yi   = interp1([1:mt]',bt,[ii:ii+ms-1]','linear',0);
  switch algorithm
  case 'svd(x^T*x)'
    if ms<ns+nt
      s    = svd([a,yi]*[a,yi]');
      res  = sum(s(nocomp+1:end))/sum(s(1:nocomp));
    else
      s    = svd([a,yi]'*[a,yi]);
      res  = sum(s(nocomp+1:end))/sum(s(1:nocomp));
    end  
  case 'svd(x)'        %uses svd(x)  (slower)
    s    = svd([a,yi]);
    res  = sum(s(nocomp+1:end))/sum(s(1:nocomp));
  end
case 'projection'
  %itst = fminsearch('shiftmat2fun',x,optoptions,algorithim,uloads,b,imode,lsiz,bsiz,bnds);
  %res  =              alignmatfun(ii,           algorithm ,a,     bt,ms,  mt,  ns,  nt)
  ysiz    = ns;       %axes
  ik      = find(ms); %modes to align
  for ij=1:length(ii)
    ysiz{ik(ij)} = [ii(ij):ii(ij)+mt(ik(ij))-1];
  end
  ysiz{1} = ysiz{1}';
  bt      = interpn(ns{:},bt,ysiz{:},'*linear');
  %unfold bt along the last order i.e. the singleton dimension
  if any(ii<nt(1,ik))|any(ii>nt(2,ik))
    res   = inf;
  else
    res   = sum((bt(:)-a*(a\bt(:))).^2);
  end
case 'projection2d'
  [u,v] = meshgrid([ii(2):ii(2)+ns-1],[ii(1):ii(1)+ms-1]);
  yi   = interp2(bt,u,v);
  v    = yi';
  v    = diag(v(:)'*a);
  u    = (yi-nocomp{1}*v*nocomp{2}').^2;
  res  = sum(sum(u)');
end
