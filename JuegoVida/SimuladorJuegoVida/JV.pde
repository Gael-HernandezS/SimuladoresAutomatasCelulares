import controlP5.*;
import java.io.*;

int cols, rows;
float[][] grid;
boolean simulationRunning = false;
int sMin, sMax, nMin, nMax;
String ruleInput = "R(2,3,3,3)";
ControlP5 cp5;

int cellsPerSideSliderValue = 100;
int cellSizeSliderValue = 5;
float probabilityDropdownValue = 0.9;
int generationCount = 0;
float simulationSpeed = 1.0;
int aliveCellColor = color(0); 
int deadCellColor = color(255);
PrintWriter output;
PrintWriter entropyOutput;

void setup() {
  fullScreen();
  cp5 = new ControlP5(this);
  output = createWriter("densidad.txt");
  entropyOutput = createWriter("entropia.txt");
  initializeGrid(cellsPerSideSliderValue, cellsPerSideSliderValue);
  
  // Interfaz 
  createInputFields();
  createSimulateButton();
  createReiniciarButton();
  createGridSizeSlider();
  createCellSizeSlider();
  createProbabilityDropdown();
  createColorPickers();
  createStatusLabel();
  createSpeedSlider();
  createGuardarButton();
  createCargarButton(); 
  createConfigButton();
}

void draw() {
  background(255);
  drawGrid();
  updateStatusLabels(); 
  
   if (simulationRunning && frameCount % int(60 / simulationSpeed) == 0) {
    updateGrid();
    generationCount++;
    
    float density = calculateDensity();
    output.println(generationCount + "\t" + density);
    float entropy = calculateShannonEntropy();
    entropyOutput.println(generationCount + "\t" + entropy);
  }
  
  fill(0);
  textSize(16);
  text("Generaciones: " + generationCount, 400, height - 10);
}

float calculateShannonEntropy() {
  
  int[] configCounts = new int[9];
  

  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      int neighbors = countNeighbors(i, j);
      configCounts[neighbors]++;
    }
  }
  
 
  float entropy = 0;
  float totalCells = cols * rows;
  
  for (int count : configCounts) {
    if (count > 0) {
      float probability = count / totalCells;
      entropy -= probability * log(probability) / log(2);
    }
  }
  
  return entropy;
}


float calculateDensity() {
  int countOnes = countAliveCells();
  int countZeros = cols * rows - countOnes;
  
  if (countZeros == 0) {
    return Float.POSITIVE_INFINITY;  // Evitar la división por cero
  }
  
  return (float) countOnes / countZeros;
}

void exit() {
  // Cerrar el archivo al salir del programa
  output.flush();
  output.close();
  entropyOutput.flush();
  entropyOutput.close();
  super.exit();
}

void createColorPickers() {
  cp5.addColorPicker("aliveCellColor")
     .setPosition(800, height - 160)
     .setColorValue(aliveCellColor)
     .setLabel("Color de celdas vivas")
     .getCaptionLabel().setVisible(false);
  
  cp5.addColorPicker("deadCellColor")
     .setPosition(800, height - 90)
     .setColorValue(deadCellColor)
     .setLabel("Color de celdas muertas")
     .getCaptionLabel().setVisible(false);
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom("aliveCellColor")) {
    aliveCellColor = cp5.get(ColorPicker.class, "aliveCellColor").getColorValue();
  } else if (theEvent.isFrom("deadCellColor")) {
    deadCellColor = cp5.get(ColorPicker.class, "deadCellColor").getColorValue();
  }
}

void createGuardarButton() {
  cp5.addButton("guardarButton")
     .setPosition(600, height - 80)
     .setSize(150, 30)
     .setCaptionLabel("Guardar")
     .onClick(e -> guardarConfiguracion("guardada.txt"));
}

void createConfigButton(){
  cp5.addButton("generarConfiguracionesButton")
     .setPosition(600, height - 120)
     .setSize(150, 30)
     .setCaptionLabel("Generar Configuraciones")
     .onClick(e -> generarYGuardarConfiguraciones());
  
}

void createCargarButton() {
  cp5.addButton("cargarButton")
     .setPosition(600, height - 40)
     .setSize(150, 30)
     .setCaptionLabel("Cargar")
     .onClick(e -> cargarConfiguracion("cargada.txt"));
}

void guardarConfiguracion(String nombreArchivo) {
  String[] contenido = new String[rows];
  for (int j = 0; j < rows; j++) {
    String fila = "";
    for (int i = 0; i < cols; i++) {
      fila += str(int(grid[i][j]));
    }
    contenido[j] = fila;
  }
  saveStrings(nombreArchivo, contenido);
}

void cargarConfiguracion(String nombreArchivo) {
  String[] lineas = loadStrings(nombreArchivo);
  if (lineas.length == rows) {
    for (int j = 0; j < rows; j++) {
      String fila = lineas[j];
      for (int i = 0; i < cols; i++) {
        grid[i][j] = float(fila.charAt(i) - '0');
      }
    }
  } else {
    println("Error: La configuración en el archivo no coincide con el tamaño de la cuadrícula.");
  }
}


void createSpeedSlider() {
  cp5.addSlider("speedSlider")
     .setPosition(400, height - 100)
     .setSize(150, 10)
     .setRange(0.1, 60.0) 
     .setValue(simulationSpeed)
     .setColorBackground(color(200))
     .setLabel("Generaciones por segundo")
     .setLabelVisible(true)
     .onChange(e -> simulationSpeed = cp5.get(Slider.class, "speedSlider").getValue());
}

void createStatusLabel() {
  cp5.addTextlabel("vivasLabel")
     .setPosition(400, height - 80)
     .setText("Celdas Vivas: 0")
     .setColorValue(color(0));
  
  cp5.addTextlabel("muertasLabel")
     .setPosition(400, height - 60)
     .setText("Celdas Muertas: 0")
     .setColorValue(color(0));
}

void updateStatusLabels() {
  int vivas = countAliveCells();
  int muertas = cols * rows - vivas;
  
  cp5.get(Textlabel.class, "vivasLabel").setText("Celdas Vivas: " + vivas);
  cp5.get(Textlabel.class, "muertasLabel").setText("Celdas Muertas: " + muertas);
}


int countAliveCells() {
  int count = 0;
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      count += grid[i][j];
    }
  }
  return count;
}

void mousePressed() {
  if (!simulationRunning) {
    int col = floor(mouseX / cellSizeSliderValue);
    int row = floor(mouseY / cellSizeSliderValue);
    
    if (col >= 0 && col < cols && row >= 0 && row < rows) {
      grid[col][row] = 1 - grid[col][row];
    }
  }
}


void keyPressed() {
  if (key == ' ') {
    simulationRunning = !simulationRunning;
  }
}

void createInputFields() {
  cp5.addTextfield("ruleInput")
     .setPosition(20, height -90)
     .setSize(150, 20)
     .setText("R(2,3,3,3)")
     .onChange(e -> parseRule());
     
  cp5.addTextlabel("ruleLabel")
     .setPosition(20, height - 70)
     .setText("Regla (R(Smin, Smax, Nmin, Nmax)):")
     .setColorValue(color(0));
}

void createSimulateButton() {
  cp5.addButton("simulateButton")
     .setPosition(20, height - 40)
     .setSize(150, 30)
     .setCaptionLabel("Simular")
     .onClick(e -> {
       parseRule();
       simulationRunning = true;
       generationCount = 0;
       initializeGrid(cellsPerSideSliderValue, cellsPerSideSliderValue);
     });
}

void createReiniciarButton() {
  cp5.addButton("reiniciarButton")
     .setPosition(180, height - 40)
     .setSize(150, 30)
     .setCaptionLabel("Reiniciar")
     .onClick(e -> {
       generationCount = 0;
       initializeGrid(cellsPerSideSliderValue, cellsPerSideSliderValue);
     });
}

void createGridSizeSlider() {
  cp5.addSlider("cellsPerSideSlider")
     .setPosition(20, height - 120)
     .setSize(150, 10)
     .setRange(3, 1000)
     .setValue(cellsPerSideSliderValue)
     .setColorBackground(color(200))
     .onChange(e -> resizeGrid());
}

void createCellSizeSlider() {
  cp5.addSlider("cellSizeSlider")
     .setPosition(20, height - 160)
     .setSize(150, 10)
     .setRange(1, 100)
     .setValue(cellSizeSliderValue)
     .setColorBackground(color(200))
     .onChange(e -> resizeGrid());
}

void createProbabilityDropdown() {
  cp5.addSlider("probabilitySlider")
     .setPosition(200, height - 130)
     .setSize(150, 10)
     .setRange(0, 1)
     .setValue(probabilityDropdownValue)
     .setColorBackground(color(200))
     .setLabel("Proporción de unos")
     .setLabelVisible(true)
     .onChange(e -> {
       probabilityDropdownValue = cp5.get(Slider.class, "probabilitySlider").getValue();
       fillGridWithProbability(probabilityDropdownValue);
     });
}

void initializeGrid(int initialCols, int initialRows) {
  cols = initialCols;
  rows = initialRows;
  grid = new float[cols][rows];
  fillGridWithProbability(probabilityDropdownValue);
  generationCount = 0; 
}

void drawGrid() {
  noStroke(); 
  
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      float x = i * cellSizeSliderValue;
      float y = j * cellSizeSliderValue;
      
      if (grid[i][j] == 1) {
        fill(aliveCellColor);
      } else {
        fill(deadCellColor);
      }
      
      rect(x, y, cellSizeSliderValue, cellSizeSliderValue);
    }
  }
}

void updateGrid() {
  float[][] next = new float[cols][rows];
  
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      float state = grid[i][j];
      int neighbors = countNeighbors(i, j);
      
      if (state == 0 && neighbors >= nMin && neighbors <= nMax) {
        next[i][j] = 1;
      } else if (state == 1 && neighbors >= sMin && neighbors <= sMax) {
        next[i][j] = 1;
      } else {
        next[i][j] = 0;
      }
    }
  }
  
  grid = next;
}

int countNeighbors(int x, int y) {
  int count = 0;
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
      int col = (x + i + cols) % cols;
      int row = (y + j + rows) % rows;
      count += grid[col][row];
    }
  }
  count -= grid[x][y];
  return count;
}



void parseRule() {
  String[] parts = splitTokens(cp5.get(Textfield.class, "ruleInput").getText(), "(),");
  if (parts.length >= 5) {
    sMin = constrain(parseInt(parts[1]), 0, 8);
    sMax = constrain(parseInt(parts[2]), 0, 8);
    nMin = constrain(parseInt(parts[3]), 0, 8);
    nMax = constrain(parseInt(parts[4]), 0, 8);
  }
}

void resizeGrid() {
  cellsPerSideSliderValue = int(cp5.get(Slider.class, "cellsPerSideSlider").getValue());
  cellSizeSliderValue = int(cp5.get(Slider.class, "cellSizeSlider").getValue());
  initializeGrid(cellsPerSideSliderValue, cellsPerSideSliderValue);
}

void fillGridWithProbability(float probability) {
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      float rand = random(1);
      grid[i][j] = (rand < probability) ? 1 : 0;
    }
  }
}

void generarYGuardarConfiguraciones() {
  // Abrir el archivo para escritura
  PrintWriter outputConfiguraciones = createWriter("configuraciones.txt");

  // Iterar sobre todas las configuraciones posibles
  float totalConfiguraciones = pow(2, cols * rows);
  for (int configDecimal = 0; configDecimal < totalConfiguraciones; configDecimal++) {
    // Convertir el número decimal a binario y llenar la cuadrícula
    String configBinaria = Integer.toBinaryString(configDecimal);
    llenarCuadriculaDesdeConfiguracionBinaria(configBinaria);

    // Calcular la primera generación con la regla actual
    parseRule(); // Asegurarse de tener la regla actualizada
    simulationRunning = true;
    generationCount = 0;
    updateGrid();

    // Obtener los valores decimales de la configuración inicial y la primera generación
    int valorInicial = configDecimal;
    int valorPrimeraGeneracion = convertirConfiguracionAValorDecimal();

    // Escribir los valores en el archivo
    outputConfiguraciones.print(valorInicial + "\t" + valorPrimeraGeneracion);

    // Hacer un salto de línea después de cada configuración
    outputConfiguraciones.println();
  }

  // Cerrar el archivo
  outputConfiguraciones.flush();
  outputConfiguraciones.close();
}

void llenarCuadriculaDesdeConfiguracionBinaria(String configBinaria) {
  // Asegurarse de tener una cuadrícula válida
  initializeGrid(cols, rows);

  // Rellenar la cuadrícula con la configuración binaria
  int index = configBinaria.length() - 1;
  for (int i = cols - 1; i >= 0; i--) {
    for (int j = rows - 1; j >= 0; j--) {
      if (index >= 0) {
        grid[i][j] = configBinaria.charAt(index) - '0';
        index--;
      }
    }
  }
}

int convertirConfiguracionAValorDecimal() {
  int valorDecimal = 0;
  int base = 1;
  for (int i = cols - 1; i >= 0; i--) {
    for (int j = rows - 1; j >= 0; j--) {
      valorDecimal += grid[i][j] * base;
      base *= 2;
    }
  }
  return valorDecimal;
}
