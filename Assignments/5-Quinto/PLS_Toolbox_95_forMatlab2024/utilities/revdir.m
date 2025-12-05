function revdir(fig)
%REVDIR Called when user clicks "reverse" button

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

ax = get(fig,'currentaxes');
switch get(gca,'xdir'); 
  case 'reverse'; 
    set(gca,'xdir','normal'); 
  case 'normal'; 
    set(gca,'xdir','reverse'); 
end

if strcmpi(getappdata(fig,'figuretype'),'plotgui')
  plotgui('update','figure',fig);
end
