function [xint,column_ID] = doeinteractions(x, column_ID)
%DOEINTERACTIONS Calculates interaction terms of a raw DOE matrix.
% Creates product combinations of columns of a DOE matrix.
% INPUTS:
%   x         = the raw DOE matrix (x) and 
%   column_ID = type of interactions to include in the final DOE as either:
%               (A) a scalar numerical value indicating the highest number
%                   of interacting factors to include (A value of 1 (one)
%                   indicates no interactions)
%                   Example: [2]
%               (B) a cell array of numerical vectors indicating which 
%                   column(s) should be combined an in what way(s) to
%                   create the interaction terms.
%                   Example:  { [1] [2] [3] [1 3] }
%                   Scalar cell entries will copy the specified column(s)
%                   directly from (x) into (xint). Vector cell entries will
%                   multiply the corresponding columns together to create
%                   the output column.
% OUTPUTS:
%   xint      = selected columns and interaction columns from x based on
%               column_ID. Interaction columns have values which are unique
%               values for each combination of main effect factor levels.
%   column_ID = cell array of interactions identical to the input (if a
%               cell array was given as input) or created as needed for the
%               given scalar interaction level (if scalar provided as input
%               column_ID) 
%
% EXAMPLE:
%   If column_ID = {[1] [2] [3] [1 2] [2 3]}
%   then xint will contain the first three columns of x (unmodified),
%   followed by two additional columns each of which has distinct values 
%   for each col1:col2 values pair.
%   Another example, column_ID = {[1] [2] [1 2]}
%   x1  x2            xint cols
%   1   1             1  1  1
%   1   2             1  2  2
%   1   3             1  3  3
%   2   1             2  1  4
%   2   2             2  2  5
%   2   3             2  3  6
%
%I/O: [xint,column_ID] = doeinteractions(x, column_ID)
%
%See also: ANOVADOE, FACTDES, FFACDES1

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isdataset(x)
  x = dataset(x);
end

nx = size(x,2);
if isempty(x.label{2})
  x.label{2} = str2cell(sprintf('(F%i)\n',1:nx));
end

if isnumeric(column_ID)
  if numel(column_ID)>1
    error('Expected cell array of interactions or scalar value of interaction level to calculate')
  end
  
  % if userdata.DOE.col_ID not empty then use it to identify factor cols
  % otherwise assume x is basic factors and we want this number of interactions
  if isfield(x.userdata, 'DOE') & isfield(x.userdata.DOE, 'col_ID') & ~isempty(x.userdata.DOE.col_ID)
    effectcols = cellfun(@length, x.userdata.DOE.col_ID)==1;
    x = x(:,effectcols);
    nx = size(x,2);
  end
  
  interactions = column_ID;
  column_ID   = num2cell(1:nx);  %create basic column_ID
  
  %create all combinations of "i" factors up to the number of interactions
  %identfied in options.
  for i=2:interactions
    %     %first do powers
    %     for k=1:nx
    %       column_ID{end+1} = ones(1,i).*k;
    %     end
    %now do real interactions
    if i<=nx
      %as long as we aren't trying to do interactions beyond the number of
      %factors...
      last = (nx-i+1:nx);
      prm = 1:i;             %basic combo of "i" elements
      column_ID{end+1} = prm;   %store this set
      while any(prm<last);   %keep increasing indices until we reach the "last" possible one
        p = max(find(prm<last));  %find right-most index we can increase
        prm(p:end) = prm(p)+(1:i-p+1);   %increase it and reset all after it
        column_ID{end+1} = prm;   %store this set
      end
    end
  end
  
  %AN ALTERNATIVE WAY TO DO THE ABOVE IS THIS:
  %   allperms = sortrows(perms(1:nfacts));
  %   for i=2:interactions
  %     prm = unique(allperms(:,1:i),'rows');             %get combos of i at once
  %     prm = prm(all(diff(prm')>0,1),:);  %drop rows which double-back on themselves (drop duplicates)
  %     col_ID(end+(1:size(prm,1))) = mat2cell(prm,ones(1,size(prm,1)),i)';  %copy into col_ID
  %   end
  
end

%identify order of column_ID entries
order  = cellfun('length',column_ID);

%check for bad column_ID entries
allinds = [column_ID{:}];
if any(allinds>nx) | any(allinds<1)
  error('All Column_ID values must refer to existing columns of x');
end

%start by grabbing all one-way columns
oneway = [column_ID{order==1}];
xint   = x(:,oneway);
lbl    = str2cell(x.label{2});

%then get product columns and augment them on
nway   = column_ID(order>1);
naug   = length(nway);
augx   = zeros(size(x,1),naug);
auglbl = cell(1,naug);
for j=1:naug;
  % get unique index for each combination of main effect factor levels
  % Note: do not use prod. [1][2] gives same as [2][1]!
  [junk,junk,IC] = unique(x(:,nway{j}).data, 'rows');
  augx(:,j) = IC;
  if ~all(nway{j}==nway{j}(1));
    %actual interaction term
    mylbl     = sprintf('(%s) x ',lbl{nway{j}});
    auglbl{j} = mylbl(1:end-3);  %drop ending " x "
  else
    %power term
    auglbl{j} = sprintf('(%s)^%i ',lbl{nway{j}(1)},length(nway{j}));
  end
end

if ~isempty(augx)
  augx = dataset(augx);
  augx.name = '+Interactions';
  augx.label{2} = auglbl;
  xint = [xint augx];
end

%create class to indicate order of each factor
%look for existing "Factor Type" class and add to that if possible
names = xint.classname(2,:);
useset = find(ismember(names,'Factor Type'));
if isempty(useset)
  %can't find that set? locate empty set to use instead
  useset = min(find(cellfun('isempty',xint.class(2,:))));
  if isempty(useset)
    useset = length(names)+1;
  end
end

%get current lookup table for this set
lookup = xint.classlookup{2,useset};
if isempty(lookup)
  %empty? create from scratch
  indx = 0;
  lookup = {1 'Factor'};
  myclass = zeros(1,size(xint,2));
else
  %existing set, add to end
  indx = max([lookup{:,1}])-1;
  myclass = xint.class{2,useset};
end
for j=2:max(order);
  lookup(end+1,1:2) = {indx+j sprintf('%i Term Interaction',j)};
end
xint.classlookup{2,useset} = lookup;
xint.classname{2,useset} = 'Factor Type';
myclass(myclass==0) = order(myclass==0)+indx;  %replace items without class using our "order" variable
xint.class{2,useset} = myclass;

% update doe.userdata.DOE.col_ID
xint.userdata.DOE.col_ID = column_ID;


