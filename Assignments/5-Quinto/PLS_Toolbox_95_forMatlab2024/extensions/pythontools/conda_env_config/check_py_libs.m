function [flag] = check_py_libs
%CHECK_PY_LIBS Calibrates pyenv to use Python libraries and not Matlab
%libraries.
%   On UNIX systems, the Python module sys contains methods to set and get
%   the flags that correspond to the way libraries are accessed via
%   dlopen(). Some Python modules have libraries in common with Matlab when
%   Matlab is opened. Because of this, there can be version mismatches when
%   some Python code is executed. Changing this flag will tell Python to
%   use its own libraries so it prevents library version mismatches. The
%   library, libprotobuf, is just one example of a library that can be used
%   by both Python packages and Matlab. Setting the flag to 10 makes sure
%   Python will use its own libraries, which will be checked here and
%   changed if needed.
%
%  INPUT: None
%
%  OUTPUT:
%    flag = Should be 10 on UNIX systems, a code that tells dlopen() how to
%           use these libraries. Returns 'windows' if not a UNIX system.
%
%
%  I/O: flag = check_py_libs
%
%See also: config_pyenv
%  smr

if isunix
    flag = double(py.sys.getdlopenflags());
    if flag ~= 10
       terminate(pyenv);
       py.sys.setdlopenflags(int32(10));
       flag = 10;
    end
else
    flag = 'windows';
end
end

