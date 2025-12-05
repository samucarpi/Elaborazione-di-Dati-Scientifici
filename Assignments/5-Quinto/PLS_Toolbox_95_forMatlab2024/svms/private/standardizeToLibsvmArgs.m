function args = standardizeToLibsvmArgs(args)
%STANDARDIZETOLIBSVMARGS convert arguments to libsvm expected form, names and values.
% standardizeToLibsvmArgs converts arguments (names and values) to libsvm expected form
% Users may use abbreviated argument name or the full name, case insensitively.
% For example, 'c', 'C', 'Cost', 'cost', 'COST' are mapped to 'c'.
% Users may use abbreviated argument values, or string form. 
% For example,  the 's' arg value '0' means use C-classification, which
% might be called using 'C-SVC'. This value is converted to '0'.
%
% %I/O: out = standardizeToLibsvmArgs(options); convert option, names and 
% values, to libsvm expected form.
%
%See also: CONVERTTOLIBSVMARGNAMES, CONVERTTOLIBSVMARGVALUES

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

% conversion of argument names to that expected by libsvm (e.g. Cost -> c).
args = convertToLibsvmArgNames(args);

% conversion of argument values to that expected by libsvm
args = convertToLibsvmArgValues(args);
