function out = classsummary(x,mode)
%CLASSSUMMARY List class and axisscale distributions for a DataSet.
% Produces a text summary of the class and axisscales in an input DataSet
% object. The summary includes, for each class set, the number of items
% (rows, columns, etc) in each class type. It also includes for each
% axisscale set a rough distribution of items at a range of axisscale
% "bins". If a given axisscale contains more than 10 discrete values, the
% bins are automatically calculated to include 10 values over the full
% range of axissscale values.
%
%I/O: out = classsummary(x,mode)

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  mode = 1;
end
out = {};

cls = x.class(mode,:);
for s = 1:length(cls);
  if isempty(cls{s})
    continue;
  end
  lookup = x.classlookup{mode,s};
  if size(lookup,1)>1
    [hy,hx] = hist(cls{s},[lookup{:,1}]);
  else
    hy = length(cls{s});
  end
  
  %note which classes have ANY members
  show = hy>0;
  
  if any(show)
    len = max(5,max(cellfun('size',lookup(show,2),2)));
    
    out {end+1} = (sprintf('Class Set #%i %s',s,x.classname{mode,s}));
    out {end+1} = (['   =' sprintf(['  % ' num2str(len) 's'],lookup{show,2})]);
    out {end+1} = (['   #' sprintf(['  % ' num2str(len) 'i'],hy(show))]);
  end
end

axs = x.axisscale(mode,:);
for s = 1:length(axs);
  if isempty(axs{s})
    continue;
  end
  
  hx = unique(axs{s}(~isnan(axs{s})));
  maxbins = 10;
  if isempty(hx) | length(hx)>maxbins; hx = maxbins; end
  [hy,hx] = hist(axs{s},hx);
  
  lookup = str2cell(sprintf('%6g\n',hx));
  len = max(5,max(cellfun('size',lookup,2)));
  out {end+1} = (sprintf('Axisscale Set #%i %s',s,x.axisscalename{mode,s}));
  out {end+1} = (['   =' sprintf(['  % ' num2str(len) 's'],lookup{:})]);
  out {end+1} = (['   #' sprintf(['  % ' num2str(len) 'i'],hy)]);
end

if nargout==0
  disp(char(out));
  clear out
end
