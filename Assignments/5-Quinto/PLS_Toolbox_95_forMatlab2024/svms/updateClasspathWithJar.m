function updateClasspathWithJar(jarname)
%UPDATECLASSPATHWITHJAR adds jar to javaclasspath. jarname='name.jar', no path prepended.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if checkmlversion('<','7')
  %Matlab 6.5 compatibility
  error(['To use Java classes from ' jarname ' with Matlab 6.5 (R13) you need to add the ' jarname ' file manually to the java class path. Use "edit classpath.txt".'])
else
  %other versions
  %Add jar to javaclasspath.
  jpth = javaclasspath('-all');
  jpth = [jpth{:}];
  if isempty(strfind(jpth, jarname))
    %automatic java path add for ML 7 +.
    fn = which(jarname);
    if exist(fn)>0
      javaaddpath(which(jarname));
    else
      error(['Jar file ' jarname ' was not found on the matlab path']);
    end
  end
end
