echo on
% COV_CVDEMO Demo of the cov_cv function
 
echo off
% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The COV_CV function is used to estimate a regularized inverse
% covariance matrix.
 
% In each example below, a different data matrix is loaded
% and the inverse is estimated. The plots show eigenvalue
% distributions, regularized eigenvalues, and the regularization
% parameters that were employed prior to taking the inverse.
%
% The vertical line indicates the approximate number of components
% and the horizontal line indicates the maximum condition number
% (see options.condmax).
 
pause
 
load nir_data
[ccov,results] = cov_cv(spec1);
axis([0 50 1e-8 1]), vline(results.ncomp), hline(results.s(1)/results.options.condmax)
title(['nir_data: 30x401 ',get(get(gca,'title'),'string')],'interpreter','none'), figfont
pause
%-------------------------------------------------
 
opts           = cov_cv('options');
opts.preprocessing = {preprocess('default','derivative')};
sgopts = opts.preprocessing{1}.userdata;
sgopts.width = 15;
sgopts.order = 2;
sgopts.deriv = 2;
sgopts.useexcluded = true;
opts.preprocessing{1}.userdata = sgopts;
[ccov,results] = cov_cv(spec1,opts);
axis([0 50 1e-9 1e-2]), vline(results.ncomp), hline(results.s(1)/results.options.condmax)
title(['nir_data 2ndD: 30x401 ',get(get(gca,'title'),'string')],'interpreter','none'), figfont
pause 
%-------------------------------------------------
 
load plsdata
xblock1 = delsamps(xblock1,[73 278 279]);
[ccov,results] = cov_cv(xblock1);
axis([0 20 1e-4 1e5]), vline(results.ncomp), hline(results.s(1)/results.options.condmax)
title(['plsdata: 297x20 ',get(get(gca,'title'),'string')],'interpreter','none'), figfont
pause  
%------------------------------------------------- 
 
opts  = cov_cv('options');
opts.preprocessing = 2;
load alcohol
[ccov,results] = cov_cv(alcohol,opts);
axis([0 53 1e-6 5e2]), vline(results.ncomp), hline(results.s(1)/results.options.condmax)
title(['Alcohol auto ',get(get(gca,'title'),'string')],'interpreter','none'), figfont
% The Alcohol data was only slightly regularized.
% Note that the std is all 1 for autoscaled data.
pause  
%------------------------------------------------- 
 
load arch
opts  = cov_cv('options');
opts.preprocessing = 2;
[ccov,results] = cov_cv(arch,opts);
axis([0 10 1e-2 1e1]), vline(results.ncomp), hline(results.s(1)/results.options.condmax)
title(['arch autoscale: 75x10 ',get(get(gca,'title'),'string')],'interpreter','none'), figfont
% The arch data was not regularized.
pause  
%------------------------------------------------- 
 
load oesdata
[ccov,results] = cov_cv(oes1.data);
axis([0 100 1e-7 1e7]), vline(results.ncomp), hline(results.s(1)/results.options.condmax)
title(['oesdata: 46x770 ',get(get(gca,'title'),'string')],'interpreter','none'), figfont, disp(results.ncomp)
% The oes data had a good condition number up to factor 46 and then fell off.
% Prior to regularization, this data was truly rank deficient.
% In this case, the user may want to increase the options.condmax to avoid
% a discontinuity in the eigenvalue distribution.
pause  
%------------------------------------------------- 
 
load FTIR_microscopy
[ccov,results] = cov_cv(FTIR_microscopy);
axis([0 82 1e-12 5e1]), vline(results.ncomp), hline(results.s(1)/results.options.condmax)
title(['FTIR_microscopy: 17x81 ',get(get(gca,'title'),'string')],'interpreter','none'), figfont, disp(results.ncomp)
pause  
%------------------------------------------------- 
 
load raman_time_resolved
[ccov,results] = cov_cv(raman_time_resolved);
axis([0 70 1e-12 1e2]), vline(results.ncomp), hline(results.s(1)/results.options.condmax)
title(['raman_time_resolved: 16x151 ',get(get(gca,'title'),'string')], ...
  'interpreter','none'), figfont
pause 
%------------------------------------------------- 
 
load wine
opts  = cov_cv('options');
opts.preprocessing = 2;
[ccov,results] = cov_cv(wine,opts);
axis([0 5 1e-2 1e1]), vline(results.ncomp), hline(results.s(1)/results.options.condmax)
title(['wine: 10x5 ',get(get(gca,'title'),'string')],'interpreter','none'), figfont
 
%End of COV_CVDEMO
 
echo off
