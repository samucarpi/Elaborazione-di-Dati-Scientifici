function newmodel = copymodel(oldmodel)
%COPYMODEL Copy a model object.
% When copying a model a new .uniqueid field is needed so the .time field
% is changed to alter the uniqueid. Also copy "parent" .uniqueid to
% .copyparentid field of "child" model.
%
%
%I/O: newmodel = copy(oldmodel)

%Copyright (c) Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

newmodel = oldmodel;
newmodel.time = clock;
newmodel.copyparentid = oldmodel.uniqueid;

end

function test

load plsdata
m1 = evrimodel('pls');

m1.x = xblock1;
m1.y = yblock1;
m1.ncomp = 3;
m1.options.preprocessing = {'autoscale' 'autoscale'};
m1 = m1.calibrate;

m2 = copymodel(m1);
disp('The following IDs should be different.')
m1.uniqueid
m2.uniqueid
all(m1.uniqueid==m2.uniqueid)%Should = 0

disp('The .copyparentid should be empty on M1.')
m1.copyparentid

disp('The .copyparentid on M2 should equal uniqueid of M1.')
m2.copyparentid


end
