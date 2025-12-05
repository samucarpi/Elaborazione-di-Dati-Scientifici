function [y,nonzero] = class2logical(cls,groups,classset)
%CLASS2LOGICAL Create a PLSDA logical block from class assignments.
% Given a list of sample classes or a DataSet object with class assignments
% for samples (mode 1), CLASS2LOGICAL creates a logical array in which each
% column contains the logical class membership for each unique class. This
% logical block can be used as y in PLS or PCR to perform Discriminant
% Analysis. Similarly, the output can be used with crossval to perform
% PLSDA cross-validation. Classes can optionally be grouped together by
% providing class groupings. Note that samples marked as class zero (0)
% will be included in no class (zeros for all classes).
%
% INPUTS:
%    clas = a list of class assignments or a dataset with classes assigned
%           for the first mode
% OPTIONAL INPUT:
%  groups = an optional input containing either: 
%          [] a vector of classes to model OR
%          {[] []...} a cell array containing groups of classes to consider
%          as one class. Each cell element will be one class (see e.g.
%          below). Any classes in (cls) which are not listed in (groups)
%          are considered part of no group and will be assigned zero for
%          all columns in the output.
%  classset = when input (cls) is a dataset, classset specifies which class
%             set from (cls) should be used as classes. This defaults to
%             class set 1. An error will occur if the specified class does
%             not exist.
%
% OUTPUTS:
%        y = a DataSet containing a logical array in which each column
%            represents one of the classes in the input class list or one
%            of the groups in (groups).
%  nonzero = the indices of samples with non-zero class assignment. Note:
%            if class zero is explictly referenced in the (groups) input,
%            then nonzero will include all samples.
% 
% Examples:
% (A) Given DataSet "arch" with classes 0-5, the following creates a
%   logical block with two columns consisting of "true" only for class 3 in
%   the first column and "true" only for class 2 in the second column.
%    y = class2logical(arch,[3 2])
%
% (B) Given DataSet "arch" with classes 0-5, the following creates a
%   logical block with two columns consisting of "true" only for classes 0
%   and 1 in the first column and "true" only for classes 2 and 4 in the
%   second column.
%    y = class2logical(arch,{[1 0] [2 4]})
%
%I/O: [y,nonzero] = class2logical(clas,groups,classset)
%
%See also: CROSSVAL, PLSDA, PLSDTHRES

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 3/04
%jms 4/20/04 -better handling of excluded classes
%   -allow groups to be a vector (considered "use these classes only")
%   -give correct nonzero if class was array
%jms 5/6/04 -empty class in dataset returns empty set (no longer errors) 
%jms 6/20/04 -output dataset object with classes on columns
%jms 9/1/04 -added better tests for "nonzero" samples
%jms 12/06 -non-listed classes (in cell) are reassigned as class zero

if nargin == 0; cls = 'io'; end
if ischar(cls);
  options = [];
  if nargout==0; evriio(mfilename,cls,options); else; y = evriio(mfilename,cls,options); end
  return; 
end

if nargin<3;
  %default class set
  classset = 1;
end

%get classes
if isa(cls,'dataset');
  %dataset? extract classes from first mode as classes
  originalcls = cls;
  incl        = cls.include{1};
  clslookup   = cls.classlookup{1,classset};
  cls         = cls.class{1,classset};
else
  %non-dataset? assume all items are included
  %If it is a row vector with anything other than 0 or 1, then transpose it
   if size(cls,1)==1 & length(setdiff(unique(cls), [0 1]))>0
     cls = cls';
   end
  incl = 1:size(cls,1);
  clslookup = {};
  originalcls = cls;
end
if isempty(cls);
  %empty class? return as empty
  y = [];
  nonzero = [];
  return
end
if all(size(cls)>1);
  %multi-column and multi-row? 
  if ~isempty(setdiff([0 1],cls(:)));
    %more than just 0 and 1? 
    error('Multi-column y-blocks must consist of only zeros and ones and will be interpreted as multi-class logical matrices.')
  else
    %just 0 and 1? convert to logical
    cls(~isfinite(cls)) = 0;  %assign nan's as zeros
    y = dataset(logical(cls));
    if isdataset(originalcls)
      y = copydsfields(originalcls,y);
    end
    nonzero = find(any(y.data,2));  %locate all-zero rows
    y.include{1} = incl;
    return
  end
end
if islogical(cls)
  %already logical? use as the column itself INCLUDE ZEROS!
  y = dataset(cls);
  if isdataset(originalcls)
    y = copydsfields(originalcls,y);
  end
  nonzero = [1:size(y,1)]';
  y.include{1} = incl;
  return
end

%combine grouped items (if any) and identify unique classes (except zero)
if nargin>1 & ~isempty(groups)
  if size(groups,1)>size(groups,2);
    groups = groups';
  end
  if ~iscell(groups);
    groups = mat2cell(groups,1,ones(1,length(groups)));
  end
  % for each group, reassign all members the first listed class of that group
  classlookup = {};
  clsnew = cls;

  %Check if any group has more than 1 item OR if any group contains just class zero.
  %IF SO: use "groupclass" value as new class #. 
  %IF NOT: use ORIGINAL class # (groups{j}) as class #
  morethanoneitem = length([groups{:}]) > length(groups);
  containsclasszero = false;
  for j1=1:length(groups);
    if any([groups{j1}]==0)
      containsclasszero = true;
      break;
    end
  end
  usenewclass = morethanoneitem | containsclasszero;
  
  for j=1:length(groups);    
    if usenewclass
      groupclass = j; % this avoids ever setting group class = 0
    else
      groupclass = groups{j};
    end
    
    if ~isempty(clslookup)
      desc = clslookup(ismember([clslookup{:,1}],[groups{j}]),2);
      desc = sprintf('%s,',desc{:});
      desc = desc(1:end-1);
      classlookup(end+1,1:2) = {groupclass desc};
    end
    clsnew(ismember(cls,groups{j})) = groupclass;
    classes(j) = groupclass;
  end
  clsnew(~ismember(cls,[groups{:}])) = 0; %if not in any group set as class zero
  cls = clsnew;
else
  %unspecified groups and non-logical input, infer groups as unique classes
  classes = setdiff(unique(cls(incl)),0);
  if isempty(classes)
    error('No non-zero classes found.');
  end
  classes = classes(:)';
  classlookup = clslookup;
end

%create logical y-block columns for each class in classes
y = (cls(:)*ones(1,length(classes))) == (ones(length(cls),1)*classes);
if ~ismember(classes,0);
  nonzero = find(cls);
else
  nonzero = [1:size(y,1)];
end

y = dataset(y);
y.class{2} = classes;
y.class{1} = cls;
if ~isempty(classlookup)
  if ~ismember(0,[classlookup{:,1}])
    classlookup(end+1,:) = {0 'Unmodeled'};
  end
  y.classlookup{1} = classlookup;
  y.classlookup{2} = classlookup;
end
y.author = 'class2logical';
if nargin>1 & ~isempty(groups)
  y.description = ['Class grouping: ' encode(groups,'')];
  y.userdata.groups = groups;
else
  y.userdata.groups = [];
end
