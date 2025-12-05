function t = tinv(p,dof) 
%TINV The inverse Student's T distribution function.
%  Wrapper for ttestp in PLS_Toolbox use ONLY with LIBRA. Note: this
%  function is subject to change without warning! We recommend you use
%  ttestp if necessary.
%
%  Inputs are the probability point (p) and the degrees of freedom (dof).
%  Output (t) is the t statistic for the given point.
%
%I/O: t = tinv(p,dof);

%Copyright (c) 2005-2006 Eigenvector Research, Inc.

nargchk(2,2,nargin);

if p>.5;
  t = ttestp(1-p,dof,2);
else
  t = -ttestp(p,dof,2);
end
