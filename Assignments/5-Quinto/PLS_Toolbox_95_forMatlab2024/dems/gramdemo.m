echo on
%GRAMDEMO Demonstrates GRAM and PARAFAC functions
 
echo off
%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw
%nbg 10/00 decay profiles using the gram function fixed
%jms 4/03 updated for v3.0
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% As originally developed, Generalized Rank Annihilation (GRAM)
% is often somewhat difficult to use. The problem is that second
% order systems often suffer from baseline stretching in one of 
% the orders, which limits the direct application of GRAM. An 
% example of this is GC-MS, where changes in the elution times
% of the analytes can cause problems. (Note that these problems
% can often be solved, but not without some additional preprocessing
% of the data.) 
 
% Willem Windig, however, identified a technique for which
% GRAM works beautifully: time decay Nuclear Magnetic Resonance
% (NMR). In time decay NMR, a system is given a magnetic pulse 
% then the NMR spectra are observed as they decay. Different species 
% decay exponentially with different half-lifes. Windig recognized 
% that, because the decay curves are exponential, the profile for a 
% single component is the same within a single scale factor 
% regardless of the time slice one looks at. Different analytes, 
% however, have different profiles because of their different half 
% lives. Because of this, one can use GRAM to decompose a single 
% time decay NMR matrix by inputing slightly different slices of 
% the original matrix. 
pause
%-------------------------------------------------
% We will demonstrate GRAM using nmr_data.mat file in the toolbox. 
% The data consists of a 20 by 1176 matrix of time decay NMR spectra 
% of photographic film. Lets load the data and plot it up.
pause
%-------------------------------------------------
load nmr_data
figure
plot(nmrdata.axisscale{2},nmrdata.data(1:2:20,:));
set(gca,'xdir','reverse')
xlabel('Frequency Shift (ppm)')
ylabel('Intensity')
title('Time Decay NMR Data of Photographic Film')
 
% The figure shows the NMR spectra over the decay time. The
% upper most spectra in the plot corresponds to the earliest
% one in time after the NMR pulse. 
 
% GRAM can be used to extract the pure component spectra and time 
% decay profiles using the 'gram' function as follows:
 
pause
%-------------------------------------------------
% First we will extract two offset time slices from the orginal
% data matrix, nmrdata, as follows:
 
a = nmrdata.data(1:19,:);
b = nmrdata.data(2:20,:);
 
% Now we are ready to call gram. We'll also input the number
% of components to solve for (in this case we know that it is
% 3), and some scales to plot against.
pause
%-------------------------------------------------
close
 
[ord1,ord2,ssq,aeigs,beigs] = gram(a,b,3,1:19,nmrdata.axisscale{2});
 
echo off
set(gca,'xdir','reverse')
echo on
 
pause
%-------------------------------------------------
% In the figure we can see the recovered profiles in both of
% the orders. The first order is time and the exponential decay
% of the profiles is evident. The second order is the spectra,
% and we see the pure component spectra of each of the three
% analytes: water (the one with the fastest decay), gel and
% backing. 
 
pause
%-------------------------------------------------
% GRAM has a requirement that the none of the components in the
% two matrices can occur in the the same ratio. In other words,
% if the ratio of two of the analytes in the first matrix is 2:1,
% GRAM won't work if the ratio of these two analytes in the second
% matrix is also 2:1. This isn't a problem in our example because
% the exponential decay makes the apparent "concentrations" of
% the analytes different in each of the subsets of the data. 
% However, this can be a problem in some data sets. Consider for
% a moment a 3 analyte system with three samples where the 
% concentrations are [1 1 1], [1 1 2] and [2 1 2]. If one chooses
% any two of these samples, there are a pair of analytes that
% have the same ratio in both samples. Thus GRAM will not work
% on any pair of these samples. 
pause
%-------------------------------------------------
% We can demonstrate this using some synthetic data starting from 
% the solution just obtained. We will create three matrices, 
% a, b and c with the "analyte" ratios noted above:
 
a = ord1*ord2;
b = ord1*diag([1 1 2])*ord2;
c = ord1*diag([1 2 1])*ord2;
pause
%-------------------------------------------------
close
 
% We can try each of these pairs with GRAM and see if what we
% get looks like the pure component spectra that we know went
% into them. For example, lets try a and b:
 
[ord1,ord2,ssq,aeigs,beigs] = gram(a,b,3,1:19,nmrdata.axisscale{2});
echo off
set(gca,'xdir','reverse')
echo on
 
pause
%-------------------------------------------------
% So that doesn't look very good. There are negative peaks
% in the spectra and negative "concentrations." How about
% samples a and c?
pause
%-------------------------------------------------
close
 
[ord1,ord2,ssq,aeigs,beigs] = gram(a,c,3,1:19,nmrdata.axisscale{2});
echo off
set(gca,'xdir','reverse')
pause
%-------------------------------------------------
echo on
 
% This doesn't look so good either. How about b and c?
pause
%-------------------------------------------------
close
 
[ord1,ord2,ssq,aeigs,beigs] = gram(b,c,3,1:19,nmrdata.axisscale{2});
echo off
set(gca,'xdir','reverse')
echo on
 
pause
%-------------------------------------------------
% We see that in each case the pure component spectra are
% not recovered. So how can this be solved? The answer is
% the Tri-Linear Decomposition (TLD). TLD uses GRAM at its
% heart, but it combines the a, b and c matrices in a way
% that creates a pair of matrices that include contributions
% from each of the analytes in differing ratios. First,
% though, we need to store the matrices as a multiway array.
pause
%-------------------------------------------------
mwa(:,:,1) = a;
mwa(:,:,2) = b;
mwa(:,:,3) = c;
pause
%-------------------------------------------------
% Of course, if we want to be at least a little realistic,
% we should add some noise.
 
mwa = mwa + randn(size(mwa))*.001;
pause
%-------------------------------------------------
% We are now ready to use the TLD algorithm which is part of the PARAFAC
% function
pause
%-------------------------------------------------
close
 
model = parafac(mwa,3,[],struct('algo','tld','plots','none'));
 
echo off
subplot(2,1,1)
plot(model.loads{1})
subplot(2,1,2)
plot(nmrdata.axisscale{2},model.loads{2})
set(gca,'xdir','reverse')
echo on
 
% So you can see that by using TLD we managed to recover
% the pure component spectra and time profiles even though we
% weren't able to do it using any pair of the two data matrices.
pause
%-------------------------------------------------
%End of GRAMDEMO
 
echo off
