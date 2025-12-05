function obj = evriaddon(varargin)
%EVRIADDON/EVRIADDON Create an Eigenvector Add-On object.
% EVRIADDON objects allows add-on products to indicate to PLS_Toolbox that
% they contain specific add-on funcitonality which is specifically queried
% by certain PLS_Toolbox functions.
%
% A product can add itself to PLS_Toolbox by simply creating an @evriaddon
% folder in its main folder. Within this folder, the application should
% create a single m-file named for the add-on product after a prefix of
% "addon_". For example: mia_toolbox -> addon_mia_toolbox.m
% This function should create an instance of an evriaddon_connection object
% (including an optional descriptive name of the add-on product) and then
% assign function handles to any of the entry points available within that
% connector. For example, within a folder named @evriaddon, the following
% function could be created:
%
%   function out = addon_mytoolbox(obj)
%   out = evriaddon_connection('My Toolbox');
%   out.importmethods = @myimport_methodlist;
%
% evriaddon_connection entry points can be assigned as single function
% handles or as a cell array of function handles.
%
% Entry points in PLS_Toolbox needing to retrieve the list of function
% handles requesting calls into it should call evriaddon with the single
% input of the entry point name:
%    list = evriaddon('importmethods');
% returns (list) as a cell array of function handles requesting calls.
%
%I/O: list = evriaddon(entrypoint)

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = struct('evriaddonversion','1.0');
obj = class(obj,'evriaddon');

if nargin>0;
  obj = subsref(obj,struct('type','.','subs',varargin{1}));
elseif nargout==0
  disp(obj);
  clear obj
end
