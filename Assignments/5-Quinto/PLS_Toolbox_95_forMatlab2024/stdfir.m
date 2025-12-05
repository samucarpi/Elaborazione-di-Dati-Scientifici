function [sspec] = stdfir(nspec,rspec,win,mc);
%STDFIR Standardization based on FIR modelling.
%  STDFIR is a moving window multiplicative scatter correction
%  with a fixed window size. This algorithm uses an inverse least
%  squares regression.
%
%  Inputs are (nspec) a matrix of new spectra to be standardized,
%  (rspec) the vector of the standard spectrum from the standard
%  instrument (i.e. a reference spectrum), and (win) the window
%  width (must be an odd number).
%  If optional input (mc) is 1 {default} the regression allows for
%  an offset and slope, if (mc) is set to 0 only the slope is used.
%
%  The output is (sspec) the matrix of standardized spectra.
%
%I/O: sspec = stdfir(nspec,rspec,win,mc);
%I/O: stdfir demo
%
%See also: BASELINEW, DERESOLV, MSCORR, POLYINTERP, REGISTERSPEC, SAVGOL, SAVGOLCV, STDGEN

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%jms 5/02 added evriio
%nbg modified 5/02 to accept datasets, changed to ILS

if nargin == 0; nspec = 'io'; end
varargin{1} = nspec;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear sspec; evriio(mfilename,varargin{1},options); else; sspec = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin<3
  error('STDFIR requires at least 3 inputs.')
end

%convert DataSet to double (might do this the other way around...)
if isa(nspec,'dataset')
  nspec = nspec.data;
end
if isa(rspec,'dataset')
  rspec = rspec.data;
end

[ms,ns] = size(nspec);
[mr,nr] = size(rspec);
if mr>1&nr>1                   %rspec must be a vector
  error('(rspec) must be a vector')
elseif mr>nr                   %make rspec a row vector
  rspec = rspec';
end, clear mr nr
if ns~=length(rspec)           %make sure rspec is same size as nspec
  error('number of columns in (nspec) must equal length(rspec)')
end
if (round(win/2)-win/2)==0|win<3              %win must be odd
  error('input (win) must be >2 and odd')
end
if nargin<4
  mc    = 1;
end
ps      = floor(win/2);
sspec   = zeros(ms,ns);
for ii=ps+1:ns-ps              %standardize middle of spectra
  if mc==0
    smean = zeros(ms,win);
    rmean = 0;
  else
    smean = mean(nspec(:,ii-ps:ii+ps)')';
    rmean = mean(rspec(1,ii-ps:ii+ps)');
  end
  scent = (nspec(:,ii-ps:ii+ps)-smean(:,ones(1,win)))';
  rcent = (rspec(1,ii-ps:ii+ps)-rmean)';
  %breg  = scent/rcent;
  %sspec(:,ii) = scent(:,ps+1)./breg+rmean;
  for i1=1:ms
    breg  = scent(:,i1)\rcent;                       %5/02
    sspec(i1,ii) = scent(ps+1,i1)*breg+rmean;        %5/02
  end
end
if mc==0 %standardize left end
  smean = zeros(ms,win);
  rmean = 0;
else
  smean = mean(nspec(:,1:win)')';
  rmean = mean(rspec(1,1:win)');
end
scent = (nspec(:,1:win)-smean(:,ones(1,win)))';
rcent = (rspec(1,1:win)-rmean)';
% breg  = scent/rcent;
% sspec(:,1:ps) = scent(:,1:ps)./breg(:,ones(1,ps))+rmean;
for i1=1:ms
  breg  = scent(:,i1)\rcent;
  sspec(i1,1:ps) = scent(1:ps,i1)'*breg+rmean;
end
if mc==0 %standardize right end
  smean = zeros(ms,win);
  rmean = 0;
else
  smean = mean(nspec(:,ns-win+1:ns)')';
  rmean = mean(rspec(1,ns-win+1:ns)');
end
scent = (nspec(:,ns-win+1:ns)-smean(:,ones(1,win)))';
rcent = (rspec(1,ns-win+1:ns)-rmean)';
% breg  = scent/rcent;
% sspec(:,ns-ps+1:ns) = scent(:,ps+2:win)./breg(:,ones(1,ps))+rmean;
for i1=1:ms
  breg  = scent(:,i1)\rcent;
  sspec(i1,ns-ps+1:ns) = scent(ps+2:win,i1)'*breg+rmean;
end
