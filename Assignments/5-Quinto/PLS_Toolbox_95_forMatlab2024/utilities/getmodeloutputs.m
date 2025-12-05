function [list, defaults] = getmodeloutputs(model,selitems)
%GETMODELOUTPUTS Get ouput fields for a model.
%
% INPUTS:
%   model    = Standard model structure.
%   selitems = If cell array of strings then items will be preselected in choose dialog.
%              If selitems is numeric:
%                [] = Show choose dialog nothing preselected.
%                1  = Preselect defualts in choose dialog.
%                0  = No dialog preselect defualts. 
%                -1 = No dialog full list.
%
% OUTPUTS:
%   item     = n x 3 cell array. First column is string description of field.
%              Second column is subs ref structer. Third column is xml
%              description of column 2.
%   defualts = default fields.
%
%
%I/O: [list, defaults] = getmodeloutputs(model,{'Scores on PC #1' 'Scores on PC #2'});
%I/O: [list, defaults] = getmodeloutputs(model); %Show dialog nothing preselected.
%I/O: [list, defaults] = getmodeloutputs(model,1); %Preselect defualts in choose dialog.
%I/O: [list, defaults] = getmodeloutputs(model,0); %No dialog preselect defualts. 
%I/O: [list, defaults] = getmodeloutputs(model,-1); %No dialog full list.
% 
%See also: MODELSTRUCT

%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  selitems = [];
end

list = {};  %NOTHING

defaults = [];
default_fieldkeys = {'Scores' 'Q'};%Search terms for finding defaults. Default is scores and Q.

if model.isclassification
  %classification model
  classes = model.classification.classids;
  list = {
    'Pred. Class (String)'  substruct('.','prediction')
    };
  for j=1:length(classes);
    list = [list; {sprintf('Probability %s',classes{j}) substruct('.','classification','.','probability','()',{':' j})}];
  end
  if ~isempty(model.T2)
    list = [list; {'Hotelling T^2'  substruct('.','T2')}];
  end
  if ~isempty(model.Q)
    list = [list; {'Q Residuals'  substruct('.','Q')}];
  end
  
  default_fieldkeys = {'Probability' 'Q'};
  
elseif model.isyused
  %regression model
  lbl = str2cell(char(model.detail.label{2,2}));  %y-column labels
  if isempty(lbl)
    lbl = str2cell(sprintf('Y%i\n',1:model.datasource{2}.size(2)));
  end
  list = {};
  myincld = model.detail.include{2,2};
  for j=1:length(myincld)
    list = [list; {['Predicted ' lbl{myincld(j)}] substruct('.','prediction','()',{':' j})}];
  end
  if ~isempty(model.T2)
    list = [list; {'Hotellings T^2'    substruct('.','T2')}];
  end
  if ~isempty(model.Q)
    list = [list; {'Q Residuals'    substruct('.','Q')}];
  end
  
  scrs = model.scores;
  if ~isempty(scrs)
    switch model.modeltype
      case 'PLS'
        desc = 'LV';
      case 'PCR'
        desc = 'PC';
      case 'CLS'
        scrs = [];  %EMPTY scores (so they don't show up) with CLS models
      otherwise
        desc = 'Comp.';
    end
    for j=1:size(scrs,2);
      list = [list; {['Scores on ' desc ' #' num2str(j)] substruct('.','scores','()',{':' j})}];
    end
  end
  
  default_fieldkeys = {'Predicted' 'Q'};
  
else
  %other model
  scrs = model.scores;
  switch model.modeltype
    case 'PCA'
      desc = 'PC';
    otherwise
      desc = 'Comp.';
  end
  for j=1:size(scrs,2);
   list = [list; {['Scores on ' desc ' #' num2str(j)] substruct('.','scores','()',{':' j})}];
  end
  
  if ~isempty(model.T2)
    list = [list; {'Hotellings T^2'   substruct('.','T2')}];
  end
  if ~isempty(model.Q)
    list = [list; {'Q Residuals'   substruct('.','Q')}];
  end

end

if isempty(list)
  evrihelpdlg(sprintf('This model type (%s) does not support output selection',model.modeltype),'No Outputs');
  return;
end

%encode all the substructs into XML to make it easier to match
for j=1:size(list,1);
  list{j,3} = encodexml(list{j,2},'item');
end

%Get defaults.
defaults = list(:,1);
useidx = ~cellfun('isempty',strfind(defaults,default_fieldkeys{1}));
for i = 2:length(default_fieldkeys)
  useidx = useidx + ~cellfun('isempty',strfind(defaults,default_fieldkeys{i}));
end
defaults = defaults(logical(useidx),:);

%Show gui flag.
showgui = 1;

if isnumeric(selitems)
  if selitems==-1
    %Return entire list.
    return
  elseif selitems==0
    %Return default list and no dialog.
    showgui = 0;
    selitems = defaults;
  elseif selitems==1
    %Use default list.
    selitems = defaults;
  end
end

if showgui
  %ask user for which they want to use
  [selitems, btnpushed] = listchoosegui(list(:,1),selitems);
  if ~strcmpi(btnpushed,'ok')|isempty(selitems)
    list = [];%User cancel.
    return;
  end
end

%get index of selected items and grab the first and second columns to store
inds = strlookup(selitems,list(:,1));
list = list(inds,:);

%---------------------------------------------------
function inds = strlookup(strcell,lookup)

[junk,ii,jj] = intersect(lookup,strcell);
rev = nan(1,max(jj));
rev(jj) = 1:length(jj);
rev(isnan(rev)) = [];
inds = ii(rev);

