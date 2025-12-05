function of_model = parafacforopenfluor(data,model,filename)
%PARAFACFOROPENFLUOR exports data/dso & parafac model as a .txt file
%  Exports a data/dso & parafac model as a .txt file for openfluor.org
%  It saves the data, axisscales (modes 2 & 3), & model loadings.
%  
%  INPUTS:
%    data = a 3-way dataset object (dso) used in constructing the model.
%    model = an n component parafac model of data.
%    filename = path and filename to save the model for OpenFluor.org.
%
%  OUTPUT:
%    of_model = parafac model structure formatted for OpenFluor.org.
%
%I/O: of_model = parafacforopenfluor(data,model,'MyModel.txt');
%
%See also: PARAFAC DATASET ISDATASET OPENFLUOR
%
%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% TODO: need to add openfluor.m is used with permission.

% TODO: MORE ROBUST INPUT ARGUMENT SCHEME have data, model, & filename as intermediate variables.
% Note: the %# comments signifies core code (there are ordered 1:5),
% everything else is safegaurds and error checking.

% Check openfluor.m is present.
if ~(exist('openfluor.m','file')==2)
  error('openfluor.m does not exist, download at http://www.openfluor.org');
end

% Check the model is a 3-way PARAFAC model (not PARAFAC2, TUCKER3, or otherwise)
if(strcmp(model.modeltype,'PARAFAC'))
  if (length(model.loads)==3)
    of_model.(['Model' num2str(model.ncomp)])=model.loads'; %4
  else
    error('Only 3-way data can be exported to OpenFluor.');
  end
else
  error('Only PARAFAC models can be exported to OpenFluor.');
end

% Check the dataset is 3-way & is consistent with the parafac model.
if (isdataset(data))
  if(~ndims(data.data==3))
    error('Only 3-way data can be exported to OpenFluor.');
  end
  consistent= true;
  subset=false; % assume ALL the data was included
  for i=1:ndims(data.data);
    mns=size(of_model.(['Model' num2str(model.ncomp)]){1,i},1);
    mds=size(data.data,i);
    if (mns ~= mds) % model X block must be a subset (<= data)
      if (mns > mds)
        consistent = false;
        break;
      else
        if (mns < mds) & (subset == false)
          subset=true;
        end
        if (mds ~= size(model.detail.axisscale{i,1},2)) %Check the axisscale
          consistent = false;
          break;
        end
      end
    end
  end

  if ~consistent % Check consistancy
    error('Dataset is inconsistant with the PARAFAC model.');
  end
  
  if ~subset % Check if subset
    of_model.X = data.data; %1
    of_model.Em = data.axisscale{2}'; %2
    of_model.Ex = data.axisscale{3}'; %3
  else % Use only included data
    of_model.X = data.data((model.detail.includ{1,1}),(model.detail.includ{2,1}),(model.detail.includ{3,1}));
    of_model.Em=data.axisscale{2}(model.detail.includ{2,1})';
    of_model.Ex=data.axisscale{3}(model.detail.includ{3,1})';
  end

  if (isempty(of_model.Em) || isempty(of_model.Ex))
    error('Both Axisscales are required for a succesful OpenFluor query');
  end
  
else
  % TODO: can axisscales be inputted using nvarargin{} & verified with size()?
  error('Data must be a dataset type variable.');
end

% Safegaurd: robust checking for file name & name extension.
% If there's no filename, use the default.
if(isempty(filename) || strcmp(filename(1),'.'))
  % Make open Fluor model name using parafac default name.
  defaultfilename = ['OpenFluorModel_',defaultmodelname(model),'.txt'];
  
  %Query user where to put file.
  [filename,PathName,MyIndex] = evriuiputfile({'*.txt' 'Text File (*.txt)'},'Save Model As',defaultfilename);
  if ~filename
    %User cancel.
    return
  end
  filename = fullfile(PathName,filename);
end

%Check for file extension (user may have manually added it), add if not there.
if isempty(strfind(filename,'.txt'))
  filename = [filename '.txt'];
end

% Save model as .txt file for OpenFluor.org
openfluor(of_model,model.ncomp,filename); % 5

% % Get file's location (for uploading).
% mydir = pwd;
% fileloc = [pwd,'\',filename];
% 
% % Open the query page on http://www.OpenFluor.org.
% ofurl='http://models.life.ku.dk:8083/database/query';
% [stat,h] = web(ofurl);% use system '-browser' for compiled products?
% % Important, mac does not have -browser option, need special preference
% 
% % TODO: upload file for query. <-may need more knowledge of site.
% % on the page:
% % html>body>div#root>div#content>div#main>div#model_input>form#querymodel>input
% 
% % TODO: run the query? Probably waiting for user to press the button would
% % be better.
% % html>body>div#root>div#content>div#main>div#model_input>form#querymodel>input#querybutton.button
% % Look at webread() & webwrite() or websave()
% % also see: http://www.mathworks.com/help/matlab/ref/weboptions.html
end
