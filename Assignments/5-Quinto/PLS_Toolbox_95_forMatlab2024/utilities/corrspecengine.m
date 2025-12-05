function matrix=corrspecengine(data_x,data_y,purvar_index,offset,matrix_options)
%CORRSPECENGINE This function is the primary calculational engine for the function corrspec.
%
%INPUTS:
%         data_x: x-matrix for dispersion matrix
%         data_y: y-matrix for dispersion matrix
%   purvar_index: indices of maximum value in purity_values,
%                 i.e. the index of the pure variable. First column for
%                 x data, second column for y data
%                 empty when no pure variables have been chosen yet
%                 When base_x is a single number n the program calculates the
%                 first n pure purity_indices
%         offset: noise correction factor. One element defines offset for
%                 both x and y, two elements separately for x and y.
% matrix_options: (optional) if not given, only weight matrix
%                 will be calculated, otherwise it contains the options for 2
%                 of the output matrices: dispersion matrix and max_matrix, 2
%                 elements:
%                 1: synchronous correlation
%                 2: asynchronous correlation
%                 3: synchronous covariance
%                 4: asynchronous covariance
%                 5: purity about origin
%                 6: purity about mean
%
%OUTPUTS:
%        matrix: cell array with either one or three matrices, with size
%                [ncols_y ncols_x] (ncols_y represents number of spectra in
%                y, etc.).
%               matrix{1}: weight_matrix, matrix used to correct for
%                          previously selected pure variables.
%               matrix{2}: dispersion_matrix, matrix of interest,
%                          generally correlation matrix, corrected for
%                          previously selected pure variables.
%               matrix{3}: max_matrix, matrix from which pure variables
%                          are chosen, generally a co-purity matrix 
%                          corrected for previously selected pure variables.
%
%I/O: matrix=corrspecengine(data_x,data_y,purvar_index,offset,matrix_options)
%
%See also: CORRSPEC, DISPMAT, PLOT_CORR, RESOLVE_SPECTRA_2D_COR

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%ww  09/28/06


if nargin == 0; data = 'io'; end
if ischar(data_x);
  options=[];
  if nargout==0;
    evriio(mfilename,data_x,options);
  else
    purvar_index = evriio(mfilename,data_x,options);
  end
  return
end

%INITIALIZATIONS

[nrows_x,ncols_x]=size(data_x);
[nrows_y,ncols_y]=size(data_y);
if size(offset(:))==1;offset(2)=offset(1);end;

%matrix=zeros(ncols_y,ncols_x,dim_matrix);
matrix{1}=zeros(ncols_y,ncols_x);
matrix{2}=matrix{1};
matrix{3}=matrix{1};


if length(purvar_index)==0;
  purvarindex_x=[];
  purvarindex_y=[];
else;
  purvarindex_x=purvar_index(:,1);
  purvarindex_y=purvar_index(:,2);
end;

%CALCULATE MATRIX
%%%%%copts.offsetx    = 3;
%%%%%copts.offsety    = 3;
%%%%%copts.dispersion = 1;
copts.offsetx    = offset(1);
copts.offsety    = offset(2);
copts.dispersion = matrix_options(1);


%dispersion
matrix{2}=dispmat(data_x,data_y,copts);
%max
copts.dispersion = matrix_options(2);
matrix{3}=dispmat(data_x,data_y,copts);
%weight
%%%%%%mx=mean(data_x);max_mx=max(mx);fx=mx./(mx+(offset(1)/100)*max_mx);
%%%%%%my=mean(data_y);max_my=max(my);fy=my./(my+(offset(2)/100)*max_my);
%matrix{1}=getweight(data_y'*data_x,purvarindex_x,purvarindex_y);
matrix{1}=corrspecutilities('getweight2',data_x,data_y,purvarindex_x,purvarindex_y,...
  offset(1),offset(2));
%matrix{1}=weight;


%matrix(:,:,1)=matrix(:,:,1).*(fy'*fx).^1;

matrix{2}=matrix{1}.*matrix{2};
matrix{3}=matrix{1}.*matrix{3};


