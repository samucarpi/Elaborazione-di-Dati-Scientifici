echo on
%PDF2TEXTDEMO Demo of the PDF2TEXT function
 
echo off
%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% DF2TEXT Read PDF document into a string array. Read in
% PLS_Toolbox_Quick_Reference.pdf into a text string.
 
manualtext = pdf2text('PLS_Toolbox_Quick_Reference.pdf');
manualtext = pdf2text('PLS_Manual.pdf');

pause
%-------------------------------------------------
% Now prepare the text for the wordcloud

punctuationCharacters = ["." "?" "!" "," ";" ":"];
manualtext = replace(manualtext,punctuationCharacters," ");
words = split(join(manualtext));
words(strlength(words)<5) = [];
words = lower(words);
words(1:10)

pause
%-------------------------------------------------
% Find the unique words in the document and count their frequency.

[numOccurrences,uniqueWords] = histcounts(categorical(words));

pause
%-------------------------------------------------
% Create the wordcloud

fig = figure;
wc = wordcloud(fig,uniqueWords,numOccurrences);
title(wc,"PLS\_Toolbox Manual Wordcloud")

pause
%-------------------------------------------------
% Let's narrow down the text to the Bibliography

bibidx = strfind(manualtext,"17  Bibliography");
bibtext = extractAfter(manualtext,bibidx(2));
bibwords = split(join(bibtext));
bibwords(strlength(bibwords)<5) = [];
bibwords = lower(bibwords);
[numOccurrences,uniqueWords] = histcounts(categorical(bibwords));
bibfig = figure;
wc = wordcloud(bibfig,uniqueWords,numOccurrences);
title(wc,"PLS\_Toolbox Manual Bibliography Wordcloud")
 
%End of PDF2TEXTDEMO
 
echo off