%% CONFRONTO METODI DI CLUSTERING - OLIVE OIL
% Include: Confronto (Gerarchico vs K-Means vs Realtà), DBSCAN, OPTICS
clear; close all; clc;

% 1. CARICAMENTO E PREPROCESSING
% ---------------------------------------------------------
load dataset.mat

% Standardizzazione (Z-score) fondamentale per metodi basati su distanza
data = zscore(olivdata); 
true_labels = category; % Le categorie vere (1-9) per confronto

% Nomi regioni per le legende
RegionNames = {'1.N.Apulia', '2.Calabria', '3.S.Apulia', '4.Sicily', ...
               '5.In.Sardinia', '6.Co.Sardinia', '7.E.Liguria', ...
               '8.W.Liguria', '9.Umbria'};

% Calcolo PCA preliminare (serve per visualizzare i grafici 2D)
[coeff, scores, latent] = pca(data);
var_expl = 100 * latent / sum(latent); 
xlabel_str = ['PC1 (' num2str(var_expl(1), '%.1f') '%)'];
ylabel_str = ['PC2 (' num2str(var_expl(2), '%.1f') '%)'];


%% ---------------------------------------------------------
% 2. CONFRONTO DIRETTO: GERARCHICO vs K-MEANS vs REALTÀ
% ---------------------------------------------------------
disp('--- Calcolo Cluster per Confronto ---');

% A. Metodo Gerarchico (Ward)
% ---------------------------
Z = linkage(data, 'ward', 'euclidean');
cutoff_val = 25; % Cutoff che separa le macro-aree
idx_ward = cluster(Z, 'Cutoff', cutoff_val, 'Criterion', 'distance');
k_num = max(idx_ward); % Otteniamo il numero di cluster (dovrebbe essere 4)

% B. Metodo K-Means
% ---------------------------
% Usiamo lo stesso k del gerarchico per un confronto coerente
[idx_kmeans, C] = kmeans(data, k_num, 'Replicates', 10, 'Display', 'off');

% --- PLOT DI CONFRONTO (La parte richiesta) ---
figure('Name', 'Confronto Metodi di Clustering', 'Color', 'w', 'Position', [50, 100, 1600, 500]);

% Plot 1: Gerarchico
subplot(1, 3, 1);
gscatter(scores(:,1), scores(:,2), idx_ward);
title(['1) Gerarchico (Ward, Cutoff ' num2str(cutoff_val) ')']);
xlabel(xlabel_str); ylabel(ylabel_str); grid on; 
lgd1 = legend('Location', 'best'); title(lgd1, 'Cluster ID');

% Plot 2: K-Means
subplot(1, 3, 2);
gscatter(scores(:,1), scores(:,2), idx_kmeans);
title(['2) K-Means (k=' num2str(k_num) ')']);
xlabel(xlabel_str); ylabel(ylabel_str); grid on; 
lgd2 = legend('Location', 'best'); title(lgd2, 'Cluster ID');

% Plot 3: Realtà (Ground Truth)
subplot(1, 3, 3);
gscatter(scores(:,1), scores(:,2), true_labels); 
title('3) Realtà (Ground Truth - 9 Regioni)');
xlabel(xlabel_str); ylabel(ylabel_str); grid on; 
lgd3 = legend(RegionNames, 'Location', 'bestoutside'); title(lgd3, 'Regioni');


%% ---------------------------------------------------------
% 3. DBSCAN (Density-Based Clustering)
% ---------------------------------------------------------
disp('--- Esecuzione DBSCAN ---');

% Parametri
minpts = 10; 

% Grafico k-distance per scelta epsilon
figure('Name', 'DBSCAN Parameter Selection', 'Color', 'w');
kD = pdist2(data, data, 'euc', 'Smallest', minpts);
plot(sort(kD(end,:)));
title(['k-Distance Graph (minpts=' num2str(minpts) ')']);
ylabel('Distanza k-esimo vicino'); xlabel('Punti ordinati');
grid on; yline(2.5, 'r--', 'Epsilon suggerito'); 

% Esecuzione
epsilon = 2.5; 
idx_dbscan = dbscan(data, epsilon, minpts);

% Plot Risultati
figure('Name', 'Risultati DBSCAN', 'Color', 'w');
gscatter(scores(:,1), scores(:,2), idx_dbscan);
title(['DBSCAN (eps=' num2str(epsilon) ', minpts=' num2str(minpts) ')']);
xlabel(xlabel_str); ylabel(ylabel_str); grid on;
lgd_db = legend('Location', 'bestoutside'); title(lgd_db, 'Cluster (-1 = Noise)');


%% ---------------------------------------------------------
% 4. OPTICS (Richiede file optics.m)
% ---------------------------------------------------------
disp('--- Esecuzione OPTICS ---');

try
    k_optics = 15; 
    [RD, CD, order] = optics(data, k_optics);
    
    % Plot Reachability
    figure('Name', 'OPTICS Reachability Plot', 'Color', 'w');
    colors_map = jet(9); % Colori per le 9 regioni
    
    hold on;
    for i = 1:length(order)
        obj_index = order(i);
        true_class = true_labels(obj_index); 
        val = RD(obj_index);
        if val > 100, val = 0; end 
        bar(i, val, 'FaceColor', colors_map(true_class, :), 'EdgeColor', 'none');
    end
    hold off;
    
    title('OPTICS Reachability Plot (Colorato per Regioni Vere)');
    ylabel('Reachability Distance'); xlabel('Ordering of Objects'); grid on;
    
    % Legenda finta per i colori
    hold on;
    for i=1:9
        plot(nan, nan, 's', 'MarkerFaceColor', colors_map(i,:), 'MarkerEdgeColor', 'none', 'DisplayName', ['Regione ' num2str(i)]);
    end
    legend('Location', 'bestoutside');
    disp('OPTICS completato.');

catch ME
    warning('Impossibile eseguire OPTICS.');
    disp('Assicurati che il file "optics.m" sia nella cartella corrente.');
end