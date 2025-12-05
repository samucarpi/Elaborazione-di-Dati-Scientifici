function [sp,xi] = fastnnls_proj(x,xi,p,y);
%FASTNNLS_PROJ Projection utility for use from FASTNNLS.
% This function is only for use through fastnnls and does not support
% direct user calls
%
%I/O: <not available>
%
%See also: FASTNNLS

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%I/O: [sp,xi] = fastnnls_proj(x,xi,p,y);  
%see fastnnls code for definitions of I/O

% Do the regression using inverse-caching
% Apology: This code is optimized for SPEED and not readibility.
% In order to pull off inverse caching and actually IMPROVE speed, we have to be
% very careful how and what we store. The fastest database method turns out
% to be using a structure with alphanumeric named fields which represent a
% pattern of included variables. 

try
  %QUICKLY create the index pattern which matches the included variables:
  ind = char(p+97);
  
  %Now, try to pull the associated inverse out of the X_inverse (xi) structure. If
  %we get an error, then we know we haven't calculated that inverse yet and
  %we need to do it.
  try
    xi_ind = xi.(ind);    %try to extract the inverse from the matrix.
    sp = xi_ind*y;        %and do the regression
  catch
    %We got here because our x_inverse (xi) matrix didn't have the inverse we
    %were looking for (the field name in "ind" didn't exist).
    xi_ind = pinv(x(:,p));  %calculate inverse
    xi(1).(ind) = xi_ind;   %create a field with alphanumeric "ind" as name, and store that inverse
    sp = xi_ind*y;          %do the regression
  end
  
catch
  %--plain method--
  %if something goes wrong above, just default to using the plain method
  % (note, because some of the code above still gets executed, this apprach
  % will still be SLOWER than the plain method called outright so,
  % therefore, it is advantageous to just use the plain method explictly
  % when that is desired)
  sp = x(:,p)\y;
end

