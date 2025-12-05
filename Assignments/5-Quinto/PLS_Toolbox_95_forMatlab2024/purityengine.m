function [purity_index,purity_values,length_values]=purityengine(data,base,offset,h);
%PURITYENGINE Calculates purity values of columns of data set.
% This function is the primary calculational engine for the function purity
%
%INPUTS:
%           data: matrix to be analyzed
%           base: matrix with previously selected pure variable 
%                 intensities, for first pure variable it should be empty.
%                 When base is a single integer, e.g. 3, the first 3 pure
%                 variables are calculated.  
%           offset: noise correction factor
%           h: handle for waitbar, optional
%
%OUTPUTS:
%           purity_index: index(indices) of maximum value in purity_values, i.e. the
%               index of the pure variable 
%           purity_values: array (or matrix) with purity values with length of the
%              column dimension of data, the purity spectrum
%           length_values: array (or matrix) with purity values multiplied by length of
%               columns of the data set, whci results in a spectra than is easier
%               to relate to the original data. The length is the
%               column dimension of data
%
%I/O: [purity_index,purity_values,length_values] = purityengine(data,base,offset,h);
%  
%See also: PURITY

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%ww

if nargin == 0; data = 'io'; end
if ischar(data);
    %options=define_options;
    options=[];
    if nargout==0; 
        evriio(mfilename,data,options); 
    else;
        purity_index = evriio(mfilename,data,options); 
    end;
  return 
end;

%INITIALIZATIONS

[nrows,ncols]=size(data);

%IF BASE IS SINGLE ELEMENT FUNCTION IS CALLED RECURSIVELY

if length(base(:))==1;
    n_components=base;
    purity_index=zeros(n_components,1);
    purity_values=zeros(n_components,ncols);
    length_values=zeros(n_components,ncols);
    base=[];
    for i=1:n_components;
        [purity_index0,purity_values0,length_values0]=...
            purityengine(data,base,offset);      
        purity_values(i,:)=purity_values0;  
        length_values(i,:)=length_values0;
        purity_index(i)=purity_index0;
        base=data(:,purity_index(1:i));
    end;
    return
end;

%INITIALIZATIONS

mean_data=mean(data);
length_data=sqrt(mean(data.*data));
angle_variables=nan(1,ncols);
if isempty(base);base=ones(nrows,1);end;
%if isempty(base);base=std(data,1,2);end;

noise_correction=mean_data./(mean_data+(offset/100)*max(mean_data));
noise_correction=(1+offset/100)*noise_correction;%to make maximum value 1

base = orth(base);
colnorm = nan(ncols, 1);
for j=1:ncols;
  colnorm(j) = norm(data(:,j));
end;
usable = ~isnan(colnorm) & ~colnorm==0;
range=1:length(usable);
for j=range(usable)
  item = data(:,j)./colnorm(j);
  angle_variables(j) = norm(item - base*(base'*item));
end;
angle_variables = asin(min(angle_variables,1));

angle_variables=180*angle_variables/pi;%convert to degrees
purity_values=angle_variables.*noise_correction;
length_values=purity_values.*length_data;
max_value=max(purity_values);
purity_index=find(purity_values==max_value);
purity_index=purity_index(1);

