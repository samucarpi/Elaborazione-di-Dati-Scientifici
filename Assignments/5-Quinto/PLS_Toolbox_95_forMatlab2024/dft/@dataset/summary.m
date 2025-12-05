function summ = summary(varargin)
%SUMMARY Summary statistics for a data vector.
%  The input is a data matrix (x) (numeric or DataSet object) and the
%  output is a DataSet object array with the following statistics reported
%  as rows for each column of x:
%    mean  = mean,
%    std   = standard deviation,
%    min   = minimum,
%    max   = maximum,
%    p10   = 10th percentile,
%    p25   = 25th percentile,
%    p50   = 50th percentile,
%    p75   = 75th percentile,
%    p90   = 90th percentile,
%    skew  = skewness,
%    kurt  = kurtosis.
%
%  If input x is a multi-dimensional array, the output contains the above
%  statistics for each multi-dimensional column of the array (the result
%  will have the same dimensions on modes 2-n where n = number of modes in
%  x) If summary is called without setting a return value it prints a
%  summary table of up to 20 columns (default), or up to number specified
%  by second input parameter, out to the command window.
%
%I/O: summ = summary(x);     % returns struct
%I/O:        summary(x);     % prints summary text, for up to 20 columns
%I/O: text = summary(x, n);  % returns summary as text, for up to n cols
%I/O:        summary(x, n);  % prints summary text, for up to n columns
%
%See also: MEANS, PCTILE1, PCTILE2

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin<1
  x = 'io';
  options = [];
  if nargout==0; clear summ; evriio(mfilename,x,options); else; summ = evriio(mfilename,x,options); end
  return;
end

if nargin == 1 & ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics')) %Help, Demo, Options
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

switch nargin
  case 1
    x = varargin{1};
    vec = 20;   % default max number of columns to print
  case 2
    % (x, n)
    x = varargin{1};
    vec = varargin{2};
end

if ~isdataset(x)
  x = dataset(x);
end
if nargout==0 | (nargout==1 & nargin==2)
  %if we will be displaying or sending back limited text results,
  %limit x to only those columns we care about (speeds up for text display)
  x = subsref(x,substruct('()',{':',1:min(size(x.data,2),vec)}));  
end
sz   = size(x);
incl = x.include;
xd   = x.data(incl{1},:);  %apply include field (and reshape into matrix if n-way)

%get missing data map
[fmiss,mmap] = mdcheck(xd);
if fmiss==0
  %no missing or inf - do all at once
  [summ,statorder] = calcstats(xd);
else
  %Some missing/nan? do in groups based on which rows are missing
  [mptrn,inds,minds] = unique(mmap','rows');  %identify patterns of missing data
  mptrn = ~mptrn; %invert map logic (so true==not missing)
  [summ,statorder] = calcstats(xd(mptrn(1,:),minds==1));  %first pattern done "manually"
  if length(inds)>1
    %more than one missing data pattern?
    summ(:,minds==1) = summ;  %re-arrange to put columns into correct places 
    %(this approach allows pre-allocation of summ without knowing # of
    %stats we'll get even if calcstats changes)
    if size(summ,2)<size(xd,2);
      summ(end,size(xd,2)) = 0;  %expand to appropriate # of columns
    end
    %do all the other column patterns
    for p = 2:length(inds);
      if ~all(mptrn(p,:)==0)
        summ(:,minds==p) = calcstats(xd(mptrn(p,:),minds==p));
      end
    end
  end
end
  
%build DSO of results
summ = dataset(summ);
summ.label{1,1,1} = char(statorder);
summ.label{1,2,1} = 'Statistics';
summ.title{1} = 'Summary Statistics';

if length(sz)>2
  %multiway - reshape to n-way now
  summ = reshape(summ,[size(summ,1) sz(2:end)]);
end
%copy labels from other mode(s)
for i=2:length(sz);
  summ = copydsfields(x,summ,i);
end

if nargout==0
  printsummary(summ, vec);          % case B or C: output string
  clear summ;
elseif nargout==1 & nargin==2
  summ = printsummary(summ, vec);   % case D
end

%------------------------------------------------------------------------
function [summ,statorder] = calcstats(x)

rvones = ones(1,size(x,2));
mn   = mean(x,1) ;
stdv = std(x,[],1) ;
N    = size(x,1)*rvones ;
minx = min(x,[],1) ;
maxx = max(x,[],1) ;
p    = pctile1(x,[10 25 50 75 90]) ;
skew = skewness(x);
kurt = kurtosis(x);

if size(x,1)==1
  summ = [mn; stdv; N; minx; maxx; repmat(x,5,1); rvones*0; rvones*0];
else
  summ = [mn; stdv; N; minx; maxx; p; skew; kurt];
end

statorder = {'mean','std','n','min','max',...
  'p10','p25','p50','p75','p90',...
  'skew','kurt'};


%------------------------------------------------------------------------
function textout = printsummary(summ, maxcols)
% print up to maxcols cols
if ndims(summ)>2
  summ = summ(:,:);  %unfold if n-way
end
ncols = min(size(summ,2), maxcols);
fldnames = summ.label{1};

textout = {'----------------Summary-------------'};
if ~isempty(summ.label{2})
  %display labels, if present.
  line = {'Label  '};
  for j=1:ncols
    line{end+1} = sprintf('<%10.10s>', strtrim(summ.label{2}(j,:)));
  end
elseif ~isempty(summ.axisscale{2})
  %display AXISSCALE, if present
  line = {'Axis   '};
  line{end+1} = sprintf('< %8.4g >',summ.axisscale{2}(1:ncols));
else
  %just do simple labels
  line = {'Column '};
  line{end+1} = sprintf('<    %3i   >',1:ncols);
end
textout{end+1} = cat(2,line{:});

%add rows for each statistic
for ifld=1:length(fldnames)
  textout{end+1} = [sprintf('%-6s', strtrim(fldnames(ifld,:))) sprintf('%12.4g', summ.data(ifld,1:ncols))];
end

%convert to char and output as requested
textout = char(textout);
if nargout==0; 
  disp(textout);
end;
