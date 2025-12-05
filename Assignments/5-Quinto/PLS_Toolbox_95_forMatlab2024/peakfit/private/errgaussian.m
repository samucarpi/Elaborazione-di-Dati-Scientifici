function [y1,y2,y3] = errgaussian(b,y,t,wts);
%ERRGAUSSIAN Gaussian loss function
%  INPUTS:
%    b       = NXx1 vector, exponential parameters.
%    y       = 1xN vector, measured signal to fit peaks to.
%    t       = 1xN vector, peak axis.
%    wts     = 1xN vector of weights 0<wts<1.
%
%  OUTPUTS:
%    y1      = scalar, squared fit error.
%    y2      = NXx1 vector, Jacobian
%    y3      = NXxNX matrix, Hessian
%
%I/O: [y1,y2,y3] = errgaussian(b,y,t,wts);

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 4/04
%nbg 8/9/05 modified peakerror.m

b           = b(:);
y           = y(:)';
t           = t(:)';
wts         = sqrt(wts(:)');

if nargout==1
  s1        = peakgaussian(b,t);
  s1        = (y - s1).*wts;
  y1        = s1*s1';            %fval
else
  y2          = zeros(3,1);        %Jacobian
  y3          = zeros(3,3);        %Hessian
  [s1,s2,s3]  = peakgaussian(b,t);
  s1          = (y - s1).*wts;
  y1          = s1*s1';            %fval
  wts         = wts(ones(3,1),:);
  s2          = s2.*wts;
  for i2=1:3
    s3(:,i2,:)  = squeeze(s3(:,i2,:)).*wts;
  end
  y2(:,1)     = -2*s2*s1';
  y3(:,:)     = 2*s2*s2';
  for i2=1:3
    y3(i2,i2) = y3(i2,i2)-2*s1*squeeze(s3(i2,i2,:));
    for i3=i2+1:3
      y3(i2,i3) = y3(i2,i3)-2*s1*squeeze(s3(i2,i3,:));
      y3(i3,i2) = y3(i3,i2);
    end
  end
end
