function [cmd] = executeCondaConfigFiles()
%EXECUTECONDACONFIGFILES Execute config files to find Conda.
%   Execute config files, $CONDA_PREFIX is created from these startup
%   files:
%      ~/.zshrc, ~/.bashrc, ~/.bash_profile
%   Check for prescence of these config files. The variable should be in
%   at least one of these. These files will be hidden but can be exposed
%   by using the -a flag.

cmd = '';
if isunix
  [~,contents] = system('ls -a ~');
  contents = split(contents);
  config_files = {'.zshrc' '.bashrc' '.bash_profile'};
  cmd = '';
  for i=1:length(config_files)
    if ismember(config_files{i},contents)
      cmd = append(['source ~/' config_files{i} ';']);
    end
  end
end
end