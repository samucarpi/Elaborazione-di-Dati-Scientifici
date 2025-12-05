function [] = set_pyenv_flags
%SETFLAGS Set pyenv unix dlopen flags to 10
%   Wrapper to set the dlopen flags to 10 to ensure Python uses its own
%   libaries. Not applicable for Windows machines.
if isunix
  py.sys.setdlopenflags(int32(10));
end
end

