%This script is an example of what you might include in a Matlab "startup"
%file to add PLS_Toolbox folders to your path. The 'setpath' function is in
%PLS_Toolbox so that folder should always be the first in your list of
%products.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Get the current folder.
mydir = pwd;

%List of parent folders to add to the path (sub folders will be added automatically). 
%  NOTE: PLS_Toolbox MUST be first on this list!
myproducts = {'C:\Program Files\MATLAB\R2006b\toolbox\PLS_Toolbox_401' 
             'C:\Program Files\MATLAB\R2006b\toolbox\MIA_Toolbox'};

%Add folders.
for i = myproducts'
 cd(i{:});
 setpath
end

%Go back to orginal folder.
cd(mydir);
