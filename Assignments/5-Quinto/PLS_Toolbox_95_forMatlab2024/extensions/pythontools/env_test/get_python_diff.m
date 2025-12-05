function [addons,addons_size,missing,missing_size] = get_python_diff
%GET_PYTHON_DIFF Get added on and missing packages from default PLS_Toolbox
%Python configuration.
%   Since it cannot be guaranteed that the Python methods work if the
%   environment is changed, this script aims to retrieve information as to
%   how the current pyenv is different than the default configuration. The
%   default environment contents are in this directory and are in
%   the corresponding pythonXY.mat files. Each of these will load 3 pickled
%   Python lists, each list containing the valid contents of what should be
%   in the user's Python environment. The .py file takes a set difference
%   between what the user currently has, and what should be there. We get
%   the added and missing packages from check_pyenv.py. The variable addons
%   is a Python set containing added packages. addons_size is the size of
%   that set. missing is a Python set of missing packages and missing_size
%   is the size of that set. These sizes needed to be returned from here because
%   using MATLAB's size of an empty Python set is 1,1. The proper way to
%   get the sizes of these sets is to use py.len().
%
%I/O: [addons,addons_size,missing,missing_size] = get_python_diff
%
%See also: check_pyenv

%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%  smr

%TODO, will eventually have to condition on MATLAB as to which Python env
%to check
pyver = split(whichPython,'_');
pyver = pyver{end};
switch pyver
  case '38'
    load python38.mat;
  case '310'
    load python310.mat;
end

switch computer
  case 'MACI64'
    true = py.pickle.loads(mac);
  case 'MACA64'
    true = py.pickle.loads(macarm);
  case 'PCWIN64'
    true = py.pickle.loads(windows);
  case 'GLNXA64'
    true = py.pickle.loads(linux);
end

results = cell(py.check_pyenv.main(true));
addons = results{1};
addons_size = double(py.len(addons));
missing = results{2};
missing_size = double(py.len(missing));

end

