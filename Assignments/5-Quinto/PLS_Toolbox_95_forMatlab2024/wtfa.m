function [rho,angl,q,skl] = wtfa(spec,tspec,window,p,options)
%WTFA Window target factor analysis.
%  INPUTS:
%     spec = MxN data matrix {class double or DataSet},
%    tspec = KxP matrix of target/candidate spectra.
%   window = scalar containing the window width >= 1.
%        p = The number of principal components, PCs, for modeling each
%            window of spectra.
%            p >= 1: (integer) number PCs is a constant p,
%        0 < p <  1: sets a relative criterion for selecting number
%                    of PCs in each window i.e. only the first set of
%                    PCs that together capture >=p*100% of the sum-of-
%                    squares in the window are used, or
%            p <  0: sets an absolute value for number of PCs i.e.
%                    factors with eigenvalues <|p| are not used.
%                EWFA can be used as a guide for setting p when p<0.
%
%  Optional input:
%    options = structure variable used to govern the algorithm with the following fields:
%      plots: [ 'none' | {'angle'} | 'rho' | 'q' ]   governs plotting.
%        'angle' plots projection angle {default},
%        'rho'   plots direction cosine, and
%        'q'     plots Q residuals.
%      scale: [] is a M element vector scale to plot against.
%
%  OUTPUTS:
%      rho = direction cosine between (tspec) and a (p) component PCA model
%            of (spec) in each window.
%     angl = angle between targets and PCA model [= acos(rho)].
%        q = Q residuals.
%
%  Note that the output values near the end of the record (less than
%  the half width of the window) are plotted as dashed lines and
%  the window center is output in the variable (skl).
%
%  References:
%  Lohnes, MT, Guy, RD, Wentzell, PD, "Window Target-Testing Factor Analysis:
%    Theory and Application to the Chromatographic Analysis of Complex
%    Mixtures with Multiwavelength Fluorescence Detection", Anal. Chim.
%    Acta, 389, 95-113 (1999).
%  Malinowski, ER, "Obtaining the Key Set of Typical Vectors by Factor
%    Analysis and Subsequent Isolation of Component Spectra," 134, 129-
%    137 (1982). DOI: 10.1016/S0003-2670(01)84184-2
%  Malinowski, ER, Factor Analysis in Chemistry, 2nd ed. John Wiley & Sons,
%    New York 1991.
%
%I/O: [rho,angl,q,skl] = wtfa(spec,tspec,window,p,options);
%I/O: wtfa demo
%
%See also: EVOLVFA, EWFA, PCA

%Copyright Eigenvector Research, Inc., 1998-2020
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 11/98,1/99
%nbg 12/00 check for isempty(plots), changed Q res plot to semilogy
%nbg 8/02 change to standard I/O format, allow DataSets
%nbg 8/05 fixed logic error when p<1
%nbg 12/09 fixed a missing normalization of the projected target

%q really should be normalized to the local residual limit

if nargin == 0; spec = 'io'; end
varargin{1} = spec;

if ischar(varargin{1}) %Help, Demo, Options
  
  options = [];
  options.name    = 'options';
  options.plots   = 'angle';  %Governs plots to make
  options.display = 'on';     %governs waitbar.
  options.scale   = [];       %Scale to plot against

  if nargout==0; clear rho; evriio(mfilename,varargin{1},options); else; rho = evriio(mfilename,varargin{1},options); end
  return;   
end
if strcmpi(options.display,'on')
  options.display = true;
else
  options.display = false;
end

warning off backtrace
if nargin<4
  error('WTFA requires at least 4 inputs.')
end
[m,n]    = size(spec);
if n~=size(tspec,2)
  error('Error - number of columns of spec and tspec must be equal')
end
if isdataset(tspec)
  spec   = spec(:,tspec.include{2});
  tspec  = tspec.data(:,tspec.include{2});
end
if isdataset(spec)
  spec   = spec.data;
end

if window<2
  window = 1;
end
if p>=window
  p      = window;
end
if nargin<5               %set default options
  options  = wtfa('options');
else
  options = reconopts(options,wtfa('options'));
end
if isempty(options.scale) %set up scale to plot against        
  skl = [[1:.5:window/2+.5] [window/2 + 1.5:m-window/2+.5] [m-window/2 + 1:.5:m]]';
elseif length(options.scale)~=m
  warning('EVRI:WtfaScaleBad',['optons.scale must be = number of rows in spec [length(size(spec,1))]', ...
    'input options.scale not used'])
  skl = [[1:.5:window/2+.5] [window/2 + 1.5:m-window/2+.5] [m-window/2 + 1:.5:m]]';
else
  skl      = zeros(1,m+window-1);
  for ii=1:window
    skl(ii) = mean(options.scale(1:ii));
  end
  for ii=window+1:m
    skl(ii) = mean(options.scale(ii-window+1:ii));
  end
  for ii=m+1:m+window-1
    skl(ii) = mean(options.scale(ii-window+1:m));
  end
end

mt       = size(tspec,1);
[tspec,ns] = normaliz(tspec);
rho      = zeros(m+window-1,mt);
q        = rho;
if options.display
  h       = waitbar(0,'WTFA working');
end
for ii=1:window-1              %left hand side
  [mx,nx]   = size(spec(1:ii,:));
  try
    if mx<nx
      [u,s]   = svd(spec(1:ii,:)*spec(1:ii,:)');
      v       = spec(1:ii,:)'*u;
      for i1=1:size(u,2)
        v(:,i1) = v(:,i1)/norm(v(:,i1));
      end
    else
      [v,s]   = svd(spec(1:ii,:)'*spec(1:ii,:));
    end
    if ii==1
      s       = s(1,1);
    else
      s       = diag(s);
    end
    if p<0
      u       = find(s>=p^2);
      v       = v(:,1:length(u));
    elseif p<1
      u       = find(cumsum(s)/sum(s)>p);
      v       = v(:,1:u(1));
    else
      v       = v(:,1:min([ii n p]));
    end
    u         = normaliz((tspec*v)*v');
    rho(ii,:) = diag(u*tspec')';
    q(ii,:)   = diag((tspec-u)*(tspec-u)')';
  catch
    rho(ix,iy,:)  = 0;
    q(ix,iy,:)    = diag(tspec*tspec');
  end
end
for ii=window:m                %middle
  [mx,nx]   = size(spec(ii-window+1:ii,:));
  if mx<nx
    [u,s]   = svd(spec(ii-window+1:ii,:)*spec(ii-window+1:ii,:)');
    v       = spec(ii-window+1:ii,:)'*u;
    for i1=1:size(u,2)
      v(:,i1) = v(:,i1)/norm(v(:,i1));
    end
  else
    [v,s]   = svd(spec(ii-window+1:ii,:)'*spec(ii-window+1:ii,:));
  end
  s         = diag(s);
  if p<0
    u       = find(s>=p^2);
    v       = v(:,1:length(u));
  elseif p<1
    u       = find(cumsum(s)/sum(s)>p);
    v       = v(:,1:u(1));
  else
    v       = v(:,1:min([window n p]));
  end
  u         = normaliz((tspec*v)*v');
  rho(ii,:) = diag(u*tspec')';
  q(ii,:)   = diag((tspec-u)*(tspec-u)')';
  if options.display
    waitbar(ii/m,h)
  end
end
for ii = m-window+2:m           %right hand side
  [mx,nx]   = size(spec(ii:m,:));
  if mx<nx
    [u,s]   = svd(spec(ii:m,:)*spec(ii:m,:)');
    v       = spec(ii:m,:)'*u;
    for i1=1:size(u,2)
      v(:,i1) = v(:,i1)/norm(v(:,i1));
    end
  else
    [v,s]   = svd(spec(ii:m,:)'*spec(ii:m,:));
  end
  if ii==m
    s       = s(1,1);
  else
    s       = diag(s);
  end  
  if p<0
    u       = find(s>=p^2);
    v       = v(:,1:length(u));
  elseif p<1
    u     = find(cumsum(s)/sum(s)>p);
    v     = v(:,1:u(1));
  else
    v       = v(:,1:min([(m-ii+1) n p]));
  end
  u         = normaliz((tspec*v)*v');
  rho(ii+window-1,:) = diag(u*tspec')';
  q(ii+window-1,:)   = diag((tspec-u)*(tspec-u)')';
end
% rho      = sqrt(rho);
angl     = real(acos(rho))*180/pi;
for ii=1:size(tspec,1)
  q(:,ii) = q(:,ii)*(ns(ii)^2);
end
if options.display
  close(h)
end

switch options.plots
case {0, 'none'}
  %plot nothing
case {1, 'angle'}
  figure
  plot(skl(1:window),angl(1:window,:),'--'), hold on
  plot(skl(window:m),angl(window:m,:))
  plot(skl(m:m+window-1),angl(m:m+window-1,:),'--'), hold off
  vline([skl(window) skl(m)])
  title(sprintf('Window Target Factor Analysis with Window Width = %g',window))
  xlabel('Sample Number of Window Center')
  ylabel('Angle (degrees)')
case {2, 'rho'}
  figure
  plot(skl(1:window),rho(1:window,:),'--'), hold on
  plot(skl(window:m),rho(window:m,:))
  plot(skl(m:m+window-1),rho(m:m+window-1,:),'--'), hold off
  vline([skl(window) skl(m)])
  title(sprintf('Window Target Factor Analysis with Window Width = %g',window))
  xlabel('Sample Number of Window Center')
  ylabel('Cosine')
case {3, 'q'}
  figure
  semilogy(skl(1:window),q(1:window,:),'--'), hold on
  semilogy(skl(window:m),q(window:m,:))
  semilogy(skl(m:m+window-1),q(m:m+window-1,:),'--'), hold off
  vline([skl(window) skl(m)])
  title(sprintf('Window Target Factor Analysis with Window Width = %g',window))
  xlabel('Sample Number of Window Center')
  ylabel('Q Residual')
otherwise
  disp('plot option not recognized')
end
warning backtrace
