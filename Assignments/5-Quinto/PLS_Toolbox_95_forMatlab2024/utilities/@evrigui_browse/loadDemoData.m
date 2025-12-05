function out = loadDemoData(obj,parent,varargin)
%CHANGECACHEVIEW Load demo data from cache to workspace.
%I/O: .loaddemodata('arch')

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))


%Create demo struct.
mystruct.val = ['demo/' varargin{1}];
mystruct.nam = varargin{1};
mystruct.str = [varargin{1}];
mystruct.icn = which('data.gif');
mystruct.isl = logical([ 1 ]);
mystruct.clb = 'browse';
mystruct.chd = [ ];

%Change current varaible.
browse('tree_callback',parent.handle,varargin{1},mystruct,[]);
%Call double-click.
browse('tree_double_click',parent.handle,'cache',[],[]);
out = 1;
