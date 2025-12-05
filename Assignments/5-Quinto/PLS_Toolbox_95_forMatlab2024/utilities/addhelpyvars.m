function model = addhelpyvars(model)
%ADDHELPYVARS Adds y-block specific info to help field of a model
%I/O: model = addhelpyvars(model)

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isfieldcheck(model,'model.datasource') || length(model.datasource)<2
  %no datasource information or no y-block, leave now
  return
end
yinclude = model.detail.includ{2,2};
ny = length(yinclude);  %number of y-block columns

%Grab y-block label information
if ~isfieldcheck(model,'model.detail.label')  %no labels field
  return
end
lbl = model.detail.label{2,2};  %y-block labels
if isempty(lbl)  %no labels given, fake them
  lbl = [ones(ny,1)*'Y' num2str([1:ny]') repmat(' Prediction',ny,1)];
else
  lbl = lbl(yinclude,:);
end

%Replace '\n' in lbl with ' '
if (length(size(lbl))<3)
    for i=1:size(lbl,1)
        tmp = [];
        for j=1:size(lbl,2)
            if (int32(lbl(i,j)) ~= char(10)) % char(10) is '\n'
                tmp = [tmp lbl(i,j)];
            else
                tmp = [tmp ' '];
            end
        end
        lbl(i,:) = tmp;
    end
end

%create three-column cell of all info
lbl = [str2cell(lbl) str2cell(sprintf('pred{2}(:,%i)\n',1:ny)) repmat({'scalar'},ny,1)];


%get current help info
helpinfo = model.help.predictions;
if iscell(helpinfo)
  try
    helpinfo = makepredhelp(helpinfo);
  catch
    %unable to convert to structure? clear for default values
    helpinfo = [];
  end
end
if isempty(helpinfo);  %no help info in model?
  helpinfo = makepredhelp({'Predictions','pred{2}','ny'});  %make temporary entry
end

%remove "Predictions" entry (if any)
toremove = strmatch('Predictions',{helpinfo.label});
helpinfo(toremove) = [];  %drop Predictions entry

%add our y-predictions entries at the top of the list
helpinfo = [makepredhelp(lbl) helpinfo];
model.help.predictions = helpinfo;
