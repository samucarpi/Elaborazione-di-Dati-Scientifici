function out = pdf2text(file_path)
%PDF2TEXT Read PDF document into a string array.
%
%I/O: out = pdf2text(file_path)
%
%See also: EXTRACT, EXTRACTBETWEEN, EXTRACTBEFORE, EXTRACTAFTER

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Uses Apache PDFBOX java package
%    https://javadoc.io/doc/org.apache.pdfbox/pdfbox/2.0.30/index.html

jfile = java.io.File(file_path);
doc = org.apache.pdfbox.pdmodel.PDDocument.load(jfile);
textReader = org.apache.pdfbox.text.PDFTextStripper;
out = string(textReader.getText(doc));
doc.close;
