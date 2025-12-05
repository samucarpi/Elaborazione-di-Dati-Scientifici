function display(obj)
%EVRIADDON/DISPLAY Display EVRIAddOn object products and entry points.
% Displays an evriaddon object products and connection entry points.

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

disp('EVRI Slider Object:');
disp(['      version: ' num2str(obj.esliderversion)]);
disp([' ']);
disp(['       parent: ' num2str(obj.parent)]);
disp(['         axis: ' num2str(double(obj.axis))]);
disp(['        patch: ' num2str(double(obj.patch))]);
disp([' ']);
disp(['     position: ' num2str(obj.position)]);
disp(['  callbackfcn: ' obj.callbackfcn]);
disp(['     vislible: ' obj.visible]);
%disp(['       enable: ' obj.enable]);
%disp(['          tag: ' obj.tag]);
disp([' ']);
disp(['        range: ' num2str(obj.range)]);
disp(['    page_size: ' num2str(obj.page_size)]);
disp(['        value: ' num2str(obj.value)]);
disp(['    selection: ' num2str(obj.selection)]);



 
