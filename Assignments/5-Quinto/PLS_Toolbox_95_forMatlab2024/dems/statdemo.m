echo on
%STATDEMO Elementary stats, t test, F test and AVOVA
 
echo off
%Copyright Eigenvector Research, Inc. 1994
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% This script demonstrates the elementary statistics
% functions in the PLS_Toolbox including the t test,
% F test, and one- and two- way analysis of variance.
 
% The development in the script follows Chapter 2 of 
% "Chemometrics" by Sharaf, Illman and Kowalski, John Wiley
% & Sons, 1986.
 
load statdata
 
pause
%-------------------------------------------------
% First consider the t test. A t test can be used to
% compare the means of two samples ("samples" here is a
% a collection of measurements). For instance, suppose
% that we have tested the percent yield from a given
% chemical reaction using two different catalysts and
% would like to determine if the difference in yield
% is significant. A table of our data is below:
 
pause
%-------------------------------------------------
echo off
disp('  ')
disp('Percent yield with A and B')
disp('    A      B')
disp(a1dat(:,1:2))
disp('   ')
disp('Mean yield with A and B')
disp(mean(a1dat(:,1:2)));
disp('  ')
disp('Yield variance with A and B')
disp(std(a1dat(:,1:2)).^2);
echo on
 
% For the moment, assume that the populations for
% each catalyst should have equal variance, even though
% it is apparent that our sample variances are not equal.
 
pause
%-------------------------------------------------
% The t test statistic is defined as
%
%         [(x1bar-x2bar)-(mu1-mu2)][n1+n2-2]^0.5 
% t = -----------------------------------------------
%  v  [1/n1 + 1/n2]^0.5 [(n1-1)s1^2 + (n2-1)s2^2]^0.5
%
% where
% n1, n2     = size of first and second samples
% mu1, mu2   = true mean of first and second populations
% s1^2, s2^2 = variance of first and second samples
% v          = n1 + n2 - 2 is the degress of freedom
 
pause
%-------------------------------------------------
% The quantity
%
%     (n1-1)s1^2 + (n2-1)s2^2
%     -----------------------
%           n1 + n2 - 2
% 
% is the pooled variance and is the best unbiased estimator
% of the population variance.
 
% If we assume that mu1 = mu2 then the t statistic can
% be calculated as follows:
 
pause
%-------------------------------------------------
t_data = abs(((mean(a1dat(:,1))-mean(a1dat(:,2)))*sqrt(14))/...
           (sqrt(1/4)*sqrt(7*std(a1dat(:,1)).^2 + 7*std...
	         (a1dat(:,2)).^2)))
 	
% We can now compare this value of t to the value from
% a t table calculated with the TTESTP function.
% The first input to TTESTP is the probability point corresponding
% to the desired confidence level. If we want 95% confidence,
% we would choose 0.025 since 100(1-2*(0.025)) = 95%.
% The second input is the degrees of freedom, which in
% this case is 14=(8 + 8 - 2).
% The final input is a flag which tells the function that the
% input is a probability point and it should return the t statistic
% (we will use the other way around shortly).
 
t_table = ttestp(0.025,14,2)
 
pause
%-------------------------------------------------
% As you can see, t from the data is greater than the value
% expected from TTESTP. The value from TTESTP is what would
% be expected if the difference were due to random error.
% The fact that t_data>t_table tells us that the means are
% significantly different at the 95% level.
 
% Note however, that if we had chosen the 99% confidence
% level, then TTESTP yields
 
t_table = ttestp(0.005,14,2)
 
% and the difference between catalysts is not significant at
% the 99% level. It is also possible to estimate the
% confidence level at which the test fails using the
% inverse test as follows:
 
pause
%-------------------------------------------------
tt = ttestp(t_data,14,1)
 
% Thus, we see that the hypothesis of equal means fails
% at the 
100*(1-2*tt)
% percent confidence level. Note that we input t_data
% calculated from the data with the correct number of
% degrees of freedom (14) and set the flag to 1 to indicate
% that the input is a t value and the output should be the
% probablility point.
 
pause
%-------------------------------------------------
% Earlier in this example, it was assumed that the population
% variances were equal even though the samples variances
% were clearly unequal. It is easy to check the assumption
% of equal population variances using an F test. To do this,
% we calculate the ratio of the variances of the two samples,
% using the greater variance as the numerator
 
f_data = std(a1dat(:,1))^2/std(a1dat(:,2))^2
 
pause
%-------------------------------------------------
% This value can be compared to the value from an F-table
% to determine its significance. In our case, we have 
% 7 degrees of freedom in each sample, using our F test
% function, FTEST, we obtain
 
f_table = ftest(0.05,7,7) 
 
% and we can see that f_data is much less than the value
% f_table that might be expected if the differences were
% due to random error at 95% confidence. Thus, at 95%
% confidence, there is not evidence to claim that the
% populations have significantly different variances.
 
pause
%-------------------------------------------------
% It is also possible to use the t-test when observations
% are paired. For example, imagine that a series of
% measurements are made on soil samples before and after
% a treatment to remove Hg:
 
echo off
disp('  ')
disp('Concentration of Hg Before and After Treatment')
disp('   Before    After      Difference')
disp([tdat2 tdat2(:,1)-tdat2(:,2)])
echo on
 
pause
%-------------------------------------------------
% In this case, we're interested in the difference
% between the observations before and after treatment.
% Thus, we must test to see if the difference is
% significantly different from zero to see if the
% treatment is effective. The relevant t statistic can
% be calculated from
%
%       dbar - mu
%  t  = --------- sqrt(n)
%   v      sd
%
% where dbar is the mean difference between the samples,
% mu is the true mean difference (assumed 0 in the null
% hypothesis), n is the sumber of samples, v = n-1 is the
% degrees of freedom, and sd is the standard deviation
% of the differences.
 
pause
%-------------------------------------------------
% Applying this we obtain
 
t_data = mean(tdat2(:,1)-tdat2(:,2))*sqrt(10)/ ...
           std(tdat2(:,1)-tdat2(:,2))
 
% Comparing to the t from the tables we get
 
t_table = ttestp(0.05,9,2)
 
% and we can see that the treatment does have a significant
% effect at the 95% confidence level. Note that here we used
% 0.05 since this is a one-sided test - we want to know if
% dbar>0 at 95% confidence.
 
% We can also use the inverse t test to determine the level
% at which the significance test would fails
 
pause
%-------------------------------------------------
tt = ttestp(t_data,9,1)
 
% And we see that the it would fail at the
100*(1-tt)
% percent confidence level.
 
pause
%-------------------------------------------------
% Now suppose that we have added an additional treatment
% to our first data set, e.g. we are now looking at 
% three catalysts instead of two. The percent yields
% for catalysts A, B and C are
 
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
% To see if the treatments are having an effect, we can
% use analysis of variance or ANOVA. In this case, we
% are only looking for the effect of one factor, so we
% will perform one-way ANOVA with the ANOVA1W function.
% The inputs are the data and the desired confidence level.
 
pause
%-------------------------------------------------
anova1w(a1dat,0.95)
 
% From this we can see that the effect of the factor is
% significant at the 95% confidence level, that is, we
% are 95% certain the catalysts are having a significant
% effect on the yield.
 
pause
%-------------------------------------------------
% Now suppose we have a situation where there are two 
% factors which could affect the outcome of the experiment.
% Typically, we would call the first one a "factor" and 
% arrange our data into "blocks" where the second factor
% is constant w/in each block. Consider the following data
% where the concentration of Cr is measured at different
% soil depths and distances from a hazardous waste site:
 
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
% analysis of variance with AVOVA2W as follows. The inputs
% are the data matrix and the desired confidence level.
 
pause
%-------------------------------------------------
anova2w(a2dat1,0.95)
 
pause
%-------------------------------------------------
% From this we can see that the effect of the factors (the
% distance from the site) and the blocks (the depth) are
% significant at the 95% level.
 
% In a final example, suppose that we would like to determine
% if there is a significant difference between the concentration
% of an analyte in some samples and simultaneously determine
% if there is a difference between the methods used to measure 
% the concentrations. The measurements are:
 
pause
%-------------------------------------------------
echo off
disp('   ')
disp('               Measured concentration of Analyte')
disp('                         Sample Number')
disp('             -------------------------------------')
disp('    Method      1         2         3         4         5         6')
disp([[1:5]' a2dat2])
echo on
 
pause
%-------------------------------------------------
% Once again, we can use ANOVA2W to determine if the effects
% of the samples (factors) and method (blocks) are significant.
 
pause
%-------------------------------------------------
anova2w(a2dat2,0.95)
 
% We see that at the 95% level both factors are significant.
 
%End of STATDEMO
%
%See also: TTESTP, FTEST, ANOVA1W, ANOVA2W
 
echo off
