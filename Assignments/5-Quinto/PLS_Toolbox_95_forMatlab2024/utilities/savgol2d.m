function [y0,dx,dy,d1,d2]= savgol2d(x,w,o,d,options)
%SAVGOL2D Savitzky-Golay smoothing and differentiation for images.
%  If (z) is a MxNxP multi-layer image with each MxN image corresponding to
%  p=1,...,P then a SavGol filter is applied to each MxN gray-scale image.
%  See SAVGOL help for description of 1D case.
%
%  INPUT:
%    z = MxNxP image data of class 'double' or 'dataset'.
%        a) If 'double' it must be MxNxP (P can = 1).
%        b) If 'dataset' it must x.type=='image', x.imagesize = MxN and
%            x.data is size MNxP.
%
%    w = The number of points in filter (odd integer >0).
%         If (w) is a scalar it defines the width in both the X- and
%         Y-directions, otherwise
%         (w) is a two element vector defining the two widths.
%    o = The order of the polynomial fit in each window/mask (integer scalar).
%    d = The derivative (integer scalar).
%
% OPTIONAL INPUTS:
%    options = structure with the following fields:
%      algorithm: [{'full'} | 'nocross' ];
%                 'full'    = uses all cross terms, and
%                 'nocross' = uses no cross terms (fast).
%             wt: [ {''} | '1/d' | w(1)xw(2) array ] allows
%                  for weighted least-squares when fitting the polynomials.
%                 '' (empty) provides usual (unweighted) least-squares.
%                 '1/d' weights by the inverse distance from the window
%                   center, or
%                 A w(1) by w(2) array with values 0<wt<=1 allowing for
%                  custom weighting.
%          tails: [{'polyinterp'}, 'weighted'] Governs how edges of image
%                  are handled.                 
%                 'polyinterp' uses polynomial interpolation.
%                 'weighted' prgressively deweights pixels away from the
%                  edges.
%
%  OUTPUTS:
%    y0 = a) When (d=0), (y0) is the mean smoothed image, and (dx) and (dy)
%            are smoothed images in each direction (x and y).
%         b) When (d>0), (y0) is the magnitude of the dirivatives and
%            y0 = sqrt(dx.^2 + dy.^2).
%     dx: Derivative with respect to X, dz/dx (for d>0, NaN otherwise).
%     dy: Derivative with respect to Y, dz/dy (for d>0, NaN otherwise).
%
%I/O: [y0,dx,dy,d1,d2] = savgol2d(z,w,o,d,options);
%
%See also: BOX_FILTER, POLYINTERP, SAVGOL

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 3/07, 2/08, 9/15

%% I/O Testing
if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.name      = 'options';
  options.algorithm = 'full';       %'nocross'
  options.wt        = '';
  options.tails     = 'polyinterp'; %'weighted'
  if nargout==0;
    evriio(mfilename,x,options);
  else
    y0    = evriio(mfilename,x,options);
  end
  return;
end

if nargin<5               %set default options
  options = savgol2d('options');
else
  options = reconopts(options,savgol2d('options'));
end

if nargin<4
  error('SAVGOL2D requires 4 inputs.')
end

wasdso    = false;
if isa(x,'dataset')
  if ~strcmp(x.type, 'image')
    error('SAVGOL2D requires input dataset to be an image dataset.')
  end
  wasdso  = true;
  m   = [x.imagesize, size(x,2)];
else
  m   = size(x);
  if ndims(x)==2
    m(3)  = 1;
  end
  x   = buildimage(x);
end

if length(w)==1   %window(s) width, needs to be odd (include 3 for later)
  w   = w(ones(2,1));
elseif length(w)==2
  w   = w(:);
else
  error('Input (w) must have 1 or 2 elements.')
end

for i1=1:2 %make sure window dimensions are odd
  if (w(i1)/2-floor(w(i1)/2))==0
    disp(['Window win(',int2str(i1),') must be odd.'])
    disp([' Changing win(',int2str(i1),') from ',int2str(w(i1)),' to ',int2str(w(i1)-1),'.'])
    w(i1) = max([1 w(i1)-1]);
  end
end

if length(o)~=1 %if o is not scalar throw an error
  error('Input (o) must an integer scalar.')
end

p     = (w-1)/2; %half width

if isempty(options.wt) | strcmpi(options.wt,'none'); %Set weights.
  options.wt = '';
elseif strcmpi(options.wt,'1/d')
  options.wt = (1./([p(2):-1:1, 1, 1:p(2)]'))*(1./([p(1):-1:1, 1, 1:p(1)]));
elseif isa(options.wt,'double')
  if isvec(options.wt) | ...
     ndims(options.wt)~=2 | ...
     ~all(size(options.wt)==w(1:2)')
    error('Input (options.wt) must be a w(1) by w(2) array.')
  end 
  if any(options.wt>1) | any(options.wt<0) | all(options.wt==0)
    error('Input (options.wt) must all be 0<options.wt<=1')
  end
end

%% SavGol
switch lower(options.algorithm)
case 'nocross' %fast, cheap algorithm
  opts        = savgol('options');
  opts.tails  = options.tails;
  if ~isempty(options.wt)
    opts.wt   = options.wt(:,p(1)+1)';
  end
  [y0,d1]     = savgol(1:m(1),w(1),o,d,opts);
  if ~isempty(options.wt)
    opts.wt   = options.wt(p(2)+1,:);
  end
  [y0,d2]     = savgol(1:m(2),w(2),o,d,opts);

  dx  = reshape(d1'*unfoldmw(reshape(x.data,m),1),m);
  dy  = permute(reshape(d2'*unfoldmw(permute(reshape(x.data,m),[2 1 3]),1), ...
          m([2 1 3])),[2 1 3]);
    
  if d==0
    y0    = (dx + dy)/2;
    dx    = NaN;
    dy    = NaN;
  else
    y0    = sqrt(dx.^2 + dy.^2);
  end
  if wasdso
    y0    = copydsfields(x,buildimage(y0));
    if nargout>1
      dx  = copydsfields(x,buildimage(dx));
      dy  = copydsfields(x,buildimage(dy));
    end
  end
  d1      = [zeros(w(1),p(1)),full(d1(1:w(1),p(1)+1)), zeros(w(1),p(1))];
  d2      = [zeros(p(2),w(2));full(d2(1:w(2),p(2)+1))';zeros(p(2),w(2))];
  
case 'full'
  d1      = ((-p(1):p(1))'*ones(1,1+o)).^(ones(w(1),1)*(0:o));
  d2      = ((-p(2):p(2))'*ones(1,1+o)).^(ones(w(2),1)*(0:o));
  d2      = d2';
  z       = zeros(size(d1,1)*size(d2,2),(o+1).^2);
  i0      = 0;
  for i1=1:size(d1,2)
    for i2=1:size(d2,1)
      i0      = i0+1;
      a       = d1(:,i1)*d2(i2,:);
      z(:,i0) = a(:);
    end
  end
%  a = b0 +b1y +b2y^2 +b3x +b4xy +b5xy^2 + b6x^2 +b7x^2y +b8x^2y^2
%  evaluate at (x=0,y=0), therefore cross-terms are zero
  
  wp      = prod(w);
  if isempty(options.wt)
    weights   = z\speye(wp);
  else
    weights   = (diag(options.wt(:))*z)\spdiag(options.wt(:));
  end
  coeff   = prod(1:d);
  d1      = weights((o+1)*d+1,:)*coeff; d1 = d1(:);
  d2      = weights(d+1,:)*coeff;       d2 = d2(:);
  z       = reshape(x.data,m);
  opts    = options;
  opts.algorithm  = 'nocross';
  
  if d==0
    y0    = z;
    %Handle the edges
    y0    = savgol2d(z,w,o,d,opts);
    
    %Handle the bulk of the data
    for i1=p(1)+1:m(1)-p(1)
      for i2=p(2)+1:m(2)-p(2)
        a = reshape(z(i1-p(1):i1+p(1),i2-p(2):i2+p(2),:),[wp,m(3)]);
        y0(i1,i2,:) = sum(a.*d1(:,ones(1,m(3))));
      end %EO i2
    end %EO i1
    if wasdso
      y0  = copydsfields(x,buildimage(y0));
    end
    dx    = NaN;
    dy    = NaN;
    d1      = reshape(d1,w');
    d2      = reshape(d2,w');
  else
    %Handle the edges
    [y0,dx,dy]      = savgol2d(z,w,o,d,opts);
    
    %Handle the bulk of the data
    for i1=p(1)+1:m(1)-p(1)
      for i2=p(2)+1:m(2)-p(2)
        a = reshape(z(i1-p(1):i1+p(1),i2-p(2):i2+p(2),:),[wp,m(3)]);
        dx(i1,i2,:) = sum(a.*d1(:,ones(1,m(3))));
        dy(i1,i2,:) = sum(a.*d2(:,ones(1,m(3))));
      end %EO i2
    end %EO i1
    y0    = sqrt(dx.^2 + dy.^2);
    if wasdso
      y0  = copydsfields(x,buildimage(y0));
      if nargout>1
        dx    = copydsfields(x,buildimage(dx));
        dy    = copydsfields(x,buildimage(dy));
      end
    end
  end
  d1      = reshape(d1,w');
  d2      = reshape(d2,w');
otherwise
  error('Input (options.algorithm) not recognized.')
end
end %EOF

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'algorithm'              'Standard'       'select'        {'full' 'nocross'}               'novice'        'Algorithm for polynomial terms ''full'' usses all terms. ''nocross'' does not include cross terms (fast).';
'wt'                     'standard'       'select'        {'', '1/d'}                      'novice'        'Governs weight least-squares w/in each window.';
'tails'                  'Standard'       'select'        {'polyinterp', 'weighted'}       'novice'        'Governs how edges of image are handled.';
};

out = makesubops(defs);
end
