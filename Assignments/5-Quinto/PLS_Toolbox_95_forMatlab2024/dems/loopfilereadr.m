function out = loopfilereadr(mydir,extension)
%LOOPFILEREADR An example function for reading files in a loop from a directory.
%  The output is a structure array containing one file per elemnt. The
%  "reader" function is textreadr. The input is a directory and optional
%  file extension. This function is written to work for CSV files
%  containing one row of "variable" labels and one column "sample" labels.
%  It is meant as a template for writing custom file reading within a loop.
%  See comments in the code below for examples of changing "readers" and
%  output argument.
%
%  Inputs:
%    mydir      : directory (folder) to search, only searches single
%                 directory, no subdirectories. 
%    extension  : file extension to specify (optional).
%
%  Outputs:
%    out        : structure array with one dataset per element.
%
%  Example of file contents:
%
%     ,columnLabel_1,columnLabel_2,columnLabel_3
%     rowLabel_1,1,2,3
%     rowLabel_2,4,5,6
%     rowLabel_3,7,8,9
%
%  NOTE: the first element (1,1) is empty.
%
%I/O:  out = loopfilereadr('c:\temp\myfiles\','csv')
%
%See also: AREADR, DATASET, SPCREADR, TEXTREADR, XCLGETDATA, XCLPUTDATA, XLSREADR

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk
 
%Test number of arguments passed into function. If less than one, raise
%error. If less than two, make 'extension' default for all files.
if nargin == 0
  error('LOOPFILEREADR requires at least one input.')
elseif nargin == 1
  extension = '*';
elseif isempty(extension)
  extension = '*';
end
 
%Use fullfile command to build filename to search for.
fname = fullfile(mydir,['*.' extension]);

%Use 'dir' command to build list of specified files. 
files = dir(fname);
 
%Remove directories (folders) from files list if present.
files = files(~[files.isdir]);
 
%%INITIATE 'out' variable dataset before loop for augmentation EXAMPLE.
%out = dataset;
 
%Start loop.
for i = 1:length(files)
  %PROGRAMMING NOTE: Here we are using textreadr to bring in (import) a CSV
  %file and put it directly into a DataSet Object. Then each DataSet is
  %added to a structure array in field called "dataset". Then number of
  %elements in the structure array will be equal to the number of files.
 
  %Use textreadr to import csv file into dataset.
  out(i).dataset = textreadr(fullfile(mydir,files(i).name));
  
  %PROGRAMMING NOTE: The output variable used here is a structure array
  %with one element per file. Output could be assigned to a cell array or
  %augmented to one dataset:
  
    %%EXAMPLE of cell array:
    %out{i} = textreadr(fullfile(mydir,files(i).name));
    
    %%EXAMPLE of augmentation (you will need to INITIATE the 'out' variable
    %%before beginning the loop):
    %tempout = textreadr(fullfile(mydir,files(i).name));%create dataset
    %out = cat(1,out,tempout); %First input is dimension to augment onto.
    
  %PROGRAMMING NOTE: You can choose any of a number of different "readers"
  %for importing files. Try finding a reader function and settings for a
  %single file via the command line and then use it within this loop. The
  %following code is an example of using the Matlab function 'dlmread' to
  %read in just numeric data (ignoring labels, row and column) from an
  %example file described above:
    
    %%EXAMPLE using dlmread:
    %out(i).data = dlmread(fullfile(mydir,files(i).name),',',1,1);
    
end


