function [xc,xh,covc,covh] = savgol_2(x,w,o,d,options)
%SAVGOL_2 Spatial derivative operator for images
%  Savitzky-Golay down the colums of pixes and across the rows of pixels
%  for images (see SAVGOL). Outputs include the derivatized images and
%  corresponding covariance matrices. SAVGOL_2 calls RMEXCLD_2 to ensure 
%  that edges and excluded pixels do not adversely effect the calculation
%  of the covariance matrices.
%
%  INPUTS:
%       x = DataSet object of x.type = 'image',
%   width = number of points in filter,
%   order = polynomial order of the filter, and
%   deriv = order of the derivative for the filter.
%
%  OPTIONAL INPUT:
%   options = structure with the following field:
%          wt: [ {''} | '1/d' | [1xwidth] ] allows for weighted least-
%              squares when fitting the polynomials.
%              '' (empty) provides usual (unweighted) least-squares.
%              '1/d' weights by the inverse distance from the window
%                center, or
%              a 1 by width vector with values 0<wt<=1 allows for
%                custom weighting.
%
%  OUTPUTS:
%      xc = spatial derivative down the columns (DataSet object).
%           xc.include{1} = iinc; (see outputs from RMEXCLD_3).
%      xh = spatial derivative across the rows (DataSet object).
%           xh.include{1} = jinc; (see outputs from RMEXCLD_3).
%    covc = column covariance. For zc = xc.data(xc.include{1},x.include{2})
%           covc = zc'*zc/length(xc.include{1});
%    covh = row covariance. For zr = xr.data(xr.include{1},x.include{2})
%           covh = zh'*zh/length(xh.include{1});
% 
%I/O: [xc,xh,covc,covh] = savgol_2(x,width,order,deriv,options);
%
%See also: RMEXCLD_2, SAVGOL

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Note: minimal error checking in the interest of speed
%Note: could add capability to work with N-way. See "if ~isdataset(x)||~strcmpi(x.type,'image')"

%% Check I/O
if nargin == 0; x       = 'io'; end
if ischar(x)
  options               = [];
  options.wt            = ''; %'1/d';
  options.functionname  = 'savgol_2';

  if nargout==0; clear xc; evriio(mfilename,x,options);
  else;              xc =  evriio(mfilename,x,options); end
  return
end

if nargin<5
  options   = [];
end
options     = reconopts(options,mfilename);
if ~isdataset(x)||~strcmpi(x.type,'image')
  error('SAVGOL_2 only works with DataSets of type "image" [x.type=''image'']')
end
m           = x.imagesize;
n           = size(x,2);

%% Spatial Derivative
[iinc,jinc] = rmexcld_2(m,x.include{1},w);
xc          = reshape(x.data,m(1),m(2),n);
% Down the Columns
if w==1
  xc(:,2:end,:) = xc(:,2:end,:)-xc(:,1:end-1,:);
  xc(:,1,:) = xc(:,2,:);
else
  [~,dop]   = savgol(1:m(1),w,o,d,struct('wt',options.wt));
  dop       = dop';
  for ii=1:n
    xc(:,:,ii)  = dop*xc(:,:,ii);
  end
end
xc          = copydsfields(x,dataset(reshape(xc,prod(m),n)));
xc.include{1}   = iinc;
% Across the rows
xh          = reshape(x.data,m(1),m(2),n);
if w==1
  xh(2:end,:,:) = xh(2:end,:,:)-xh(1:end-1,:,:);
  xh(1,:,:) = xh(2,:,:);
else
  [~,dop]   = savgol(1:m(2),w,o,d,struct('wt',options.wt));
  for ii=1:n
    xh(:,:,ii)  = xh(:,:,ii)*dop;
  end
end
xh          = copydsfields(x,dataset(reshape(xh,prod(m),n)));
xh.include{1}   = jinc;

%% Covariance Matrices
if nargout>2
  covc      = xc.data.include;
  covc      = covc'*covc/length(xc.include{1});
  covh      = xh.data.include;
  covh      = covh'*covh/length(xh.include{1});
end

end %SAVGOL_2