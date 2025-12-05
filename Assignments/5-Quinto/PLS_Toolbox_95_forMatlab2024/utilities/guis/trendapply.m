function [results,tags,normto] = trendapply(mydata,markers,options)
%TRENDAPPLY Apply trend tool markers to data.
% Applies a set of trend tool markers to data returning the numerical
% results and labels indicating how the values were derived.
%
% INPUTS:
%   mydata = a double or dataset object containing the data to apply the
%            trend markers to.
%  markers = a trend markers structure as created by trend tool.
%
% OPTIONAL INPUTS:
%  options = a standard options structure with one or more of the following
%            fields:
%     viewexcludeddata : [ 0 | 1 ] controls whether excluded data is used
%            in the derivation of the trend marker results. If 1 (one),
%            excluded data is used when calculating results. If 0 (zero),
%            excluded data is ignored.
%
% OUTPUTS:
%   results = numerical array with each column representing the results
%             from one of the trend markers.
%      tags = cell array of strings which describe each column of results.
%    normto = numerical index indicating which (if any) of the columns of
%             results was used to normalize the other columns. If no marker
%             was indicated as the "normalize to" marker, then normto will
%             be empty and all results will be the raw values of the
%             associated marker.
% 
%I/O: [results,tags,normto] = trendapply(mydata,markers,options)
%
%See also: TRENDTOOL, TRENDMARKER, TRENDLINK, TRENDWATERFALL

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin==0; mydata = 'io'; end
if ischar(mydata)  
  options = [];
  options.viewexcludeddata = 0;
  if nargout==0; evriio(mfilename,mydata,options); else; results = evriio(mfilename,mydata,options); end
  return;
end

if nargin<3; options = []; end
options = reconopts(options,mfilename,{'plotby'});

if ~isdataset(mydata)
  mydata = dataset(mydata);
end

if ismodel(markers)  
  %apply preprocessing in model passed in
  preprocessing = markers.detail.preprocessing;
  if ~isempty(preprocessing{1})
    mydata = preprocess('apply',preprocessing{1},mydata);
  end
  markers = markers.markers;
end

if isfield(markers,'handles');
  %convert from GUI-based handles to self-indexing:
  for j=1:length(markers.data);
    markers.data(j).link = find(ismember(markers.handles,markers.data(j).link));
  end
  markers = markers.data;  %and extract just the data field (now matches what we save from GUI too)
end

%Determine indicies closest to marked points
xind   = 1:size(mydata,2);
xaxis  = mydata.axisscale{2};
if isempty(xaxis);  %working in unitless "index"
  xaxis = xind;
end
if ~isempty(markers)
  if length(xind)>1
    x = min(max([markers.x],min(xaxis(xind))),max(xaxis(xind)));
    ind   = interp1(xaxis,xind,x,'nearest');
  else
    ind = 1;
  end
  %get x-values from those indicies (except "bad" points which should = NaN
  bad   = isnan(ind);
  ind(bad) = 1;
  xind  = xaxis(ind);
  xind(bad) = nan;
  ind(bad) = nan;
end

results = [];
tags = cell(0);

%- - - - - - - - - - -
%do calculations
normto = [];
  
for j = 1:length(markers);
  
  if ~isempty(markers(j).link); continue; end; %skip this one, it is linked to another
  
  if isfinite(ind(j))
    switch markers(j).mode
      case {'p' 'w' 'm'}  %position, width or maximum
        %locate other side of peak maximum search area
        j2 = findmate(markers,j);
        j2 = min(max(j2,1),length(ind));
        intrange = sort(ind([j j2]));    %put indicies into order and extract range
        intrange = intrange(1):intrange(2);

        xval = sort([xind(j) xind(j2)]);
        switch markers(j).mode
          case 'p'
            tag = 'Peak Position between ';
          case 'w'
            tag = 'Full-width half max between ';
          case 'm'
            tag = 'Maximum between ';
        end
        tag = [tag num2str(xval(1)) '-' num2str(xval(2))];
        
        %generalized extraction of indicies
        inds = cell(1,ndims(mydata.data));
        [inds{1:end}] = deal(':');
        if ~options.viewexcludeddata
          %use only included variables
          intrange = intersect(intrange,mydata.include{2});
        end
        inds{2}       = intrange;
        
        %extract spectral sub-range
        subspec = mydata.data(inds{:});

        %Do correction for baseline
        refs = findref(markers,j);
        if ~isempty(refs) & all(isfinite(ind(refs)));
          x = [];
          xapp = [];
          tag = [tag ' baseline'];
          for jj=1:length(refs);
            x(jj,:)    = xaxis(ind(refs)).^(jj-1);      %x values for calc of baseline
            xapp(jj,:) = xaxis(intrange).^(jj-1);       %x values for application of baseline
            xval = sort(xind(refs(jj)));
            if jj == 1;
              tag = [tag ' ' num2str(xval)];
            else
              tag = [tag '&' num2str(xval)];
            end
          end
          inds{2}  = ind(refs);
          y = mydata.data(inds{:});
          b = y/x;
          subspec = subspec - b*xapp;
        end

        %locate rough maximum
        [what,where] = max(subspec,[],2);
        
        switch markers(j).mode
          case 'm';
            result = what;
          case 'p';
            %if oversample is <1, the following does interpolation of the max
            oversample = .1;
            if oversample<1 & size(subspec,2)>4
              xind_oversampled = -2:oversample:2;
              for specnum=1:size(subspec,1);
                where_subset = where(specnum)+(-2:2);
                where_subset = min(max(where_subset,1),size(subspec,2));
                [what_i,where_i] = max(interp1(-2:2,subspec(specnum,where_subset),xind_oversampled,'spline'));
                where(specnum) = where(specnum)+xind_oversampled(where_i);
              end
              result = interp1(1:size(subspec,2),xaxis(intrange),where);
            else
              %no interpolation
              result = xaxis(intrange(where));
            end
          case 'w'
            %if request for width, do that now
            xaxissub = xaxis(intrange);
            for specnum=1:size(subspec,1);
              %locate first approximation of low-variable 1/2 point
              temp = xaxissub;
              temp(where(specnum):end) = -inf;  %block out points above peak max
              temp(subspec(specnum,:)>what(specnum)/2) = -inf;   %block out intensities above 1/2 of peak max
              [low_what,low_where] = max(temp);
              if ~isfinite(low_what) 
                low_what = nan;
              elseif low_where==1;
                low_what = xaxissub(1);
              else
                try
                  low_what = interp1(subspec(specnum,low_where-1:low_where+1),xaxissub(low_where-1:low_where+1),what(specnum)/2);
                catch
                  low_what = nan;
                end
              end
              
              %locate first approximation of high-variable 1/2 point
              temp = xaxissub;
              temp(1:where(specnum)) = inf;  %block out points below peak max
              temp(subspec(specnum,:)>what(specnum)/2) = inf;   %block out intensities above 1/2 of peak max
              [high_what,high_where] = min(temp);
              if ~isfinite(high_what)
                high_what = nan;
              elseif high_where==length(temp);
                high_what = xaxissub(end);
              else
                try                  
                  high_what = interp1(subspec(specnum,high_where-1:high_where+1),xaxissub(high_where-1:high_where+1),what(specnum)/2);
                catch
                  high_what = nan;
                end
              end
              
              result(specnum) = diff([low_what high_what]);
            end            
            
        end
        
        
      case {'h' 'a'}
        switch markers(j).mode
          case 'h'   %height
            intrange = ind(j);
            xval = xind(j);
            tag = ['Response ' num2str(xval)];
          case 'a'   %area
            %locate other side of integration area
            j2 = findmate(markers,j);
            j2 = min(max(j2,1),length(ind));
            intrange = sort(ind([j j2]));    %put indicies into order and extract range
            intrange = intrange(1):intrange(2);

            xval = sort([xind(j) xind(j2)]);
            tag = ['Area ' num2str(xval(1)) '-' num2str(xval(2))];
        end

        %generalized extraction of indicies
        inds = cell(1,ndims(mydata.data));
        [inds{1:end}] = deal(':');
        if options.viewexcludeddata
          %showing excluded data? use all variables
          inds{2} = intrange;
        else
          %use only included variables
          inds{2} = intersect(intrange,mydata.include{2});
        end
        
        %Extract indicated indicies
        if ~isempty(inds{2})
          result = sum(mydata.data(inds{:}),2);
        else
          result = zeros(size(mydata,1),1).*nan;
        end

        %Do correction for baseline
        refs = findref(markers,j);
        refs = min(max(refs,1),length(ind));
        if ~isempty(refs) & all(isfinite(ind(refs))) & ~isempty(inds{2})
          x = [];
          xapp = [];
          tag = [tag ' baseline'];
          for jj=1:length(refs);
            x(jj,:)    = xaxis(ind(refs)).^(jj-1);      %x values for calc of baseline
            xapp(jj,:) = xaxis(intrange).^(jj-1);       %x values for application of baseline
            xval = sort(xind(refs(jj)));
            if jj == 1;
              tag = [tag ' ' num2str(xval)];
            else
              tag = [tag '&' num2str(xval)];
            end
          end
          inds{2}  = ind(refs);
          y = mydata.data(inds{:});
          b = y/x;
          correction = sum(b*xapp,2);
          result = result - correction;
        end
    end

  else  %invalid index, fake entry
      result = zeros(size(mydata.data,1),1)*nan;
      tag = '';
  end
  
  %insert one-column answer into results array
  
  if (ndims(mydata)>2)
    beep;
    g=errordlg('Trendtool is not compatible with multiway data.');
    return;
  end
  
  results(:,end+1) = result;
  tags{end+1} = tag;
  
  %if this is the peak we're normalizing to...
  if markers(j).normalize
    normto = size(results,2);  %store this column's index
  end
  
end

%normalize if requested
if ~isempty(markers) & ~isempty(normto)
  results = scale(results',zeros(1,size(results,1)),results(:,normto)')';
end

%-----------------------------------------------------------
function mate = findmate(markers,ind)

linked = findlinked(markers,ind);
mate = [];
for j=1:length(linked)
  if markers(linked(j)).mode==markers(ind).mode & ind~=linked(j);
    %this one matches in mode and isn't me? it is my partner
    mate = linked(j);
    return
  end
end

%-----------------------------------------------------------
function refs = findref(markers,ind)

linked = findlinked(markers,ind);
modes  = [markers(linked).mode];
refs   = linked(modes=='b' | modes=='o');


%----------------------------------------------------------
function linked = findlinked(markers,ind)

linked = [];
for j=1:length(markers)
  if markers(j).link==ind
    linked(end+1) = j;
  end
end
    
