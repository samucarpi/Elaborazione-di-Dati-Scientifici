function [coeff,bint,res] = regress(y,x);
% Helper function for OLS.
% BMW 7-29-2006

coeff = x\y;
bint = 0;
res = y - x*coeff;