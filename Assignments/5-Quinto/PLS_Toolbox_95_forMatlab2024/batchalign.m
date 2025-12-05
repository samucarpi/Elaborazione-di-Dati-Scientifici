function aligned = batchalign(data,ref_column,target,options)
%BATCHALIGN Convert data columns based on matching ref col to target vector.
%  Stretch or contract data columns based on a 'target' using given
%  'method'. Savgol options can be used to exagerate transitions in data
%  prior to cow.
% INPUTS:
%         data = (nsample, nvar) dataset or double array containing data 
%                columns to align.
%   ref_column = scalar indicating the column # of data that we are going
%                to match OR ref_vector which is a vector to use in match.
%       target = (nsample, 1) vector or dataset to which we are trying to 
%                match the ref_column or ref_vector.
% OPTIONAL INPUTS:
%   options = options includes:
%         method = 'cow', 'linear' or 'padwithnan' (default = 'cow')
%        savgolwidth = Number of points in savgol filter
%        savgolorder = Order of savgol polynomial
%        savgolderiv = [0,1,2...] Order of derivative to take of target and
%                        ref_column before doing alignment (default = 0) 
%         cow.segments   = length of segments (used with COW only)
%         cow.slack      = max range of warping (used with COW only. Must be <= segments - 4)
%         cow.plots             = Governs plotting with COW (0 = no plots, see cow)
%         cow.correlationpower  = correlation power (see cow)
%         cow.forceequalsegs    = Force equal segment lengths in "xt" and "xP" (see cow)
%         cow.fixmaxcorrection  = Fix maximum correction (see cow)
% OUTPUTS: 
%         aligned = dataset or double array (depending on input data type)
%         containing the aligned data. If it is a dataset of different
%         number of rows from input then the class, axisscale and labels
%         are set according to the closest row in input dataset.
%
%I/O: aligned = batchalign(data,ref_column,target,options)
%
%See also: ALIGNMAT, COW, MATCHROWS

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0;
  data = 'io';
end
if ischar(data)
  options = [];
  options.name        = 'options';
  options.method      = 'cow';     %Alignment method to use
  options.savgolderiv = 0;         %Order of derivative to take
  options.savgolwidth = 11;        %Number of points in filter
  options.savgolorder = 3;         %Order of polynomial
  options.cow.segments= 6;         %Segment length
  options.cow.slack   = 2;         %Maximum range or degree of warping in segment
  options.cow.plots   = 0;          %Make plot (note: only last row/object in "xP" is plotted)
  options.cow.correlationpower  = 1;  %Correlation power (minimum 1th power, maximum is 4th power)
  options.cow.forceequalsegs    = 1;  %Force equal segment lengths in "xt" and "xP" instead of filling up "xt" with N boundary-points
  options.cow.fixmaxcorrection  = 0;  %Fix maximum correction to + or - options(4) points from the diagonal
  options.definitions   = @optiondefs;
  if nargout==0; evriio(mfilename,data,options); else; aligned = evriio(mfilename,data,options); end
  return;
end

if nargin<4
  options = [];
end
options = reconopts(options,mfilename);

origdata = data;
inputdso = false;
if isa(origdata,'dataset')
  inputdso = true;
  data = data.data;
  rowindex = 1:size(data,1);
  data = [data rowindex'];
end

if length(ref_column)==1  % assume this is a column index
  if ref_column > size(data,2)
    error('Input ref column index exceeds number of columns in data');
  end
  ref_column = data(:, ref_column);
end

nref    = size(data,1);
if isa(target, 'dataset')
  target = target.data;
end
ntarget = length(target);

if strcmp(options.method, 'linear')
  % interpolate within the ref to make ntarget points
  aligned = interp1(1:nref, data, linspace(1, nref, ntarget));
elseif strcmp(options.method, 'padwithnan')
  % length(ref) < length(target): pad ref with NaNs to make ntarget points 
  % length(ref) > length(target): truncate ref to make ntarget points
  
  aligned = nan(ntarget, size(data,2));
  if nref < ntarget
    aligned(1:nref,:) = data;
  elseif nref > ntarget
    aligned = data(1:ntarget,:);
  else
    aligned = data;
  end
else
  % COW
      
  if options.savgolderiv > 0
    ref_columnp = savgol(ref_column', options.savgolwidth, options.savgolorder, options.savgolderiv);
    targetp = savgol(target', options.savgolwidth, options.savgolorder, options.savgolderiv);
    target = targetp';
    ref_column = ref_columnp';
  end
  
  %  [Warping,XWarped,Diagnos] = cow(T,X,Seg,Slack,Options);
  segs  = options.cow.segments; %6;
  slack = options.cow.slack;    %2;
  cowopts = [options.cow.plots options.cow.correlationpower options.cow.forceequalsegs options.cow.fixmaxcorrection 0];
  %   [Warping,xwarped,Diagnos] = cow(target', ref_column', seg, slack, cowopts);
  Warping = cow(target', ref_column', segs, slack, cowopts);
  
  % Apply to other columns
  xw = cow_apply(data', Warping);
  aligned = xw'; 
end

if isa(origdata,'dataset')
  [nrow, ncol] = size(origdata);
  %   apply warping to all relevant dataset fields
  rowindexnew = aligned(:,end);
  rowindexnew = round(rowindexnew);
  nanrows = isnan(rowindexnew);
  rowindexnew = rowindexnew(~nanrows);
  tmp = origdata(rowindexnew, :);
  tmp = [tmp;nan(sum(nanrows),size(tmp,2))];  %add at bottom for padded rows
  tmp.data = aligned(:,1:ncol);
  aligned = tmp;
  if ~inputdso
    aligned = aligned.data;
  end
end

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'method'                 'Standard'       'select'        {'cow' 'linear' 'padwithnan'}    'novice'        'Alignment method.';
'savgolderiv'            'Standard'       'select'        {0 1 2 3 4 5}                    'novice'        'Order of derivative to take.';
'savgolwidth'            'Standard'       'double'        'int(0:inf)'                     'novice'        'Number of points in filter. ''svd'' is standard decomposition algorithm. ''robustpca'' uses the robust PCA algorithm of the LIBRA toolbox (automatic outlier exclusion). ''maf'' is Maximum Autocorrelative Factors and requires Eigenvector''s MIA_Toolbox.';
'savgolorder'            'Standard'       'select'        {0 1 2 3 4 5}                    'novice'        'Order of polynomial.';
'cow.segments'           'COW Options'    'double'        'int(0:inf)'                     'novice'        'Segment length.';
'cow.slack'              'COW Options'    'double'        'int(0:inf)'                     'novice'        'Maximum range or degree of warping in segment length. NOTE: The slack cannot be larger than the length of the segments minus 4.';
};

out = makesubops(defs);
