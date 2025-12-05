function desgn = doescale(desgn,scales)
%DOESCALE Convert coded DOE to scaled DOE or scaled back to coded.
% When given an coded DOE (desgn) and a cell array (scales) equal in length
% to the number of factors (i.e. columns) in the DOE, the DOE is converted
% to the uncoded scaled form using the corresponding values from the scales
% array. 
%
% AUTOMATIC LINEAR SCALING:
% Any cell in scales containing only two values is assumed to be
% specifying the minimum and maximum values for the DOE and intermediate
% values are interpolated using the DOEs coded levels. 
% EXAMPLE:
%    scales = { [10 15] [20 100] }
% would convert the first factor to uncoded format using a minimum value of
% 10 and maximum value of 15, and the second factor to a minimum of 20 and
% maximum of 100.
%
% MANUAL CUSTOM SCALING:
% If any cell has more than two elements, it is assumed to be the specific
% scales to use for the corresponding factor. It must be equal in length to
% the number of levels in the corresponding factor.
% EXAMPLE:
%    scales = { [10 15] [20 60 65 70] }
% would convert the second factor to the values indicated (20, 60, 65 and
% 70) assuming it is a 4-level factor. 
%
% CUSTOM SCALING WITH MISSING CENTER POINT: If the coded version of given
% factor has a center point, but the manually-provided scales for that
% factor is missing one value (e.g. a centered 5-level factor has only 4
% scales provided), then a value for the center point is automatically
% added by calculating the mean of the provided scales. Thus, scales of
% [10 20 30 40] for a 5-level factor would use 25 for the center point,
% which is the equivalent of having passed [10 20 25 30 40] for the
% scales.
%
% RE-CODING (unscaling):
% When given only an uncoded DOE (without the scales input), the DOE is
% converted back to coded format.
%
%I/O: desgn = doescale(desgn,scales)   %coded to scaled
%I/O: desgn = doescale(desgn)          %scaled to coded
%
%See also: CCDFACE, CCDSPHERE, DOEINTERACTIONS, FACTDES, FFACDES1

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  error('Design is a required input')
end
nfact = size(desgn,2);

%get apparent number of levels in this design
nlvl = ones(1,nfact)*2;
for j=1:nfact;
  nlvl(j) = length(unique(desgn(:,j)));
end

if nargin>1
  %APPLYING coding
  undo = false;
  
  %check inputs
  if length(scales)~=nfact
    error('Number of elements in scales must be equal to the number of design factors (columns)');
  end
  nsetlvl = cellfun('length',scales);  %get number of scales user is passing for each factor

  %locate non-centered factors
  noncent = all(desgn~=0,1);
  
  %if factor is centered and number of set levels is one less than number
  %needed, we should ADD a centering value
  needscenter = ~noncent & nlvl==nsetlvl+1;
  for j=find(needscenter)
    %add center point as mean of all other values
    scales{j} = scales{j}(:)';
    scales{j} = [scales{j}(1:nsetlvl(j)/2) mean(scales{j}) scales{j}((nsetlvl(j)/2+1):end)];
    nsetlvl(j) = nsetlvl(j)+1;
  end
  
  %compare nsetlvl to actual number of levels in design
  if any(nsetlvl~=2 & nsetlvl~=nlvl)
    error('Scales must be either a pair of min/max values or a vector equal to the number of levels in the corresponding factor')
  end
  
  %convert from cell array to min/max and locate non-linear levels
  mins = zeros(1,nfact);
  maxs = ones(1,nfact);
  linear = (nsetlvl==2);  %Indicates which factors have linear coding
  for j=find(linear)
    %for levels where we were given min/max, copy those into mins/maxs
    %arrays
    mins(j) = min(scales{j});
    maxs(j) = max(scales{j});
  end

  %adjust design for factors without center points
  %adjust non-centered factors for missing zero offset
  desgn = desgn+double(desgn>0)*diag(double(noncent))*-1;
else
  %undoing previous centering - calculate apparent levels
  undo = true;
  noncent = (mod(nlvl,2)==0);
  maxs = floor(nlvl/2);
  mins = -maxs;
  linear = true(1,nfact);
end

%Undo current scaling (sets everything from 0-1)
rawmin   = min(desgn);
rawrange = range(desgn);
desgn = scale(desgn,rawmin,rawrange);

%calculate scaling to get to desired mins&maxs
ranges = maxs-mins;
desgn  = rescale(desgn,mins,ranges);

%force mapping for non-linear scales
for j=find(~linear)
  [uwhat,junk,umap] = unique(desgn(:,j));
  desgn(:,j) = scales{j}(umap);
end

if undo
  %if undoing, round to nearest integer (but only for non-centered terms)
  desgn(:,noncent) = round(desgn(:,noncent));
end
