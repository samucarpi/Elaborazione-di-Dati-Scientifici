function out = changeCacheView(obj,parent,varargin)
%CHANGECACHEVIEW Change cache view.
%I/O: .changecacheview('date')
%I/O: .changecacheview('type')
%I/O: .changecacheview('lineage')

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

leafname = ['viewby' varargin{1}];

%This is just a "dummy" structure, it's not currently used by browse when
%changing view.
mystruct.val = ['settings/' leafname];
mystruct.nam = leafname;
mystruct.str = ['View Cache By ' varargin{1}];
mystruct.icn = which('info.gif');
mystruct.isl = logical([ 1 ]);
mystruct.clb = 'browse';
mystruct.chd = [ ];


browse('tree_callback',parent.handle,varargin{1},mystruct,[])

out = 1;
