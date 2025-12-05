function [dw_value,dw_index]=coda_dw(data,level);
%CODA_DW Calculates values for the Durbin_Watson criterion of columns of data set.
%The better the quality, the lower the Durbin-Watson value.
%The function is normally used for LC/MS data. Plotting variables with a
%low Durbin_Watson value eliminates solvent peaks.
%
%   [dw_value,dw_index]=coda_dw(data,level);
%
%INPUTS:
%     data : matrix to be analyzed, matrix or dso
%    level : (optional) used when plot is required,higer level of the
%      Durbin-Watson criterion. If integer, number of columns plotted.
%      If empty, no plot will be created.
%
%OUTPUTS:
%    dw_value : quality value of columns
%    dw_index : index for sorted (low tp high) dw_values
%
%I/O: [dw_value,dw_index] = coda_dw(data,level);
%I/O: coda_dw demo
%
%See also: CODA_DW_INTERACTIVE, DURBIN_WATSON

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%ww

%EVRI INITIALIZATIONS

if nargin == 0; data = 'io'; end
if ischar(data);
    options=[];
    if nargout==0; 
        evriio(mfilename,data,options); 
    else;
        dw_value=evriio(mfilename,data,options); 
    end;
  return 
end;

%PREPARE DSO

if ~isa(data,'dataset');data=dataset(data);end;

%INITIALIZATIONS

[nrows,ncols]=size(data.data);
if nargin==1;level=[];end;
if isempty(data.axisscale{1});data.axisscale{1}=[1:nrows];end;

%CALCULATE DURBIN_WATSON VALUES 

datader=diff(data.data);
dw_value=durbin_watson(datader);

[sort_value,dw_index]=sort(dw_value);
if isempty(level);return;end;%no plot required

%PLOT DETERMINED BY dw VALUES BELOW DEFINED LEVEL

if rem(level,1);
    select=(dw_value<level);%level is a real value
    data_selection=data.data(:,select);
    nvar=sum(select);
    dw_level=level;
else;
    data_selection=data.data(:,dw_index(1:level));%level is an integer value
    nvar=level;
    dw_level=sort_value(level);
end;

if isempty(data_selection);error('No data to plot, change level');end;
    
%PLOT THE FIRST N CHROMATOGRAMS

subplot(211);plot(data.axisscale{1},data.data);
title(['original data, ',num2str(ncols),' variables']);
subplot(212);plot(data.axisscale{1},data_selection);
title(['reduced data, ',num2str(nvar),' variables']);
xlabel(['quality level: ',num2str(dw_level)]);
shg;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function s=power_spectrum (x)
%POWER_SPECTRUM power spectrum (the 'real' powerspectrum is s.*s
half=ceil((size(x,1)+1)/2);
fft_x=(fft(x));
fft_x=fft_x(1:half,:);
s=abs(fft_x);


