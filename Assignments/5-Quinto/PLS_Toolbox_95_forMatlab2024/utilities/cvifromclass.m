function cvi = cvifromclass(dso,classset,cvinfo)
%CVIFROMCLASS Create a cross-val index vector for a given method and class set.
%  Create a cross-validation index vector for given class set in a Dataset 
%  Object and a given cross-val method.
%  Inputs are: 
%  1) DataSet Object with classes
%  2) The class set to use or vector of numerical class assignments
%  3) Cross val method information, cell array which should contain:
%     method: a string defining the cross-validation method defined below, 
%     n: the number of subsets to split the data into, 
%     blocksize: the number of items to include in each block 
%                (NOTE: blocksize for 'vet' method only)
%  Method can be any of the following:
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
%I/O: cvi = cvifromclass(dso,classset,cvinfo)
%I/O: cvi = cvifromclass(dso,1,{'loo'}) using Leav-One out cross-val
%I/O: cvi = cvifromclass(dso,1,{'vet 5 1'}) using venetian blinds cross-val
%I/O: cvi = cvifromclass(dso,1,{'con 2'}) using contiguous blocks cross-val
%I/O: cvi = cvifromclass(dso,1,{'rnd 2'}) using random cross-val
%
%See also: CROSSVAL, ENCODEMETHOD, STRATIFIEDCVI

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

cvi = [];
errorString = parseInputs(dso, classset,cvinfo);
if ~isempty(errorString)
    evrierrordlg(errorString);
  return
end

if isnumeric(cvinfo)
  cvi = cvinfo;
  return
end

if strcmp(cvinfo{1},'vet')
  blindsize = cvinfo{3};
  if blindsize ~=1
    cvinfo{3} = 1;
    evriwarndlg('Blind size must be 1 when using Venetian Blinds. Blind size set to 1', 'Blind Size Warning')
  end
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
  
  uniqueClassNums = unique(dso.class{1,classset});
  cvClassInds = encodemethod(length(uniqueClassNums),cvinfo);
  if isempty(cvClassInds)
    cvi = cvClassInds;
    return
  end
  cvMap = containers.Map(uniqueClassNums, cvClassInds);
  cvi = arrayfun(@(x)cvMap(x),dso.class{1,classset});
elseif isvector(classset)
  uniqueClassNums = unique(classset);
  cvClassInds = encodemethod(length(uniqueClassNums),cvinfo);
  cvMap = containers.Map(uniqueClassNums, cvClassInds);
  cvi = arrayfun(@(x)cvMap(x),classset);
end

%Leave this code commented out for now. To revisit for 9.4
% if all(cvi==1)
%   if strcmp(cvinfo{1},'vet')
%     blindsize = cvinfo{3};
%     maxNumberOfClassesToUse = max(uniqueClassNums)-1;
%     if blindsize>maxNumberOfClassesToUse
%       warning('off','backtrace');
%       myWarn = warning('EVRI: Blindsize is too large for given class set. Using blindsize of: %d', maxNumberOfClassesToUse);
%       warning('on','backtrace');
%       cvi = cvifromclass(dso,classset,{'vet' cvinfo{2} maxNumberOfClassesToUse});
%     end
%   else
%     evrierrordlg('Invalid CVI: CVI is all ones. Try different different cross-val settings', 'Invalid CVI');
%     cvi = [];
%   end
% end

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

