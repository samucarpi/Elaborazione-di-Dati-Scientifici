function a = plotscores_simca(modl,test,options)
%PLOTSCORES_SIMCA Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 06/18/04 Change display for T and Q to show classes.

if isempty(test) | ~strcmpi(test.modeltype,'simca_pred')%| options.sct==1
  a = makescores(modl,modl);
else
  if options.sct
    a = makescores(modl,modl); 
    b = makescores(test,modl);
    cls = [zeros(1,size(a,1)) ones(1,size(b,1))];
    a              = [a;b]; clear b
    %search for empty cell to store cal/test classes
    j = 1;
    while j<=size(a.class,2);
      if isempty(a.class{1,j});
        break;
      end
      j = j+1;
    end
    a.class{1,j} = cls;  %store classes there
    a.classlookup{1,j} = {0 'Calibration';1 'Test'};
    a.classname{1,j} = 'Cal/Test Samples';

  else
    a = makescores(test,modl);
  end
end


%---------------------------------------------------------------------
function b = makescores(test,modl)

b = [];
lbl = {};

%look for "actual" classes
classset = test.detail.options.classset;
if classset>0 & size(test.detail.class,3)>=classset
  actual = test.detail.class{1,1,classset};
else
  actual = [];
end

%get matrix of isinmodel to calculate misclassed flag
if ~isempty(actual);
  %create actual assignment (if sample SHOULD be found by the given model)
  nsubmodels = length(modl.submodel); % tempdos
  for j = 1:nsubmodels;
    isinmodel(:,j) = ismember(actual(:),unique(modl.submodel{j}.detail.class{1,1,classset}(modl.submodel{j}.detail.includ{1})));
  end
  if any(sum(double(isinmodel),2)>1)
    %if ANY sample is assigned to more than one class, we can't give
    %this... erase it
    isinmodel = [];
  end
else
  isinmodel = [];
end

[data,labels] = plotscores_addclassification(test,isinmodel);
b = [b data];
lbl = [lbl labels];

%assemble reduced t/q info
for j = 1:size(test.rtsq,2);
  b   = [b test.rtsq(:,j) test.rq(:,j)];
  classstr = getclassstr(modl.submodel{j},modl.submodel{j}.detail.class{1}(modl.submodel{j}.detail.includ{1}));
  lbl = [lbl {['T^2 (Reduced) Model ' num2str(j) ' (' classstr ')']} {['Q (Reduced) Model ' num2str(j) ' (' classstr ')']}];
end

%create dataset
b          = dataset(b);
b          = copydsfields(test,b,1);
b.label{2} = lbl;

b.title{1}   = 'Samples/Scores Plot of Test';

%---------------------------------------------------------
function   classstr = getclassstr(modl,classnum)

classlookup = modl.detail.classlookup{1};
classstr = classlookup(ismember([classlookup{:,1}],classnum),2);
classstr = sprintf('%s,',classstr{:});
classstr = classstr(1:end-1); %drop ending comma

%---------------------------------------------------------
function [classofsubmodel] = getclassofsubmodel(modl)
% Get the classnums in order of sub-models.
% If a sub-model has two or more classes then return the first (lowest)
% classnum.

%look for "actual" classes
classset = modl.detail.options.classset;
if classset>0 & size(modl.detail.class,3)>=classset
  actual = modl.detail.class{1,1,classset};
else
  actual = [];
end
if isempty(actual)
  %none? use all zeros (=unknown)
  actual = zeros(1,modl.datasource{1}.size(1)).*nan;
end

%get matrix of isinmodel to calculate misclassed flag
if ~isempty(actual) & strcmp(modl.modeltype, 'SIMCA');
  %create actual assignment (if sample SHOULD be found by the given model)
  for j = 1:length(modl.submodel);
    isinmodel(:,j) = ismember(actual(:),unique(modl.submodel{j}.detail.class{1,1,classset}(modl.submodel{j}.detail.includ{1})));
  end
else
end
% Find the class associated with each sub-model
% If sub-model involves > than one class, then pick the first as the class
[maxval, modelnum] = max(isinmodel, [], 2);

classnum = modl.submodel{1}.detail.class{1,1,classset}';
ical = classnum>0 & maxval > 0;  % ignore class 0
classmodel = [classnum(ical) modelnum(ical)];

uniquemods = unique(classmodel(:,2));
for im=1:length(uniquemods)
  iim = find(uniquemods(im)==classmodel(:,2));
  uniqueclassesofsubmodel = unique(classmodel(iim));
  % need ONE class to associate with submodel, so pick first
  classofsubmodel(im) = uniqueclassesofsubmodel(1);
end
