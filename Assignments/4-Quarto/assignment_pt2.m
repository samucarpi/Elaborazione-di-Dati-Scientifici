%% CONFRONTO METODI DI CLUSTERING - OLIVE OIL (Senza Silhouette)
% Include: DBSCAN, OPTICS e il Confronto Finale (Gerarchico vs K-Means)
clear; close all; clc;
load ('dataset.mat')
data = normalize(olivdata);
true_labels = category; 
RegionNames = {'N.Apulia', 'Calabria', 'S.Apulia', 'Sicily', 'In.Sardinia', 'Co.Sardinia', 'E.Liguria', 'W.Liguria', 'Umbria'};

% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(data,'NumComponents',npc);

%% Confronto gerarchico, k-means, dati non clusterizzati
figure('Position', [50, 50, 1500, 900]);

% gerarchico (Ward, Euclidian)
subplot(2, 4, [1 2]);
linkageMethod = 'ward';
distanceMethod = 'euclidean';
Z = linkage(data, linkageMethod, distanceMethod);
cutoff = 25;
T_clusters = cluster(Z, 'Cutoff', cutoff, 'Criterion', 'distance');
gscatter(scores(:,1), scores(:,2), T_clusters);
% griglia e assi
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
title(['Gerarchico (Ward, Euclidian, Cutoff ' num2str(cutoff) ')']);
grid on;
% legenda
lgd1 = legend('Location', 'bestoutside'); 
title(lgd1, 'Cluster ID'); 

% k-means
subplot(2, 4, [3 4]);
k_num = 4;
[T_means, ~] = kmeans(data, k_num, 'Replicates', 10, 'Display', 'off'); % calcolo k-means
gscatter(scores(:,1), scores(:,2), T_means);
% griglia e assi
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
title(['K-Means (k=' num2str(k_num) ')']);
grid on;
% legenda
lgd2 = legend('Location', 'bestoutside'); 
title(lgd2, 'Cluster ID'); 

% dati non clusterizzati
subplot(2, 4, [6 7]); 
gscatter(scores(:,1), scores(:,2), true_labels);
% griglia e assi
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
title('Dati non clusterizzati');
grid on;
% legenda
lgd3 = legend(RegionNames, 'Location', 'bestoutside'); 
title(lgd3, 'Regioni');

%% DBSCAN (Density-Based Clustering)
minpts = 10; % minpts >= n_variabili + 1 (densità)

% grafico k-distance per calcolare epsilon
figure;
kD = pdist2(data, data, 'euc', 'Smallest', minpts);
plot(sort(kD(end,:)));
title(['Grafico k-Distance (minpts=' num2str(minpts) ')']);
ylabel('Distanza k-esimo vicino'); 
xlabel('Punti ordinati');
yline(1.1, '-', 'Epsilon suggerito','Color', '#990000');
grid on;

% grafico dbscan
figure;
epsilon = 1.1; 
T_dbscan = dbscan(data, epsilon, minpts);
gscatter(scores(:,1), scores(:,2), T_dbscan);
% griglia e assi
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
title(['DBSCAN (eps=' num2str(epsilon) ', minpts=' num2str(minpts) ')']);
grid on;
% legenda
lgd_db = legend('Location', 'bestoutside'); 
title(lgd_db, 'Cluster (-1=Noise)');


%% OPTICS
try
    k_optics = 10; % k_optics >= n_variabili + 1 (densità)
    [RD, CD, order] = optics(data, k_optics); % RD: distanze (asse Y), order: l'ordine dei campioni (asse X)
    % preprocess
    plot_RD = RD(order); 
    plot_RD(plot_RD > 100) = 0; % tronca il primo punto infinito
    sorted_labels = true_labels(order); % etichette nell'ordine del grafico

    % grafico OPTICS
    figure;
    hold on;
    % colori
    n_regions = 9;
    colors_map = jet(n_regions); % n colori distinti
    % inserimento delle barre per regione
    for i = 1:n_regions
        region_index = (sorted_labels == i); % posizione campione nella regione i
        x = find(region_index); % indici (posizioni)
        y = plot_RD(region_index); % altezze (distanza)
        bar(x, y, 'FaceColor', colors_map(i,:), 'EdgeColor', 'none', 'BarWidth', 1, 'DisplayName', RegionNames{i});
    end
    
    % griglia e assi
    ylabel('Distanza'); 
    xlabel('Ordine Campioni'); 
    title('OPTICS');
    grid on;
    axis tight;
    
    % legenda
    lgd = legend('Location', 'bestoutside');
    title(lgd, 'Regioni');
    hold off;
catch ME
    warning('Errore OPTICS.');
    disp(ME.message);
end