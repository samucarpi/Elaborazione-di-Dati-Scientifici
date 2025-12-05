echo on
%PLSNIPALDEMO Demo of the PLSNIPAL function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% PLSNIPAL is usually called as a subprogram of PLS, since it
% calculates only one latent variable. Here we'll calculate just
% two latent variables for the NIPALS algorithm.
 
load plsdata
whos
 
pause
%-------------------------------------------------
% For this demo we will extract the data from the DataSet
% objects and mean center.
 
[mcx,mx] = mncn(xblock1.data);        %mean center cal X-block 300x20
[mcy,my] = mncn(yblock1.data);        %mean center cal Y-block 300x1
 
pause
%-------------------------------------------------
% Next we'll estimate the first LV using the PLSNIPAL function.
 
[p1,q1,w1,t1,u1] = plsnipal(mcx,mcy);
 
% These outputs are:
%  p1 = X-block loadings on LV 1,
%  q1 = Y-block loadings on LV 1,
%  w1 = X-block weights on LV 1,
%  t1 = X-block scores on LV 1, and
%  u1 = Y-block scores on LV 1.
 
pause
%-------------------------------------------------
% The inner relationship regression vector for a 1 LV model is:
 
b1  = u1'*t1/(t1'*t1);
 
pause
%-------------------------------------------------
% Now the X- and Y-blocks are decompressed ...
 
mcx = mcx - t1*p1';
mcy = mcy - b1*t1*q1';
 
pause
%-------------------------------------------------
% ... and the next LV is calculated:
 
[p2,q2,w2,t2,u2] = plsnipal(mcx,mcy);
 
% These outputs are:
%  p2 = X-block loadings on LV 2,
%  q2 = Y-block loadings on LV 2,
%  w2 = X-block weights on LV 2,
%  t2 = X-block scores on LV 2, and
%  u2 = Y-block scores on LV 2.
 
pause
%-------------------------------------------------
% The inner relationship regression vector for a 2 LV model is:
 
b2  = u2'*t2/(t2'*t2);
 
% This procedure is continued until all the LVs
% are estimated.
 
%End of PLSNIPALDEMO
 
echo off
