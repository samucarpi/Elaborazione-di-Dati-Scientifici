echo on
% ANOVA1WDEMO Demo of the ANOVA1W function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% This example uses the "statdata" example data set and, specifically,
% the a1dat variable from that file.
 
load statdata
 
% Suppose that we have tested the percent yield from a given
% chemical reaction using three different catalysts and
% would like to determine if the difference in yield is
% significant. The percent yields for catalysts A, B and C are:
pause
%-------------------------------------------------
echo off
disp('  ')
disp('Percent yield with Catalysts A, B and C')
disp('    A     B     C')
disp(a1dat)
disp('   ')
disp('Mean yield with A, B and C')
disp(mean(a1dat));
disp('  ')
disp('Yield variance with A, B and C')
disp(std(a1dat).^2);
echo on
pause
%-------------------------------------------------
% In order to see if the treatments are having an effect,
% we can use analysis of variance or ANOVA. In this case,
% we are only looking for the effect of one factor, so
% we will perform one-way ANOVA with the ANOVA1W function
% as shown below. We need only input the data (a1dat) and the 
% desired confidence level.
pause
%-------------------------------------------------
anova1w(a1dat,.95)
 
% From this we can see that the effect of the factor is
% significant at the 95% confidence level, that is, we
% are 95% certain the catalysts are having a significant
% effect on the yield.
 
pause
%-------------------------------------------------
% Note that ANOVA1W also accepts dataset objects as inputs
% and will use only the data specified by the includ field.
 
echo off
