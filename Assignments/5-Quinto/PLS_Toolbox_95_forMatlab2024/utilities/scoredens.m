function scoreimg = scoredens(pc1,pc2,h1)
%SCOREDENS Unsupported utility.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

map = jet(256);
map(1,:) = [1 1 1];
colormap(map);
%h0 = figure; 
%h1 = axes; 
subplot(h1);
pc1 = double(pc1(:)) + 1;
pc2 = double(pc2(:)) + 1;
%[m,n] = size(pc1);
scoreimg = zeros(256,256);
for i = 1:length(pc1)
  scoreimg(pc1(i),pc2(i)) = scoreimg(pc1(i),pc2(i)) + 1;
end
imagesc(log10(scoreimg+1)'), colormap(map)
set(h1,'yticklabel',[])
set(h1,'xticklabel',[])
