echo on
%BIN2SCALEDEMO Demo of the bin2scale function
 
echo off
%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% This is simple test scenarios for bin2scale.

%Test identical scales.
x1 = dataset([1:20]');
x1.axisscale{1} = now+[0:19]/24/60;
[x1b,x2b] = bin2scale(x1,x1);
x1b.data

%Test same scale with offset.
x1 = dataset([1:20]');
x1.axisscale{1} = now+[0:19]/24/60;
x2 = x1;
x2.axisscale{1} = x1.axisscale{1}+1/24/60;
%NOTE: x2.axisscale{1}(1) matches x1.axisscale{1}(2)!!!
[x1b,x2b] = bin2scale(x1,x2);
x1b.data

%Simple tests

hf = dataset([1 1 1 1 1 5 5 5 5 5]');%High frequency data.
hf.label{1} = str2cell(sprintf('Sample_%d\n',[1:10]));%Example sample labels, they are tracked in sample name in binned data.
ts = now+[0:19]/24/60;%20 time points.
hf.axisscale{1} = ts(5:14);%10 time points in middle.

lf = dataset([10 20 30]');%Low frequency data.

%LF time points completely inside of HF range.
lf.axisscale{1} = [ts(7) ts(10) ts(12)];
[a,b] = bin2scale(lf,hf);
a.data%Answer is [1 5]

%First LF starts before HF so drop first interval.
lf.axisscale{1} = [ts(1) ts(10) ts(12)];
[a,b] = bin2scale(lf,hf);
a.data%Answer is [5]

%Last LF outside of HF range so takes all available HF data.
lf.axisscale{1} = [ts(7) ts(10) ts(19)];
[a,b] = bin2scale(lf,hf);
a.data%Answer is [1 5]

%Only first LF is overlap with HF data.
lf.axisscale{1} = [ts(13) ts(17) ts(19)];
[a,b] = bin2scale(lf,hf);
a.data%Answer is [5]

%No overlap, return empty.
lf.axisscale{1} = [ts(17) ts(18) ts(19)];
[a,b] = bin2scale(lf,hf);
a %Answer is []

%No overlap, return empty.
lf.axisscale{1} = [ts(1) ts(2) ts(3)];
[a,b] = bin2scale(lf,hf);
a %Answer is []

lf.axisscale{1} = [ts(2) ts(5) ts(8)]

[a,b] = bin2scale(lf,hf);
a.data

%Test order of join. Should be 1 1 2 2 3 3 and A,B,C
a = dataset(rand(50,2));
%a.userdata = 'a userdata';
b = dataset(rand(90,2));
%b.userdata = 'b userdata';
c = a;
c.userdata = 'c userdata';
a.axisscale{1} = now+[0:49]/24/60;
b.axisscale{1} = now+linspace(0,49,90)/24/60;
c.axisscale{1} = now+linspace(4,53,50)/24/60;
a.name = 'A';
b.name = 'B';
c.name = 'C';
[mod,joined] = multiblock({a b c});
joined.class{2}
joined.name

%Test monotonic.
a = dataset(rand(100,1000));
a.axisscale{1} = linspace(0,200,100);
 
b = dataset(rand(3000,50));
b.axisscale{1} = linspace(0,200,3000);

%-------------------------------------------------
% 


%End of BIN2SCALEDEMO
 
echo off
