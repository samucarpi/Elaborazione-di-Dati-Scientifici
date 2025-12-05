function [dat, mins, maxs] = minmax(dat, options)
%MINMAX Perform min-max scaling, sometimes called "unity normalization" 
% where each sample ( or variable) in the calibration X-block is scaled as:
% xpp = (x - min(x))/(max(x) - min(x))
% so it transforms X such that each row ( or column) will have range [0,1] 
% after this preprocessing. 
%
% INPUTS:
%     x   = Data to be scaled (double or DataSet object).
% OPTIONAL INPUTS:
% options = Options structure with one or more of the following fields:
%           mode: [ 1 ] indicate whether to calculate the min/max over rows
%                 (default), or columns.
%                  1 = scale each row so it ranges from 0 to 1.
%                  2 = scale each column so it ranges from 0 to 1.
% OUTPUTS:
%     dat = Scaled data.
%    mins = Vector of minima calculated for given data.
%    maxs = Vector of maxima calculated for given data.
%
%I/O: [xs,mins, maxs] = minmax(x,options);     %calibrate scaling

%Copyright Eigenvector Research, Inc. 2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; dat = 'io'; end
if ischar(dat); %Help, Demo, Options
  options = [];
  options.mode = 1;
  options.display = 'on';
  if nargout==0; evriio(mfilename,dat,options); clear dat; else; dat = evriio(mfilename,dat,options); end
  return;
end

switch nargin
  case 1
    % (x)
    options = [];
  case 2
    % (x,options)
end
options = reconopts(options,mfilename);


% %if it is a dataset, extract data
wasdataset = isdataset(dat);
if wasdataset
  originaldata = dat;
  incl = dat.include;
  dat = dat.data;
  dat = dat(incl{1}, incl{2});
end

switch options.mode
  case 1
    
  case 2
    % scale by cols
    dat = dat';
end

%create output vectors of min and max values
mins = min(dat, [], 2);
maxs = max(dat, [], 2);

% %loop through variables and perform min-max operation
% for bb = 1:size(dat,2)
%     col_min = min(dat(:,bb));
%     col_max = max(dat(:,bb));
%         for yy = 1:size(dat,1)
%             dat(yy,bb) = (dat(yy,bb)-col_min)/(col_max-col_min);
%         end
% end

dat = dat - mins*ones(1, size(dat,2));
difference = maxs-mins;
if any(difference<eps)
  difference(find(difference<eps)) = eps;
end
dat = dat./((difference)*ones(1, size(dat,2)));


% undo transpose if necessary
switch options.mode
  case 1
    
  case 2
    % scale by rows
    dat = dat';
end

if wasdataset
  %re-insert back into dataset (if it was to begin with)
  originaldata.data(incl{1},incl{2}) = dat;
  dat = originaldata;
end

end

