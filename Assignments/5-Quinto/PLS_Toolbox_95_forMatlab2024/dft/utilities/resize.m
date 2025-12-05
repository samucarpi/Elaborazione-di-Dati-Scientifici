function [xout,varargout] = resize(x,varargin)
%RESIZE resizes arguments to same length.
%  Inputs are (x) and (v) can be scalars, vectors, matrices, or
%  multidimensional arrays. The function will attempt to resize all inputs
%  to the largest size of each dimension for any given input. If input is a
%  scalar, the function will return that scalar.
%
%  Example:
%    (newx,newv1,newv2) = resize(x,v1,v2,v3);
%      original sizes are:
%         x  - 2x2x2
%         v1 - 2x6
%         v2 - 4x1
%         v3 - 1x1
%      new sizes are:
%         newx  - 4x6x2
%         newv1 - 4x6x2
%         newv2 - 4x6x2
%         newv3 - 1x1
%
%I/O: (newx,newv1,newv2) = resize(x,v1,v2);
%
%See also: REPMAT

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.

%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
%nbg - 04/03 mod to PLS_Toolbox
%rsk 01/03/06 - Change behavior to resize to largest size of any input for each dim.

if nargin==0; 
  x = 'io'; 
end

if ischar(x) & ismember(x,evriio([],'validtopics'));
  options = [];
  if nargout==0;
    evriio(mfilename,x,options);
  else;
    xout = evriio(mfilename,x,options);
  end
  return;
end

if nargin<2, error('Resize requires at least 2 arguments.') ; end
narg      = length(varargin); %number of inputs
sz        = size(x); %orginal size of x
varargout = cell(narg,1); %output variable
xout = x;
%Up-size x if needed and then upsize all other inputs based on x.
for ii=1:narg
  thissz = size(varargin{ii}); %variable size
  if length(thissz)>length(sz)
    %Add dimensions.
    nsz = thissz;
    nsz(1:length(sz)) = sz;
    sz(end+1:length(thissz)) = 1;
    %thisrescale_1 = thissz./sz(1:length(thissz));
    thisrescale_1 = nsz./sz;
    if any(thisrescale_1~=fix(thisrescale_1))
      error('Input(s) must be scalar or repeatable unit(s) of each other.')
    else
      xout = repmat(xout,thisrescale_1);
      sz = size(xout);
    end
  end
  if any(thissz>sz(1:length(thissz)))
    %Up-size existing dimensions.
    nsz = sz;
    nsz(find(thissz>sz(1:length(thissz)))) = thissz(find(thissz>sz(1:length(thissz))));
    thisrescale_1 = nsz./sz;
    if any(thisrescale_1~=fix(thisrescale_1))
      error('Input(s) must be scalar or repeatable unit(s) of each other.')
    else
      xout = repmat(xout,thisrescale_1);
      sz = size(xout);
    end
  end
end

%Resize other inputs based on size of x.
for ii=1:narg
  thissz = size(varargin{ii}); %variable size
  if length(thissz)<length(sz)
    thissz(end+1:length(sz)) = 1; %fill in unit lengths on other dims
  end
  thisrescale = sz./thissz;
  if any(thisrescale~=fix(thisrescale))
    error('Input(s) must be scalar or repeatable unit(s) of each other.')
  elseif isscal(varargin{ii})
    varargout{ii} = varargin{ii};
  else
    varargout{ii} = repmat(varargin{ii},thisrescale);
  end
end

%Return scalar for x if input was scalar.
if isscal(x)
  xout = x;
end
