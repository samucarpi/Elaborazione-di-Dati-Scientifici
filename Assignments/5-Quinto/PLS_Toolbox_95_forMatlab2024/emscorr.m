function [sx,fx,xref,reg,res] = emscorr(x,xref,options)
%EMSCORR Extended Multiplicative Scatter Correction (EMSC)
%  EMSCORR attempts to remove multiplicative scattering effects in spectra.
%  This can be thought of as a filter where some portions of the signal are
%  passed and some are rejected.
%
%  INPUT:
%    x       = M by N matrix of spectra (class "double" or "dataset").
%
%  OPTIONAL INPUTS:
%    xref    = 1 by N reference vector. If not given then mean(x) is used.
%    options = structure array with the following fields:
%     display: [ 'off' | {'on'} ]  Governs level of display to command window.
%       order: [{2}]               Order of the polynomial filter.
%       logax: [{'no'} | 'yes' ]    Use the log of the axisscale, x.axisscale{2}.
%                If the axisscale is not present log(1:N) is used.
%                When options.logax is used, options.order is typically
%                set to zero.
%           s: [] Dataset or matrix, K  by N spectra to not filter out.
%           p: [] Dataset or matrix, Kp by N spectra to filter out.
%   algorithm: [ {'cls'} | 'ils' ] Governs correction model method
%               'cls' uses Classical Least Squares i.e. EMSC.
%               'ils' uses Inverse Least Squares i.e. EISC.
%         win: [] An odd scalar that defines the window width (number of
%               variables) for piece-wise correction. If empty {the
%               default} piece-wise is not used.
%               WARNING: Piece-wise analysis uses all variables, whether or
%               not they have been excluded in the input DataSet.
%      initwt: [] Empty or Nx1 vector of initial weights (0<=w<=1).
%                 Low weights are used for channels not to be included in the fit.
%     condnum: [1e6]   Condition number for x'*x used in the least squares estimates.
%       xrefS: [{'no'} | 'yes']  Indicates whether input (xref) includes spectra
%               contained in options.s. If 'yes' then the spectra in options.s are
%               centered and an SVD estimate of options.s is used in EMSCORR.
%      robust: [{'none'} | 'lsq2top' ] Governs the use of robust least squares
%               if 'lsq2top' is used then "trbflag", "tsqlim", and "stopcrit" are
%               also used (see LSQ2TOP for descriptions of these fields).
%         res: [] Scalar (required with "lsq2top") this is input (res) to
%               the LSQ2TOP function.
%     trbflag: [ 'top' | 'bottom' | {'middle'}] Used only with lsq2top.
%      tsqlim: [ 0.99 ] Used only with lsq2top.
%    stopcrit: [1e-4 1e-4 1000 360] Used only with lsq2top.
%   axisscale: [] 1 by N axis scale for the spectral mode, if empty [1:N] is used.
%         mag: [ {'yes'} | 'no' ], performs slope correction when set to 'yes'
%
%  OUTPUTS:
%        sx = a M by N matrix of filtered ("corrected") spectra.
%        fx = a M by N matrix of rejected spectra (i.e. what was filtered out).
%      xref = reference spectrum.
%       reg = regression coefficients, for non-windowed it is [# coef] x M
%             The coefficients are ordered according to the following basis
%               xbase = [xref, 1 x x^2 ..., options.p, options.s]
%       res = residuals of fit of the estimated basis minus the measured
%             spectrum.
%
% Based on the papers:
%  H Martens, JP Nielsen, SB Engelsen, Anal. Chem. 2003, 75, 394-404.
%  H Martens, EJ Stark, Pharm. Biomed. Anal. 1991, 9, 625-635.
%  NB Gallagher, TA Blake, PL Gassman, J. Chemo. 2005, 19(5-7), 271-281.
%
%I/O:  [sx,fx,xref,reg,res] = emscorr(x,xref,options);
%
%See also: MSCORR, STDFIR, EMSCORRDEMO2

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 2/04
%nbg 7/04 added options.algorithm, options.xrefS, options.robust, condnum
%  changed help, added windowing, ils, added initwt
%nbg 10/23/05 added outputs reg and res, modified help
%nbg 04/08/08 added mag correction option, allowed for options.order = 0
%nbg 04/24/08 made DSO compatible, 4/29/08 added log option
%nbg 10/24/12 added fx = fx'; xref = xref'; at the end of the windowed code

%add the following comments when double window is included
%                 If (win) is a two element vector the first element defines the
%                 regression window size to use, and the second element defines
%                 the number of channels to include in the sample matrix.

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  options.name       = 'options';
  options.display    = 'on';
  options.order      = 2;
  options.logax      = 'no'; %'yes'
  options.algorithm  = 'cls';
  options.xrefS      = 'no';
  options.robust     = 'none';
  options.res        = [];
  options.trbflag    = 'middle';
  options.tsqlim     = 0.99 ;
  options.stopcrit   = [1e-4 1e-4 1000 360];
  options.initwt     = [];
  options.win        = [];
  options.condnum    = 1e6; %condition number for x'*x
  options.axisscale  = [];
  options.s          = [];
  options.p          = [];
  options.mag        = 'yes'; %'no'
  options.definitions = @optiondefs;
  if nargout==0; evriio(mfilename,varargin{1},options); else
    sx = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin<3               %set default options
  options = [];
end
options  = reconopts(options,mfilename);

options.condnum = 1/options.condnum; %need the inverse of the condition number

if ~isa(x,'dataset')
  x        = dataset(x);
  wasdso   = false;
else
  wasdso   = true;
end
[m,n]      = size(x);
if isempty(x.axisscale{2})
  x.axisscale{2} = 1:n;
end

if nargin<2 || isempty(xref)
  xref     = mean(x.data);
end

if isdataset(xref)
  xref = xref.data;
end

if length(xref)~=n
  error('Input xref must be a row vector with the same number of columns as x.')
end
if ~isempty(options.s)
  if isdataset(options.s)
    options.s = options.s.data;
  elseif ismodel(options.s) %
    ms        = size(options.s.loads{2},2);
    junk      = options.s;
    options.s = zeros(ms,junk.datasource{1}.size(2)); 
    options.s(:,junk.detail.includ{2}) = junk.loads{2}';
  end
  [ms,junk]  = size(options.s);
  if junk~=n
    error('Input options.s must be a matrix with K rows and the same number of columns as x.')
  end
end
if ~isempty(options.p)
  if isdataset(options.p)
    options.p = options.p.data;
  elseif ismodel(options.p) %
    mp        = size(options.p.loads{2},2);
    junk      = options.p;
    options.p = zeros(mp,junk.datasource{1}.size(2)); 
    options.p(:,junk.detail.includ{2}) = junk.loads{2}';
  end
  [mp,junk]  = size(options.p);
  if junk~=n
    error('Input options.p must be a matrix with Kp rows and the same number of columns as x.')
  end
end
if ~isempty(options.win)
  if options.win/2-round(options.win/2)==0
    switch lower(options.display)
      case 'on'
        disp(' ')
        disp(['Input option win (window) must be odd, reset to win-1 = ',int2str(options.win-1),'.'])
    end
    options.win   = options.win-1;
  end
end
if isempty(options.axisscale)
  options.axisscale = x.axisscale{2};
elseif length(options.axisscale(:))~=n
  options.axisscale = x.axisscale{2};
end
options.axisscale = mncn(options.axisscale(:));

if isempty(options.initwt)
  options.initwt  = ones(n,1);
else
  if length(options.initwt)~=n
    error('Options.initwt must be a vector with a length equal to the number of columns of (x).')
  end
  options.initwt  = options.initwt(:);
end

switch lower(options.robust)
  case 'none'
  case 'lsq2top'
    if isempty(options.res)
      error('Input options.res must not be empty (see LSQ2TOP for additional help).')
    elseif options.res<=0
      error('Input options.res must be positive (see LSQ2TOP for additional help).')
    end
    optlsq2top = lsq2top('options');
    optlsq2top.trbflag  = options.trbflag;
    optlsq2top.tsqlim   = options.tsqlim;
    optlsq2top.stopcrit = optlsq2top.stopcrit;
    optlsq2top.initwt   = options.initwt;
  otherwise
    error('Options.Robust not recognized.')
end

if strcmpi(options.display,'on')
  hwait = waitbar(0,'EMSCORR Filter Being Estimated.');
end

if ~isempty(options.s)
  if isdataset(options.s)
    options.s = options.s.data
  end
  switch lower(options.xrefS)
    case 'yes'
      if ms>1
        ms        = ms-1;
        %[u,s,v]   = svd(scale(options.s,xref),0); clear u s %changed 4/29/08
        [u,s,v]   = svd(scale(options.s,mean(options.s)),0); clear u s
        options.s = v(:,1:ms)'; clear v
        %else
        %  options.s = scale(options.s,xref);
      end
  end
  options.s(:,x.include{2}) = normaliz(options.s(:,x.include{2}));
  options.s     = options.s';
end
if ~isempty(options.p)
  if isdataset(options.p)
    options.p = options.p.data;
  end
  switch lower(options.xrefS)
    case 'yes'
      if mp>1
        mp        = mp-1;
        %[u,s,v]   = svd(scale(options.p,xref),0); clear u s %changed 4/29/08
        [u,s,v]   = svd(scale(options.p,mean(options.p)),0); clear u s
        options.p = v(:,1:mp)'; clear v
        %else
        %  options.p = normaliz(options.p)';
      end
  end
  options.p(:,x.include{2})   = normaliz(options.p(:,x.include{2}));
  options.p     = options.p';
end
xref          = xref(:); %make xref a column vector

if isempty(options.order)
  filt = [];
else
  filt = (options.axisscale(:,ones(1,options.order+1)).^(ones(n,1)*(0:options.order)))';
  filt(:,x.include{2}) = normaliz(filt(:,x.include{2}));
  filt = filt';
end
if strcmpi(options.logax,'yes')
  filt = [filt log(x.axisscale{2})'];
end
if ~isempty(options.p)
  filt = [filt options.p];
end
fx   = zeros(size(x));
sx   = fx;
if isempty(filt(x.include{2},:))
  if strcmpi(options.display,'on')
    disp('Filter empty (nothing filtered from the signal).')
  end
  return;
end
if nargout>3 %added regression coefficients 10/23/05
  switch length(options.win)
    case 0 %non-windowed
      if isempty(filt) %1+order+Kp
        if isempty(options.s) %K
          reg = zeros(1,m);
        else
          reg = zeros(size(options.s,2)+1,m);
        end
      else
        if isempty(options.s) %K
          reg = zeros(size(filt,2)+1,m);
        else         %1+Ks+K+1 by M
          reg = zeros(size(filt,2)+size(options.s,2)+1,m);
        end
      end
    otherwise %windowed
      if isempty(filt) %1+order+Kp
        if isempty(options.s) %K
          reg = zeros(n,m);
        else
          reg = zeros(size(options.s,2)+1,n,m);
        end
      else
        if isempty(options.s) %K
          reg = zeros(size(filt,2)+1,n,m);
        else         %1+Ks+K+1 by M
          reg = zeros(size(filt,2)+size(options.s,2)+1,n,m);
        end
      end
  end
end
if nargout>4
  res = zeros(m,n)*NaN;
end

originalx = x;
switch length(options.win)
  case 0 %non-windowing approach
    if exist('optlsq2top','var')
      optlsq2top.initwt = optlsq2top.initwt(x.include{2});
    end
    switch lower(options.algorithm)
      case 'cls'
        switch lower(options.robust)
          case 'none'
            d   = spdiags(options.initwt,0,n,n);
            y   = d*x.data';
            xbase = d*[xref filt options.s]; clear d
          case 'lsq2top'
            xbase = [xref filt options.s];
        end
        for i=1:m
          switch lower(options.robust)
            case 'none'
              b   = emscorrinv(xbase(x.include{2},:),y(x.include{2},i),options.condnum);
            case 'lsq2top'
              % b       = lsq2top(xbase,x(:,i),0,options.res,optlsq2top); %5/8/06
              b   = lsq2top(xbase(x.include{2},:),x.data(i,x.include{2})',[],options.res,optlsq2top);
          end
          if isempty(options.s)
            fx(i,:) = (filt*b(2:end))';
          else
            fx(i,:) = (filt*b(2:end-ms))';
          end
          if strcmpi(options.mag,'yes')
            sx(i,:)   = (x.data(i,:) - fx(i,:))/b(1);
          else
            sx(i,:)   = x.data(i,:) - fx(i,:); %nbg /4/08/08
          end
          if nargout>3, reg(:,i) = b; end %nbg 10/23/05
          if nargout>4, res(i,x.include{2}) = (xbase(x.include{2},:)*b)' - x(i,x.include{2}); end %nbg 10/23/05
          if strcmpi(options.display,'on')
            waitbar(i/m,hwait);
          end
        end
      case 'ils'
        switch lower(options.robust)
          case 'none'
            d   = spdiags(options.initwt,0,n,n);
            y   = d*x.data';
            yref  = d*xref;
            xbase = d*[filt options.s]; clear d
          case 'lsq2top'
            xbase = [filt options.s];
        end
        for i=1:m
          switch lower(options.robust)
            case 'none'
              b   = emscorrinv([y(x.include{2},i) xbase(x.include{2},:)],yref(x.include{2}),options.condnum);
            case 'lsq2top'
              b   = lsq2top([x.data(i,x.include{2})' xbase(x.include{2},:)],xref(x.include{2}),[],options.res,optlsq2top); %5/8/06
          end
          if isempty(options.s)
            fx(i,:) = (filt*b(2:end))';
          else
            fx(i,:) = (filt*b(2:end-ms))';
          end
          if strcmpi(options.mag,'yes')
            sx(i,:) = x.data(i,:)*b(1) + fx(i,:);
          else
            sx(i,:) = x.data(i,:) + fx(i,:); %nbg 04/08/08
          end
          if nargout>3, reg(:,i)  = b; end %nbg 10/23/05
          if nargout>4, res(i,x.include{2}) = ([x.data(i,x.include{2})' xbase(x.include{2},:)]*b - xref(x.include{2}))'; end %nbg 10/23/05
          if strcmpi(options.display,'on')
            waitbar(i/m,hwait);
          end
        end
    end
    xref     = xref';
  case 1 %single window approach   %NOT DSO Compatible
    p  = (options.win-1)/2;
    x  = x.data';    %HARD EXTRACTION ignoring include field!
    sx = sx';
    fx = fx';
    switch lower(options.algorithm)
      case 'cls'
        switch lower(options.robust)
          case 'none'
            d   = spdiags(options.initwt,0,n,n);
            y   = d*x;
            xbase = d*[xref filt options.s]; clear d
          case 'lsq2top'
            xbase = [xref filt options.s];
        end
        switch lower(options.robust)
          case 'none'
            for i=1:m
              i1      = p+1;     %left side
              b       = emscorrinv(xbase(i1-p:i1+p,:),y(i1-p:i1+p,i),options.condnum);
              if isempty(options.s)
                fx(i1-p:i1,i)   = filt(i1-p:i1,:)*b(2:end);
              else
                fx(i1-p:i1,i)   = filt(i1-p:i1,:)*b(2:end-ms);
              end
              if strcmpi(options.mag,'yes')
                sx(i1-p:i1,i)   = (x(i1-p:i1,i) - fx(i1-p:i1,i))/b(1);
              else
                sx(i1-p:i1,i)   = x(i1-p:i1,i) - fx(i1-p:i1,i);
              end
              if nargout>3, reg(:,i1-p:i1,i) = b(:,ones(1,length(i1-p:i1))); end %nbg 10/23/05
              if nargout>4
                res(i,i1-p:i1) = (xbase(i1-p:i1,:)*b - x(i1-p:i1,i))';
              end %nbg 10/23/05
              i1      = n-p;     %right side
              b       = emscorrinv(xbase(i1-p:i1+p,:),y(i1-p:i1+p,i),options.condnum);
              if isempty(options.s)
                fx(i1-p:i1+p,i) = filt(i1-p:i1+p,:)*b(2:end);
              else
                fx(i1-p:i1+p,i) = filt(i1-p:i1+p,:)*b(2:end-ms);
              end
              if strcmpi(options.mag,'yes')
                sx(i1-p:i1+p,i) = (x(i1-p:i1+p,i) - fx(i1-p:i1+p,i))/b(1);
              else
                sx(i1-p:i1+p,i) = x(i1-p:i1+p,i) - fx(i1-p:i1+p,i);
              end
              
              if nargout>3, reg(:,i1-p:i1+p,i) = b(:,ones(1,length(i1-p:i1+p))); end %nbg 10/23/05
              if nargout>4
                res(i,i1-p:i1+p) = (xbase(i1-p:i1+p,:)*b - x(i1-p:i1+p,i))';
              end %nbg 10/23/05
              for i1=p+2:n-p-1   %middle
                b     = emscorrinv(xbase(i1-p:i1+p,:),y(i1-p:i1+p,i),options.condnum);
                if isempty(options.s)
                  fx(i1,i)      = filt(i1,:)*b(2:end);
                else
                  fx(i1,i)      = filt(i1,:)*b(2:end-ms);
                end
                if strcmpi(options.mag,'yes')
                  sx(i1,i)      = (x(i1,i) - fx(i1,i))/b(1);
                else
                  sx(i1,i)      = x(i1,i) - fx(i1,i);
                end
                if nargout>3, reg(:,i1,i) = b; end %nbg 10/23/05
                if nargout>4, res(i,i1) = (xbase(i1,:)*b - x(i1,i))'; end %nbg 10/23/05
              end
            end
          case 'lsq2top'
            for i=1:m
              i1      = p+1;     %left side
              optlsq2top.initwt = options.initwt(i1-p:i1+p,1);
              b       = lsq2top(xbase(i1-p:i1+p,:),x(i1-p:i1+p,i),[],options.res,optlsq2top); %5/8/06
              if isempty(options.s)
                fx(i1-p:i1,i)   = filt(i1-p:i1,:)*b(2:end);
              else
                fx(i1-p:i1,i)   = filt(i1-p:i1,:)*b(2:end-ms);
              end
              if strcmpi(options.mag,'yes')
                sx(i1-p:i1,i)   = (x(i1-p:i1,i) - fx(i1-p:i1,i))/b(1);
              else
                sx(i1-p:i1,i)   = x(i1-p:i1,i) - fx(i1-p:i1,i);
              end
              
              if nargout>3, reg(:,i1-p:i1,i) = b(:,ones(1,length(i1-p:i1))); end %nbg 10/23/05
              if nargout>4
                res(i,i1-p:i1) = (xbase(i1-p:i1,:)*b - x(i1-p:i1,i))';
              end %nbg 10/23/05
              i1      = n-p;     %right side
              b       = lsq2top(xbase(i1-p:i1+p,:),x(i1-p:i1+p,i),[],options.res,optlsq2top); %5/8/06
              if isempty(options.s)
                fx(i1-p:i1+p,i) = filt(i1-p:i1+p,:)*b(2:end);
              else
                fx(i1-p:i1+p,i) = filt(i1-p:i1+p,:)*b(2:end-ms);
              end
              if strcmpi(options.mag,'yes')
                sx(i1-p:i1+p,i) = (x(i1-p:i1+p,i) - fx(i1-p:i1+p,i))/b(1);
              else
                sx(i1-p:i1+p,i) = x(i1-p:i1+p,i) - fx(i1-p:i1+p,i);
              end
              
              if nargout>3, reg(:,i1-p:i1+p,i) = b(:,ones(1,length(i1-p:i1+p))); end %nbg 10/23/05
              if nargout>4
                res(i,i1-p:i1+p) = (xbase(i1-p:i1+p,:)*b - x(i1-p:i1+p,i))';
              end %nbg 10/23/05
              for i1=p+2:n-p-1   %middle
                optlsq2top.initwt = options.initwt(i1-p:i1+p,1);
                b     = lsq2top(xbase(i1-p:i1+p,:),x(i1-p:i1+p,i),[],options.res,optlsq2top); %5/8/06
                if isempty(options.s)
                  fx(i1,i)      = filt(i1,:)*b(2:end);
                else
                  fx(i1,i)      = filt(i1,:)*b(2:end-ms);
                end
                if strcmpi(options.mag,'yes')
                  sx(i1,i)      = (x(i1,i) - fx(i1,i))/b(1);
                else
                  sx(i1,i)      = x(i1,i) - fx(i1,i);
                end
                if nargout>3, reg(:,i1,i) = b; end %nbg 10/23/05
                if nargout>4, res(i,i1) = (xbase(i1,:)*b - x(i1,i))'; end
              end
            end
        end
      case 'ils'
        switch lower(options.robust)
          case 'none'
            d   = spdiags(options.initwt,0,n,n);
            y   = d*x;
            yref  = d*xref;
            xbase = d*[filt options.s]; clear d
          case 'lsq2top'
            xbase = [filt options.s];
        end
        switch lower(options.robust)
          case 'none'
            for i=1:m
              i1      = p+1;     %left side
              b       = emscorrinv([y(i1-p:i1+p,i),xbase(i1-p:i1+p,:)],yref(i1-p:i1+p,1),options.condnum);
              if isempty(options.s)
                fx(i1-p:i1,i)   = filt(i1-p:i1,:)*b(2:end);
              else
                fx(i1-p:i1,i)   = filt(i1-p:i1,:)*b(2:end-ms);
              end
              if strcmpi(options.mag,'yes')
                sx(i1-p:i1,i)   = x(i1-p:i1,i)*b(1) + fx(i1-p:i1,i);
              else
                sx(i1-p:i1,i)   = x(i1-p:i1,i) + fx(i1-p:i1,i);
              end
              if nargout>3, reg(:,i1-p:i1,i) = b(:,ones(1,length(i1-p:i1))); end %nbg 10/23/05
              if nargout>4
                res(i,i1-p:i1) = ([x(i1-p:i1,i) xbase(i1-p:i1,:)]*...
                  b - xref(i1-p:i1,1))';
              end %nbg 10/23/05
              i1      = n-p;     %right side
              b       = emscorrinv([y(i1-p:i1+p,i),xbase(i1-p:i1+p,:)],yref(i1-p:i1+p,1),options.condnum);
              if isempty(options.s)
                fx(i1-p:i1+p,i) = filt(i1-p:i1+p,:)*b(2:end);
              else
                fx(i1-p:i1+p,i) = filt(i1-p:i1+p,:)*b(2:end-ms);
              end
              if strcmpi(options.mag,'yes')
                sx(i1-p:i1+p,i) = x(i1-p:i1+p,i)*b(1) + fx(i1-p:i1+p,i);
              else
                sx(i1-p:i1+p,i) = x(i1-p:i1+p,i) + fx(i1-p:i1+p,i);
              end
              if nargout>3, reg(:,i1-p:i1+p,i) = b(:,ones(1,length(i1-p:i1+p))); end %nbg 10/23/05
              if nargout>4
                res(i,i1-p:i1+p) = ([x(i1-p:i1+p,i) xbase(i1-p:i1+p,:)]*...
                  b - xref(i1-p:i1+p,1))';
              end %nbg 10/23/05
              for i1=p+2:n-p-1   %middle
                b     = emscorrinv([y(i1-p:i1+p,i),xbase(i1-p:i1+p,:)],yref(i1-p:i1+p,1),options.condnum);
                if isempty(options.s)
                  fx(i1,i)      = filt(i1,:)*b(2:end);
                else
                  fx(i1,i)      = filt(i1,:)*b(2:end-ms);
                end
                if strcmpi(options.mag,'yes')
                  sx(i1,i)      = x(i1,i)*b(1) + fx(i1,i);
                else
                  sx(i1,i)      = x(i1,i) + fx(i1,i);
                end
                if nargout>3, reg(:,i1,i) = b; end %nbg 10/23/05
                if nargout>4
                  res(i,i1) = ([x(i1,i) xbase(i1,:)]*b - xref(i1,1))';
                end %nbg 10/23/05
              end
            end
          case 'lsq2top'
            for i=1:m
              i1      = p+1;     %left side
              optlsq2top.initwt = options.initwt(i1-p:i1+p,1);
              b       = lsq2top([x(i1-p:i1+p,i),xbase(i1-p:i1+p,:)],xref(i1-p:i1+p,1),[],options.res,optlsq2top); %5/8/06
              if isempty(options.s)
                fx(i1-p:i1,i)   = filt(i1-p:i1,:)*b(2:end);
              else
                fx(i1-p:i1,i)   = filt(i1-p:i1,:)*b(2:end-ms);
              end
              if strcmpi(options.mag,'yes')
                sx(i1-p:i1,i)   = x(i1-p:i1,i)*b(1) + fx(i1-p:i1,i);
              else
                sx(i1-p:i1,i)   = x(i1-p:i1,i) + fx(i1-p:i1,i);
              end
              if nargout>3, reg(:,i1-p:i1,i) = b(:,ones(1,length(i1-p:i1))); end %nbg 10/23/05
              if nargout>4
                res(i,i1-p:i1) = ([x(i1-p:i1,i) xbase(i1-p:i1,:)]*...
                  b - xref(i1-p:i1,1))';
              end %nbg 10/23/05
              i1      = n-p;     %right side
              optlsq2top.initwt = options.initwt(i1-p:i1+p,1);
              b       = lsq2top([x(i1-p:i1+p,i),xbase(i1-p:i1+p,:)],xref(i1-p:i1+p,1),[],options.res,optlsq2top); %5/8/06
              if isempty(options.s)
                fx(i1-p:i1+p,i) = filt(i1-p:i1+p,:)*b(2:end);
              else
                fx(i1-p:i1+p,i) = filt(i1-p:i1+p,:)*b(2:end-ms);
              end
              if strcmpi(options.mag,'yes')
                sx(i1-p:i1+p,i) = x(i1-p:i1+p,i)*b(1) + fx(i1-p:i1+p,i);
              else
                sx(i1-p:i1+p,i) = x(i1-p:i1+p,i) + fx(i1-p:i1+p,i);
              end
              if nargout>3, reg(:,i1-p:i1+p,i) = b(:,ones(1,length(i1-p:i1+p))); end %nbg 10/23/05
              if nargout>4
                res(i,i1-p:i1+p) = ([x(i1-p:i1+p,i) xbase(i1-p:i1+p,:)]*...
                  b - xref(i1-p:i1+p,1))';
              end %nbg 10/23/05
              for i1=p+2:n-p-1   %middle
                optlsq2top.initwt = options.initwt(i1-p:i1+p,1);
                b     = lsq2top([x(i1-p:i1+p,i),xbase(i1-p:i1+p,:)],xref(i1-p:i1+p,1),[],options.res,optlsq2top); %5/8/06
                if isempty(options.s)
                  fx(i1,i)      = filt(i1,:)*b(2:end);
                else
                  fx(i1,i)      = filt(i1,:)*b(2:end-ms);
                end
                if strcmpi(options.mag,'yes')
                  sx(i1,i)      = x(i1,i)*b(1) + fx(i1,i);
                else
                  sx(i1,i)      = x(i1,i) + fx(i1,i);
                end
                if nargout>3, reg(:,i1,i) = b; end %nbg 10/23/05
                if nargout>4
                  res(i,i1) = ([x(i1,i) xbase(i1,:)]*b - xref(i1,1))';
                end %nbg 10/23/05
              end
            end
        end
    end
    sx = sx';
    fx = fx';
    xref = xref';
    %case 2 %double window approach
    %  disp('Double Window Approach Not Yet Available.')
  otherwise
    disp('Input options.window must be empty or scalar.')
    %  disp('Input options.window must be empty, scalar, or 2-element vector only.')
end
if strcmpi(options.display,'on')
  close(hwait), clear hwait
end
if ~isdataset(sx) & wasdso
  %if we had to extract from a dataset, re-assign it back to a DSO now.
  temp = sx;
  sx = originalx;
  sx.data = temp;
end

function b = emscorrinv(x,y,condnum)
%EMSECORRINV
[x,nx]  = normaliz(x');
[u,s,v] = svd(x*x'); s = diag(s);      clear u
s(s/s(1)<condnum)      = s(1)*condnum;
b       = diag(1./nx)*v*diag(1./s)*v'*x*y;

%--------------------------
function out = optiondefs

defs = {
  %name                    tab           datatype        valid                            userlevel       description
  'display'                'Display'      'select'        {'off' 'on'}                    'novice'        'Governs level of display to command window.'
  'order'                  'Settings'     'double'        'int(0:6)'                      'novice'        'Order of polynomial filter (0<=order<=6).'
  'logax'                  'Settings'     'select'        {'no' 'yes'}                    'intermediate'  'Use log of x.axisscale{2} as part of the filter?'
  'p'                      'Settings'     'matrix'        []                              'novice'        'Kp by N spectra to filter out (N is number of variables).';
  's'                      'Settings'     'matrix'        []                              'novice'        'K by N spectra to NOT filter out.';
  'win'                    'Settings'     'double'        'int(1:inf),odd'                'intermediate'  'An odd scalar that defines the window width (number of variables) for piece-wise correction. If empty, piece-wise correction is not used.'
  'xrefS'                  'Settings'     'select'        {'no' 'yes'}                    'advanced'      'Indicates whether (xref) includes spectra contained in the s option (options.s). If ''yes'' then the spectra in options.s are centered and an SVD estimate of options.s is used in EMSCORR.';
  'algorithm'              'Algorithm'    'select'        {'cls' 'ils'}                   'intermediate'  'Defines correction model method.  ''cls'' uses Classical Least Squares i.e. EMSC, ''ils'' uses Inverse Least Squares i.e. IEMSC.'
  'initwt'                 'Algorithm'    'vector'        []                              'advanced'      'Empty or Nx1 vector of initial weights (0<=w<=1). Low weights are used for channels not to be included in the fit.';
  'condnum'                'Algorithm'    'double'        []                              'advanced'      'Condition number for x''*x used in the least squares estimates.';
  'robust'                 'Algorithm'    'select'        {'none' 'lsq2top'}              'intermediate'  'Governs the use of robust least squares. if ''lsq2top'' is used then "trbflag", "tsqlim", and "stopcrit" are also used (see LSQ2TOP for descriptions of these fields).';
  'res'                    'Algorithm'    'double'        []                              'intermediate'  'Scalar required when "robust" is "lsq2top". Input to LSQ2TOP function.';
  'trbflag'                'Algorithm'    'select'        {'top' 'bottom' 'middle'}       'intermediate'  'Used only with "lsq2top" robust least squares mode. Defines if robust least squares is done to top, bottom, or middle of the data.';
  'tsqlim'                 'Algorithm'    'double'        'float(0:1)'                    'intermediate'  'T-squared limit used only with "lsq2top" robust least squares mode.';
  'stopcrit'               'Algorithm'    'vector'        []                              'intermediate'  'Stopping criteria used only with "lsq2top" robust least squares mode.';
  'mag'                    'Algorithm'    'select'        {'yes' 'no'}                    'advanced'      'Use Multiplicative Correction?'
  };
out = makesubops(defs);

