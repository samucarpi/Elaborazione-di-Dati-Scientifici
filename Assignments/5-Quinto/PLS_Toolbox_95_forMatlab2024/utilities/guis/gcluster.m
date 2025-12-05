function varargout = gcluster(varargin)
%GCLUSTER GUI function for use with CLUSTER.
%  This is a helper function used by CLUSTER. Please see that function for
%  more information on CLUSTER analysis.
%
%I/O: n/a
%
%See also: ANALYSIS, CLUSTER

% Copyright © Eigenvector Research, Inc. 1995
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0;
  
  analysis cluster
  
else
  
  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  end
  
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end

end


%------------------------------------------------------
% --- Executes on button press in knn.
function algorithm_Callback(hObject, eventdata, handles)

handles = guihandles(handles.analysis);


% --------------------------------------------------------------------
% --- Executes on button press in mahalanobis.
function mahalanobis_Callback(hObject, eventdata, handles)
% if get(handles.mahalanobis_gcluster,'value')
%   set(handles.manhattan_gcluster,'value',0);
%   set(handles.manhattan_gcluster,'enable','off');
% end

% --------------------------------------------------------------------
% --- Executes on button press in manhattan.
function manhattan_Callback(hObject, eventdata, handles)
if get(handles.manhattan_gcluster,'value')
  set(handles.pca_gcluster,'value',0);
  set(handles.mahalanobis_gcluster,'value',0);
  set(handles.mahalanobis_gcluster,'enable','off');
else
  set(handles.pca_gcluster,'enable','on');
end

% --------------------------------------------------------------------
function hca_Callback(hObject, eventdata, handles)
% Use clusterimg.

set(handles.agglomerative,'value',1);
otherctrls = [handles.algorithm_gcluster handles.pca_gcluster handles.manhattan_gcluster handles.mahalanobis_gcluster];

%Disable other controls
set(otherctrls,'enable','on')
set([handles.dbscan_gcluster handles.clusterimg_gcluster],'value',0)


% --------------------------------------------------------------------
function clusterimg_Callback(hObject, eventdata, handles)
% Use clusterimg.

if ~evriio('mia')
  set(handles.clusterimg_gcluster,'value',0);
  resp = evriquestdlg('Partitional K-Means (DCA) requires MIA_Toolbox or Solo+MIA','MIA Required','Cancel','More Information','Cancel');
  switch resp
    case 'More Information'
      web('http://software.eigenvector.com','-browser');
  end
  return
end
set(handles.clusterimg_gcluster,'value',1);
otherctrls = [handles.algorithm_gcluster handles.pca_gcluster handles.manhattan_gcluster handles.mahalanobis_gcluster];

%Disable other controls
set(otherctrls,'enable','off')
set([handles.dbscan_gcluster handles.agglomerative],'value',0)

% --------------------------------------------------------------------
function dbscan_Callback(hObject, eventdata, handles)
% Use dbscan.

set(handles.dbscan_gcluster,'value',1);  %converted to radio button so a click always means "on"
otherctrls = [handles.algorithm_gcluster handles.pca_gcluster handles.manhattan_gcluster handles.mahalanobis_gcluster];

%Disable all others.
set(otherctrls,'enable','off')
set([handles.clusterimg_gcluster handles.agglomerative],'value',0)

% --------------------------------------------------------------------
% --- Executes on button press in pca.
function pca_Callback(hObject, eventdata, handles)
% hObject    handle to pca (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pca
handles = guihandles(handles.analysis);
if get(handles.pca_gcluster,'value');
  set(handles.mahalanobis_gcluster,'enable','on');
  set(handles.manhattan_gcluster,'value',0);
else
  set(handles.mahalanobis_gcluster,'enable','off');
end

% --------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects.
algh = findobj(figh,'tag','algorithm_gcluster','userdata',mfilename);
mypos = get(algh,'position');
mypos(3) = 250;
set(algh,'String',clustermethods('string'),'value',strmatch('Ward''s Method',clustermethods('string')),'position',mypos,'FontName','FixedWidth');

% --------------------------------------------------------------------
function panelupdate_Callback(figh, frameh, varargin)
%Update panel objects.

handles = guihandles(figh);

delete(findobj(figh,'tag','frame3','userdata',mfilename))
delete(findobj(figh,'tag','frame2','userdata',mfilename))
delete(findobj(figh,'tag','cancel','userdata',mfilename))
delete(findobj(figh,'tag','execute','userdata',mfilename))

% %Check for image data/mia and enable
% ctrls = panelmanager('findcontrols',handles.ssqframe);
% if evriio('mia')
  set(handles.clusterimg_gcluster,'enable','on')
% else
%   set(ctrls,'enable','on')
%   set(handles.clusterimg_gcluster,'enable','off')
%   if get(handles.clusterimg_gcluster,'value')
%     %if that was the mode, reset now to HCA
%     hca_Callback(handles.pca_gcluster, [], handles)
%   end
% end

val = get([handles.dbscan_gcluster handles.clusterimg_gcluster handles.agglomerative],'value');
if all([val{:}]==0)
  %nothing selected? make agglomerative the current selection
  hca_Callback(handles.pca_gcluster, [], handles)
end

% --------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle. 
%  Remove frame2, frame3, cancel, and execute.

handles = guihandles(figh);

%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]
w1 = 250;
h1  = 20;
if get(0,'ScreenPixelsPerInch')>100
  %Upsize figure if zoom font.
  w1 = 310;
  h1  = 24;
end

newbottom = (frmpos(2)+frmpos(4)-(h1+4));

set(handles.agglomerative,'position',[(frmpos(1)+4) newbottom w1 h1]);

algh = findobj(figh,'tag','algorithm_gcluster','userdata',mfilename); %Two contorls with same tag so need to use userdata.
newbottom = newbottom-(h1+2);
%Some coloring issues so set background to white manually.
set(algh,'position',[(frmpos(1)+4+19) newbottom w1 h1],'BackgroundColor','white');

set(handles.algorithmhelp,'units','pixels','position',[(frmpos(1)+19)+w1+15 newbottom 50 h1]);

% kmeanspos = get(handles.kmeans_gcluster,'position');
% newbottom = newbottom-(kmeanspos(4)+2);
% set(handles.kmeans_gcluster,'position',[(frmpos(1)+19) newbottom kmeanspos(3) kmeanspos(4)]);

pcah = findobj(figh,'tag','pca_gcluster','userdata',mfilename); %Two contorls with same tag so need to use userdata.
newbottom = newbottom-(h1+2);
set(pcah,'position',[(frmpos(1)+4+19) newbottom w1 h1]);

newbottom = newbottom-(h1+2);
set(handles.mahalanobis_gcluster,'position',[(frmpos(1)+4+19+15) (newbottom) w1 h1]);
set(handles.mahalanobis_gcluster,'enable','off'); % disable unless useing PCA

newbottom = newbottom-(h1+2); % added Manhattan Distance
set(handles.manhattan_gcluster,'position',[(frmpos(1)+4+19) newbottom w1 h1]);

newbottom = newbottom-(h1+2);
set(handles.dbscan_gcluster,'position',[(frmpos(1)+4) newbottom w1 h1]);

newbottom = newbottom-(h1+2);
set(handles.clusterimg_gcluster,'position',[(frmpos(1)+4) newbottom w1 h1]);

% --------------------------------------------------------------------
function out = clustermethods(action,hObj)
%Get method informaiton for cluster.
% action:
%   list   - list of methods.
%   string - list in format for dropdown.
%   method - get method from list.
% 
% hObj - handle to dropdown
%

list = {'knn'     'K-Nearest Neighbor';
        'fn'      'Furthest Neighbor';
        'avgpair' 'Average Paired Distance';
        'med'     'Median';
        'cnt'     'Centroid';
        'ward'    'Ward''s Method';
        'kmeans'  'K-means';
  };

switch action
  case 'string'
    out = [strvcat(list{:,2})];
  case 'list'
    out = list;
  case 'method'
    myval = get(hObj,'value');
    out = list{myval,1};
end

