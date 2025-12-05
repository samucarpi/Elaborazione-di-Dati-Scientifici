function fig = ffacconfusion(alias_ID)
%DOECONFUSION Generates confusion table for a fractional factorial DOE.
% Given the alias_ID information from a fractional factorial DOE, this
% function generates a graphical depiction of the confounded factors.
% Output is the handle of the figure generated.
%
% Input can also be a DOE DataSet object (DOEDSO) created for a fractional
% factorial design. The alias_ID information will be automatically
% extracted from the provided DataSet object.
%
%I/O: fig = ffacconfusion(alias_ID)
%I/O: fig = ffacconfusion(DOEDSO)
%
%See also: FFACDES1

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isdataset(alias_ID)
  ud = alias_ID.userdata;
  if ~isfield(ud,'DOE')
    error('Input must be either an alias table or a DOE DataSet object')
  end
  alias_ID = ud.DOE.alias_ID;
end

clbl = {};
rlbl = {};
con  = [];
for j=1:length(alias_ID);
  item = alias_ID{j};
  cv = char(['A'+[1:size(item,2)]-1]);  %generate necessary letters
  clbl{j} = cv(item(1,:));
  for k=2:size(item,1);
    onelbl = cv(item(k,:));
    myrow = find(ismember(rlbl,onelbl));
    if isempty(myrow)
      %new label
      rlbl{end+1} = onelbl;
      con(end+1,j) = 1;
    else
      %row exists, add confusion point
      con(myrow,j) = 1;
    end
  end
end

%order table in increasing order of interaction
l = cellfun('length',rlbl);
[junk,order] = sort(l);
rlbl = rlbl(order);
con = con(order,:);

%create plot
fig = figure('integerhandle','off','numbertitle','off','name','Confounded Factors','toolbar','none','menubar','none');

h1 = uimenu(fig,'Label','File');
uimenu(h1,'Label','Save','Callback',{@save_ctable,fig});
uimenu(h1,'Label','Close','Callback','close(gcf)','separator','on');
figbrowser('addmenu',fig);

imagesc(con); 
colormap([1 1 1; 1 .2 .2]); 
axis image
set(gca,'xtick',1:length(clbl),'xticklabel',clbl,'xaxislocation','top')
set(gca,'ytick',1:length(rlbl),'yticklabel',rlbl)
set(gca,'TickDir','out');
hline([1:length(rlbl)]+.5,'k')
vline([1:length(clbl)]+.5,'k')

% %create DSO
condso = dataset(con);
condso.label{1} = rlbl;
condso.label{2} = clbl;
setappdata(fig,'condso',condso);

% %display table
% tbl = {sprintf(' % 3s  ',' ',clbl{:})};
% for j=1:length(rlbl); 
%   tbl{end+1} = [sprintf(' % 3s ',rlbl{j}) sprintf('    %i ',con(j,:))]; 
% end
% disp(char(tbl))

if nargout==0;
  clear fig;
end

%---------------------------------------------
function save_ctable(varargin)
%Save from menu call.

fig = varargin{end};
condso = getappdata(fig,'condso');
svdlgpls(condso,'Save Confusion Table','confusion_table')

