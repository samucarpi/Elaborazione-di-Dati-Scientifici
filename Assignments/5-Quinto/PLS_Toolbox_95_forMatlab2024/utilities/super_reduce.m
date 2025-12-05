function corr_values=super_reduce(data,level_corr);
%SUPER_REDUCE Eliminates highly correlated variables.
% When several variables have a high correlation, the variable(s) with the
% lower intensity will be deleted, leaving the most intense variable.
% Generally used in combination with CODA and COMPARLCMS applications.
% corr_values=super_reduce(data,level_corr);
% 
% INPUTS:
%   data: matrix to be analyzed or a dataset object. Only included rows and
%       columns will be analyzed
%   level_corr: (optional) sets the correlation level above which variables
%       will be eliminated. A plot will be made when level_corr is given.
%
% OUTPUT:
%   corr_val: correlation values used for elimination.
%
%I/O: corr_values=super_reduce(data,level_corr);
%I/O: super_reduce demo

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%EVRI INITIALIZATIONS

corr_values=[];
if nargin == 0; data = 'io'; end
if ischar(data);
    options=[];
    if nargout==0; 
        evriio(mfilename,data,options); 
    else;
        corr_values = evriio(mfilename,data,options); 
    end;
  return 
end;

%INITIALIZATONS

if isa(data,'dataset');
    incl=data.include;
    data=data.data(incl{:});    
end;

[nrows,ncols]=size(data );
max_values=max(data);
index_array=1:ncols;

%CALCULATE CORRELATION MATRIX

c=corrcoef(data);
c=c-eye(ncols);

%FIND MAX CORRELATION

thrownout=[];
for i=1:ncols;
	maxmaxc=max(c(:));
	[i,j]=find(c==maxmaxc);
	i=i(1);j=j(1);
	varindex=[i j];%variable index of vars with highest correlation
	[m,index]=sort(max_values(varindex));
	varindex=varindex(index(1));
	thrownout=[thrownout index_array(varindex)];
    corr_values(index_array(varindex))=maxmaxc;
	
	%UPDATE 
	
    max_values(varindex)=[];
	index_array(varindex)=[];
	c(varindex,:)=[];
	c(:,varindex)=[];
end;

q_index2=[1:ncols];
if nargin==3;return;end;

%PLOT

if nargin==2;
  figure
	subplot(211);plot(data);title(['original reduced data, ',num2str(ncols),' variables']);
	select2=q_index2(corr_values<level_corr);
	nvar2=length(select2);
	subplot(212);plot(data(:,select2));
	title(['super reduced data, ',num2str(nvar2),' variables']);
	shg;
end;

