function out = evrigui_trendtool(varargin)
%EVRIGUI_fcn Creates EVRIGUI interface to a given GUI type

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%GENERIC CODE (to allow easy creation of new objects from this template)
out = [];
out.([mfilename 'version']) = 1.0;
out = class(out,mfilename);
