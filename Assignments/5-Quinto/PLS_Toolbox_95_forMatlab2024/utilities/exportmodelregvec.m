function exportmodelregvec(modl)
%EXPORTMODELREGVEC Export model as regression vector (using regcon).
%  Only works with PLS, PCR and MLR models. Outputs to mat, csv, or xml file.
%
%I/O: exportmodelregvec(model)
%
%See Also: REGCON, SAVEMODELAS

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin < 1 | isempty(modl)
  error('No model present.')
end

if ~ismember(lower(modl.modeltype),{'pls','pcr','mlr'})
  error('EXPORTMODELREGVEC will only work with PLS, PCR, and MLR model types.')
end

%Default list.
mylist = {
  'CSV/Excel (*.csv)'           'save'        '.csv';
  'MAT File (*.mat)'            'save'        '.mat';
  'Extensible Markup (*.xml)'   'encodexml'   '.xml'
  };

%Create filter spec.
fspec = '';
for i = 1:size(mylist,1)
  fspec = [fspec; {['*' mylist{i,3}]} mylist(i,1)];
end

%Get file info.
defaultname = lower([modl.modeltype 'regcon' datestr(modl.time,30)]);
[FileName,PathName,FilterIndex] = evriuiputfile(fspec,'Save Model As',defaultname);

if ~FileName
  %User cancel.
  return
end

%Check for file extension (user may have manually added it), add if not there.
if isempty(strfind(FileName,mylist{FilterIndex,3}))
  FileName = fullfile(PathName,[FileName mylist{FilterIndex,3}]);
else
  FileName = fullfile(PathName,FileName);
end

%Get regression vector.
[out.regression_coefficients out.intercept] = regcon(modl);

%Write file
switch mylist{FilterIndex,3}
  case '.mat'
    save(FileName,'out');
  case '.xml'
    encodexml(out,defaultname,FileName);
  case '.csv'
    fid = fopen(FileName,'w');
    commas = ones(1,size(out.intercept,2))*',';
    
    %First row = Intercept label.
    fprintf(fid,['Intercept:' commas '\n']);
    
    %Second row = scalar or vector of intercept.
    fprintf(fid,'%g,',out.intercept);
    fprintf(fid,'\n');
    
    %Third row = empty.
    fprintf(fid,[commas '\n']);
    
    %Fourth row = Coefficient label.
    fprintf(fid,['Regression Coefficients:' commas '\n']);

    %Fifth row and beyond = coeff matrix.
    x = out.regression_coefficients';
    for j=1:size(x,1)
      fprintf(fid,'%g,',x(j,:));
      fprintf(fid,'\n');
    end
    
    fclose(fid);
end
