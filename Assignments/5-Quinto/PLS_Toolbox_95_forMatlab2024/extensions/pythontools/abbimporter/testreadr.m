function [dsos] = testreadr
%TESTABBREADR Test abbspectrumreadr import of spectrum files

thisdir = fileparts(which("testreadr"));

datafiles = dir([thisdir filesep 'Data' filesep '*.spectrum']);

dsos = cell(length(datafiles),1);

for i=1:length(dsos)
  i
  try
    dsos{i} = abbspectrumreadr([datafiles(i).folder filesep datafiles(i).name]);
  catch E
    disp(['Error reading ' datafiles(i).name])
    disp(encode(E.message))
  end
end