function eddata = delsamps(data,samps)
%DELSAMPS Deletes samples (rows) or variables (columns) from data matrices.
%  Inputs are the original data matrix (data) of class "double"
%  and the row numbers of the samples to delete (samps).
%  The output is the edited data matrix (eddata).
%
%I/O: eddata = delsamps(data,samps);   %deletes rows (samps) from data
%
%  To delete variables (columns) operate on the matrix transpose
%  were (vars) are the column numbers to delete.
%
%I/O: eddata = delsamps(data',vars)';  %deletes columns (vars) from data
%I/O: delsamps demo
%
%See also: SHUFFLE, SPECEDIT

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified 11/93, 1/96

if nargin == 0; data = 'io'; end
varargin{1} = data;
if ischar(varargin{1}) & any(size(varargin{1})==1) & ismember(varargin{1},evriio([],'validtopics'));
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; eddata = evriio(mfilename,varargin{1},options); end
  return; 
end

[m,n]    = size(data);
[ms,ns]  = size(samps);
if ms>ns
  samps  = samps';
  ns     = ms;
end
samps    = sort(samps);
savsamps = 1:m;
savsamps(samps) = zeros(1,ns);
savsamps = find(savsamps ~= 0);
eddata   = data(savsamps,:);
