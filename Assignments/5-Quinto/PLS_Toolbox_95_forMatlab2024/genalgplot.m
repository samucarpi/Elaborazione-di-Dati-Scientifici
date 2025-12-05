function indices  = genalgplot(varargin)
%GENALGPLOT Plot GA results using selected variable plot, color-coded by RMSECV.
%  After selecting a sub-portion of the results to use, a plot of 
%  selected positions for the selected models is provided. The models 
%  are sorted up the figure in decreasing quality of fit. If an optional 
%  reference "spectrum" is provided, it is plotted with of the selected 
%  variable results. If optional variables xaxis and xtitle are given, 
%  they are used for the x-axis of the plot. GENALGPLOT can also return 
%  the indices  of the selected models
%
%  INPUTS:
%     results  = Standard GenAlg results structure
% or  fit, pop = results from genetic algorithm run (see GASELCTR)
%
%  OPTIONAL INPUTS:
%    spectrum = intensity values to plot along with ga results
%       xaxis = numeric or text labels for variable axis
%      xtitle = text label for x-axis 
%
%  OUTPUT:
%     indices = vector containing the indices  of the models seleced by the user
%
%I/O: indices  = genalgplot(fit,pop,spectrum,xaxis,xtitle);
%I/O: indices  = genalgplot(results,spectrum,xaxis,xtitle);
%I/O: genalgplot demo
%
%See also: GASELCTR, GENALG

%Copyright (c) Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 2/28/01 written
% JMS 7/1/01 rewritten to use gselect -updated help
% jms 8/28/01 check for empty selection
% jms 12/8/01 fixed help text
% jms 10/02 modified to allow model input
% jms 12/02 added fast display mode for large numbers of variables
%   -fixed "labels"->"label" for dataset input
%   -removed use of includ for variable dim
% jms 6/03 allow single-model selection and plotting
%   -automatic single-model display
%   -don't change fig size
% jms 3/05 use caxis to give colorbar rmsecv scale

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; indices  = evriio(mfilename,varargin{1},options); end
  return; 
end

if ismodel(varargin{1})
  % (model,...)
  gapop = varargin{1}.icol;
  gafit = varargin{1}.rmsecv;
  varargin = varargin(2:end);
else
  % (fit,gapop,...)
  if nargin < 2;
    error('Insufficient inputs')
  end
  gafit = varargin{1};
  gapop = varargin{2};
  varargin = varargin(3:end);  
end

xlabels  = [];
spectrum = [];
xaxis    = 1:size(gapop,2);
xtitle   = 'Variable #';

if length(varargin)>= 1;
  spectrum = varargin{1};
end
if length(varargin)>= 2;
  xaxis = varargin{2};
end
if length(varargin)>= 3;
  xtitle = varargin{3};
end

includ = {};
if ~isempty(spectrum);
  if isa(spectrum,'dataset');
    %Extract useful info if spectrum is a dataset object
    includ   = spectrum.includ;
    xaxis    = spectrum.axisscale{2};
    xtitle   = spectrum.axisscalename{2};
    xlabels  = spectrum.label{2};
    spectrum = spectrum.data(includ{1},:);
  end
  %give mean spectrum if it isn't already
  if size(spectrum,1) ~= 1 & size(spectrum,2) ~= 1;
    spectrum = mean(spectrum); 
  end;
end;
if ~isempty(includ);
  %mark out excluded regions (they wern't used in GA run)
  temp = gapop*0;
  temp(:,includ{2}) = gapop(:,includ{2});
  gapop = temp;
end

%make sure xaxis is in correct orientation
if size(xaxis,2) == 1; xaxis = xaxis'; end;

if length(gafit) > 50; 
  symbol = '.';       %lots of vars, do smaller symbol
else; 
  symbol = 'o'; 
end;  

%get user to identify results to look at
fig = figure;
if length(gafit)>1;
  hdata = plot(sum(gapop')',gafit,symbol);
  xlabel('Number of Included Variables')
  ylabel('Fit (RMSECV)')
  h = title('Drag a box around results to plot');
  set(h,'fontweight','bold')
  axis manual
  selected = gselect('rbbox',hdata,struct('helpbox','off'));      %jms 7/1/01
  if isempty(selected); return; end       %jms 8/28/01
  
  selected = find(selected{1});
  if isempty(selected);        %jms 8/28/01
    close;
    return; 
  end
else
  selected = 1;
end

%make figure pointer "busy"
set(fig,'pointer','watch');

%determine range of selected fits
minfit = min(gafit(selected));
rangefit = (max(gafit(selected))-min(gafit(selected)));
if rangefit == 0; rangefit = 2; end;

%more than 10% of variables selected for any model? use lines instead of points
lineflag = any(mean(gapop(selected,:)')>.1);        

%now, sort by fit
[junk,sortorder] = sort(gafit(selected));
selected = selected(sortorder);

%Do the results plot
cjet = jet;
colormap(cjet);   % Ensure the colorbar uses this too
hold off;
cla
drawnow;

if size(gapop,2)<100;
  for k = 1:length(selected);   
    %get positions of selected variables
    inds = find(gapop(selected(k),:));   
    if length(selected)<100 | lineflag;
      h = plot([xaxis(inds);xaxis(inds)],[ones(1,length(inds))*(k-1);ones(1,length(inds))*k],'-','linewidth',2+(8-length(inds)/max(100,size(gapop,2))*8));  
    else
      h = plot([xaxis(inds)]',ones(length(inds),1)+k,'.');   
    end;
    set(h,'color',cjet(round( ( gafit(selected(k))-minfit ) /rangefit*63 )+1,:));
    %     set(h,'buttondownfcn',['disp(' num2str(selected(k)) ');']);
    hold on;
  end;
else
  z = diag(gafit(selected))*gapop(selected,:);
  z(z==0) = nan;
  [what,where] = sort(gafit(selected));
  if length(selected)==1;
    pcolor(xaxis,0:1,[z;z]);
  else
    % Add replicate last row and column to account for pcolor ignoring them
    z1 = z(where,:);
    [m,n] = size(z1);
    z1 = [z1 z1(:,n)];
    z1 = [z1;z1(m,:)];
    % Similarly, add extra element to each axis
    pcolor([xaxis (2*xaxis(end)-xaxis(end-1))],0:(length(selected)),z1);
  end
  shading flat
  hold on
  
  %handle opengl / colorbar bug in Matlab Release 14
  drawnow;
   if checkmlversion('==','7.0') & strcmp(lower(get(gcf,'renderer')),'opengl')
     set(gcf,'renderer','zbuffer');
  end

end
myplot = gca;

%If we have a reference spectrum, plot it over top
if ~isempty(spectrum);
  scalingfactor = 1; %Determine how big the spectrum should be relative to the points
  h = plot(xaxis,(spectrum-min(spectrum))/max(spectrum-min(spectrum))*(length(selected)*scalingfactor),'k');
  set(h,'linewidth',2,'color',[.4 0 0]);
end;
xlabel(xtitle)

%add labels if we have them
if ~isempty(xlabels)
  set(myplot,'xticklabel',xlabels,'xticklabelmode','manual','xtickmode','manual')
end

%add title
if length(selected)==1;
  if length(gafit)==1;
    title({['Fit: ' num2str(gafit(selected)) '  Using: ' num2str(min(sum(gapop(selected,:)'))) ' variables']})
  else
    title({['1 Model Out of ' num2str(length(gafit)) ' - Fit: ' num2str(gafit(selected)) '  Using: ' num2str(min(sum(gapop(selected,:)'))) ' variables']})
  end    
  axis tight
  set(myplot,'userdata','myplot');
else
  if min(sum(gapop(selected,:)')) == max(sum(gapop(selected,:)'));
    title({[num2str(length(selected)) ' of ' num2str(length(gafit)) ' Models - Using ' num2str(min(sum(gapop(selected,:)'))) ' variables']})
  else
    title({[num2str(length(selected)) ' of ' num2str(length(gafit)) ' Models - Using ' num2str(min(sum(gapop(selected,:)'))) '-' num2str(max(sum(gapop(selected,:)'))) ' variables']})
  end;
  axis tight
  set(myplot,'userdata','myplot');
  
  %add colorbar reference
  cx = [min(gafit(selected)) max(gafit(selected))];
  if cx(1)==cx(2); cx = [-.1 .1]+cx(1); end
  caxis(cx)
  colorbar
  h = findobj(fig,'tag','Colorbar');
  if isempty(h)
    h = findobj(fig,'type','axes');
    h = setdiff(h,myplot);  %remove "myplot" from that list, the one remaining must be the colorbar
  end

  %and set labels of colorbar to match the fit scale
  %   set(h,'yticklabel',num2str(fix(([10:10:60]'*(max(gafit(selected))-min(gafit(selected)))/64+min(gafit(selected)))*1000)/1000))
  %   set(get(h,'ylabel'),'string','RMSECV')
  set(h,'DeleteFcn','');
  ylabel('RMSECV (see colorbar)');

end

%make figure pointer normal
set(fig,'pointer','arrow');

%and pretty-it-up
% set(fig,'units','normalized','position',[0.0371    0.3125    0.7354    0.5690])
set(myplot,'yticklabel','')
% set(get(myplot,'xlabel'),'fontname','Arial','fontsize',12)
% set(get(myplot,'ylabel'),'fontname','Arial','fontsize',12)
% set(get(myplot,'title'),'fontname','Arial','fontsize',16)
% set(myplot,'fontname','Arial','fontsize',12)
% ans = get(fig,'children');
% set(ans(2),'fontname','Arial','fontsize',12)
% set(get(ans(2),'ylabel'),'fontname','Arial','fontsize',12)
% set(ans(2),'position',get(ans(2),'position').*[1 1 3/5 1])

if nargout == 1;
  indices  = selected;     %get indices  sorted in fit order
end;

