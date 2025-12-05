function varargout = cluster_guifcn(varargin);
%CLUSTER_GUIFCN CLUSTER Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%rsk 08/11/04 Change help line and add ssqupdate to keep error from appearing.
%rsk 01/16/06 Fix bug for cancel number cluster dialog.

try
  if nargout == 0;
    
    feval(varargin{:}); % FEVAL switchyard
  else
    [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    
  end
catch
  erdlgpls(lasterr,[upper(mfilename) ' Error']);
end  
%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin);
%create toolbar
[atb abtns] = toolbar(handles.analysis, 'cluster','');
handles  = guidata(handles.analysis);
analysis('toolbarupdate',handles);
%change ssq table labels
%No ssq table, disable.
set(handles.pcsedit,'Enable','off')
%set(handles.ssqtable,'Enable','off')
%turn off valid crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','off');

%general updating
set(handles.tableheader,'string', {' ' 'Click "Calc" to perform analysis' },'horizontalalignment','center')
set([handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','off')

%Add view selections to dropdown.
panelinfo.name = 'Function Settings';
panelinfo.file = 'gcluster';
panelmanager('add',panelinfo,handles.ssqframe)

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
closefigures(handles);
set([handles.tableheader handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','on')
set(handles.tableheader,'string', { '' },'horizontalalignment','left')
setappdata(handles.analysis,'enable_crossvalgui','on');
%Get rid of panel objects.
panelmanager('delete','gcluster',handles.ssqframe)

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes OR y
% out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
% out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

out = false;


%----------------------------------------------------
function  calcmodel_Callback(h,eventdata,handles,varargin);

handles = guihandles(handles.analysis);

x = analysis('getobjdata','xblock',handles);
xval = analysis('getobjdata','validation_xblock',handles);

% %TODO: revise "keep classes" logic in dendrogram to handle when cal and val are both present
% %The following code causes errors when we try to assign classes back to
% data (because dendrogram doesn't know how to sort out calibration and
% validation)
%
% if ~isempty(xval);
%   try
%     if ~isempty(x.label{2,1})
%       x = [x;matchvars(x.label{2,1},xval)];
%     elseif ~isempty(x.axisscale{2,1})
%       x = [x;matchvars(x.axisscale{2,1},xval)];
%     else
%       error('no match');
%     end
%   catch
%     erdlgpls({'Could not combine calibration and validation for simultaneous analysis (variables too dissimilar).' 'Only calibration data will be shown'},'Error combining data');
%   end
% end

if evriio('mia') & get(handles.clusterimg_gcluster,'value')
  %if automated call, use components 
  %     obj = evrigui(handles.analysis);
  %         numcluster = obj.getComponents;  %CAN'T use this because we can't set components when cluster mode is on
  numcluster = num2str(getappdata(handles.analysis,'numcluster'));
  if isempty(numcluster) | ~inevriautomation
    numcluster = inputdlg('Enter number of clusters to identify in data.', 'Number of Clusters',1,{numcluster});
    drawnow;
    
    if isempty(numcluster)
      %User cancel.
      return
    else
      numcluster = str2num(numcluster{1});
    end
  else
    numcluster = str2num(numcluster);
  end

  if ~isnumeric(numcluster) | sum(size(numcluster))~=2
    erdlgpls('Value must be a scalar.', 'Cluster Number Error');
    return
  end
  if numcluster<2
    erdlgpls('Number of clusters must be >= 2.', 'Cluster Number Error');
    return
  end
  
  setappdata(handles.analysis,'numcluster',numcluster);
  
  options = cluster_img('options');
  options.plots = 'final';
  options.preprocessing = {getappdata(handles.preprocessmain,'preprocessing')};
  [a, b, c, h] = cluster_img(x,numcluster,options);
  %Add dialog box for augmenting, replacing, or don't save.
  if strcmpi(options.saveclassdialog,'on')
    myans=evriquestdlg('Save cluster class information?', ...
      'Replace Last','Add to End','Replace Last','Ignore','Ignore');
  else
    myans = 'Ignore';
  end
  switch myans
    case {'Ignore'}
      %Don't do anything.
      
    case {'Replace Last' 'Add to End'}
      x = analysis('getobjdata','xblock',handles);
      xcls = x.class(1,:);
      myclsidx = size(xcls,2);
      if strcmpi('Add to End',myans)
        if ~isempty(xcls{myclsidx})
          %Only add to end if last class is not empty.
          myclsidx = myclsidx+1;
        end
      end
      x.class{1,myclsidx} = a;
      x.classname{1,myclsidx} = 'Cluster Classes';
      analysis('setobjdata','xblock',handles,x);

      evrihelpdlg(['Displayed classes have been stored in Analysis X-block class set ' num2str(myclsidx) ' for samples'],'Classes stored');
  end
  
elseif get(handles.dbscan_gcluster,'value')
  %DBSCAN
  minpts = inputdlg('The smallest number of similar samples which should be considered a "class" (default = 2).', 'DBSCAN Class Size',1,{'2'});
  if isempty(minpts)
    %User cancel.
    return
  else
    minpts = str2num(minpts{1});
  end
  
  [cls,eps] = dbscan(x,minpts);
 
  try 
    % Add classset for Clusters, setting class -1 as 'Noise'.
    if isempty(x.classlookup{1,1})
      nrowcls1 = 1;
    else
      nrowcls1 = size(x.classlookup(1,:),2)+1;
    end
    x.class{1,nrowcls1} = cls;
    classlookup=x.classlookup{1,nrowcls1};
    ncls = size(classlookup,1);    
    for j=1:ncls;
      if classlookup{j,1}==-1
        classlookup{j,2} = 'Noise';
      elseif classlookup{j,1}==0
        classlookup{j,2} = sprintf('Class %i', classlookup{j,1});
      else
        classlookup{j,2} = sprintf('Cluster %i', classlookup{j,1});
      end
    end
    x.classlookup{1,nrowcls1} = classlookup;    
    x.classname{1,nrowcls1} = 'Clusters';
    
    x.title{1} = ['Density-based Clustering (min class size = ' num2str(minpts) ')'];
    fig = figure;
    plotgui('update','figure',fig,x,'viewclassset', nrowcls1, 'viewclasses',1,'noinclude',1);
    analysis('adopt',handles,fig,'staticchildplot');
    
    %Add dialog box for augmenting, replacing, or don't save.
    myans=evriquestdlg('Save cluster class information?','Save Info?','Add to End','Ignore','Ignore');
    switch myans
      case {'Ignore'}
        %Don't do anything.
      otherwise
        analysis('setobjdata','xblock',handles,x);
        evrihelpdlg(['Displayed classes have been stored in Analysis X-block class set ' num2str(nrowcls1) ' for samples'],'Classes stored');
    end
  catch
    erdlgpls(lasterr,'Cluster')
  end
  
else
  %if size(x.data,1)>200
  if length(x.include{1})>200 & isempty(getappdata(handles.analysis,'bigclusterapproved'))
    myans = evriquestdlg('Analyzing more than 200 samples using ''cluster'' may take some time to analyze. Do you wish to continue?','Cluster Size Warning!','Continue','Cancel','Continue');
    if strcmp(myans,'Cancel')
      evritip('partitionalclustering','Clustering Canceled - Considering using the Partitional clustering option (Requires MIA_Toolbox)',1);
      return
    end
    setappdata(handles.analysis,'bigclusterapproved',1)  %don't ask again
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  options = cluster('options');
  options.algorithm = gcluster('clustermethods','method',handles.algorithm_gcluster);
  options.preprocessing = {getappdata(handles.preprocessmain,'preprocessing')};

  if get(handles.pca_gcluster,'value');
    options.pca = 'on';
  else
    options.pca = 'off';
  end
  options.ncomp = [];

  if get(handles.mahalanobis_gcluster,'value');
    options.mahalanobis = 'on';
  else
    options.mahalanobis = 'off';
  end

  if get(handles.manhattan_gcluster,'value') %& strcmp(get(handles.manhattan_gcluster,'enable'),'on')
    options.distance='manhattan';
  else
    options.distance='euclidean';
  end
  
  try
    %[junk,dendroploth] = cluster(x,options);
    [results,dendroploth,distances] = cluster(x,options);
    if ~isempty(handles.analysis) & ishandle(handles.analysis) & ~isempty(dendroploth)
      setappdata(dendroploth,'parent',double(handles.analysis)); %allows trigger of "Keep" classes option
      analysis('adopt',handles,dendroploth,'staticchildplot');
    end
  catch
    erdlgpls(lasterr,'Cluster')
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%h = gcluster(x,getappdata(handles.preprocessmain,'preprocessing'),handles.analysis);
end

%setappdata(handles.calcmodel,'children',h)

%----------------------------------------------------
function  ssqtable_Callback(h, eventdata, handles, varargin)

%----------------------------------------------------
function  pcsedit_Callback(h, eventdata, handles, varargin)

% --------------------------------------------------------------------
function [modl,success] = crossvalidate(h,modl,perm)
success = 0;

if nargin>2 & perm>0
  %not available - return empty
  modl = [];
  return;
end

%--------------------------------------------------------------------
function updatefigures(h)

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures
for parent = [handles.calcmodel];
  toclose = getappdata(parent,'children');
  toclose = toclose(ishandle(toclose));  %but only valid handles
  if ~isempty(toclose)
    delete(toclose); 
  end
  setappdata(parent,'children',[]);
end

temp = getappdata(handles.analysis,'staticchildplot');
close(temp(ishandle(temp)));
setappdata(handles.analysis,'staticchildplot',[]);


pca_guifcn('closefigures',handles);

%-------------------------------------------------
function updatessqtable(handles,pc)

%----------------------------------------------------
function  optionschange(h)
