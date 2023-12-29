nombreArchivo = 'C:\Users\Gael Hernández Solís\Desktop\PROYECTO\VARIANZA.txt';  

fid = fopen(nombreArchivo, 'r');
if fid == -1
    error('No se pudo abrir el archivo.');
end

cadenas = {};
linea = fgetl(fid);
while ischar(linea)
    cadenas{end+1} = linea;
    linea = fgetl(fid);
end

fclose(fid);

generaciones = 1:length(cadenas); % Crear un vector de generaciones

for i = 1:length(cadenas)
    varianzas(i) = var(cadenas{i}); % Calcular la varianza
end

% Graficar las varianzas
figure;
plot(generaciones, varianzas, 'o-'); % Graficar con puntos y líneas
xlabel('Generación');
ylabel('Varianza');
title('Varianzas de las cadenas por generación');
grid on;

