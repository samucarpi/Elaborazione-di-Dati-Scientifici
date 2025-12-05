function index = num2ind(i,sizeX)
%NUM2IND Finds the index for element in array given the number of the element.
%
% If X is e.g. a three-way array and i is an integer number, then 
% X(i) = X(index(1),index(2),index(3))
%
% I/O index = num2ind(i,sizeX)
%

%Copyright Eigenvector Research 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified 10/01 rb


index = [];

sX = sizeX;
for j = length(sizeX):-1:1
   prX = prod(sX(1:end-1));
   modx = mod(i,prX);if modx==0;modx=prX;end
   index(j) = ((i-modx)/prX)+1;
   i = i-(index(j)-1)*prX;
   sX = sX(1:end-1);
end
