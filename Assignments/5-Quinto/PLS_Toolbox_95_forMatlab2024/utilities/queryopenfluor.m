function of_model = queryopenfluor(data,model,filename)
%QUERYOPENFLUOR is a wrapper for PARAFACFOROPENFLUOR, that also opens the
% website for querying the openfluor.org database using the created .txt file.
%  
%  INPUTS:
%    data = a 3-way dataset object (dso) used in constructing the model.
%    model = an n component parafac model of data.
%    filename = filename and path to save the model for OpenFluor.org.
%
%  OUTPUT:
%    of_model = parafac model structure formatted for OpenFluor.org.
%
%I/O: of_model = parafacforopenfluor(data,model,'MyModel.txt');
%
%See also: PARAFAC DATASET ISDATASET OPENFLUOR PARAFACFOROPENFLUOR
%
%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

of_model = parafacforopenfluor(data,model,filename);

% Open the query page on http://www.OpenFluor.org.
ofurl='http://models.life.ku.dk:8083/database/query';
web(ofurl,'-browser');% use system '-browser' for compiled products?
% Important, mac does not have -browser option, need special preference

% TODO: upload file for query. <-may need more knowledge of site.
% on the page:
% html>body>div#root>div#content>div#main>div#model_input>form#querymodel>input

% TODO: run the query? Probably waiting for user to press the button would
% be better.
% html>body>div#root>div#content>div#main>div#model_input>form#querymodel>input#querybutton.button
% Look at webread() & webwrite() or websave()
% also see: http://www.mathworks.com/help/matlab/ref/weboptions.html

end
