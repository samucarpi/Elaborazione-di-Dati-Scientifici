%% CARICAMENTO DATI E INIZIALIZZAZIONE
clear; close all; clc;
load('dataset.mat');
X = farineanimNIRdata; % valori numerici
wl = assexscale; % asse x (lunghezze d'onda)
[y, classNames] = grp2idx(category); % converte le categorie testuali in numeri
colors = [0 0.447 0.741; 0.850 0.325 0.098; 0.929 0.694 0.125]; % colori

%% APPLICAZIONE PREPROCESSING MIGLIORE
% applicazione "Derivata 2 con smoothing"
X_der2 = sgolayfilt(X', 2, 15, [], 2)';  % (finestra=15 con polinomio=2)
X_mc = X_der2 - mean(X_der2); % mean centering

%% GRAFICO PCA E LOADINGS
% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(X_mc,'NumComponents',npc);

% grafico PCA
figure('Name', 'Derivata 2', 'Position', [50, 500, 1000, 400]);
subplot(1, 2, 1); % 2 colonne 1 riga (2° colonna)
gscatter(scores(:,1), scores(:,2), y, colors);
% griglia e assi
xline(0);
yline(0);
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
legend(classNames);
title('PCA SCORES');
grid on; axis square;

% grafico Loadings (line plot con assexscale)
subplot(1, 2, 2);
plot(wl, loading(:,1), 'b-', 'LineWidth', 1.0); hold on; % loading PC1
plot(wl, loading(:,2), 'r-', 'LineWidth', 1.0); % loading PC2
yline(0);
% Acqua (O-H stretch + O-H def.) ~5159 cm^-1
xline(5159, 'b:', 'LineWidth', 1.5);
text(5159, max(loading(:,1)), '  Acqua', 'Color', 'b', 'Rotation', 90);
% Amido (O-H stretch + O-H def. ) ~4480 cm^-1
xline(4480, 'r:', 'LineWidth', 1.5);
text(4480, max(loading(:,2)), '  Amido', 'Color', 'r', 'Rotation', 90);
% Amido (2 O-H def. + C-O stretch ) ~4715 cm^-1
xline(4715, 'r:', 'LineWidth', 1.5);
text(4715, max(loading(:,2)), '  Amido', 'Color', 'r', 'Rotation', 90);
% Amido (2 O-H def. + C-O def. ) ~4970 cm^-1
xline(4970, 'r:', 'LineWidth', 1.5);
text(4970, max(loading(:,2)), '  Amido', 'Color', 'r', 'Rotation', 90);
% Cellulosa (C-H stretch + C-H deformazione) ~4300 cm^-1
xline(4300, 'r:', 'LineWidth', 1.5);
text(4300, max(loading(:,2)), '  Cellulosa', 'Color', 'r', 'Rotation', 90);
% Lipidi (C-H stretch 1° sovratono gruppi (CH2) ) ~5890 cm^-1
xline(5890, 'r:', 'LineWidth', 1.5);
text(5890, max(loading(:,2)), '  Lipidi', 'Color', 'r', 'Rotation', 90);
title('PCA LOADINGS SU ASSEXSCALE');
xlabel('Wavenumber (cm^{-1})');
ylabel('Peso (Loading)');
legend({'Loading PC1', 'Loading PC2'}, 'Location', 'southeast');
axis tight; 
grid on;