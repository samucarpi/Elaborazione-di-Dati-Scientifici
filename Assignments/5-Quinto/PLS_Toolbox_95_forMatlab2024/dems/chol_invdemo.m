
echo on
% CHOL_INVDEMO Demo of the CHOL_INV function
 
echo off
% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The CHOL_INV function is used to calculate a regularized inverse of
% X'*X based on the Cholesky decomposition.
%
% The algorithm is intended to optimize the calculation based on speed 
% while providing a reasonably accurate inverse.
%
% Given the input data matrix (x) = X, the regularization procedure is an
% automated ridging procedure that attempts to set the condition number of
% X'*X to an approximate value given by input (c).
% The inverse of X'*X is approximated as inv(x'*x + eye(size(x,2))*trace(x'*x)/c).
% although the calculation is performed a little differently.
 
% This demo is a test that provides the relative time for two different
% methods for estimating an inverse using SVD, CHOL_INV and MLDIVIDE.
% Accuracy is based on a comparison to the SVD inverse as the RMS
% difference of the elements of each inverse.
% The inputs include X that is M by N where M = 10*N (i.e., M>N for all
% tests) and a condition number c = 1e6.
 
% Hit a return to start the comparison. Edit the code (cov_invdemo.m) to
% examine the test code.
 
pause
 
echo off
 
nx    = [10 100 1000];       %Number of variables (columns) of X.
mr    = 100;                 %Number of times to repeat the test
c     = 1e6;                 %Condition number (approximate)

etim  = zeros(3,length(nx)); %Average times for the tests
erri  = zeros(2,length(nx)); %RMS difference with SVD inverse.
hwb   = waitbar(0,' ');
hwb.Name  = 'COV_INV demo';
for i1=1:length(nx)
  waitbar((i1-0.5)/length(nx),hwb,['cov inv demo running, N = ',int2str(nx(i1))]);
  for i2=1:mr
    x     = randn(nx(i1)*10,nx(i1));
    mx    = size(x,1);
    %SVD
    tstrt = tic;
    z     = x'*x/mx;
    [u,s] = svd(z+spdiag(nx(i1))*trace(z)/c,'econ');
    cinv  = u*inv(s)*u';
    etim(1,i1) = etim(1,i1)+toc(tstrt);
    %CHOL_INV
    tstrt = tic;
    z     = x/sqrt(mx);
    cinw  = chol_inv(z,c);
    etim(2,i1) = etim(2,i1)+toc(tstrt);
    erri(1,i1) = erri(1,i1)+rmse(cinv(:),cinw(:)).^2;
    %MLDIVIDE
    tstrt = tic;
    z     = x'*x/mx;
    cinw  = (z+spdiag(nx(i1))*trace(z)/c)\speye(nx(i1));
    etim(3,i1) = etim(3,i1)+toc(tstrt);
    erri(2,i1) = erri(2,i1)+rmse(cinv(:),cinw(:)).^2;
  end
  waitbar(i1/length(nx),hwb)
end
close(hwb)

etim  = 1000*etim/mr;
h     = figure('Name','Log(Time)');
bar(log10(etim')), grid
ylabel('Log10(Time) [log10(ms)]')
legend('SVD','Chol Inv','MLDIVIDE','location','northwest')
set(gca,'xticklabel',{'10', '100', '1000'})
xlabel('\itN','interpreter','tex'), figfont

erri  = sqrt(erri/mr);
h(2)  = figure('Name','RMSE');
bar(erri')
ylabel('RMS Difference of Chol_inv with SVD')
legend('Chol Inv','MLDIVIDE')
set(gca,'xticklabel',{'10', '100', '1000'})
xlabel('\itN','interpreter','tex'), figfont
h(2).Position = h(1).Position+[20 -20 0 0];
 
disp('Ratio of times for SVD to CHOL_INV for all N')
disp(etim(1,:)./etim(2,:))
disp('Ratio of times for SVD to MLDIVIDE for all N')
disp(etim(1,:)./etim(3,:))
disp(' ')
 
%End of COV_INVDEMO
  