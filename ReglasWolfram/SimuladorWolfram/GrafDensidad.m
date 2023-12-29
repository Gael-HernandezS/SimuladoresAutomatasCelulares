% Cargar los datos desde el archivo .txt
data = load('C:\Users\Gael Hernández Solís\Desktop\JV\densidad.txt');

% Encontrar el valor absoluto mínimo en los datos
min_value = min(data(:, 2));
min_value = abs(min_value) + 1;

% Crear una figura
figure;

% Graficar los datos originales en azul y luego aplicar el logaritmo en base 10 a la serie azul
semilogy(data(:, 1), data(:, 2), 'b.-', 'LineWidth', 1.5); % Gráfico de línea con escala logarítmica en el eje y (azul)
hold on;

% Graficar los datos con logaritmo base 10 en rojo
semilogy(data(:, 1), log10(data(:, 2) + min_value), 'r.-', 'LineWidth', 1.5); % Gráfico de línea con escala logarítmica en el eje y (rojo)

% Ajustar el estilo de la cuadrícula
grid on;

% Etiquetas y título
xlabel('Generaciones');
ylabel('Densidades');
title('Gráfico de Densidades (Azul: Original, Rojo: Log10)');

% Agregar una leyenda
legend('Original', 'Log10', 'Location', 'Best');
