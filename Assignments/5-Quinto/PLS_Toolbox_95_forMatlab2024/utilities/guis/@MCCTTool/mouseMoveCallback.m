function [ output_args ] = mouseMoveCallback(obj,jobj,event,varargin)
%MOUSEMOVECALLBACK Move moving over graph. Update info box.

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mygraph = varargin{1};
fig = mygraph.ParentFigure;

%Get any existing infobox.
infoh = obj.infoBoxHandle;
if ~ishandle(infoh)
  infoh = [];
end

cm = findobj(fig,'tag','mcctcontextmenu');
if ~isempty(cm) & ishandle(cm) & strcmpi(get(cm,'visible'),'on')
  return
end

mycell = mygraph.GraphComponent.getCellAt(event.getX,event.getY);
if isempty(mycell)
  %Clicking in open space.
  visoff(infoh)
  return
end

if ~mycell.isVertex
  %Clicking on an edge.
  visoff(infoh)
  return
end

%Clicking on cell.
myid = char(mycell.getId);
if strfind(myid,'pool')
  %Clicking in pool but not on data/model cell.
  visoff(infoh)
  return
end
myid(end-2:end);

if ~isempty(strfind(lower(myid),'data')) | ~isempty(strfind(lower(myid),'model')) | ismember(myid(end-1:end),{'p1' 'p2'})| ~isempty(strfind(myid,'ValidationResults'))
  
  if ismember(myid(end-1:end),{'p1' 'p2'})
    mystr = getPreproDescriptoin(obj,myid(end-1:end));
  else
    mystr = obj.sourceInfo.(myid);
  end
  
  if isempty(mystr)
    visoff(infoh)
    return
  end
  mygraph = obj.graph;
  myview  = mygraph.GraphComponent.getGraph.getView;
  myscale = myview.getScale;
  
  ppos    = obj.graph.getpixelposition;
  cellpos = [mycell.getGeometry.getX mycell.getGeometry.getY mycell.getGeometry.getWidth mycell.getGeometry.getHeight];
  
  if isempty(infoh)
    %infoh = infobox('',struct('openmode','reuse','figurename','Info'));
    infoh = uicontrol(fig,'style','listbox','tag','status_infobox','backgroundcolor',[1 1 1],...
                      'userdata',[],'Max',2,'Min',0,'FontName','Courier','fontsize',obj.guiFontSize,...
                      'position',[1 1 1 1]);
    obj.infoBoxHandle = infoh;
  end
  
  %Add offset for validation pool if needed.
  if strcmpi(mycell.getParent.getValue,'validation')
    myoffset = mycell.getParent.getGeometry.getX;
    cellpos(1) = cellpos(1)+myoffset;
  end

  %Cell position is in java orientation so need to calc inverse to matlab.
  infobottom = ppos(2)+(ppos(4)-cellpos(2)*myscale-cellpos(4)*myscale)-208;
  set(infoh,'String',mystr,'position',[cellpos(1)*myscale infobottom 280 200],'Visible','on');
end


end

function mydes = getPreproDescriptoin(obj,pploc)
%Using prepocessing from model and insert point get prepro description.
%Make raw prepro description presistent so it can be quicker in mouse
%motion callback. Input 'pploc' is 'p1' or 'p2' for prepro icon location.

%2 element cell %{modelid ppdescription}
persistent rawppdescription 
mydes = '';
mymod = obj.MasterModel;
if isempty(mymod)
  return
end

if isempty(rawppdescription) | ~strcmp(rawppdescription{1},mymod.uniqueid)
  mypp = mymod.preprocessing{1};
  thisdes = [];
  for i = 1:length(mypp)
    thisdes{i} = mypp(i).description;
  end
  rawppdescription{1} = mymod.uniqueid;
  rawppdescription{2} = thisdes;
end

mydes = rawppdescription{2};

insrtpp = obj.PreprocessingInsertInd;
%Get description.
if strcmp(pploc,'p1')
  if insrtpp==0
    mydes = '';
  else
    mydes = sprintf('%s\n',mydes{1:insrtpp});
  end
else
  mydes = sprintf('%s\n',mydes{insrtpp+1:end});
end

if isempty(mydes)
  mydes = 'Empty';
end

end

function visoff(h)
%Turn visible off.
if ishandle(h)
  set(h,'visible','off')
end
end
