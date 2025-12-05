function putlabel(x,y,names,z,znames)
%PUTLABEL labels observations in 2- or 3-dimensional figures.
%  If no labels are given, the indices are used.
%
%  INPUTS:
%    x = x-coordinates of the data
%    y = y-coordinates of the data
% 
%  OPTIONAL INPUTS::
%   names : labels to be added on the plot. They must be listed in a
%           column vector. 
%       z : z-coordinates of the data
%  znames : labels to be added on the 3D-plot. They must be listed in a
%           columnvector.
%
% This function is part of LIBRA:  the Matlab Library for Robust Analysis,
% available at: http://wis.kuleuven.be/stat/robust.html
%
%I/O: putlabel(x,y,names,z,znames)

% Written by S. Verboven on 01/10/2002
% Last update on 18/02/2004
% nbg 1/07 changed help

xrange=get(gca,'Xlim');
range=xrange(2)-xrange(1);
if nargin<3
   for i=1:length(x)
      text(x(i)+range/50,y(i),num2str(i));
   end
else
   if nargin<4
      for i=1:length(x)
         text(x(i)+range/50,y(i),names(i,:));
      end
   else
      if nargin<5
         for i=1:length(x)
            text(x(i)+range/50,y(i),z(i),num2str(i));
         end
      else
         for i=1:length(x)
            text(x(i)+range/50,y(i),z(i),znames(i,:));
         end
      end
   end
end


         


   
   