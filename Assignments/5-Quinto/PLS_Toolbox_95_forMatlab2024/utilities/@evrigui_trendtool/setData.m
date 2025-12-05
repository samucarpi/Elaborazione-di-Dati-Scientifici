function out = setData(obj,parent,varargin)
%SETDATA Assigns data being analyzed in TrendTool.
%I/O: .setData(data)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

[mydata,figtype] = trendmarker('getobjdata',parent.handle);
switch figtype
  case 'plotgui'
    myid = plotgui('getlink',parent.handle);
    myid.object = varargin{1};
    trendlink(parent.handle,'on');  %update trend
  otherwise
    myid = getshareddata(parent.handle);
    myid{1}.object = varargin{1};
end
out = 1;  

