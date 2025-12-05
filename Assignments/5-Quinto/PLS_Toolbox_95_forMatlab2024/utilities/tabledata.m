function [dat, lab] = tabledata(targFig)
%TABLEDATA Extracts line data from a figure.
% Extracts label and data information from a figure for use in a databox.
% Will work with subplots. 
%
%  INPUTS:
%       targFig = Handle of figure.
%
%  OUTPUT:
%       dat = cell array of line data.
%       lab = char array of label data.
%
%I/O: [dat, lab] = tabledata(targFig);
%
%See also: CREATETABLE DATABOX

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 02/17/04 initial coding
%jms 02/20/04 force selection of "userdata"="data" using findobj restriction
%jms 03/26/04 added support for images
%jms 5/3/04 reverse order of lines grabbed from figure

%Assume only one dataset for X and Z axis and possible multiple datasets on Y axis.
dat = {};
lab = '';
for targAxes = findobj(targFig, 'type', 'axes')'
  
  dathandle = findobj(allchild(targAxes), 'type', 'line','userdata','data');
  xlab = get(targAxes,'XLabel');
  xlabstr = get(xlab, 'String');
  if ~isempty(xlabstr)
    lab = char(lab, xlabstr);
  end
  
  zlab = get(targAxes,'ZLabel');
  zlabstr = get(zlab, 'String');
  if ~isempty(zlabstr)
    lab = char(lab, zlabstr);
  end    
  
  xDat = get(dathandle,'XData');
  if iscell(xDat)
    xDat = xDat{1};
  end
  if ~isempty(xDat)
    dat = [dat; {xDat}];
  end
  
  zDat = get(dathandle,'ZData'); 
  if iscell(zDat)
    zDat = zDat{1};
  end
  if ~isempty(zDat)
    dat = [dat; {zDat}];
  end
  
  lines = fliplr(dathandle');
  %UserData field must have 'data' in it. This will indicate the correct
  %line and eliminate possible duplicate values. May be empty [] so test
  %for both conditions before extraction.
  if ~isempty(lines);
    for targLine = lines;
      
      if checkmlversion('<','7')
        ylab = get(targLine, 'Tag');  %Tag gives ydata label.
      else
        ylab = get(targLine, 'Displayname');  %R14 ydata label
      end
      ydat = get(targLine, 'YData');
      
      lab = char(lab, ylab); 
      dat = [dat; {ydat}];
      
    end
  else
    %no line objects? look for images
    images = findobj(allchild(targAxes), 'type', 'image','userdata','data')';
    for targLine = images;
      
      ylab = get(targLine, 'Tag');  %Tag gives ydata label.  
      ydat = get(targLine, 'CData');
      
      lab = char(lab, ylab); 
      dat = [dat; {ydat}];
    end
      
  end
end
%Remove first empty (initialization) cell.
lab = lab(2:end,:);
