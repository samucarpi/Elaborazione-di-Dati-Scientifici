function dso = ms_bin(data,options)
%MS_BIN bins Mass Spectral data into user-defined bins.
%   INPUTS:
%               data : a cell array with the data. Each cell will
%                      correspond to a row in the resulting dataset 'dso'
%                      and should contain nx2 numeric array of "xy" MS
%                      data: the first column contains the mass numbers,
%                      the second column contains the counts (intensities).
%                      The number of rows in the cells can be different.
%   OPTIONS:
%     Optional structure input (options) can contain any of the fields:
%         resolution : optional, defines the resolution. The default value is 1.
%    round_off_point : optional. Normally the round-off point is in the
%                      middle of the bin. For unit resolution it would be 0.5:
%                      everything below 0.5 will be rounded down, everything higher
%                      than 0.5 will be rounded up. In case the peak is asymmetrical
%                      other points are used, e.g. 0.65. The round off for the
%                      array m with the mass numbers is then:
%                      round(m+0.5-round_off_point);
%                      The asymmetric round-off is also valid for resolution lower than
%                      1: the round_off_point is the relative position in the bin.
%   OUTPUTS:
%                dso : dataset object
%
%I/O: dso = ms_bin(data);
%I/O: dso = ms_bin(data, options);
%I/O: ms_bin demo
%
%See also: MS_BINDEMO

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%WW 01/05/07

%INITIALIZATIONS
if nargin == 0; data = 'io'; end
if ischar(data);
  options = [];
  options.resolution      = 1;
  options.round_off_point = 0.5;
  if nargout==0;
    evriio(mfilename,data,options);
  else
    dso = evriio(mfilename,data,options);
  end
  return;
end

if nargin<2;
  options = ms_bin('options');
else
  options = reconopts(options,'ms_bin');
end;

resolution = options.resolution;
round_off_point = options.round_off_point;

%GET SIZE INFO AND INITIALIZE MATRICES

n_data=length(data);
nrows=zeros(length(n_data));
for i=1:n_data;
  nrows(i)=size(data{i},1);
end;

d=zeros(sum(nrows),3);
index2=0;
for i=1:n_data;
  index1=index2+1;
  index2=index1+nrows(i)-1;
  d(index1:index2,[1 3])=data{i};
  d(index1:index2,2)=i;
end;

d(:,1)=d(:,1)/resolution;
d(:,1)=d(:,1)+.5-round_off_point;
d(:,1)=round(d(:,1));

array=(d(:,1)==0);
d(array,:)=[];
first_mass=min(d(:,1));
d(:,1)=d(:,1)-first_mass+1;
s=sparse(d(:,1),d(:,2),d(:,3));

[index1,dummy,d2]=find(s);
index1=unique(index1);

f=full(s);
f=f(index1,:);

axisscale2=index1+first_mass-1;
axisscale2=axisscale2*resolution;
dso=dataset(f');
dso.axisscale{1}=[1:n_data];
dso.axisscale{2}=axisscale2;
