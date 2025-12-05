function y=comparelcms_simengine(data,filter_width,h);
%COMPARELCMS_SIMENGINE Calculational Engine for comparelcms.
%The function calculates similarity values of variables of several
%different data sets. Plotting variables with a low similarity value 
%shows the variables that are different across the samples. A typical
%example is the analysis of data sets of different batches of the same
%material with the goal to extract the minor differences between the
%samples.
%
%INPUTS:
%           data : data cube, size n_samples, n_spectra, n_variables
%   filter_width : optional, filter used for smoothing of columns in order
%     to take care of minor peak shifts, default is 1 = no filtering
%              h : handle for waitbar, optional
%OUTPUTS:
%         y : similarity indices of the variables, size n_variables*1.
%              Low values indicate differences.
%
%I/O: y=comparelcms_simengine(data,filter_width)
%I/O: comparelcms_simengine demo
%
%See also: COMPARELCMS_SIM_INTERACTIVE

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%ww

%EVRIIO 

if nargin == 0; data = 'io'; end
if ischar(data);
    options=[];
    if nargout==0; 
        evriio(mfilename,data,options); 
    else;
        y = evriio(mfilename,data,options); 
    end;
  return 
end;

%INITIALIZATIONS

[nslabs,nrows,ncols]=size(data);
if nargin==1;filter_width=1;end;

%FILTER DATA

if filter_width>1;
	for i=1:nslabs;
       b=reshape(data(i,:,:),nrows,ncols);
       data(i,:,:)=filter2(ones(filter_width,1)/filter_width,b,'same');
	end;
end;
if nargin==3;waitbar(1/5,h);end;

%CALCULATE SIMILARITY INDEX

mean_spec=mean(data);
mean_spec=reshape(mean_spec,nrows,ncols);
min_spec=min(data);
min_spec=reshape(min_spec,nrows,ncols);
if nargin==3;waitbar(2/5,h);end;

% array1=all(mean_spec==0);%take out all zero arrays
% array2=all(min_spec==0);
% array=((array1==1)|(array2==1));
% masses_selected(array)=[];
% mean_spec(:,array)=[];
% min_spec(:,array)=[];
% data_all(:,:,array)=[];
% max_rows(array)=[];

%CALCULATE CORELATION BETWEEN MEANSPEC AND MINSPEC

m=mean(mean_spec);
m=repmat(m,nrows,1);
s=std(mean_spec);
array=(s==0);%takes care of dividing by 0;
s(array)=1;%takes care of dividing by 0;
s=repmat(s,nrows,1);
a1=(mean_spec-m)./s;
if nargin==3;waitbar(3/5,h);end;

m=mean(min_spec);
m=repmat(m,nrows,1);
s=std(min_spec);
array=(s==0);%takes care of dividing by 0;
s(array)=1;%takes care of dividing by 0;
s=repmat(s,nrows,1);
a2=(min_spec-m)./s;
y=sum(a1.*a2)/nrows;
if nargin==3;waitbar(4/5,h);end;

%WEIGHS THE CORRELATION COEFFICIENTS WITH LENGTHS

% a=sum(sqrt(mean_spec.^2));
% array=(a==0);
% a(array)=1;%prevents divide by zero error;
% %y=y.*sum(sqrt(min_spec.^2))./sum(sqrt(mean_spec.^2));
% y=y.*sum(sqrt(min_spec.^2))./a;
% y(array)=1;

a=sqrt(sum(mean_spec.^2));
array=(a==0);
a(array)=1;%prevents divide by zero error;
y=y.*sqrt(sum(min_spec.^2))./a;
y(array)=1;

if nargin==3;waitbar(5/5,h);end;
