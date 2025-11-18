%% CARICAMENTO DATI E INIZIALIZZAZIONE
clear; close all; clc;
load('dataset.mat');
X = farineanimNIRdata; % valori numerici
wl = assexscale; % asse x (lunghezze d'onda)
[y, classNames] = grp2idx(category); % converte le categorie testuali in numeri
colors = [0 0.447 0.741; 0.850 0.325 0.098; 0.929 0.694 0.125]; % colori

%% RAW DATA
X_mc = X-mean(X); % mean centering

% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(X_mc,'NumComponents',npc);

% grafico spettri
figure('Name', 'Spettri senza preprocessing', 'Position', [50, 500, 1000, 400]);
subplot(1,2,1); hold on; % 2 colonne 1 riga (1° colonna)
for c = 1:max(y)
    plot(wl, X(y==c, :), 'Color', colors(c,:));
end
% griglia e assi
xlabel('Numero di onda');
ylabel('Intensità');
title('Spettri senza preprocessing'); 
axis tight; % elimina bordi vuoti

% grafico PCA
subplot(1,2,2); % 2 colonne 1 riga (2° colonna)
gscatter(scores(:,1), scores(:,2), y, colors);
% griglia e assi
xline(0);
yline(0);
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
legend(classNames);
title('PCA SCORES');


%% BASELINE CORRECTION (Detrend)
X_detrend = detrend(X')'; % detrend 
X_mc = X_detrend - mean(X_detrend); % mean centering

% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(X_mc,'NumComponents',npc);

% grafico spettri
figure('Name', 'Detrend', 'Position', [50, 500, 1000, 400]);
subplot(1,2,1); hold on; % 2 colonne 1 riga (1° colonna)
for c = 1:max(y)
    plot(wl, X_detrend(y==c, :), 'Color', colors(c,:));
end
% griglia e assi
xlabel('Numero di onda');
ylabel('Intensità');
title('Preprocessing: Detrend'); 
axis tight; % elimina bordi vuoti

% grafico PCA
subplot(1,2,2); % 2 colonne 1 riga (2° colonna)
gscatter(scores(:,1), scores(:,2), y, colors);
% griglia e assi
xline(0);
yline(0);
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
legend(classNames);
title('PCA SCORES');


%% NORMALIZZAZIONE (Norm)
% normalizzazione (x_new = x / ||x||)
mynorm = sqrt(sum(X.^2, 2)); % norma euclidea di ogni riga
X_norm = X ./ mynorm;
X_mc = X_norm - mean(X_norm); % mean centering

% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(X_mc,'NumComponents',npc);

% grafico spettri
figure('Name', 'Normalizzazione (norm)', 'Position', [50, 500, 1000, 400]);
subplot(1,2,1); hold on; % 2 colonne 1 riga (1° colonna)
for c = 1:max(y)
    plot(wl, X_norm(y==c, :), 'Color', colors(c,:));
end
% griglia e assi
xlabel('Numero di onda');
ylabel('Intensità');
title('Preprocessing: Normalizzazione (norm)');
axis tight; % elimina bordi vuoti

% grafico PCA
subplot(1,2,2); % 2 colonne 1 riga (2° colonna)
gscatter(scores(:,1), scores(:,2), y, colors);
% griglia e assi
xline(0);
yline(0);
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
legend(classNames);
title('PCA SCORES');


%% SNV (Standard Normal Variate)
% normalizzazione (x - media)/deviazione_std
mean_spec = mean(X, 2);
std_spec = std(X, 0, 2);
X_snv = (X - mean_spec) ./ std_spec;
X_mc = X_snv - mean(X_snv); % mean centering

% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(X_mc,'NumComponents',npc);

% grafico spettri
figure('Name', 'Normalizzazione (SNV)', 'Position', [50, 500, 1000, 400]);
subplot(1,2,1); hold on; % 2 colonne 1 riga (1° colonna)
for c = 1:max(y)
    plot(wl, X_snv(y==c, :), 'Color', colors(c,:));
end
% griglia e assi
xlabel('Numero di onda');
ylabel('Intensità');
title('Preprocessing: Normalizzazione (SNV)');
axis tight; % elimina bordi vuoti

% grafico PCA
subplot(1,2,2); % 2 colonne 1 riga (2° colonna)
gscatter(scores(:,1), scores(:,2), y, colors);
% griglia e assi
xline(0);
yline(0);
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
legend(classNames);
title('PCA SCORES');


%% MSC (Multiplicative Scatter Correction)
% normalizzazione rispetto allo spettro medio globale
X_mean = mean(X, 1)'; % x_ref
[n, m] = size(X);
X_msc = zeros(n, m);
for i = 1:n
    % fit lineare: x_i = a+b*x_ref
    % dove: a=pendenza, b=intercetta
    poly = polyfit(X_mean, X(i,:)', 1); % polyfit restituisce [pendenza, intercetta]
    a = poly(2); % intercetta
    b = poly(1); % pendenza
    % correzione: x_i = (x_i-a)/b
    X_msc(i,:) = (X(i,:)-a)/b;
end
X_mc = X_msc - mean(X_msc); % mean centering

% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(X_mc,'NumComponents',npc);

% grafico spettri
figure('Name', 'Normalizzazione (MSC)', 'Position', [50, 500, 1000, 400]);
subplot(1,2,1); hold on; % 2 colonne 1 riga (1° colonna)
for c = 1:max(y)
    plot(wl, X_msc(y==c, :), 'Color', colors(c,:));
end
% griglia e assi
xlabel('Numero di onda');
ylabel('Intensità');
title('Preprocessing: Normalizzazione (MSC)');
axis tight; % elimina bordi vuoti

% grafico PCA
subplot(1,2,2); % 2 colonne 1 riga (2° colonna)
gscatter(scores(:,1), scores(:,2), y, colors);
% griglia e assi
xline(0);
yline(0);
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
legend(classNames);
title('PCA SCORES');


%% DERIVATA PRIMA CON SMOOTHING
X_der1 = sgolayfilt(X', 2, 15, [], 1)'; % (finestra=15 con polinomio=2)
X_mc = X_der1 - mean(X_der1); % mean centering

% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(X_mc,'NumComponents',npc);

% grafico spettri
figure('Name', 'Derivata 1', 'Position', [50, 500, 1000, 400]);
subplot(1,2,1); hold on; % 2 colonne 1 riga (1° colonna)
for c = 1:max(y)
    plot(wl, X_der1(y==c, :), 'Color', colors(c,:));
end
% griglia e assi
xlabel('Numero di onda');
ylabel('Intensità');
title('Preprocessing: Derivata 1');
axis tight; % elimina bordi vuoti
title('Preprocessing: Derivata 1');

% grafico PCA
subplot(1,2,2); % 2 colonne 1 riga (2° colonna)
gscatter(scores(:,1), scores(:,2), y, colors);
% griglia e assi
xline(0);
yline(0);
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
legend(classNames);
title('PCA SCORES');


%% DERIVATA SECONDA CON SMOOTHING
X_der2 = sgolayfilt(X', 2, 15, [], 2)';  % (finestra=15 con polinomio=2)
X_mc = X_der2 - mean(X_der2); % mean centering

% PCA
npc = 2;
[loading, scores, eigenvalues, T2, varexpl] = pca(X_mc,'NumComponents',npc);

% grafico spettri
figure('Name', 'Derivata 2', 'Position', [50, 500, 1000, 400]);
subplot(1,2,1); hold on; % 2 colonne 1 riga (1° colonna)
for c = 1:max(y)
    plot(wl, X_der2(y==c, :), 'Color', colors(c,:));
end
% griglia e assi
xlabel('Numero di onda');
ylabel('Intensità');
title('Preprocessing: Derivata 2');
axis tight; % elimina bordi vuoti

% grafico PCA
subplot(1,2,2); % 2 colonne 1 riga (2° colonna)
gscatter(scores(:,1), scores(:,2), y, colors);
% griglia e assi
xline(0);
yline(0);
xlabel(['PC1 (' num2str(varexpl(1),'%.1f') '%)']);
ylabel(['PC2 (' num2str(varexpl(2),'%.1f') '%)']);
legend(classNames);
title('PCA SCORES');