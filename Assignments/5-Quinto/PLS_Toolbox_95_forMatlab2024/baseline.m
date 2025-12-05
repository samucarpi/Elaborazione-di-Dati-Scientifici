function [newspec,b,r,z] = baseline(varargin)
%BASELINE Subtracts a polynomial baseline offset from spectra.
%  Selects user specified regions (regions free of peaks),
%  regresses a polynomial through the regions, and then subtracts
%  the baseline from the original spectra.
%
%  Can also be used to perform DETREND and Min or Max baselining (see range
%  input below.)
%
%  INPUTS:
%    spec = MxN set of spectra to be baselined class "double" or "dataset",
%   freqs = the wavenumber or frequency axis vector {Default:
%           taken from dataset axisscale or a linear vector}, and
%   range = the baseline regions which is either:
%           a) a logical vector (1 by size(spec,2) with a true value at
%              each point to use as baseline and false otherwise
%              {default = logical(ones(1,size(spec,2)) which uses
%              all points for baselining. Default is same as detrending},
%           b) a vector of indices to use as baseline,
%           c) an empty vector meaning use all points as baseline (same as
%              a "detrend" operation)
%           d) an m by 2 matrix specifying baseline regions as start/end
%              pairs of indices:
%                  [ start_1  end_1
%                    start_2  end_2 ]
%           e) a scalar infinite value meaning: 
%               -inf = baseline to the minimum value in each spectrum
%                inf = baseline to the maximum value in each spectrum
%
%  OTIONAL INPUT:
%   options = structure array with the following fields:
%     plots: [ {'none'} | 'final' ] governs plotting, and
%     order: positive integer for polynomial order {default =1}.
%   algorithm: [ {'ConditionedBasis'} | 'preVer8.8.1' ] governs the use of a
%              conditioned basis (recommended), or select a pre Ver 8.1.1 basis
%
%  OUTPUTS:
%   newspec = MxN matrix or dataset of baselined spectra, and
%         b = a matrix of regression coefficients. If (b) is passed
%             in place of (range) along with (newspec), a baseline
%             operation can be "undone".
%     range = the baseline regions used as a vector of indices.
%         z = MxN matrix of baselines.
%
%I/O: [newspec,b,range,z] = baseline(spec,freqs,range,options); %perform baselining
%I/O: spec        = baseline(newspec,freqs,b,options);  %undo baselining
%I/O: baseline demo
%
%See also: BASELINEW, DERESOLV, LAMSEL, LSQ2TOP, LSQ2TOPB, MED2TOP, NORMALIZ, POLYINTERP, SAVGOL, SAVGOLCV, SPECEDIT, STDGEN, WLSBASELINE

%Copyright Eigenvector Research, Inc. 1997-2020
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw
%jms 4/9/2002 -added range as logical vector option
%jms 4/29/02 -revised input for new format and allowed higher-order baselines
%   -added undo option
%   -added hidden "plot" graphical selection option for range
%jms 5/21/03 -fixed typo of default x-lables ('wevenumbers')
%jms 5/28/04 -allow for two columns of range to be the same indicating find
%      nearest single point to this value (uses findindx)
%jms 12/17/04 -give error if no spectral points end up being included

if nargin==0; varargin{1} = 'io'; end
if ischar(varargin{1})
  options       = [];
  options.name  = 'options';
  options.plots = 'none';
  options.order = 1;
  options.algorithm   = 'ConditionedBasis'; % 'preVer8.8.1' 
  options.definitions = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; newspec = evriio(mfilename,varargin{1},options); end
  return;
end

%Defaults
xlab  = 'Wavenumbers';
ylab  = 'Absorbance';

%- - - - - - -
%typical calls:
% (spec,freqs,range,options)
% (spec,freqs,range,plots)
% (spec,freqs,range)
% (spec,range,options)
% (spec,range,plots)
% (spec,range)
% (spec,options)
% (spec,plots)
% (spec)
% any of these can have "b" in place of "range"

%get options
if isa(varargin{end},'struct')
  %last input is structure, assume it is options
  options  = varargin{end};
  varargin = varargin(1:end-1);   %drop last input
else
  %last input is neither? Use default options
  options  = [];
end

try
  options  = reconopts(options,'baseline',{'range'});
catch
  error('Unrecognized options structure');
end

%Dataset compatibility
if isa(varargin{1},'dataset')
  %SPEC is a dataset, see if we can use info from there to do baselining
  wasdataset = 1;
  orig       = varargin{1};
  spec       = varargin{1};
  include    = spec.includ;
  if ~isempty(spec.axisscalename{1})
    ylab     = spec.axisscalename{1};
  end
  if ~isempty(spec.axisscalename{2})
    xlab     = spec.axisscalename{2};
  end
  
  %is freqs present?
  % (spec,freqs,range)
  % (spec,range)
  switch length(varargin)
  case 3
    range    = varargin{3};
    freqs    = varargin{2};
  case {1,2}
    if length(varargin)==2
      range  = varargin{2};
    else
      range  = [];
    end
    if ~isempty(spec.axisscale{2})
      freqs  = spec.axisscale{2};
    else
      freqs  = [];
    end
  otherwise
    error('Unrecognized input(s)');
  end
  
  %get data from dataset
  %NOTE: we're not using the includ field because it will be used below to limit the used points
  spec       = spec.data;
  
else
  wasdataset = 0;
  spec       = varargin{1};
  
  %is freqs present?
  % (spec,freqs,range)
  % (spec,range)
  switch length(varargin)
  case 3
    range    = varargin{3};
    freqs    = varargin{2};
  case 2
    range    = varargin{2};
    freqs    = [];
  case 1
    range    = [];
    freqs    = [];
  otherwise
    error('Unrecognized input(s)')
  end
  
  include    = {[1:size(spec,1)] [1:size(spec,2)]};
end

if isempty(freqs)
  if wasdataset & ~isempty(orig.axisscale{2})
    freqs = orig.axisscale{2};
  else
    freqs = 1:size(spec,2);
  end
end

%Interpret range
[m,n]        = size(spec);
undo         = 0;  %unless a coefficients matrix was passed as (range) this is a "do" and not an "undo" operation
if isempty(range)
  r          = 1:n;    %no range = all are baseline (detrend)
  
elseif all(size(range)==1) & ~isfinite(range)
  switch range
    case {inf -inf}
      r      = range;
    otherwise
      error('Unrecognized input for "range"');
  end
elseif min(size(range))==1 & max(size(range))==n & all(ismember(unique(range),[0 1]));
  %(mode "b" for range)
  %essentially a logical vector equal in length to spec
  r          = find(range);
elseif size(range,2)==2  %(mode "a" for range)
  if all((range(:,1)-range(:,2))==0)
    %[point1 point1; point2 point2; ...] of indicies to use
    r        = findindx(freqs,range(:,1));
  else
    %[start end; start end; ...] of indices range
    r        = lamsel(freqs,range,strcmp(options.plots,'final'));
  end
elseif size(range,2) == size(spec,1)   %undo call
  undo       = 1;  %trigger undo
  r          = 1:n;
  b          = -range;  %invert coefficients (causes "undo")
  options.order = size(b,1)-1;
elseif ~ischar(range) & size(range,1)==1    %range is r (mode "c" for range)
  r          = range;
  
elseif strcmp(range,'plot')
  c.cont     = {'style','pushbutton','string','Continue','callback','close(getappdata(gcbf,''target''));'};
  h          = plotgui(spec,'plotby',0,'axismenuvalues',{1 2},'uicontrol',c,'pgtoolbar',0);
  evrimsgbox('Select baseline points and click "Continue"','Select baseline')
  range      = [];
  while ishandle(h)
    uiwait(h);
    if ishandle(h)
      range  = getappdata(h,'selection');
    end
  end
  if isempty(range)
    r        = 1:size(spec,2);
  else
    r        = range{2};
  end
else
  error('Unrecognized input for range');
  
end

[mf,nf]      = size(freqs);
if nf~=n
  error('Number of columns in wavenumber axis and spectra not the same')
end

if numel(r)>1 | all(isfinite(r))
  %normal baseline (choosing points and doing a polynomial)
  if wasdataset   %apply includ to range
    r = intersect(r,include{2});   %use only the includ'ed points
    if isempty(r)
      error('All baseline points marked as excluded in DataSet object')
    end
  end
  
  [mr,nr]    = size(r);
  newspec    = spec;
  if nargout>3
    z        = zeros(m,n);
  else
    z        = [];
  end

  if isempty(r)
    error('No baseline points identified')
  elseif max(r)>size(spec,2)
    error('Range region is larger than spec, check range input.')
  end
  
  %calculate polynomial basis spectra
  switch lower(options.algorithm)
  case 'conditionedbasis'
    xb         = ones(n,options.order+1);
    for ord=1:options.order
      xb(:,options.order - ord + 1) = mncn(freqs').^(ord);
    end
    xb         = normaliz(xb')';
  otherwise      %'preVer8.8.1'
    xb         = ones(n,options.order+1);
    for ord=1:options.order
      xb(:,options.order - ord + 1) = freqs'.^(ord);
    end
  end
  
  xr         = xb(r,:);

  for i=1:m
    if ~undo
      b(:,i) = xr\spec(i,r)';
    end
    newspec(i,:) = spec(i,:) - (xb*b(:,i))';
    if nargout>3
      z(i,:)     = (xb*b(:,i))';
    end
    if strcmp(options.plots,'final')
      plot(freqs,spec(i,:),freqs,newspec(i,:))
      hline(0)
      xlabel(xlab)
      ylabel(ylab)
      s = sprintf('Original and Baselined Spectra Number %g',i);
      title(s)
      pause
    end
  end
else
  %simple baseline to min/max
  if wasdataset & length(include{2})<n
    %dataset with exclusions on variables?
    specsub  = spec(:,include{2});
  else
    specsub  = spec;
  end
    
  switch r
    case inf
      b = max(specsub,[],2);
    case -inf
      b = min(specsub,[],2);
    otherwise
      error('Unrecoginzed value for range')
  end

  if m*n<50000;  %< critical # of points (<0.5Mb) ? use matrix
    newspec = (spec-b(:,ones(n,1)));
  else   %otherwise use loop
    newspec = zeros(size(spec));
    for col = 1:n
      newspec(:,col) = (spec(:,col)-b);
    end
  end

  if strcmp(options.plots,'final')
    plot(freqs,spec,freqs,newspec)
    hline(0)
    xlabel(xlab)
    ylabel(ylab)
    pause
  end

end

if wasdataset;
  orig.data = newspec;
  newspec   = orig;
end

%--------------------------
function out = optiondefs

defs = {
  %name                    tab               datatype        valid                  userlevel       description
  'plots'                  'Display'     'select'        {'none' 'final'}           'novice'        'Governs level of plotting.';
  'order'                  'General'     'double'        'int(1:inf)'               'novice'        'Positive integer for polynomial order {default =1}.'
  'algorithm'              'General'     'select'   {'ConditionedBasis' 'preVer8.8.1'} 'expert'     'Use a conditioned basis (recommended), or select a pre Ver 8.1.1 basis'
  };

out = makesubops(defs);
