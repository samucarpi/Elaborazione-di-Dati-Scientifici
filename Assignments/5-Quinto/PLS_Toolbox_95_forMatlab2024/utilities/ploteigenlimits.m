function ploteigenlimits(fig)
%PLOTEIGENLIMITS Adjust eigenvalue plots for special settings
% Used by ploteigen to handle special axis cases
%
%I/O: ploteigenlimits(fig)

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS

if nargin<1;
  fig = gcf;
end

isplotgui   = strcmp(getappdata(fig,'figuretype'),'PlotGUI');
if isplotgui
  %call from plotgui figure
  lbls = getappdata(fig,'axismenuvalues');
  inds = getappdata(fig,'axismenuindex');
  [modl,test] = plotscoreslimits('getmodel',fig);
  if isempty(modl); return; end
  showlim = getappdata(fig,'showlimits');
  
  if showlim & length(modl.datasource)>1
    for m = [2 1];
      switch m
        case 2
          linecmd = @hline;
        case 1
          linecmd = @vline;
      end
      lbl = lbls{m};
      
      %check if we've got specific selections
      if ~isa(lbl,'cell')
        lbl = {lbl};
      end
      
      myrmse = regexp(lbl,'RMSE[CP][V]?');
      isrmse = ~cellfun('isempty',myrmse);
      isrmse = isrmse(:)';
      ycol = [];
      for j=find(isrmse)
        myycol = regexp(strtrim(lbl{j}),'(\d+)$','match');
        if ~isempty(myycol)
          myycol = str2num(myycol{1});
          if isempty(ycol)
            ycol = myycol;
          elseif myycol~=ycol
            ycol = [];
            break;
          end
        elseif length(modl.detail.include{2,2})==1
          ycol = modl.detail.include{2,2};
        end
      end
      
      if ~isempty(ycol)
        ydat = modl.detail.data{2}(:,ycol);
        sy = std(ydat.data.include);
        h = linecmd(sy,'r--');
        ax = axis;
        if ax(4)<sy;
          ax(4) = sy*1.05;
          axis(ax)
        end
        legendname(h,'Standard Deviation Y')
      end
      
    end
    
  end
  
end
