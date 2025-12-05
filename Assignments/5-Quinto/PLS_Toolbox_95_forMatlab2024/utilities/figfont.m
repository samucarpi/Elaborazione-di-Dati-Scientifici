function g = figfont(h,filenames,options)
%FIGFONT Modify figures for word processor documents.
%  FIGFONT modifies figures to have fonts and font sizes
%  to the values in the input (options). FIGFONT can also
%  save and print the figures. This function is useful for
%  creating and saving figures that all have the same look
%  and size for use in word processor documents.
%
%If included, output (g) contains the figure handles.
%
%OPTIONAL INPUTS:
%          h = N element vector of figure handles. Entries that are not
%              valid handles of open figures are ignored.
%  filenames = N element cell array of strings. These strings are used
%              when printing or saving the figures (see options.save
%              and options.print).
%    options = structure array with the following fields:
%     figure.color         = [1 1 1],                figure color
%     figure.position      = [-1 -1 506.6667 380],   figure position
%     axis.Color           = [1 1 1],                axis color
%     axis.Position        = [0.13 0.11 0.775 0.815],axis position
%                            Only used if there is a single axes in a figure.
%     axis.FontName        = 'Times New Roman',      axis font
%     axis.FontSize        = 10,                     axis fontsize
%     axis.Title.FontName  = 'Times New Roman',      title   font
%     axis.Title.FontSize  = 14,                     title   fontsize
%     axis.XLabel.FontName = 'Times New Roman',      x-label font
%     axis.XLabel.FontSize = 14,                     x-label fontsize
%     axis.YLabel.FontName = 'Times New Roman',      y-label font
%     axis.YLabel.FontSize = 14,                     y-label fontsize
%     axis.ZLabel.FontName = 'Times New Roman',      z-label font
%     axis.ZLabel.FontSize = 14,                     z-label fontsize
%     save                 = [ {'no'} | 'yes'], used to save a .fig file
%     print                = [ {'no'} | 'yes'], used to print a figure
%     printdevice          = '-depsc', print device option (see PRINT)
%     printpreview         = '-tiff',  print preview option
%     printoptions         = '-r600',  print options
%
%I/O: options = figfont('options');   %returns a default options structure
%I/O: g = figfont;                    %modifies only the current figure
%I/O: figfont(h,filenames);
%I/O: figfont(h,options);
%I/O: figfont(h,filenames,options);

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%NBG 3/08

if nargin==0 %assume that the current figure is to be modified
  options = figfont('options');
  g   = gcf;
  filenames = cell(length(g),1);
  for i1=1:length(g)
    filenames{i1} = ['Figure ',double(g(i1))];
  end
elseif nargin==1
  if ischar(h) %Help, Demo, Options
    options = [];
    options.name          = 'options';
    options.figure.color         = [1 1 1];
    options.figure.position      = [-1 -1 506.6667 380];
    options.axis.Color           = [1 1 1];
    options.axis.Position        = [0.13 0.11 0.775 0.815];
    options.axis.FontName        = 'Times New Roman';
    options.axis.FontSize        = 10;
    options.axis.Title.FontName  = 'Times New Roman';
    options.axis.Title.FontSize  = 14;
    options.axis.XLabel.FontName = 'Times New Roman';
    options.axis.XLabel.FontSize = 14;
    options.axis.YLabel.FontName = 'Times New Roman';
    options.axis.YLabel.FontSize = 14;
    options.axis.ZLabel.FontName = 'Times New Roman';
    options.axis.ZLabel.FontSize = 14;
    options.paper.PaperPosition  = [0.7292+2.0417/2 2.8611+1.5280/2 7.0417-2.0417 5.2778-1.5280];
    options.paper.PaperSize      =  [8.5 11];
    options.save                 = 'no'; %'yes'
    options.print                = 'no'; %'yes'
    options.printdevice          = '-depsc';
    options.printpreview         = '-tiff';
    options.printoptions         = '-r600';

    if nargout==0; evriio(mfilename,h,options); else
      g = evriio(mfilename,h,options); end
    return;
  else
    options = figfont('options');
    g = h;
  end
  filenames = cell(length(g),1);
  for i1=1:length(g)
    filenames{i1} = ['Figure ',g(i1)];
  end
elseif nargin==2
  g = h;
  if iscell(filenames)
    options   = figfont('options');
  elseif isstruct(filenames)
    options = reconopts(filenames,'figfont',1);
    filenames = cell(length(g),1);
    for i1=1:length(g)
      if isobject(g)
        filenames{i1} = ['Figure ',g(i1).Number];
      else
        filenames{i1} = ['Figure ',g(i1)];
      end
    end
  end
elseif nargin==3
  g = h;
  options = reconopts(options,'figfont',1);
end
if length(filenames)~=length(g)
  error('Number of filenames must equal number of figures.')
end

for i2=1:length(g)
  if ishandle(g(i2)) && strcmpi(get(g(i2),'Type'),'figure')
    h     = findobj(g(i2),'type','axes');
    for i1=1:length(h)
      switch lower(get(h(i1),'Tag'))
        case 'legend'
        case ''
          set(h(i1),'FontName',options.axis.FontName, ...
                    'FontSize',options.axis.FontSize);
          if length(h)==1
            set(h(i1),'Position',options.axis.Position);
          end   
          set(get(h(i1),'Title'), 'FontName',options.axis.Title.FontName, ...
                                  'FontSize',options.axis.Title.FontSize);
          set(get(h(i1),'Xlabel'),'FontName',options.axis.XLabel.FontName, ...
                                  'FontSize',options.axis.XLabel.FontSize);
          set(get(h(i1),'Ylabel'),'FontName',options.axis.YLabel.FontName, ...
                                  'FontSize',options.axis.YLabel.FontSize);
          set(get(h(i1),'Zlabel'),'FontName',options.axis.ZLabel.FontName, ...
                                  'FontSize',options.axis.ZLabel.FontSize);
        otherwise
      end
    end
    set(g(i2),'Color',options.figure.color)
    
    axv   = get(gcf,'position');
    ax    = options.figure.position;
    if ax(1)>=0, axv(1) = ax(1); end
    if ax(2)>=0, axv(2) = ax(2); end
    axv(3:4) = ax(3:4);
    set(g(i2),'Position',axv)
    set(gcf,'PaperPosition',options.paper.PaperPosition)
    
    if strcmpi(options.save,'yes')
      if isempty(filenames{i2})
        disp(['Filename empty for h(',int2str(i2),'). Figure not saved.'])
      else
        saveas(g(i2),filenames{i2},'fig')
      end
    end
    if strcmpi(options.print,'yes')
      if isempty(filenames{i2})
        disp(['Filename empty for h(',int2str(i2),'). Figure not printed.'])
      else
        eval(['print ',options.printdevice,' ',options.printpreview,' ', ...
          options.printoptions,' ',filenames{i2}])
      end
    end
  end
end
if nargout==0
  clear g
end
set(gcf,'paperpositionmode','auto')
