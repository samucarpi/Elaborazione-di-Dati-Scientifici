function [peakdef,fval,exitflag,out] = testfitpeaks(test)
%TESTFITPEAKS Demo calls to the FITPEAKS function
%  test =  1 fits a single Gaussian peak.
%  test =  2 fits two Gaussian peaks.
%  test =  3 fits a single Lorentzian peak.
%  test =  4 fits two Lorentzian peaks.
%  test =  5 fits a Gaussian and Lorentzian peak.
%  test =  6 fits a single PVoigt2 peak.
%  test =  7 fits a Gaussian and a PVoigt2 peak.
%  test =  8 fits a gaussian and a PVoigt1 peak.
%  test =  9 fits a single PVoigt1 peak.
%  test = 10 fits two GaussianSkew peaks.
%
%I/O:  [peakdef,fval,exitflag,output] = testfitpeaks(test);
%
%See also: FITPEAKS, PEAKFUNCTION, PEAKSTRUCT

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 4/20/04, 6/05
%nbg 10/05 streamlined the code and changed the help.

if nargin<1
  test = 1;
end

ax   = 1:100; %axis scale

switch test
case 1 %single gaussian peak
  %Make known peak (also see PEAKFUNCTION)
  y             = peakgaussian([2 51 8],ax);

  %Define first estimate and peak type
  peakdef       = peakstruct;
	peakdef.param = [0.1  43   5]; %coef, position, spread
	peakdef.lb    = [0     0  0.0001]; %lower bounds on param
	peakdef.penlb = [1 1 1];
	peakdef.ub    = [10 99.9 40]; %upper bounds on params
	peakdef.penub = [1 1 1];

  %Estimate fit and plot
  yint   = peakfunction(peakdef,ax);
  [peakdef,fval,exitflag,out,yfit] = fitpeaks(peakdef,y,ax);
  figure; plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--')
  legend('Initial','Actual','Fit')
  title('Single Gaussian Peak')
case 2 %fits two gaussian peaks
  %Make known peaks (also see PEAKFUNCTION)
  y             = peakgaussian([2 51 4],ax) + peakgaussian([4 39 5],ax);

  %Define first estimate and peak type
  peakdef       = peakstruct('',2);
	peakdef(1).param = [1.5 55   4]; %Coef, Position, Spread
	peakdef(1).lb    = [0   48   0.1]; %lower bounds on param
	peakdef(1).ub    = [10  70  10];   %upper bounds on params
	peakdef(2).id    = 2;
	peakdef(2).param = [3    35   3  ]; %Coef, Position, Spread
	peakdef(2).lb    = [0    32   0.1]; %lower bounds on param
	peakdef(2).ub    = [10   47  10];   %upper bounds on params

  yint   = peakfunction(peakdef,ax);
  [peakdef,fval,exitflag,out,yfit] = fitpeaks(peakdef,y,ax); figure
  plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--'), legend('Initial','Actual','Fit')
  title('Two Gaussian Peaks')
case 3 %a single lorentzian peak
  %Make known peak
  y             = peaklorentzian([2 51 4],ax);

  %Define first estimate and peak type
  peakdef       = peakstruct('Lorentzian');
	%peakdef.param = [1    35   5]; %coef, position, spread
  peakdef.param = [1    41   5]; %coef, position, spread
	peakdef.lb    = [0.01  0  0.0001]; %lower bounds on param
	peakdef.ub    = [10 99.9  20]; %upper bounds on params
  
  opts = fitpeaks('options'); %example of modifying optimizer
  opts.optimopts.x = 'on';
  opts.optimopts.fval = 'on';
  opts.optimopts.Jacobian = 'on';
  opts.optimopts.Hessian = 'on';
  opts.optimopts.stopcrit(3) = 100;
  opts.optimopts.lamb(1) = 0.01;

  %Estimate fit and plot
  yint   = peakfunction(peakdef,ax);
  [peakdef,fval,exitflag,out,yfit] = fitpeaks(peakdef,y,ax,opts); figure
  plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--'), legend('Initial','Actual','Fit')
  title('Single Lorentzian Peak')
case 4
 %Make known peaks
  y             = peaklorentzian([2 51 8],ax) + peaklorentzian([4 39 12],ax);

  %Define first estimate and peak type
  peakdef       = peakstruct('Lorentzian',2);
  %Peak 1
	peakdef(1).param = [3   55   6];   %Coef, Position, Spread
	peakdef(1).lb    = [0   48   1];   %lower bounds on params
	peakdef(1).ub    = [10  70  10];   %upper bounds on params
  %Peak 2
	peakdef(2).id    = 2;
	peakdef(2).param = [5    35   7];   %Coef, Position, Spread
	peakdef(2).lb    = [0    32   1];   %lower bounds on param
	peakdef(2).ub    = [10   47  40];   %upper bounds on params
  yint   = peakfunction(peakdef,ax);
  [peakdef,fval,exitflag,out,yfit] = fitpeaks(peakdef,y,ax); figure
  plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--'), legend('Initial','Actual','Fit')
  title('Two Lorentzian Peaks')
case 5
 %Make known peaks
  y             = peakgaussian([2 51 8],ax) + peaklorentzian([4 39 8],ax);
  %y             = peakgaussian([2 51 8],ax) + peakgaussian([4 39 8],ax);

  %Define first estimate and peak type
  peakdef       = peakstruct('',2);  
  %Peak 1
	peakdef(1).param = [0.2 52   5  ];    %Coef, Position, Spread
	peakdef(1).lb    = [0.2 48   0.1];    %lower bounds on param
	peakdef(1).ub    = [10  58  10  ];    %upper bounds on params
  %Peak 2
  peakdef(2)    = peakstruct('Lorentzian');
	peakdef(2).id    = 2;
	peakdef(2).param = [2  38   5  ];  %Coef, Position, Spread
	peakdef(2).lb    = [0  32   0.1];  %lower bounds on param
	peakdef(2).ub    = [12 41  12  ];    %upper bounds on params

  yint   = peakfunction(peakdef,ax);
  [peakdef,fval,exitflag,out] = fitpeaks(peakdef,y,ax);
  yfit   = peakfunction(peakdef,ax); figure
  plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--'), legend('Initial','Actual','Fit')
  title('A Gaussian and Lorentzian Peak')
case 6
 %Make known peak
  y             = peakpvoigt2([2 51 8 0.9],ax);

  peakdef       = peakstruct('pvoigt2');
	peakdef.param = [1.5 52   10   0.99];       %Coef, Position, Spread 0.99
	peakdef.lb    = [0.2 48   0.1 0];       %lower bounds on param
	peakdef.ub    = [10  54  10   1];       %upper bounds on params

  yint   = peakfunction(peakdef,ax);

  [peakdef,fval,exitflag,out] = fitpeaks(peakdef,y,ax);
  yfit   = peakfunction(peakdef,ax); figure %uses PeakFunction
  plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--'), legend('Initial','Actual','Fit')
  title('pvoigt2 Peak')
case 7
 %Make known peaks
  y             = peakpvoigt2([2 51 2 0.9],ax) + peakgaussian([4 39 8],ax);

  %Define first estimate and peak type
  peakdef       = peakstruct('pvoigt2',2);
  %Peak 1
	peakdef(1).param = [1.9 53   2.5 0.8];     %Coef, Position, Spread
	peakdef(1).lb    = [0.9 48   1   0  ];     %lower bounds on param
	peakdef(1).ub    = [10  54  10   1];       %upper bounds on params
  %Peak 2
	peakdef(2)    = peakstruct('Gaussian');
	peakdef(2).id    = 3.5;
	peakdef(2).param = [3.2  37   5  ];     %Coef, Position, Spread
	peakdef(2).lb    = [0    36   1  ];     %lower bounds on param
	peakdef(2).ub    = [10   40  10];       %upper bounds on params
  yint   = peakfunction(peakdef,ax);
  [peakdef,fval,exitflag,out,yfit] = fitpeaks(peakdef,y,ax); figure
  plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--'), legend('Initial','Actual','Fit')
  title('pvoigt2 and Gaussian Peaks')
case 8
 %Make known peaks
  y                = peakpvoigt1([2 51 2 0.9],ax) + peakgaussian([4 39 8],ax);

  %Define first estimate and peak type
  peakdef          = peakstruct('PVoigt1',2);
  %Peak 1
	peakdef(1).param = [1.9 53   2.5 0.8];     %Coef, Position, Spread
	peakdef(1).lb    = [0.9 48   1   0  ];     %lower bounds on param
	peakdef(1).ub    = [10  54  10   1];       %upper bounds on params
  %Peak 2
	peakdef(2)       = peakstruct('Gaussian');
	peakdef(2).id    = 3.5;
	peakdef(2).param = [3.2  37   5  ];     %Coef, Position, Spread
	peakdef(2).lb    = [0    36   1  ];     %lower bounds on param
	peakdef(2).ub    = [10   40  10];       %upper bounds on params
  yint             = peakfunction(peakdef,ax);
  [peakdef,fval,exitflag,out,yfit] = fitpeaks(peakdef,y,ax); figure
  plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--'), legend('Initial','Actual','Fit')
  title('PVoigt1 and Gaussian Peaks')
case 9
 %Make known peaks
  y                = peakpvoigt1([2 51 8 0.6],ax);

  %Define first estimate and peak type
  peakdef          = peakstruct('PVoigt1',1);
	peakdef(1).param = [1.9 53   9 0.5];     %Coef, Position, Spread
	peakdef(1).lb    = [0.9 48   1   0];     %lower bounds on param
	peakdef(1).ub    = [10  54  10   1];     %upper bounds on params
  yint             = peakfunction(peakdef,ax);
  [peakdef,fval,exitflag,out,yfit] = fitpeaks(peakdef,y,ax); figure
  plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--'), legend('Initial','Actual','Fit')
  title('PVoigt1 Peak')
case 10
 %Make known peaks
  y                = peakgaussianskew([2 40 8 3],ax) + ...
                     peakgaussianskew([3 56 8 5],ax);

  %Define first estimate and peak type
  peakdef          = peakstruct('GaussianSkew',2);
	peakdef(1).param = [1.9 45   7   1];     %Coef, Position, Spread
	peakdef(1).lb    = [0.9 35   1   0];     %lower bounds on param
	peakdef(1).ub    = [10  48  10  10];     %upper bounds on params
	peakdef(2).param = [2.5 58   7   2];     %Coef, Position, Spread
	peakdef(2).lb    = [0.9 52   1   0];     %lower bounds on param
	peakdef(2).ub    = [10  60  10  10];     %upper bounds on params  
  yint             = peakfunction(peakdef,ax);
  [peakdef,fval,exitflag,out,yfit] = fitpeaks(peakdef,y,ax); figure
  plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--'), legend('Initial','Actual','Fit')
  title('Two GaussianSkew Peaks')
end
