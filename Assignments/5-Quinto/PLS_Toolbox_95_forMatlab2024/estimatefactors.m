function S = estimatefactors(x,options,varargin)
%ESTIMATEFACTORS Estimate number of significant factors in multivariate data.
% Given a bilinear dataset, ESTIMATEFACTORS estimates the number of
% significant factors required to describe the data. The algorithm uses PCA
% bootstrapping (resampling) of the data. The PCA loadings determined for
% each resampling are compared for changes. Principal components which
% change significantly from one resampling to the next are probably due
% mostly to noise rather than signal.
%
% The output is an estimate of the signal to noize ratio for each principal
% component. Ratios of 2 or below are dominated by noise, above 3 are OK,
% and between 2 and 3 are a judgment call. The number of factors needed to
% describe the data is the number of eigenvectors with signal to noise
% ratios greater than about 2.
%
% INPUTS:
%   x = the data to analyze
% OPTIONAL INPUT:
%   options = an option structure containing one or more of the following:
%             plots: [ 'none' |{'final'}] governs plotting
%          resample: [{42}] number of times the data is to be resampled
%                     Generally, values of 40 or 50 are sufficient. Values
%                     greater than several hundred are not required.
%        maxfactors: [{30}] maximum number of factors to plot (if plots are
%                     selected by options.plots). 
%     preprocessing: { [] } preprocessing structure (see PREPROCESS) to
%                     apply before analyzing data.
% OUTPUT: 
%   S = an estimate of the signal to noise ratio for each eigenvector.
%
% This function is based on an algorithm developed and Copyrighted 1997-2006 by
% Ronald C. Henry, Eun Sug Park, and Clifford H. Spiegelman and used by
% permission of the authors. For reference see:
% * Henry, R.C., Park, E.S., & Spiegelman, C.H. (1999). Comparing A New
%   Algorithm With The Classic Methods For Estimating The Number Of
%   Factors. Chemometrics and Intelligent Laboratory Systems, 48(1), 91-97.
% * Park, E.S., Henry, R.C., & Spiegelman C.H. (2000). Estimating The
%   Number Of Factors To Include In A Height Dimensional Multivaraite
%   Bilinear Model.  Communications in Statistics-Theory and Methods, 29(3),
%   723-746.
%
%I/O: S = estimatefactors(x,options)
%
%See also: PCA, PCAENGINE

%Copyright Eigenvector Research, Inc. 1995
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
% See additional Copyright noitices in subroutine
%
% JMS

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.plots = 'final';
  options.resample = 42;
  options.maxfactors = 30;
  options.preprocessing = {[]};
  if nargout==0; evriio(mfilename,x,options); else; S = evriio(mfilename,x,options); end
  return;
end

if nargin>2
  if isstr(options)
    %create structure from all the remaining inputs
    options = struct(options,varargin{:});
  else
    error('Too many arguments')
  end
end
if nargin<2
  options = [];
end
options = reconopts(options,mfilename);

if ndims(x)>2
  error(['Input data must be 2-way. The supplied data is ' num2str(ndims(x)) '-way.'])
end

%make sure we've got a dataset object
if ~isa(x,'dataset');
  x = dataset(x);
end

%do preprocessing, if any is indicated in options
if ~isempty(options.preprocessing{1})
  x = preprocess('calibrate',options.preprocessing{1},x);
end
  
incl = x.include;

% Update incl if preprocessing includes holoreact
if ~isempty(options.preprocessing{1})
  ppx    = options.preprocessing{1};
  indexH = strfind({ppx.keyword}, 'spectraquant');
  indH    = find(not(cellfun('isempty', indexH)));
  sqf = false;  % jmbrown addition
  if ~isempty(indH)
    if ~isempty(ppx(indH).userdata)
      if isfield(ppx(indH).userdata, 'functionname') & strcmp(ppx(indH).userdata.functionname, 'sqfilter')
        sqf = true;
        reg = ppx(indH).userdata.regions;
        nreg = size(reg,1);
        incl{2} = min(reg(1,:)):max(reg(1,:));
        for i=2:nreg
          incl{2} = [incl{2}, min(reg(i,:)):max(reg(i,:))];
        end
      end
    end
  end
end

% Remove columns with near zero variance
if ~sqf
    x = adjustconstantcolumns(x, incl);
else
    % jmbrown addition
    x = x.data(incl{:});
end

%do the actual call to the calculation subroutine
S = numfactnew(x,options.resample,sqf);

if strcmp(options.plots,'final')
  figure
  Ssub = S(1:min(end,options.maxfactors));
  nf = length(Ssub);
  good  = find(Ssub>=3);
  maybe = find(Ssub>=2 & Ssub<3);
  bad   = find(Ssub<2);
  h = semilogy(1:nf,Ssub,'-',good,S(good),'g.',maybe,S(maybe),'b.',bad,S(bad),'r.');
  set(h,'markersize',20)
  hline(2,'r')
  hline(3,'g');
  ylabel('Estimated Signal to Noise')
  xlabel('Factor number')
end


%-------------------------------------------------------------
% the following is the actual calculation routine supplied by Cliff
% Spiegelman. It is isolated here to allow easier updating by the original
% authors.
% The following modifications were performed:
%   JMS 3/29/06 
%     -The display of "transposed" was removed (no display permitted)
%     -A waitbar was added to inform the user of the progress
%   
%-------------------------------------------------------------
function [S,W] = numfactnew(c,N,sqf) % jmbrown addition of sqf

% c contains the data, if the number of rows is less than the number of
% columns, the data matrix is transposed automatically.
% N is the number of times the data is resampled.  Generally values of
% 40 or 50 are sufficient; values greater than several hundred are not required.
% the output is an estimate of the signal to noise ratio for each
% eigenvector. Values of 2 or below are dominated by noise, values above 3 are
% OK, values between 2 and 3 are a jugement call.
% The number of factors is the number of eigenvectors with signal to noise
% ratios greater than about 2.
%
% The user is free to copy and distribute this function
% as long as it is not modified and the following copyright
% notification is not removed
% Copyright 1997 by Ronald C. Henry, Eun Sug Park, and Clifford H. Spiegelman.


if nargin>3
  error('Too many arguments')
end

if nargin ==1   %N=42 default added July 24, 1995
  N=42;
end;
[n p]=size(c)   ;%get number of rows n and number of cols p

if ~sqf
  if n < p,       ;%assume n>p if not transpose
    c=c'; [n p]=size(c);
    message='transposed';    % ; at end ***--added by JMS
  end
else
  % jmbrown addition
  c = c'; [n p]=size(c);
  message='transposed';
end

[u ws v0]=svd(corrcoef(c),0);   ;%get svd of the correlation matrix
ws=diag(ws);

rs=n;                           ;%set the resample rate to 1

astn=zeros(p,1);bstn=astn;              ;%initialize the variables
o1=ones(p,1);

wbh = waitbar(0,'Analyzing number of factors...');  %***--added by JMS
starttm = now;  %***--added by JMS
for i= 1:N                      ;%start the loop

  sel=round((n-1)*rand(1,rs))+1   ;%select resample

  [u d v1]=svd(corrcoef(c(sel,:)),0);     ;%do svd of resampled data

  sig=(v0'*v1);% Projection of new eigenvectors onto old ones.

  sig=diag(cumsum(sig.*sig));sig(p)=0;
  astn=astn+sig;
  bstn=bstn+(o1-sig);

  %***--added by JMS
  if ishandle(wbh);
    progress = i/N;
    waitbar(progress);
    esttm  = ((now-starttm)/progress)*(1-progress)*60*60*24;
    set(wbh,'name',['Est. Time Remaining ' besttime(ceil(esttm))]);
  else
    error('Calculation cancelled by user...');
  end
  %***--end of JMS addition

end;;%end of the loop
if ishandle(wbh); close(wbh); end %***--added by JMS

W=astn./bstn;

astn=sqrt(astn./bstn);
sig=ws.*astn./(1+astn);
noise=ws./(1+astn);
noise=sum(noise(1:p-1))/(p-1);
sn=sig/noise;
S=sn;

%--------------------------------------------------------------------------
function x = adjustconstantcolumns(x, incl)
% Ensure x has no columns of near zero variance (after possible transpose 
% of x if necessary to make x tall and narrow, nrows > ncolumns).
% Return x as matrix

% Ensure x is tall and narrow
x = x.data(incl{:});
[n p]=size(x)   ;%get number of rows n and number of cols p
if n < p,       ;%assume n>p if not transpose
  x=x'; [n p]=size(x);
end

% Remove columns which have near zero variance to avoid NaNs output from corrcoef
stdx = std(x);
igoodcols = find(stdx > 1.e-7*mean(stdx(~isnan(stdx))));
x = x(:, igoodcols);