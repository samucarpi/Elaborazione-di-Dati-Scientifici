function editds_addimportmenu(handles,callback)
%EDITDS_ADDIMPORTMENU Adds import menu items to a parent menu.
%
%I/O: editds_addimportmenu(handles,callback)
%
%See also: EDITDS_DEFAULTIMPORTMETHODS

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

importmethods = editds_defaultimportmethods;
separator = 'off';
dashCounter = 0;

haveMIA = evriio('mia');
if haveMIA
    firstCol = strvcat(importmethods{:,1});
    sepRows = strfind(firstCol(:,1)','-')';
    imgImporters_start = sepRows(2,1)+1;
    imgImporters_end = sepRows(3,1)-1;
    imgInds = imgImporters_start:imgImporters_end;
end
  
for j=1:size(importmethods,1);
  if importmethods{j,1}(1)=='-';
    dashCounter = dashCounter + 1;
    separator = 'on';
    continue
  end
  for jj=1:length(handles)
    if haveMIA && strcmp(separator, 'on') && dashCounter == 2 %create fly-out for image importers
        imageImporters = uimenu(handles(jj),'label','I&mage File Importers...','callback','','separator', separator);
        separator = 'off';
    end
    if haveMIA && any(j==imgInds) %got an image importer so add to fly-out
      uimenu(imageImporters,...
        'label',importmethods{j,1},...
        'tag','fileimporttype',...
        'separator',separator,...
        'userdata',importmethods{j,2},...
        'callback',callback);
    else
      uimenu(handles(jj),...
        'label',importmethods{j,1},...
        'tag','fileimporttype',...
        'separator',separator,...
        'userdata',importmethods{j,2},...
        'callback',callback);
    end
  end
  
  separator = 'off';
end

