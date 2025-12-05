function cvi = stratifiedcvi(dso, classset, cvinfo)
%STRATIFIEDCVI Create a stratified cross-val index vector for a given method and class set.
%  Create a stratified cross-validation index vector for given class set 
%  in a Dataset Object and a given cross-val method. This method will apply
%  the cross-val method on each class at a time and then combine the
%  resulting cross-val index vectors.
%  Inputs are: 
%  1) DataSet Object with classes
%  2) The class set to use or vector of numerical class assignments
%  3) Cross val method information, cell array which should contain:
%     method: a string defining the cross-validation method defined below, 
%     n: the number of subsets to split the data into, 
%     blocksize: the number of items to include in each block 
%                (NOTE: blocksize for 'vet' method only)
%  The method string can be any of the following:
%   'vet'   : Venetian blinds. Every n-th item is grouped together.
%             Optionally allows grouping of more than one sample together
%             using "blocksize" input. 
%   'con'   : Contiguous blocks. Consecutive items are put into n groups.
%   'loo'   : Leave one out. Each item is in an individual group, input
%              (n) can be omitted.
%   'rnd'   : Random. items are randomly split into n equal sized groups.
%
%  Output (cvi) is a vector containing the group number of each item.
%
%I/O: cvi = stratifiedcvi(dso,classset,cvinfo)
%I/O: cvi = stratifiedcvi(dso,1,{'loo'}) using Leav-One out cross-val
%I/O: cvi = stratifiedcvi(dso,1,{'vet' 5 2}) using venetian blinds cross-val
%I/O: cvi = stratifiedcvi(dso,1,{'con' 2}) using contiguous blocks cross-val
%I/O: cvi = stratifiedcvi(dso,1,{'rnd' 2}) using random cross-val
%
%See also: CROSSVAL, ENCODEMETHOD, CVIFROMCLASS

%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; dso = 'io'; end
if ischar(dso);
  options = [];
  if nargout==0; evriio(mfilename,dso,options); else; cvi = evriio(mfilename,dso,options); end
  return;
end

errorString = parseInputs(dso, classset,cvinfo);
if ~isempty(errorString)
    evrierrordlg(errorString);
    cvi = [];
  return
end
if isscalar(classset)
  testForEmptyClass = cellfun(@isempty, dso.class(1,:));
  findEmptySets = find(testForEmptyClass);
  if all(testForEmptyClass)
    evrierrordlg('No classes found in DataSet','No classes found');
    cvi = [];
    return;
  end
  
  thisClassInfo = dso.class{1,classset};
  if isempty(classset) | any(classset == findEmptySets) |  isempty(thisClassInfo)
    evrierrordlg('Empty Class Set supplied.', 'Empty Class Set');
    cvi = [];
    return
  end
  unique_classes = unique(thisClassInfo);
elseif isvector(classset)
  thisClassInfo = classset;
  unique_classes = unique(classset);
end

num_classes = length(unique_classes);

class_sizes = histcounts(thisClassInfo, num_classes);
smallest_class_size = min(class_sizes);
if smallest_class_size < cvinfo{2}
  warning('off','backtrace');
  myWarn = warning('EVRI: The least populated class has %d members, which is less than the number of splits', smallest_class_size);
  warning('on','backtrace');
end
cvi = zeros(size(dso,1),1);

for i = 1:num_classes
  class_indices = find(thisClassInfo == unique_classes(i));
  num_points_per_class = length(class_indices);
  mycvi = encodemethod(num_points_per_class,cvinfo);
  cvi(class_indices) = mycvi;
end

%----
function errorString = parseInputs(dso, classset, cvinfo)
errorString = [];
if ~isdataset(dso)
  errorString = 'First input must be a DataSet Object';
  return
end
if isempty(classset)
  errorString = 'No class set supplied';
  return
end
if ~iscell(cvinfo)
  errorString = 'CV info should be cell array with cross-validation method and settings';
  return
end


