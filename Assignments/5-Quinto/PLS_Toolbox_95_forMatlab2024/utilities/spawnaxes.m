function spawnaxes(handle)
%SPAWNAXES Split off the current sub-axes object as its own figure. 
% The current figure's axes are copied onto a new figure and stretched to
% default full-size axes. Optional input (handle) spawns the given axes to
% a new figure.
%
%I/O: spawnaxes(handle)
%
%See also: MPLOT

%Copyright Eigenvector Research 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1;
  handle = gca;
end

fig = figure; 
pos = get(gca,'position'); 
delete(gca); 
newax = evricopyobj(handle,fig);
set(newax,'position',pos);
set(newax,'uicontextmenu',[]);
