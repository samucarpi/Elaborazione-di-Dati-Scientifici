
%EVRIRELEASE Returns Eigenvector product release number.
% If no input then returns product and release for current folder
% (location). If input given then searches for particular product (e.g.
% 'PLS_Toolbox', 'MIA_Toolbox') or, give the key word 'all', function will
% return cell arrays of all products and releases.
%
%I/O: [release,product, path, rdate] = evrirelease
%I/O: [release,product, path, rdate] = evrirelease('PLS_Toolbox')
%I/O: [release,product, path, rdate] = evrirelease('all')
%
%See also: EVRIDEBUG, EVRIINSTALL, EVRIUPDATE

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
