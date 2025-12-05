function rescl = jmlimit(pc,s,cl, flag)
%JMLIMIT Confidence limits for Q residuals via Jackson-Mudholkar.
%  Inputs are the number of PCs used in the PCA model (pc), the vector of 
%  eigenvalues of the residuals' covariance (s), and the confidence limit 
%  (cl) expressed as a fraction (e.g. 0.95). 
%  The output (rescl) is the confidence limit
%  based on the method of Jackson and Mudholkar. See CHILIMIT for an 
%  alternate method of residual limit calculation based on chi^2.
%  Note: The input pc is used to indicate which eigenvalues in s are to be
%  considered as residuals. Only eigenvalues s(j), j>pc, are used as
%  residuals. For example, s is from a PCA model built with ncomp = pc and 
%  s = model.detail.ssq(:,2), then call jmlimit(ncomp, s, cl, flag) to get 
%  the limit. However, if s represents eigenvalues of the residuals' 
%  covariance then call jmlimit(0, s, cl, flag) so as to include the full 
%  residuals.
%
%Example: rescl = jmlimit(4,model.detail.ssq(:,2),0.99); %for PCA a model
%         built with ncomp = 4
%
% Do inverse calculation with flag=2: cl = jmlimit(pc,s,Q,2);
%  where Q is the sum of squares residuals from a model and "2" is a flag 
%  indicating the inverse calculation
%
%I/O: rescl = jmlimit(pc,s,cl);
%I/O: cl    = jmlimit(pc,s,Q,2);
%
%See also: ANALYSIS, CHILIMIT, PCA, RESIDUALLIMIT

%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Copyright Eigenvector Research, Inc. 1997
%nbg 4/97,7/97
%bmw 12/99
%jms 4/03 -revised to allow multiple limits to be calculated in one call
%  (vector of cl)

if nargin == 0; pc = 'io'; end
varargin{1} = pc;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear rescl; evriio(mfilename,varargin{1},options); else; rescl = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin < 4
  flag = 1;
end

if flag~=2 & any(cl>=1|cl<=0)
  error('confidence limit must be 0<cl<1')
end
if isempty(s)
  rescl = NaN;
  return
end
[m,n] = size(s);
if m>1&n>1
  error('input s must be a vector')
end
if n>m
  s   = s';
  m   = n;
end
if pc>=length(s)
  rescl = zeros(1,length(cl));
else
  theta1 = sum(s(pc+1:m,1));
  theta2 = sum(s(pc+1:m,1).^2);
  theta3 = sum(s(pc+1:m,1).^3);
  if theta1==0;
    rescl = zeros(1,length(cl));  % check inverse case...
  else
    h0     = 1-2*theta1*theta3/3/(theta2.^2);
    if h0<0.001
      h0 = 0.001;
    end
    if flag~=2  
      % forward
      ca    = sqrt(2)*erfinv(2*cl-1);
      h1    = ca*sqrt(2*theta2*h0.^2)/theta1;
      h2    = theta2*h0*(h0-1)/(theta1.^2);
      rescl = theta1*(1+h1+h2).^(1/h0);
    else
      % inverse
      h1    = (cl/theta1).^h0;
      h2    = theta2*h0*(h0-1)/theta1^2;
      deviate = theta1*(h1-1-h2)/(sqrt(2*theta2)*h0);
      rescl = 0.5*(1+erf(deviate/sqrt(2)));
    end
  end
end
