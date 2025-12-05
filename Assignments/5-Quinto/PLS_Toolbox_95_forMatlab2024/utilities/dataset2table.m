function x = dataset2table(thisdataset)
%DATASET2TABLE Convert DatasetObject to Matlab Table Object. 
%
%See also: DATASET, PARSEMIXED, TABLE2DATASET

%Copyright Eigenvector Research, Inc. 2022
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB, without
% written permission from Eigenvector Research, Inc.

if ndims(thisdataset)>2
  error('Number of dims of DataSet Object greater than 2. DATASET2TABLE requires 2-way data.');
end

%TODO: Add axisscale information. Maybe as timescale where appropriate.
%TODO: Add options for label set, class, and axisscale info.
%TODO: Make test function below into demo.

%Make main table object with array2table. Use set 1 labels as default
%variable/row names. Designate them here in case we want to make option in
%future.
row_label_set = 1;
var_label_set = 1;

add_classinfo = true; %Add class info as categorical.

row_labels = matlab.lang.makeUniqueStrings(str2cell(thisdataset.label{1,row_label_set}));
var_labels = matlab.lang.makeUniqueStrings(str2cell(thisdataset.label{2,var_label_set}));

if isempty(row_labels)
  if isempty(var_labels)
    x = array2table(thisdataset.data);
  else
    x = array2table(thisdataset.data,'VariableNames',var_labels);
  end
else
  if isempty(var_labels)
    x = array2table(thisdataset.data,'RowNames',row_labels);
  else
    x = array2table(thisdataset.data,'RowNames',row_labels,'VariableNames',var_labels);
  end
end

if add_classinfo
  %Add in class info as categorical.
  for i = 1:length(thisdataset.classlookup(1,:))
    if isempty(thisdataset.class{1,i})
      continue
    end
    thiscat = categorical(thisdataset.classid{1,i}');
    if isempty(thisdataset.classname{1,i})
      thiscat = table(thiscat,'VariableNames',{['Class_' num2str(i)]});
    else
      thiscat = table(thiscat,'VariableNames',{thisdataset.classname{1,i}});
    end
    x = [x thiscat];
  end
end

end

function test
  %No lables.
  aa = dataset(rand(4,5));
  tt = dataset2table(aa);
  %Row labels.
  aa.label{1,1} = {'r1' 'r2' 'r3' 'r4'};
  tt = dataset2table(aa);
  %Var labels.
  aa.label{1,1} = {};
  aa.label{2,1} = {'a' 'b' 'c' 'd' 'e'};
  tt = dataset2table(aa);
  %Both labels.
  aa.label{1,1} = {'r1' 'r2' 'r3' 'r4'};
  tt = dataset2table(aa);
  %Class info.
  aa.class{1,1} = [1 1 1 2];
  aa.class{1,2} = [0 1 1 0];
  aa.class{2,2} = [1 1 2 0 3];
  tt = dataset2table(aa);
  %Demo data.
  load arch
  tt = dataset2table(arch);
end