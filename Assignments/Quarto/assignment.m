%% CARICAMENTO DATI E INIZIALIZZAZIONE
clear; close all; clc;
load ('dataset.mat')
data = normalize(olivdata);
varNames = string(oliv_var_name);

%% SAMPLES DENDROGRAM
linkageMethod = 'ward';
distanceMethod = 'euclidean';
Z = linkage(data, linkageMethod, distanceMethod);
cutoff = 25;

figure;
% [H, T, outperm] -> outperm contiene l'ordine dei campioni nel dendrogramma
[H, T_dendro, outperm_samples] = dendrogram(Z, 0, 'ColorThreshold', cutoff);
yline(cutoff, '-', ['Threshold: ' num2str(cutoff)], 'LineWidth', 1.5,'Color', '#990000');

% griglia e assi
ylabel('Distanza');
xlabel('Campioni');
title(['Samples Dendrogram (' linkageMethod '/' distanceMethod ')']);

%% SCORES PCA
% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(data,'NumComponents',npc);

% grafico scores PCA
figure;
T_clusters = cluster(Z, 'Cutoff', cutoff, 'Criterion', 'distance'); % calcolo dei cluster con cutoff scelto
gscatter(scores(:,1), scores(:,2), T_clusters);

% griglia e assi
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
title(['PCA Scores - Threshold: ' num2str(cutoff)]);
grid on;

%% IMAGESC CON CAMPIONI E VARIABILI ORDINATE
data_vars = data'; 

% riordinamento in base al dendogramma
% variabili
Z_vars = linkage(data_vars, 'average', 'correlation');
fig_hidden = figure('Visible', 'off'); 
[~, ~, order_vars] = dendrogram(Z_vars, 0);
close(fig_hidden);
% campioni
data_plot = data(outperm_samples, order_vars)'; 
[n_vars, n_samps] = size(data_plot);

% definizione delle posizioni per inserire i diversi elementi
gap = 0.005; 
main_pos = [0.20, 0.15, 0.65, 0.65]; 
top_pos  = [0.20, (0.15 + 0.65 + gap), 0.65, 0.12]; 
left_pos = [0.05, 0.15, (0.15 - gap), 0.65]; 
cbar_pos = [0.20, 0.06, 0.65, 0.03];

% grafico imagesc
figure('Color', 'w', 'Toolbar', 'none');
ax_main = axes('Position', main_pos);
imagesc(data_plot);
colormap('jet');
% modifica assi
axis tight;
set(gca, 'YDir', 'reverse');
set(ax_main, 'LineWidth', 1.2); 
% asse y -> variabili
set(ax_main, 'YAxisLocation', 'right');
set(ax_main, 'YTick', 1:n_vars);
set(ax_main, 'YTickLabel', varNames(order_vars));
% asse x
set(ax_main, 'YTickLabelRotation', 0);
set(ax_main, 'XTick', []); 
xlabel('Campioni');

% dendogramma superiore (campioni)
axes('Position', top_pos);
[H_s, ~] = dendrogram(Z, 0, 'ColorThreshold', cutoff); 
axis off;
set(gca, 'XLim', [0.5, n_samps + 0.5]);

% dendogramma sinistro (variabili)
axes('Position', left_pos);
[H_v, ~] = dendrogram(Z_vars, 0, 'Orientation', 'left', 'ColorThreshold', 0.7);
axis off; 
set(gca, 'YLim', [0.5, n_vars + 0.5]); 
set(gca, 'XDir', 'reverse'); 
set(gca, 'YDir', 'reverse'); 

% colorbar
c = colorbar('Position', cbar_pos, 'Orientation', 'horizontal');