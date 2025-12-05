function [nas,nnas,sens,sel] = figmerit(x,y,b)
%FIGMERIT Analytical figures of merit for multivariate calibration.
%  Calculates analytical figures of merit for PLS and PCR models.
%  The inputs are the preprocessed (usually centered and scaled)
%  data (x), the preprocessed analyte data (y), and the
%  regression vector, (b). Note that for standard PCR and PLS model
%  structures that b = model.reg.
%  Outputs are the matrix of net analyte signals (nas) for each row
%  of (x), the "norm" of the net analyte signal for each row (nnas)
%  [with sign], the matrix of sensitivities for each sample (sens),
%  and the vector of selectivities for each sample (sel) [which are
%  positive regardless of the sign of (nas)]. 
%  
%  An earlier version of FIGMERIT estimated a "noise filtered" NAS.
%  This is no longer estimated because an improved method for 
%  calculating the NAS makes it redundant.
% 
%Example: given the 7 LV PLS model formed from
%  model = pls(x,y,7);
%
%I/O: [nas,nnas,sens,sel] = figmerit(x,y,b);
%I/O: figmerit demo
%
%See also: ANALYSIS, LEVERAG, PLS

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Barry M. Wise May 30, 1997

% aug 2002, rb, changed to new definition given by the regression vector
% according to Bro, Andersen, "Theory of net analyte signal vectors in
% inverse regression", Journal of Chemometrics
% 4/03 nbg changed the help. removed the redundant b(:)
% 

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; nas = evriio(mfilename,varargin{1},options); end
  return; 
end

warning off backtrace 

if nargout == 5
  warning('EVRI:FigmeritOldOutput',' In earlier versions of FIGMERIT, a fifth output was possible but is redundant (=nas) now')
end
if min(size(b))>1
  error(' Third input must be a regression vector for one response')
end


[mx,nx] = size(x);
nas     = zeros(mx,nx);
nnas    = zeros(mx,1);
sel     = zeros(mx,1);
b       = b(:);

nas     = ((x*b)*inv(b'*b))*b';
sens    = nas;
nnas    = x*b/norm(b);
for i=1:mx
  sel(i)    = abs(nnas(i)/norm(x(i,:)));
  sens(i,:) = sens(i,:)/y(i);
end


