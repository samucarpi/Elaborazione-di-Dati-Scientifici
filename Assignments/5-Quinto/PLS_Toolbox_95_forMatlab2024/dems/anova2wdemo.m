echo on
% ANOVA1WDEMO Demo of the ANOVA1W function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
load statdata
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Suppose we have a situation where there are two 
% factors which could affect the outcome of an experiment.
% Typically, we would call the first one a factor and 
% arrange our data into "blocks" where the second
% factor is constant. Consider the following data where
% the concentration of Cr is measured at different
% soil depths and different distances from a hazardous
% waste site:
pause
%-------------------------------------------------
echo off
disp('  ')
disp('    Concentration of Cr near waste disposal site')
disp('  ')
disp('                     Distance from Site (km)')
disp('             -------------------------------------')
disp('   Depth (m)    1         2         3         4 ')
disp([[0 0.5 1]' a2dat1])
echo on
 
pause
%-------------------------------------------------
% Are both the distance and depth significant in determining
% the concentration of Cr? We can find out using a two way
% analysis of variance with AVOVA2W as follows by simply
% inputing the data matrix (a2dat1) and the desired confidence level.  
pause
%-------------------------------------------------
anova2w(a2dat1,.95)
 
pause
%-------------------------------------------------
% From this we can see that the effect of the factors (the
% distance from the site) and the blocks (the depth) are
% significant at the 95% level.
 
pause
%-------------------------------------------------
% Note that ANOVA2W also accepts dataset objects as inputs
% and will use only the data specified by the includ field.
 
echo off
