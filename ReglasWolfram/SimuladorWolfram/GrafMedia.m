% Cargar los datos desde el archivo .txt
data = load('C:\Users\Gael Hernández Solís\Desktop\PROYECTO\MEDIA.txt');

% Extraer las columnas de datos
generaciones = data(:, 1);
mediaUnos = data(:, 2);

% Crear una figura
figure;

% Graficar los datos con un diseño atractivo
plot(generaciones, mediaUnos, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 10);

% Ajustar el estilo de la cuadrícula
grid on;

% Etiquetas y título
xlabel('Generaciones');
ylabel('Media de unos');
title('Media de unos');

% Cambiar el estilo del gráfico
set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
set(gcf, 'Color', 'w');
legend('Media de unos', 'Location', 'Best');
