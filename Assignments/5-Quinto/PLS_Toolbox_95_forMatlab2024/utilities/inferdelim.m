function [delim,headerrows] = inferdelim(data)
%INFERDELIM Infer the delimiter required to best parse strings into data
% An input of a cell of strings is analyzed to identify the most likely
% delimiter which can be used to parse those lines into separate data items.
% INPUT:
%   data = cell of strings (row vectors)
% OUTPUT:
%   delim = inferred delimiter, string indicates the delimeter string,
%           double incates fixed width.
%   headerrows = estimated number of header lines in file (lines at top of
%           file that contain a different number of the inferred delimiter
%           than the bulk of the file)
%
%I/O: [delim,headerrows] = inferdelim(data)

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isstr(data)
  data = str2cell(data);
end
%find those characters which are in common to all lines
common = unique(cat(2,data{1:min(50,length(data))}));

common = setdiff(common,['0':'9' 'A':'Z' 'a':'z' '.' '(' ')' '+' '-']);
common = setdiff(common,[10 13]); %and end of line characters
if isempty(common);
  delim = [];
  headerrows = 0;
  return
end

count = zeros(length(data),length(common));
lenc = length(data);
for j=1:lenc; 
  if ~isempty(data{j});
    d = (ones(length(common),1)*data{j})-(common'*ones(1,length(data{j})));
    count(j,:) = sum(d==0,2)';
  end
  if mod(j,50)==0 %every 50 rows, retest this
    %see if only one delimiter is found in the same amount in all rows up
    %to this point
    mx = max(count(1:j,:),[],1);  
    rng = mx-min(count(1:j,:),[],1);
    if sum(rng==0 & mx>0)==1
      %got one likely delimiter, use it
      sel = rng==0 & mx>0;
      common = common(sel);
      count = count(:,sel);
      break;
    end
  end
end

if length(common)==1
  delim = common;
else

  possible = mean(count>0,1)>=.5;  %more than 50% must have this delimiter
  common   = common(possible);
  count    = count(:,possible);
  
  prob = 1-mean(scale(count,median(count,1))~=0);
  perfect = find(prob==1);
  if ~isempty(perfect)
    [delim,sel] = min(common(perfect));  %choose one with lowest ASCII value
    count = count(:,sel);
  else
    %choose highest probability
    [pwhat,pwhere] = max(prob);
    delim = min(common(pwhere));
    count = count(:,pwhere);
  end
    
end

if ~isempty(count)
  headerrows = min(find(count==median(count)))-1;
else
  headerrows = 0;
end
