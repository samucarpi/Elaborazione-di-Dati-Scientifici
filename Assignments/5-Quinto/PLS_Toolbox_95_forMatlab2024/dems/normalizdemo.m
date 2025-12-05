echo on
% NORMALIZDEMO Demo of the NORMALIZ function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The NORMALIZ function is used to covert each row of a data matrix
% into a normalized vector. The default is to use the 2-norm so that
% the vector is of unit length, however, other norms can be calculated
% as well using optional inputs. The outputs are the matrix of normalized
% vectors and a vector containing the scale factors used to do the
% normalization. To demo the function, we'll use the ARCH data set.
 
load arch
 
pause
%-------------------------------------------------
plot(arch.data')
set(gca,'xtick',1:10,'xticklabel',arch.label{2})
title('Unnormalized ARCH Data'), shg
 
pause
%-------------------------------------------------
% We can now use the NORMALIZ function on the data and plot
% the results.
 
[ndat,norms] = normaliz(arch.data);
plot(ndat')
set(gca,'xtick',1:10,'xticklabel',arch.label{2})
title('Normalized ARCH Data'), shg
 
pause
%-------------------------------------------------
% Note how the scale on the left has changed, and how the lines seem
% to group somewhat more obviously for some elements.
 
echo off
  
   
