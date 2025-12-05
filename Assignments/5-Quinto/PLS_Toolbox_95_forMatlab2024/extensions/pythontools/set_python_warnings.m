function [] = set_python_warnings(warning_switch)
%SET_PYTHON_WARNINGS Governs the level of Python warnings displayed.
%   Takes in 'off' or 'on' for the warning_switch variable which will
%   govern the level Python warnings displayed in the Command Window.
%   Passing 'off' will silence all warnings. Turning on the warnings with
%   'on' will pass Python warnings, but some unhelpful warnings are filtered
%   out. Any other value passed for warning_switch will default to 'off'.
%
%I/O: set_python_warnings('off');
%I/O: set_python_warnings('on');
%
%See also: get_python_status

%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%  smr

orig_dir = pwd;
filepath = fileparts(mfilename('fullpath'));
cd(filepath);


switch warning_switch
  case 'off'
    py.warnings.simplefilter('ignore');
  case 'on'
    py.warnings.simplefilter('default');
    %ignore warnings from sys next
    %this is because it returns a deprecation warning each time data is
    %passed from MATLAB to Python. Not particularly useful or avoidable on our part.
    py.warnings.filterwarnings('ignore',pyargs('module','sys'));
    %run Python script for special warnings to filter out
    py.set_python_warnings.main();
  otherwise
    py.warnings.simplefilter('ignore');
    warning('EVRI:PythonWarnings', 'Unrecognized value passed for Python warnings. Silencing Python warnings.');
end

cd(orig_dir);

end

