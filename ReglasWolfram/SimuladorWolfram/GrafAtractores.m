
data = dlmread('C:\Users\Gael Hernández Solís\Desktop\JV\77225x5.txt');

tamano_muestra = min(400000, size(data, 1)); 

indices_muestra = randperm(size(data, 1), tamano_muestra);
data_muestra = data(indices_muestra, :);

nodos_enteros = unique(data_muestra(:));
mapeo_nodos = containers.Map(nodos_enteros, 1:length(nodos_enteros));
data_muestra(:, 1) = cell2mat(values(mapeo_nodos, num2cell(data_muestra(:, 1))));
data_muestra(:, 2) = cell2mat(values(mapeo_nodos, num2cell(data_muestra(:, 2))));

G = graph(data_muestra(:, 1), data_muestra(:, 2));


h = plot(G, 'Layout', 'force', 'NodeLabel', {});

saveas(gcf, 'grafo_visualizacion.png');
