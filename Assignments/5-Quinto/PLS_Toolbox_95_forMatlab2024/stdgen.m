function [stdmat,stdvect] = stdgen(spec1,spec2,win,options)
%STDGEN Piecewise and direct standardization transform generator.
%  Generates direct or piecewise direct standardization matrix with or without
%  additive background correction using the "double window" method based
%  on spectra from two instruments, or original calibration spectra and
%  drifted spectra from a single instrument.
%  INPUTS:
%    spec1 = M by N1 spectra from the standard instrument, and
%    spec2 = M by N2 spectra from the instrument to be standarized.
%
%  OPTIONAL INPUTS:
%      win = empty [], or a 1 or 2 element vector.
%            If (win) is a scalar then STDGEN uses a single window algorithm,
%            and if (win) is a 2 element vector it uses a double window algorithm.
%            win(1) = (odd) is the number of channels to be used for each transform, and
%            win(2) = (odd) is the number of channels to base the transform on.
%            If (win) is not input it is set to zero and direct standardization is used.
%  options = structure array with the following fields:
%   waitbar: ['off' | {'on'}]  governs display of waitbar.
%       tol: tolerance used in forming local models (it equals the minimum
%            relative size of singular values to include in each model)
%            {default: tol=0.0001}, and
%     maxpc: specifies the maximum number of PCs to be retained for each
%            local model {default: []}. (maxpc) must be <= the number of
%            transfer samples or when using double window <= to the number of transfer
%            samles times the second window width. If (maxpc) is not empty it supersedes (tol).
%
%  OUTPUTS:
%   stdmat = the transform matrix, and
%  stdvect = the additive background correction.
%  Note: if only one output argument is given, no background correction is used.
%
%I/O: [stdmat,stdvect] = stdgen(spec1,spec2,win,options);
%I/O: stdgen demo
%
%See also: ALIGNPEAKS, ALIGNSPECTRA, BASELINE, CALTRANSFER, DERESOLV, DISTSLCT, MSCORR, REDUCENNSAMPLES, REGISTERSPEC, STDFIR, STDIZE, STDSSLCT

%Copyright Eigenvector Research, Inc. 1994
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw
%Modified BMW 10/95,10/98,3/98, 1/99 - tolerance check
%Modified ns BMW 10/95, 7/96, 3/98
%modified nbg 03/02 to added non-square, combined w/ dw, standardized I/O
%Old I/O  [stdmat,stdvect] = stdgen(spec1,spec2,win,tol,maxpc);
%jms 4/25/02 debugged opts code, modified string-input logic
%nbg 11/17/03 found bug changed to use mean centered mspec!
%rsk 06/07/06 update i/o.
%nbg 08/14/08 added options.display, added if nargin<4
%jms -renamed display to 'waitbar'
%bmw 06/14/19 fixed error trap for maxpcs to work with double window

if nargin == 0
  spec1 = 'io';
end

if ischar(spec1);
  options = [];
  options.name        = 'options';
  options.waitbar     = 'on';
  options.tol         = 0.0001;
  options.maxpc       = [];
  options.definitions = @optiondefs;
  if nargout==0; clear stdmat; evriio(mfilename,spec1,options); else
                 stdmat = evriio(mfilename,spec1,options); end
  return;
end

if nargin<2
  error('STDGEN requires at least 2 inputs.')
end
if nargin<4               %set default options
  options  = [];
end
options = reconopts(options,mfilename,{'win'});

%Check for valid data.
if isa(spec1,'dataset')
  i1 = spec1.includ{1};
else
  i1 = 1:size(spec1,1);
end
if isa(spec2,'dataset')
  i2 = spec2.includ{1};
else
  i2 = 1:size(spec2,1);
end
if length(i1)~=length(i2) || length(i1)~=length(intersect(i1,i2))
  warning('EVRI:IncludeIntersect','Samples included in data sets do not match. Using intersection.')
  i1 = intersect(i1,i2);
  i2 = i1;
end
%index into spec1 and spec2 as indicated by include
spec1 = nindex(spec1,i1,1);
spec2 = nindex(spec2,i2,1);
if isa(spec1,'dataset')
  i     = spec1.include;
  spec1 = spec1.data(i{:});
end
if isa(spec2,'dataset')
  i     = spec2.include;
  spec2 = spec2.data(i{:});
end
[ms,ns]   = size(spec1);
[ms2,ns2] = size(spec2);
if ms ~= ms2
  error('Both spectra must have the same number of samples')
end

%Check 3rd input.
if nargin<3
  win = 0;
elseif isempty(win)
  win = 0;
end

if prod(size(win))>2
  error('Size of (win) must be scalar or 2 element vector.')
end

if win(1)>0
  if floor(win(1)/2)==win(1)/2
    error('The number of channels in each window should be odd.')
  end
end
if length(win)>1
  if win(2)>0
    if floor(win(2)/2)==win(2)/2
      error('The number of channels in both windows should be odd.')
    end
  end
end

%Assign options.
maxpc = options.maxpc;
tol   = options.tol;
if isempty(maxpc)
  maxpc = ms;
end

%Check options.  Changed by BMW 6/14/19
if length(win) < 2
  if maxpc>ms
    error('Input (options.maxpc) must be <= number of samples (rows).')
  end
else
  if maxpc>(ms*win(2))
    error('Input (options.maxpc) must be <= number of samples times win(2)')
  end
end    
    
if tol>1
  error('Input (options.tol) must be <= 1')
end

%Start calculation.
if nargout==2
  [mspec1,mns1] = mncn(spec1);
  [mspec2,mns2] = mncn(spec2);
else
  mspec1 = spec1;
  mspec2 = spec2;
end
clear spec1 spec2

starttime = now;
switch length(win)
  case 1   %single window transform generator
    if ns==ns2   %square transform
      if win==0  %direct transform
        if ms<=ns
          [u,s,v] = svd(mspec2',0);
          if nargout==2
            s     = inv(s(1:ms-1,1:ms-1));
            invs  = zeros(ms,ms);
            invs(1:ms-1,1:ms-1) = s;
          else
            invs  = inv(s);
          end
          spec2inv = u*invs*v';
        else
          spec2inv = pinv(mspec2);
        end
        stdmat    = spec2inv*mspec1;
      else           %piece-wise direct transform
        winm = floor(win/2)+1;
        rin = 1:ns; cin = 1:ns;      % Diagonal index numbers
        for i = 2:winm
          rin = [rin i:ns];          % below diagonal
          cin = [cin 1:ns-i+1];
          rin = [rin 1:ns-i+1];      % above diagonal
          cin = [cin i:ns];
        end
        stdmat = sparse(rin,cin,zeros(size(rin)),ns,ns);
        ind1   = floor(win/2);
        ind2   = win-ind1-1;
        if strcmpi(options.waitbar,'on')
          hwait = waitbar(0,'STDGEN Working on Transform');
        end
        for i=1:ns
          if i <= ind1
            xspec2 = mspec2(:,1:i+ind2);
            wind = i+ind2;
          elseif i >= ns-ind2+1
            xspec2 = mspec2(:,i-ind1:ns);
            wind = ns-i+ind1+1;
          else
            xspec2 = mspec2(:,i-ind1:i+ind2);
            wind = win;
          end
          [u,s,v] = svd(xspec2'*xspec2);
          % For a relative tolerence use this:
          %sinds = size(find((s(1,1)*ones(wind,1))./diag(s) < (1/tol))); BMW 1/99
          sinds = size(find( diag(s)./(s(1,1)*ones(wind,1)) > tol ));
          sinds = sinds(1);
          % For an absolute tolerance use this:
          %sinds = size(find(diag(s)>tol));
          %sinds = max([sinds(1) 1]);
          if sinds > maxpc
            sinds = maxpc;
          end
          sinv = zeros(size(s));
          sinv(1:sinds,1:sinds) = inv(s(1:sinds,1:sinds));
          %mod = u*sinv*v'*xspec2'*spec1(:,i); %nbg 11/17/03 comment out
          mod = u*sinv*v'*xspec2'*mspec1(:,i);
          if i <= ind1
            stdmat(1:i+ind2,i) = mod;
          elseif i >= ns-ind2+1
            stdmat(i-ind1:ns,i) = mod;
          else
            stdmat(i-ind1:i+ind2,i) = mod;
          end
          if strcmpi(options.waitbar,'on')
            if floor(i/10)==i/10
              waitbar(i/ns,hwait)
              set(hwait,'name',['STDGEN Est. time remaining ' besttime((ns-i)*(now-starttime)/i*60*60*24)]);
              drawnow;
            end
          end
        end
        if strcmpi(options.waitbar,'on')
          close(hwait)
        end
      end
      if nargout == 2
        stdvect = (mns1' - stdmat'*mns2')';
      end
    else %non-square transform
      if win==0   %direct
        [u,s,v] = svd(mspec2',0); %nbg 11/18/03 change to mspec2
        if nargout==2
          s = inv(s(1:ms-1,1:ms-1));
          invs = zeros(ms,ms);
          invs(1:ms-1,1:ms-1) = s;
        else
          invs = inv(s);
        end
        spec2inv = u*invs*v';
        stdmat = spec2inv*mspec1; %nbg 11/18/03 change to mspec1
      else
        winm = floor(win/2)+1;
        if ns2 == ns      % Diagonal index numbers
          rin = 1:ns; cin = 1:ns;
          for i = 2:winm
            rin = [rin i:ns];          % below diagonal
            cin = [cin 1:ns-i+1];
            rin = [rin 1:ns-i+1];      % above diagonal
            cin = [cin i:ns];
          end
        else
          cin   = 1:ns; rin = round(rescale([0:ns-1]',1,(ns2-1)/(ns-1))');
          for i=2:winm
            z   = find(rin(1:ns)<ns2+2-i);      % Add elements below diagonal
            cin = [cin z];
            rin = [rin rin(z)+(i-1)];
            z   = find(rin(1:ns)>i-1);          % Add elements above diagonal
            cin = [cin z];
            rin = [rin rin(z)-(i-1)];
          end
        end
        stdmat = sparse(rin,cin,ones(size(rin)),ns2,ns);
        ind1   = floor(win/2);
        ind2   = win-ind1-1;
        if strcmpi(options.waitbar,'on')
          hwait  = waitbar(0,'STDGEN Working on Transform');
        end
        for i=1:ns
          spec2inds   = find(stdmat(:,i));
          [wind,z]    = size(spec2inds);
          xspec2      = mspec2(:,spec2inds); %nbg 11/17/03 change to mspec2
          [u,s,v]     = svd(xspec2'*xspec2);
          [mzns,nzns] = size(find(diag(s)));
          sinds       = size(find(diag(s) > tol));
          sinds       = max([sinds(1) 1]);
          if sinds > maxpc
            sinds     = maxpc;
          end
          npcs(i)     = sinds;
          sinv        = zeros(size(s));
          sinv(1:sinds,1:sinds) = inv(s(1:sinds,1:sinds));
          mod         = u*sinv*v'*xspec2'*mspec1(:,i); %nbg 11/17/03 change to mspec1
          stdmat(spec2inds,i) = mod;
          if strcmpi(options.waitbar,'on')
            if floor(i/10)==i/10
              waitbar(i/ns,hwait)
              set(hwait,'name',['STDGEN Est. time remaining ' besttime((ns-i)*(now-starttime)/i*60*60*24)]);
              drawnow;
            end
          end
        end
        if strcmpi(options.waitbar,'on')
          close(hwait)
        end
      end
      if nargout == 2
        stdvect = (mns1' - stdmat'*mns2')';
      end
    end
  case 2  %double window
    winm     = floor(win(1)/2)+1;
    % Diagonal index numbers
    if ns2==ns                     %stdmat is square
      rin    = 1:ns;
      cin    = 1:ns;
      for ii=2:winm
        rin  = [rin ii:ns];        % below diagonal
        cin  = [cin 1:ns-ii+1];
        rin  = [rin 1:ns-ii+1];    % above diagonal
        cin  = [cin ii:ns];
      end
    else                           %stdmat is non-square
      rin    = round(rescale([0:ns-1]',1,(ns2-1)/(ns-1))');
      cin    = 1:ns;
      for ii=2:winm
        z    = find(rin(1:ns)<ns2+2-ii);  % below diagonal
        cin  = [cin z];
        rin  = [rin rin(z)+ii-1];
        z    = find(rin(1:ns)>ii-1);      % above diagonal
        cin  = [cin z];
        rin  = [rin rin(z)-ii+1];
      end
    end
    stdmat   = sparse(rin,cin,ones(size(rin)),ns2,ns);

    b        = win(2);
    b2       = floor(win(2)/2);
    if strcmpi(options.waitbar,'on')
      hwait    = waitbar(0,'STDGEN Generating Double Window Transform');
    end
    for ii=1:ns
      s2inds    = find(stdmat(:,ii));
      a         = length(s2inds);
      if s2inds(end)+b2>ns2           %on right hand side
        if s2inds(end)==ns2             %take samples just to left
          x     = zeros((b2+1)*ms,a);
          y     = zeros((b2+1)*ms,1);
          for ij=1:b2+1
            x((ij-1)*ms+1:ij*ms,:) = mspec2(:,s2inds-ij+1); %nbg 11/17/03 change to mspec2
            y((ij-1)*ms+1:ij*ms,:) = mspec1(:,ii-ij+1); %nbg 11/17/03 change to mspec1
          end
        else                            %take samples to left and a few on right
          x     = zeros((b2+1+ns2-s2inds(end))*ms,a);
          y     = zeros((b2+1+ns2-s2inds(end))*ms,1);
          for ij=1:b2+1+ns2-s2inds(end)
            x((ij-1)*ms+1:ij*ms,:) = mspec2(:,s2inds-ij+1+ns2-s2inds(end)); %nbg 11/17/03 change to mspec2
            y((ij-1)*ms+1:ij*ms,:) = mspec1(:,ii-ij+1+ns2-s2inds(end)); %nbg 11/17/03 change to mspec1
          end
        end
      elseif s2inds(1)-b2<1           %on left hand size
        if s2inds(1)==1                 %take samples just to right
          x     = zeros((b2+1)*ms,a);
          y     = zeros((b2+1)*ms,1);
          for ij=1:b2+1
            x((ij-1)*ms+1:ij*ms,:) = mspec2(:,s2inds+ij-1); %nbg 11/17/03 change to mspec2
            y((ij-1)*ms+1:ij*ms,:) = mspec1(:,ii+ij-1); %nbg 11/17/03 change to mspec1
          end
        else                            %take samples to right and a few on left
          x     = zeros((b2+s2inds(1))*ms,a);
          y     = zeros((b2+s2inds(1))*ms,1);
          for ij=1:b2+s2inds(1)
            x((ij-1)*ms+1:ij*ms,:) = mspec2(:,s2inds+ij-s2inds(1)); %nbg 11/17/03 change to mspec2
            y((ij-1)*ms+1:ij*ms,:) = mspec1(:,ii+ij-s2inds(1)); %nbg 11/17/03 change to mspec1
          end
        end
      else                            %in middle
        x       = zeros(b*ms,a);
        y       = zeros(b*ms,1);
        for ij=1:b %-b2:b2
          x((ij-1)*ms+1:ij*ms,:) = mspec2(:,s2inds+ij-1-b2); %nbg 11/17/03 change to mspec2
          y((ij-1)*ms+1:ij*ms,:) = mspec1(:,ii+ij-1-b2); %nbg 11/17/03 change to mspec1
        end
      end

      [nw,mw]   = size(x);
      [u,s,v]   = svd(x'*x);
      [mss,nss] = size(diag(s));
      % For a relative tolerence use this:
      sinds     = size(find((s(1,1)*ones(mw,1))./diag(s) < (1/tol)));
      sinds     = sinds(1);
      % For an absolute tolerance use this:
      %sinds = size(find(diag(s) > tol));
      %sinds = max([sinds(1) 1]);
      if sinds > maxpc
        sinds   = maxpc;
      end
      sinv      = zeros(size(s));
      sinv(1:sinds,1:sinds) = inv(s(1:sinds,1:sinds));
      mod       = u*sinv*v'*x'*y;
      stdmat(s2inds,ii) = mod;
      if strcmpi(options.waitbar,'on')
        if floor(ii/10)==ii/10
          waitbar(ii/ns,hwait)
          set(hwait,'name',['STDGEN Est. time remaining ' besttime((ns-ii)*(now-starttime)/ii*60*60*24)]);
          drawnow;
        end
      end
    end
    if nargout >= 2
      stdvect = (mns1' - stdmat'*mns2')';
    end
    if strcmpi(options.waitbar,'on')
      close(hwait)
    end
  otherwise
    error('Input window (win) not recognized.')
end

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid            userlevel       description
'tol'                    'Local Models'   'double'        'float(1:inf)'   'novice'        '[ 0.01 ] Tolerance used in forming local models (it equals the minimum relative size of singular values to include in each model)';
'plots'                  'Local Models'   'double'         'int(1:inf)'    'novice'        '[ ] Specifies the maximum number of PCs to be retained for each local model. (maxpc) must be <= the number of transfer samples. If (maxpc) is not empty it supersedes (tol).';
};

out = makesubops(defs);
