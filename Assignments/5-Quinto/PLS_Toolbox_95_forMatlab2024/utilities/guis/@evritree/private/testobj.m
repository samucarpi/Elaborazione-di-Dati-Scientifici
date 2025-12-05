function [t,c] = testobj(varargin)
%EVRITREE/TESTOBJ Test script for evritree object.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Basic data and call.



c(1).val = 'settings';
c(1).nam = 'settings';
c(1).str = 'Cache Settings and View';
c(1).icn = '/Users/scottkoch/Desktop/work/LocalSVNR/pls/app/trunk/help/settings.gif';
c(1).isl = logical([ 0 ]);
c(1).chd(1).val = 'settings/viewbylineage';
c(1).chd(1).nam = 'viewbylineage';
c(1).chd(1).str = 'View Cache By Lineage';
c(1).chd(1).icn = '/Users/scottkoch/Desktop/work/LocalSVNR/pls/app/trunk/help/info.gif';
c(1).chd(1).isl = logical([ 1 ]);
c(1).chd(1).clb = 'analysis';
c(1).chd(1).chd = [ ];
c(1).chd(2).val = 'settings/viewbydate';
c(1).chd(2).nam = 'viewbydate';
c(1).chd(2).str = 'View Cache By Date';
c(1).chd(2).icn = '/Users/scottkoch/Desktop/work/LocalSVNR/pls/app/trunk/help/info.gif';
c(1).chd(2).isl = logical([ 1 ]);
c(1).chd(2).clb = 'analysis';
c(2).val = 'demo';
c(2).nam = 'demo';
c(2).str = 'Demo Data';
c(2).icn = '/Users/scottkoch/Desktop/work/LocalSVNR/pls/app/trunk/help/folder.gif';
c(2).isl = logical([ 0 ]);
c(2).chd(1).val = 'demo/alcohol';
c(2).chd(1).nam = 'alcohol';
c(2).chd(1).str = 'Alcoholics Biological Data';
c(2).chd(1).icn = '/Users/scottkoch/Desktop/work/LocalSVNR/pls/app/trunk/help/data.gif';
c(2).chd(1).isl = logical([ 1 ]);
c(2).chd(1).clb = 'analysis';
c(2).chd(2).val = 'demo/aminoacids';
c(2).chd(2).nam = 'aminoacids';
c(2).chd(2).str = 'Aminoacid Fluorescence EEMs';
c(2).chd(2).icn = '/Users/scottkoch/Desktop/work/LocalSVNR/pls/app/trunk/help/data.gif';
c(2).chd(2).isl = logical([ 1 ]);
c(2).chd(2).clb = 'analysis';


a = evritree('tree_data',c,'root_visible','off','root_handles_show','off','selection_type','contiguous')%,'','')


%Try default file.
dftree = evritree('root_visible','off','selection_type','contiguous');
set(dftree,'units','normalized','position',[0 0 1 1]);%Test set function.
%Try extracting scroll pane.









