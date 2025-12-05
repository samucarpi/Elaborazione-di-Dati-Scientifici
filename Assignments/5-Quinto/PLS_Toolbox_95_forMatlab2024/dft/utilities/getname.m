function name = getname(uname)
%GETNAME Density name conventions
%  Below are the densities used in the DF_Toolbox. The capital
%  letters indicate minimal abbreviation.
%
%    Distribution             Allowed Specifiers
%    ----------------         ------------------------------------------
%    beta                     BETa
%    cauchy                   CAUchy
%    chi squared              CHI2, CHI-squared, CHIsquared, CHI squared
%    exponential              EXPonential
%    gamma                    GAMma
%    gumbel                   GUMbel, EXTreme
%    laplace                  LAPlace, DOUbleexponential
%    logistic                 LOGIstic
%    lognormal                LOGnormal
%    normal                   GAUssian, NORmal
%    pareto                   PAReto
%    rayleigh                 RAYleigh
%    student's t              STUendt
%    triangle                 TRIangle
%    Uniform                  UNIform
%    Weibull                  WEIbull
%    
%I/O: name = getname(uname);

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin==0; uname = 'io'; end
if ischar(uname) & ismember(uname,evriio([],'validtopics'));
  options = [];
  if nargout==0; 
    evriio(mfilename,uname,options);
  else;          
    name = evriio(mfilename,uname,options);
  end
  return;
end

%improvements can use the lower and strncmp functions 
lname = lower(deblank(uname)) ;
len   = length(uname) ; 

if strncmp(lname,'normal',max(len,3))
	name = 'norm' ;
elseif strncmp(lname,'gaussian',max(len,3))
	name = 'norm' ;
elseif strncmp(lname,'beta',max(len,3))
	name = 'beta' ;
elseif strncmp(lname,'cauchy',max(len,3))
	name = 'cauc' ;
elseif strncmp(lname,'chisquared',max(len,3))
	name = 'chi2' ;
elseif strncmp(lname,'chi squared',max(len,3))
	name = 'chi2' ;
elseif strncmp(lname,'chi2',max(len,3))
	name = 'chi2' ;
elseif strncmp(lname,'chi',max(len,3))
  name = 'chi2';
elseif strncmp(lname,'exponential',max(len,3))
	name = 'expo' ;
elseif strncmp(lname,'gumbel',max(len,3))
	name = 'gumb' ;
elseif strncmp(lname,'extreme',max(len,3))
	name = 'gumb' ;
elseif strncmp(lname,'gamma',max(len,3))
	name = 'gamm' ;
elseif strncmp(lname,'extremevalue',max(len,3))
	name = 'gumb' ;
elseif strncmp(lname,'laplace',max(len,3))
	name = 'lapl' ;
elseif strncmp(lname,'doubleexponential',max(len,3))
	name = 'lapl' ;
elseif strncmp(lname,'lognormal',max(len,3))
	name = 'logn' ;
elseif strncmp(lname,'lnormal',max(len,3))
	name = 'logn' ;
elseif strncmp(lname,'logistic',max(len,4))
	name = 'logi' ;
elseif strncmp(lname,'logistic',max(len,4))
	name = 'logi' ;
elseif strncmp(lname,'pareto',max(len,3))
	name = 'pare' ;
elseif strncmp(lname,'rayleigh',max(len,3))
	name = 'rayl' ;
elseif strncmp(lname,'student',max(len,3))
	name = 'stu' ; 
elseif strncmp(lname,'triangle',max(len,3))
	name = 'tria' ;
elseif strncmp(lname,'uniform',max(len,3))
	name = 'unif' ;
elseif strncmp(lname,'weibull',max(len,1))
	name = 'weib' ;
else
	name = 'unknown' ;
end

