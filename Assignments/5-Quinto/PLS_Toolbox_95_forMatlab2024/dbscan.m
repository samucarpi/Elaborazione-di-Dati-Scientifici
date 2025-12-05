function [cls,epsdist] = dbscan(data, minpts, epsdist)
%DBSCAN Density-based automatic sample clustering.
% DBSCAN automatically identifies clusters in data (or scores) using a
% density-based algorithm. Samples which are within an  "acceptable"
% distance are agglomerated into a single class. Samples which are too far
% from any cluster and do not have a minimum number of un-assigned neighbors
% are assigned as "noise" (although such points may be re-assigned as a
% class if a class is identified acceptably close by).
%
% INPUT:
%     data = A double or dataset object.
% OPTIONAL INPUTS:
%   minpts = The minimum number of unclassed points which should be
%            considered a "class" (default = 2)
%  epsdist = The largest distance between samples considered to be related
%            (can also be considered the minimum distance between unrelated
%            classes.) Default: determined by the range and number of data
%            points available.
% OUTUPTS:
%      cls = Numerical classes for each of the m samples in the original
%            data. Samples excluded in original dataset are always returned
%            as class 0 (zero, unknown.)
%  epsdist = The "eps" value used (useful if no epsdist value was supplied by
%            user.)
%
% Based on the algorithm presented in:
%    http://www.dbs.informatik.uni-muenchen.de/Publikationen/Papers/KDD-96.final.frame.pdf
% with additional modifications for speed.
%
%I/O: [cls,epsdist] = dbscan(data,minpts,epsdist)
%
%See also: CLUSTER, KNN, PCA

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS

if nargin==0; data = 'io'; end

if ischar(data);
  options = [];
  if nargout==0; evriio(mfilename,data,options); else; cls = evriio(mfilename,data,options); end
  return;
end


%extract data info from DSO
originaldata = data;
if isdataset(data)
  incl = data.include;
  data = data.data(incl{:});
end

[m,n] = size(data);

%determine default values for inputs
if nargin<2 || isempty(minpts)
  minpts = 2;
end
if nargin<3 || isempty(epsdist)
  % epsdist = ((prod(max(data)-min(data))*minpts*gamma(.5*n+1))/(m*sqrt(pi.^n))).^(1/n);
  % Avoid original form because gamma(n) becomes Inf for n>175. The prod
  % term also becomes very large. Then Inf.^(1/n) is still Inf...
  % Also avoid calculating huge "prod" term if n is large by working in log.
  logprod = sum(log(max(data)-min(data)));
  % Use Stirlings formula for factorial (Can use this for any n):
  % gamma(x+1) = factorial(x). factorial(x) = sqrt(2*pi*x) * (x/exp(1))^x
  t1 = exp(logprod/n);
  t2 = (minpts*sqrt(pi*n)/m)^(1/n);
  t3 = sqrt(n/(2*exp(1)*pi));
  epsdist = t1*t2*t3;
end

%initialize waitbar timer and handle
starttime = now;
wbh = [];
wfh = [];

try  %assure we exit gracefully (closing figures)
  %initialize classes and cluster ID
  cls  = zeros(1,m);
  ClusterId = 1;
  while any(cls==0)
    %find lowest-numbered unassigned point
    point = min(find(cls==0));
    
    %locate points which are close to this point
    seeds = regionQuery(data,point,epsdist,1:point-1);
    
    if length(seeds)<=minpts % not enough core points
      
      cls(point) = -1;  %mark as "noise"
      
    else % all points in seeds are density-reachable from Point
      
      cls(seeds) = ClusterId;  %mark initial seeds with cluster #
      seedind = 1;  %which seed are we pointing at to start
      examined = zeros(1,length(seeds));  %Has this seed been examined yet
      
      step = 1;     %used to update figures
      plotstep = 1;
      
      while ~all(examined)
        examined(seedind) = 1;  %mark seed examined and get connected seeds
        newseeds = regionQuery(data,seeds(seedind),epsdist,seeds);
        newseeds = newseeds(cls(newseeds)<=0); %remove those seeds with classes already
        
        if ~isempty(newseeds);
          seeds    = [seeds;newseeds(cls(newseeds)==0)];  %add remaining (non-classed) to seeds list (NOT noise peaks)
          cls(newseeds) = ClusterId;    %label ALL these as "classified" with this ID
          examined(length(seeds)) = 0;  %extend examined matrix to account for additional seeds
        end
        
        seedind = max(find(~examined));  %locate furthest connected point from last examined
        
        step = step+1;
        if floor(step/100)>plotstep;
          plotstep = floor(step/100);
          if isempty(wbh)
            if now-starttime>3/60/60/24;
              wbh = waitbar(mean(cls~=0),'Clustering Data... (Close to Cancel)');
            end
          else
            if ~ishandle(wbh)
              error('User Teriminated Clustering');
            end
            waitbar(mean(cls~=0),wbh);
            if isdataset(originaldata) & strcmp(originaldata.type,'image') & (isempty(wfh) | ishandle(wfh))
              if isempty(wfh)
                wbp = get(wbh,'position');
                pos = get(0,'defaultfigureposition');
                pos(2) = wbp(2)-pos(4);
                wfh = figure('numbertitle','off','name','DBScan Image','handlevisibility','on'...
                  ,'integerhandle','off','menubar','none','toolbar','none','position',pos);
              end
              sz = originaldata.imagesize;
              set(0,'currentfigure',wfh)
              temp = nan(1,size(originaldata,1));
              temp(originaldata.include{1}) = cls;
              imagesc(reshape(temp,sz));
              drawnow;
            end
          end
        end
      end
      
      ClusterId = ClusterId+1;
      
    end
    
    if ishandle(wbh)
      waitbar(mean(cls~=0));
    end
    
  end
  
  if ishandle(wfh); close(wfh); end
  if ishandle(wbh); close(wbh); end
  
  if isdataset(originaldata)
    if length(originaldata.include{1})~=size(originaldata,1);
      %had some excluded samples? insert zeros for those
      temp = zeros(1,size(originaldata,1));
      temp(originaldata.include{1}) = cls;
      cls = temp;
    end
  end
  
catch
  le = lasterror;
  if ishandle(wfh); close(wfh); end
  if ishandle(wbh); close(wbh); end
  rethrow(le);
end

%-------------------------------------------------------
%locate samples which are acceptably close to a given sample (with ability
%to "ignore" samples)
function found = regionQuery(data,point,epsdist,ignore)

switch 3
  %three different ways to do the same thing. Just testing speed.
  case 1
    mn = (ones(size(data,1),1)*data(point,:));
    d  = (data-mn).^2;
    d  = sqrt(sum(d,2));
    d(ignore) = inf;

  case 2
    d = sqrt(sum((data-(ones(size(data,1),1)*data(point,:))).^2,2));  %note: in-line calculation is faster than step-by-step calculation!
    d(ignore) = inf;

  case 3
    [m,n]  = size(data);
    d      = ones(m,1)*inf;
    use    = 1:m;
    use(ignore) = [];
    d(use) = sqrt(sum((data(use,:)-(ones(length(use),1)*data(point,:))).^2,2));  %note: in-line calculation is faster than step-by-step calculation!

end

found = find(d<=epsdist);

%sort found points into increasing distance order (allows jumping to
%furthest out points
[what,order] = sort(d(found));
found = found(order);
