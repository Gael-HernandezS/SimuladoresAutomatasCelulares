import controlP5.*;
import java.io.*;
import java.util.ArrayList;
import javax.swing.*;
import processing.awt.PSurfaceAWT.SmoothCanvas;


int minCellSize = 1;  // Tamaño mínimo de celda en píxeles
int maxCellSize = 100; // Tamaño máximo de celda en píxeles
int minCellsPerSide = 10; // Mínimo número de celdas por lado
int maxCellsPerSide = 10000; // Máximo número de celdas por lado
int cols, rows; // Número de columnas y filas basado en el tamaño de la ventana
color[][] grid; // Matriz para almacenar el color de cada celda
int[][] nextGeneration; // Matriz para la siguiente generación
color colorViva = color(255, 0, 0); // Color para las celdas vivas (rojo)
color colorMuerta = color(255); // Color para las celdas muertas (blanco)
int generation = 1; // Generación actual--

float percentageOnes = 0.02; // Porcentaje inicial de unos (2%)
boolean automaticMode = false; // Indica si estamos en modo automático
float interval = 0.1; // Intervalo de tiempo en milisegundos
int lastTime = 0; // Último tiempo en el que se aplicó la regla
boolean generateGrid = false; // Bandera para generar la cuadrícula
Button generateButton; // Botón para generar la cuadrícula
Button fillRandomButton; // Botón para llenar aleatoriamente la primera línea
Button saveConfigButton; // Botón para guardar la configuración
Button applyRuleButton; // Botón para aplicar la regla
Button loadPatternButton; // Botón para cargar un patrón desde un archivo
Button atrac;
ColorPicker colorPickerViva; // Selector de color para celdas vivas
ColorPicker colorPickerMuerta; // Selector de color para celdas muertas
DropdownList ruleSelector; // Selector de regla
boolean hideGenerateButton = false; // Bandera para ocultar el botón "Generar"
boolean showUI = true; // Mostrar la interfaz de usuario

int currentRow = 0; // Variable para realizar un seguimiento del estado actual de la fila
int unosGeneracion = 0; // Contador de unos en la generación actual
int cerosGeneracion = 0; // Contador de ceros en la generación actual
int[] subStringCounts = new int[8];
PrintWriter writer;
PrintWriter writer1;
PrintWriter writer2;
ArrayList<Float> densidades = new ArrayList<Float>();
ArrayList<Integer> generaciones = new ArrayList<Integer>();
ArrayList<Float> medias = new ArrayList<Float>();
boolean visualizarAtractor = false;
boolean mostrarCicloAtractor = false;
PGraphics graphCanvas; // Lienzo para el ciclo atractor
ControlP5 cp5;


// Define las reglas en una matriz bidimensional
int[][][][] rules = new int[256][2][2][2];

Textfield colsTextField;
Textfield rowsTextField;
Button applySizeButton;

void setup() {
  fullScreen();
   // Establecer la posición de los controles
  float xPosition = 10;
  float yPosition = height - 100; // Ajusta esta coordenada hacia arriba
  float spacing = 10;
  cols = width / minCellSize; // Inicialmente, se establece según el tamaño mínimo de celda
  rows = height / minCellSize; // Inicialmente, se establece según el tamaño mínimo de celda
  grid = new color[cols][rows];
  nextGeneration = new int[cols][rows];
  cp5 = new ControlP5(this);
  
   colsTextField = cp5.addTextfield("cols")
    .setPosition(1000, height - 40)
    .setSize(70, 20)
    .setValue(cols + "") // Inicializa con el valor actual de cols
    .setLabel("Celdas por Lado (Cols)");
  
  rowsTextField = cp5.addTextfield("rows")
    .setPosition(1000, height - 70)
    .setSize(70, 20)
    .setValue(rows + "") // Inicializa con el valor actual de rows
    .setLabel("Celdas por Lado (Rows)");
  
  writer = createWriter("DENSIDAD.txt");
  writer1 = createWriter("MEDIA.txt");
  writer2 = createWriter("ENTROPY.txt");
  // Crear botón para generar la cuadrícula
  generateButton = new Button(xPosition, yPosition, 80, 30, "Generar");
  xPosition += 90; // Espacio entre botones
  
  applySizeButton = new Button(xPosition, yPosition, 120, 30,"ApplySize");
  
  cp5.addButton("todo")
   .setPosition(600, height - 50)
   .setSize(80, 30)
   .setLabel("Todo");


  cp5.addButton("Reiniciar")
   .setPosition(250, height - 50)
   .setSize(80, 30)
   .setLabel("Reiniciar");
   
  cp5.addButton("atrac")
   .setPosition(10, height - 40)
   .setSize(80, 30)
   .setLabel("Atractor");
   
  // Crear botón para llenar aleatoriamente la primera línea
  fillRandomButton = new Button(xPosition, yPosition + 40, 120, 30, "Llenar Aleatoriamente");
  xPosition += 140; // Espacio entre botones

  // Crear botón para guardar la configuración
  saveConfigButton = new Button(xPosition, yPosition, 120, 30, "Guardar Configuración");
  xPosition += 140; // Espacio entre botones

  // Crear botón para aplicar la regla
  applyRuleButton = new Button(xPosition, yPosition, 100, 30, "Aplicar Regla");
  xPosition += 110; // Espacio entre botones

  // Crear botón para cargar un patrón desde un archivo
  loadPatternButton = new Button(xPosition, yPosition, 100, 30, "Cargar Patrón");
  xPosition += 110; // Espacio entre botones

  // Crear control deslizante para ajustar el tamaño de la celda
  cp5.addSlider("cellSize")
    .setPosition(1000, height - 100)
    .setRange(1, maxCellSize) // Establecer el valor mínimo a 1
    .setValue(1) // Establecer el valor inicial a 1
    .setLabel("Tamaño de Celda (px)");

  ruleSelector = cp5.addDropdownList("Rule Selector")
    .setPosition(1300, 850) // Mover más a la derecha de la ventana
    .setSize(100, 200)
    .setBarHeight(20)
    .setItemHeight(20)
    .setLabel("Regla");

  for (int i = 0; i < 256; i++) {
    ruleSelector.addItem("Regla " + i, i);
  }
  
  cp5.addButton("Automático")
   .setPosition(10, height - 70)
   .setSize(80, 30)
   .setLabel("Automático");

  // Crear selectores de color para celdas vivas y muertas
  colorPickerViva = cp5.addColorPicker("Color Viva")
    .setPosition(xPosition, yPosition)
    .setColorValue(colorViva)
    .setColorBackground(colorViva);
  xPosition += 100; // Espacio entre selectores

  colorPickerMuerta = cp5.addColorPicker("Color Muerta")
    .setPosition(xPosition, yPosition)
    .setColorValue(colorMuerta)
    .setColorBackground(colorMuerta);
    
    // Crear botón para guardar la última fila
cp5.addButton("Guardar Última Fila")
   .setPosition(width - 130, height - 40)
   .setSize(120, 30)
   .setLabel("Guardar Última Fila");
   
  cp5.addButton("2%").setPosition(xPosition + 800, yPosition).setSize(40, 30);
  cp5.addButton("50%").setPosition(xPosition + 850, yPosition).setSize(40, 30);
  cp5.addButton("75%").setPosition(xPosition + 900, yPosition).setSize(40, 30);
  cp5.addButton("95%").setPosition(xPosition + 950, yPosition).setSize(40, 30);
  
rules[1][0][0][0] = 1;rules[1][0][0][1] = 0;rules[1][0][1][0] = 0;rules[1][0][1][1] = 0;rules[1][1][0][0] = 0;rules[1][1][0][1] = 0;rules[1][1][1][0] = 0;rules[1][1][1][1] = 0;
rules[2][0][0][0] = 0;rules[2][0][0][1] = 1;rules[2][0][1][0] = 0;rules[2][0][1][1] = 0;rules[2][1][0][0] = 0;rules[2][1][0][1] = 0;rules[2][1][1][0] = 0;rules[2][1][1][1] = 0;
rules[3][0][0][0] = 1;rules[3][0][0][1] = 1;rules[3][0][1][0] = 0;rules[3][0][1][1] = 0;rules[3][1][0][0] = 0;rules[3][1][0][1] = 0;rules[3][1][1][0] = 0;rules[3][1][1][1] = 0;
rules[4][0][0][0] = 0;rules[4][0][0][1] = 0;rules[4][0][1][0] = 1;rules[4][0][1][1] = 0;rules[4][1][0][0] = 0;rules[4][1][0][1] = 0;rules[4][1][1][0] = 0;rules[4][1][1][1] = 0;
rules[5][0][0][0] = 1;rules[5][0][0][1] = 0;rules[5][0][1][0] = 1;rules[5][0][1][1] = 0;rules[5][1][0][0] = 0;rules[5][1][0][1] = 0;rules[5][1][1][0] = 0;rules[5][1][1][1] = 0;
rules[6][0][0][0] = 0;rules[6][0][0][1] = 1;rules[6][0][1][0] = 1;rules[6][0][1][1] = 0;rules[6][1][0][0] = 0;rules[6][1][0][1] = 0;rules[6][1][1][0] = 0;rules[6][1][1][1] = 0;
rules[7][0][0][0] = 1;rules[7][0][0][1] = 1;rules[7][0][1][0] = 1;rules[7][0][1][1] = 0;rules[7][1][0][0] = 0;rules[7][1][0][1] = 0;rules[7][1][1][0] = 0;rules[7][1][1][1] = 0;
rules[8][0][0][0] = 0;rules[8][0][0][1] = 0;rules[8][0][1][0] = 0;rules[8][0][1][1] = 1;rules[8][1][0][0] = 0;rules[8][1][0][1] = 0;rules[8][1][1][0] = 0;rules[8][1][1][1] = 0;
rules[9][0][0][0] = 1;rules[9][0][0][1] = 0;rules[9][0][1][0] = 0;rules[9][0][1][1] = 1;rules[9][1][0][0] = 0;rules[9][1][0][1] = 0;rules[9][1][1][0] = 0;rules[9][1][1][1] = 0;
rules[10][0][0][0] = 0;rules[10][0][0][1] = 1;rules[10][0][1][0] = 0;rules[10][0][1][1] = 1;rules[10][1][0][0] = 0;rules[10][1][0][1] = 0;rules[10][1][1][0] = 0;rules[10][1][1][1] = 0;
rules[11][0][0][0] = 1;rules[11][0][0][1] = 1;rules[11][0][1][0] = 0;rules[11][0][1][1] = 1;rules[11][1][0][0] = 0;rules[11][1][0][1] = 0;rules[11][1][1][0] = 0;rules[11][1][1][1] = 0;
rules[12][0][0][0] = 0;rules[12][0][0][1] = 0;rules[12][0][1][0] = 1;rules[12][0][1][1] = 1;rules[12][1][0][0] = 0;rules[12][1][0][1] = 0;rules[12][1][1][0] = 0;rules[12][1][1][1] = 0;
rules[13][0][0][0] = 1;rules[13][0][0][1] = 0;rules[13][0][1][0] = 1;rules[13][0][1][1] = 1;rules[13][1][0][0] = 0;rules[13][1][0][1] = 0;rules[13][1][1][0] = 0;rules[13][1][1][1] = 0;
rules[14][0][0][0] = 0;rules[14][0][0][1] = 1;rules[14][0][1][0] = 1;rules[14][0][1][1] = 1;rules[14][1][0][0] = 0;rules[14][1][0][1] = 0;rules[14][1][1][0] = 0;rules[14][1][1][1] = 0;
rules[15][0][0][0] = 1;rules[15][0][0][1] = 1;rules[15][0][1][0] = 1;rules[15][0][1][1] = 1;rules[15][1][0][0] = 0;rules[15][1][0][1] = 0;rules[15][1][1][0] = 0;rules[15][1][1][1] = 0;
rules[16][0][0][0] = 0;rules[16][0][0][1] = 0;rules[16][0][1][0] = 0;rules[16][0][1][1] = 0;rules[16][1][0][0] = 1;rules[16][1][0][1] = 0;rules[16][1][1][0] = 0;rules[16][1][1][1] = 0;
rules[17][0][0][0] = 1;rules[17][0][0][1] = 0;rules[17][0][1][0] = 0;rules[17][0][1][1] = 0;rules[17][1][0][0] = 1;rules[17][1][0][1] = 0;rules[17][1][1][0] = 0;rules[17][1][1][1] = 0;
rules[18][0][0][0] = 0;rules[18][0][0][1] = 1;rules[18][0][1][0] = 0;rules[18][0][1][1] = 0;rules[18][1][0][0] = 1;rules[18][1][0][1] = 0;rules[18][1][1][0] = 0;rules[18][1][1][1] = 0;
rules[19][0][0][0] = 1;rules[19][0][0][1] = 1;rules[19][0][1][0] = 0;rules[19][0][1][1] = 0;rules[19][1][0][0] = 1;rules[19][1][0][1] = 0;rules[19][1][1][0] = 0;rules[19][1][1][1] = 0;
rules[20][0][0][0] = 0;rules[20][0][0][1] = 0;rules[20][0][1][0] = 1;rules[20][0][1][1] = 0;rules[20][1][0][0] = 1;rules[20][1][0][1] = 0;rules[20][1][1][0] = 0;rules[20][1][1][1] = 0;
rules[21][0][0][0] = 1;rules[21][0][0][1] = 0;rules[21][0][1][0] = 1;rules[21][0][1][1] = 0;rules[21][1][0][0] = 1;rules[21][1][0][1] = 0;rules[21][1][1][0] = 0;rules[21][1][1][1] = 0;
rules[22][0][0][0] = 0;rules[22][0][0][1] = 1;rules[22][0][1][0] = 1;rules[22][0][1][1] = 0;rules[22][1][0][0] = 1;rules[22][1][0][1] = 0;rules[22][1][1][0] = 0;rules[22][1][1][1] = 0;
rules[23][0][0][0] = 1;rules[23][0][0][1] = 1;rules[23][0][1][0] = 1;rules[23][0][1][1] = 0;rules[23][1][0][0] = 1;rules[23][1][0][1] = 0;rules[23][1][1][0] = 0;rules[23][1][1][1] = 0;
rules[24][0][0][0] = 0;rules[24][0][0][1] = 0;rules[24][0][1][0] = 0;rules[24][0][1][1] = 1;rules[24][1][0][0] = 1;rules[24][1][0][1] = 0;rules[24][1][1][0] = 0;rules[24][1][1][1] = 0;
rules[25][0][0][0] = 1;rules[25][0][0][1] = 0;rules[25][0][1][0] = 0;rules[25][0][1][1] = 1;rules[25][1][0][0] = 1;rules[25][1][0][1] = 0;rules[25][1][1][0] = 0;rules[25][1][1][1] = 0;
rules[26][0][0][0] = 0;rules[26][0][0][1] = 1;rules[26][0][1][0] = 0;rules[26][0][1][1] = 1;rules[26][1][0][0] = 1;rules[26][1][0][1] = 0;rules[26][1][1][0] = 0;rules[26][1][1][1] = 0;
rules[27][0][0][0] = 1;rules[27][0][0][1] = 1;rules[27][0][1][0] = 0;rules[27][0][1][1] = 1;rules[27][1][0][0] = 1;rules[27][1][0][1] = 0;rules[27][1][1][0] = 0;rules[27][1][1][1] = 0;
rules[28][0][0][0] = 0;rules[28][0][0][1] = 0;rules[28][0][1][0] = 1;rules[28][0][1][1] = 1;rules[28][1][0][0] = 1;rules[28][1][0][1] = 0;rules[28][1][1][0] = 0;rules[28][1][1][1] = 0;
rules[29][0][0][0] = 1;rules[29][0][0][1] = 0;rules[29][0][1][0] = 1;rules[29][0][1][1] = 1;rules[29][1][0][0] = 1;rules[29][1][0][1] = 0;rules[29][1][1][0] = 0;rules[29][1][1][1] = 0;
rules[30][0][0][0] = 0;rules[30][0][0][1] = 1;rules[30][0][1][0] = 1;rules[30][0][1][1] = 1;rules[30][1][0][0] = 1;rules[30][1][0][1] = 0;rules[30][1][1][0] = 0;rules[30][1][1][1] = 0;
rules[31][0][0][0] = 1;rules[31][0][0][1] = 1;rules[31][0][1][0] = 1;rules[31][0][1][1] = 1;rules[31][1][0][0] = 1;rules[31][1][0][1] = 0;rules[31][1][1][0] = 0;rules[31][1][1][1] = 0;
rules[32][0][0][0] = 0;rules[32][0][0][1] = 0;rules[32][0][1][0] = 0;rules[32][0][1][1] = 0;rules[32][1][0][0] = 0;rules[32][1][0][1] = 1;rules[32][1][1][0] = 0;rules[32][1][1][1] = 0;
rules[33][0][0][0] = 1;rules[33][0][0][1] = 0;rules[33][0][1][0] = 0;rules[33][0][1][1] = 0;rules[33][1][0][0] = 0;rules[33][1][0][1] = 1;rules[33][1][1][0] = 0;rules[33][1][1][1] = 0;
rules[34][0][0][0] = 0;rules[34][0][0][1] = 1;rules[34][0][1][0] = 0;rules[34][0][1][1] = 0;rules[34][1][0][0] = 0;rules[34][1][0][1] = 1;rules[34][1][1][0] = 0;rules[34][1][1][1] = 0;
rules[35][0][0][0] = 1;rules[35][0][0][1] = 1;rules[35][0][1][0] = 0;rules[35][0][1][1] = 0;rules[35][1][0][0] = 0;rules[35][1][0][1] = 1;rules[35][1][1][0] = 0;rules[35][1][1][1] = 0;
rules[36][0][0][0] = 0;rules[36][0][0][1] = 0;rules[36][0][1][0] = 1;rules[36][0][1][1] = 0;rules[36][1][0][0] = 0;rules[36][1][0][1] = 1;rules[36][1][1][0] = 0;rules[36][1][1][1] = 0;
rules[37][0][0][0] = 1;rules[37][0][0][1] = 0;rules[37][0][1][0] = 1;rules[37][0][1][1] = 0;rules[37][1][0][0] = 0;rules[37][1][0][1] = 1;rules[37][1][1][0] = 0;rules[37][1][1][1] = 0;
rules[38][0][0][0] = 0;rules[38][0][0][1] = 1;rules[38][0][1][0] = 1;rules[38][0][1][1] = 0;rules[38][1][0][0] = 0;rules[38][1][0][1] = 1;rules[38][1][1][0] = 0;rules[38][1][1][1] = 0;
rules[39][0][0][0] = 1;rules[39][0][0][1] = 1;rules[39][0][1][0] = 1;rules[39][0][1][1] = 0;rules[39][1][0][0] = 0;rules[39][1][0][1] = 1;rules[39][1][1][0] = 0;rules[39][1][1][1] = 0;
rules[40][0][0][0] = 0;rules[40][0][0][1] = 0;rules[40][0][1][0] = 0;rules[40][0][1][1] = 1;rules[40][1][0][0] = 0;rules[40][1][0][1] = 1;rules[40][1][1][0] = 0;rules[40][1][1][1] = 0;
rules[41][0][0][0] = 1;rules[41][0][0][1] = 0;rules[41][0][1][0] = 0;rules[41][0][1][1] = 1;rules[41][1][0][0] = 0;rules[41][1][0][1] = 1;rules[41][1][1][0] = 0;rules[41][1][1][1] = 0;
rules[42][0][0][0] = 0;rules[42][0][0][1] = 1;rules[42][0][1][0] = 0;rules[42][0][1][1] = 1;rules[42][1][0][0] = 0;rules[42][1][0][1] = 1;rules[42][1][1][0] = 0;rules[42][1][1][1] = 0;
rules[43][0][0][0] = 1;rules[43][0][0][1] = 1;rules[43][0][1][0] = 0;rules[43][0][1][1] = 1;rules[43][1][0][0] = 0;rules[43][1][0][1] = 1;rules[43][1][1][0] = 0;rules[43][1][1][1] = 0;
rules[44][0][0][0] = 0;rules[44][0][0][1] = 0;rules[44][0][1][0] = 1;rules[44][0][1][1] = 1;rules[44][1][0][0] = 0;rules[44][1][0][1] = 1;rules[44][1][1][0] = 0;rules[44][1][1][1] = 0;
rules[45][0][0][0] = 1;rules[45][0][0][1] = 0;rules[45][0][1][0] = 1;rules[45][0][1][1] = 1;rules[45][1][0][0] = 0;rules[45][1][0][1] = 1;rules[45][1][1][0] = 0;rules[45][1][1][1] = 0;
rules[46][0][0][0] = 0;rules[46][0][0][1] = 1;rules[46][0][1][0] = 1;rules[46][0][1][1] = 1;rules[46][1][0][0] = 0;rules[46][1][0][1] = 1;rules[46][1][1][0] = 0;rules[46][1][1][1] = 0;
rules[47][0][0][0] = 1;rules[47][0][0][1] = 1;rules[47][0][1][0] = 1;rules[47][0][1][1] = 1;rules[47][1][0][0] = 0;rules[47][1][0][1] = 1;rules[47][1][1][0] = 0;rules[47][1][1][1] = 0;
rules[48][0][0][0] = 0;rules[48][0][0][1] = 0;rules[48][0][1][0] = 0;rules[48][0][1][1] = 0;rules[48][1][0][0] = 1;rules[48][1][0][1] = 1;rules[48][1][1][0] = 0;rules[48][1][1][1] = 0;
rules[49][0][0][0] = 1;rules[49][0][0][1] = 0;rules[49][0][1][0] = 0;rules[49][0][1][1] = 0;rules[49][1][0][0] = 1;rules[49][1][0][1] = 1;rules[49][1][1][0] = 0;rules[49][1][1][1] = 0;
rules[50][0][0][0] = 0;rules[50][0][0][1] = 1;rules[50][0][1][0] = 0;rules[50][0][1][1] = 0;rules[50][1][0][0] = 1;rules[50][1][0][1] = 1;rules[50][1][1][0] = 0;rules[50][1][1][1] = 0;
rules[51][0][0][0] = 1;rules[51][0][0][1] = 1;rules[51][0][1][0] = 0;rules[51][0][1][1] = 0;rules[51][1][0][0] = 1;rules[51][1][0][1] = 1;rules[51][1][1][0] = 0;rules[51][1][1][1] = 0;
rules[52][0][0][0] = 0;rules[52][0][0][1] = 0;rules[52][0][1][0] = 1;rules[52][0][1][1] = 0;rules[52][1][0][0] = 1;rules[52][1][0][1] = 1;rules[52][1][1][0] = 0;rules[52][1][1][1] = 0;
rules[53][0][0][0] = 1;rules[53][0][0][1] = 0;rules[53][0][1][0] = 1;rules[53][0][1][1] = 0;rules[53][1][0][0] = 1;rules[53][1][0][1] = 1;rules[53][1][1][0] = 0;rules[53][1][1][1] = 0;
rules[54][0][0][0] = 0;rules[54][0][0][1] = 1;rules[54][0][1][0] = 1;rules[54][0][1][1] = 0;rules[54][1][0][0] = 1;rules[54][1][0][1] = 1;rules[54][1][1][0] = 0;rules[54][1][1][1] = 0;
rules[55][0][0][0] = 1;rules[55][0][0][1] = 1;rules[55][0][1][0] = 1;rules[55][0][1][1] = 0;rules[55][1][0][0] = 1;rules[55][1][0][1] = 1;rules[55][1][1][0] = 0;rules[55][1][1][1] = 0;
rules[56][0][0][0] = 0;rules[56][0][0][1] = 0;rules[56][0][1][0] = 0;rules[56][0][1][1] = 1;rules[56][1][0][0] = 1;rules[56][1][0][1] = 1;rules[56][1][1][0] = 0;rules[56][1][1][1] = 0;
rules[57][0][0][0] = 1;rules[57][0][0][1] = 0;rules[57][0][1][0] = 0;rules[57][0][1][1] = 1;rules[57][1][0][0] = 1;rules[57][1][0][1] = 1;rules[57][1][1][0] = 0;rules[57][1][1][1] = 0;
rules[58][0][0][0] = 0;rules[58][0][0][1] = 1;rules[58][0][1][0] = 0;rules[58][0][1][1] = 1;rules[58][1][0][0] = 1;rules[58][1][0][1] = 1;rules[58][1][1][0] = 0;rules[58][1][1][1] = 0;
rules[59][0][0][0] = 1;rules[59][0][0][1] = 1;rules[59][0][1][0] = 0;rules[59][0][1][1] = 1;rules[59][1][0][0] = 1;rules[59][1][0][1] = 1;rules[59][1][1][0] = 0;rules[59][1][1][1] = 0;
rules[60][0][0][0] = 0;rules[60][0][0][1] = 0;rules[60][0][1][0] = 1;rules[60][0][1][1] = 1;rules[60][1][0][0] = 1;rules[60][1][0][1] = 1;rules[60][1][1][0] = 0;rules[60][1][1][1] = 0;
rules[61][0][0][0] = 1;rules[61][0][0][1] = 0;rules[61][0][1][0] = 1;rules[61][0][1][1] = 1;rules[61][1][0][0] = 1;rules[61][1][0][1] = 1;rules[61][1][1][0] = 0;rules[61][1][1][1] = 0;
rules[62][0][0][0] = 0;rules[62][0][0][1] = 1;rules[62][0][1][0] = 1;rules[62][0][1][1] = 1;rules[62][1][0][0] = 1;rules[62][1][0][1] = 1;rules[62][1][1][0] = 0;rules[62][1][1][1] = 0;
rules[63][0][0][0] = 1;rules[63][0][0][1] = 1;rules[63][0][1][0] = 1;rules[63][0][1][1] = 1;rules[63][1][0][0] = 1;rules[63][1][0][1] = 1;rules[63][1][1][0] = 0;rules[63][1][1][1] = 0;
rules[64][0][0][0] = 0;rules[64][0][0][1] = 0;rules[64][0][1][0] = 0;rules[64][0][1][1] = 0;rules[64][1][0][0] = 0;rules[64][1][0][1] = 0;rules[64][1][1][0] = 1;rules[64][1][1][1] = 0;
rules[65][0][0][0] = 1;rules[65][0][0][1] = 0;rules[65][0][1][0] = 0;rules[65][0][1][1] = 0;rules[65][1][0][0] = 0;rules[65][1][0][1] = 0;rules[65][1][1][0] = 1;rules[65][1][1][1] = 0;
rules[66][0][0][0] = 0;rules[66][0][0][1] = 1;rules[66][0][1][0] = 0;rules[66][0][1][1] = 0;rules[66][1][0][0] = 0;rules[66][1][0][1] = 0;rules[66][1][1][0] = 1;rules[66][1][1][1] = 0;
rules[67][0][0][0] = 1;rules[67][0][0][1] = 1;rules[67][0][1][0] = 0;rules[67][0][1][1] = 0;rules[67][1][0][0] = 0;rules[67][1][0][1] = 0;rules[67][1][1][0] = 1;rules[67][1][1][1] = 0;
rules[68][0][0][0] = 0;rules[68][0][0][1] = 0;rules[68][0][1][0] = 1;rules[68][0][1][1] = 0;rules[68][1][0][0] = 0;rules[68][1][0][1] = 0;rules[68][1][1][0] = 1;rules[68][1][1][1] = 0;
rules[69][0][0][0] = 1;rules[69][0][0][1] = 0;rules[69][0][1][0] = 1;rules[69][0][1][1] = 0;rules[69][1][0][0] = 0;rules[69][1][0][1] = 0;rules[69][1][1][0] = 1;rules[69][1][1][1] = 0;
rules[70][0][0][0] = 0;rules[70][0][0][1] = 1;rules[70][0][1][0] = 1;rules[70][0][1][1] = 0;rules[70][1][0][0] = 0;rules[70][1][0][1] = 0;rules[70][1][1][0] = 1;rules[70][1][1][1] = 0;
rules[71][0][0][0] = 1;rules[71][0][0][1] = 1;rules[71][0][1][0] = 1;rules[71][0][1][1] = 0;rules[71][1][0][0] = 0;rules[71][1][0][1] = 0;rules[71][1][1][0] = 1;rules[71][1][1][1] = 0;
rules[72][0][0][0] = 0;rules[72][0][0][1] = 0;rules[72][0][1][0] = 0;rules[72][0][1][1] = 1;rules[72][1][0][0] = 0;rules[72][1][0][1] = 0;rules[72][1][1][0] = 1;rules[72][1][1][1] = 0;
rules[73][0][0][0] = 1;rules[73][0][0][1] = 0;rules[73][0][1][0] = 0;rules[73][0][1][1] = 1;rules[73][1][0][0] = 0;rules[73][1][0][1] = 0;rules[73][1][1][0] = 1;rules[73][1][1][1] = 0;
rules[74][0][0][0] = 0;rules[74][0][0][1] = 1;rules[74][0][1][0] = 0;rules[74][0][1][1] = 1;rules[74][1][0][0] = 0;rules[74][1][0][1] = 0;rules[74][1][1][0] = 1;rules[74][1][1][1] = 0;
rules[75][0][0][0] = 1;rules[75][0][0][1] = 1;rules[75][0][1][0] = 0;rules[75][0][1][1] = 1;rules[75][1][0][0] = 0;rules[75][1][0][1] = 0;rules[75][1][1][0] = 1;rules[75][1][1][1] = 0;
rules[76][0][0][0] = 0;rules[76][0][0][1] = 0;rules[76][0][1][0] = 1;rules[76][0][1][1] = 1;rules[76][1][0][0] = 0;rules[76][1][0][1] = 0;rules[76][1][1][0] = 1;rules[76][1][1][1] = 0;
rules[77][0][0][0] = 1;rules[77][0][0][1] = 0;rules[77][0][1][0] = 1;rules[77][0][1][1] = 1;rules[77][1][0][0] = 0;rules[77][1][0][1] = 0;rules[77][1][1][0] = 1;rules[77][1][1][1] = 0;
rules[78][0][0][0] = 0;rules[78][0][0][1] = 1;rules[78][0][1][0] = 1;rules[78][0][1][1] = 1;rules[78][1][0][0] = 0;rules[78][1][0][1] = 0;rules[78][1][1][0] = 1;rules[78][1][1][1] = 0;
rules[79][0][0][0] = 1;rules[79][0][0][1] = 1;rules[79][0][1][0] = 1;rules[79][0][1][1] = 1;rules[79][1][0][0] = 0;rules[79][1][0][1] = 0;rules[79][1][1][0] = 1;rules[79][1][1][1] = 0;
rules[80][0][0][0] = 0;rules[80][0][0][1] = 0;rules[80][0][1][0] = 0;rules[80][0][1][1] = 0;rules[80][1][0][0] = 1;rules[80][1][0][1] = 0;rules[80][1][1][0] = 1;rules[80][1][1][1] = 0;
rules[81][0][0][0] = 1;rules[81][0][0][1] = 0;rules[81][0][1][0] = 0;rules[81][0][1][1] = 0;rules[81][1][0][0] = 1;rules[81][1][0][1] = 0;rules[81][1][1][0] = 1;rules[81][1][1][1] = 0;
rules[82][0][0][0] = 0;rules[82][0][0][1] = 1;rules[82][0][1][0] = 0;rules[82][0][1][1] = 0;rules[82][1][0][0] = 1;rules[82][1][0][1] = 0;rules[82][1][1][0] = 1;rules[82][1][1][1] = 0;
rules[83][0][0][0] = 1;rules[83][0][0][1] = 1;rules[83][0][1][0] = 0;rules[83][0][1][1] = 0;rules[83][1][0][0] = 1;rules[83][1][0][1] = 0;rules[83][1][1][0] = 1;rules[83][1][1][1] = 0;
rules[84][0][0][0] = 0;rules[84][0][0][1] = 0;rules[84][0][1][0] = 1;rules[84][0][1][1] = 0;rules[84][1][0][0] = 1;rules[84][1][0][1] = 0;rules[84][1][1][0] = 1;rules[84][1][1][1] = 0;
rules[85][0][0][0] = 1;rules[85][0][0][1] = 0;rules[85][0][1][0] = 1;rules[85][0][1][1] = 0;rules[85][1][0][0] = 1;rules[85][1][0][1] = 0;rules[85][1][1][0] = 1;rules[85][1][1][1] = 0;
rules[86][0][0][0] = 0;rules[86][0][0][1] = 1;rules[86][0][1][0] = 1;rules[86][0][1][1] = 0;rules[86][1][0][0] = 1;rules[86][1][0][1] = 0;rules[86][1][1][0] = 1;rules[86][1][1][1] = 0;
rules[87][0][0][0] = 1;rules[87][0][0][1] = 1;rules[87][0][1][0] = 1;rules[87][0][1][1] = 0;rules[87][1][0][0] = 1;rules[87][1][0][1] = 0;rules[87][1][1][0] = 1;rules[87][1][1][1] = 0;
rules[88][0][0][0] = 0;rules[88][0][0][1] = 0;rules[88][0][1][0] = 0;rules[88][0][1][1] = 1;rules[88][1][0][0] = 1;rules[88][1][0][1] = 0;rules[88][1][1][0] = 1;rules[88][1][1][1] = 0;
rules[89][0][0][0] = 1;rules[89][0][0][1] = 0;rules[89][0][1][0] = 0;rules[89][0][1][1] = 1;rules[89][1][0][0] = 1;rules[89][1][0][1] = 0;rules[89][1][1][0] = 1;rules[89][1][1][1] = 0;
rules[90][0][0][0] = 0;rules[90][0][0][1] = 1;rules[90][0][1][0] = 0;rules[90][0][1][1] = 1;rules[90][1][0][0] = 1;rules[90][1][0][1] = 0;rules[90][1][1][0] = 1;rules[90][1][1][1] = 0;
rules[91][0][0][0] = 1;rules[91][0][0][1] = 1;rules[91][0][1][0] = 0;rules[91][0][1][1] = 1;rules[91][1][0][0] = 1;rules[91][1][0][1] = 0;rules[91][1][1][0] = 1;rules[91][1][1][1] = 0;
rules[92][0][0][0] = 0;rules[92][0][0][1] = 0;rules[92][0][1][0] = 1;rules[92][0][1][1] = 1;rules[92][1][0][0] = 1;rules[92][1][0][1] = 0;rules[92][1][1][0] = 1;rules[92][1][1][1] = 0;
rules[93][0][0][0] = 1;rules[93][0][0][1] = 0;rules[93][0][1][0] = 1;rules[93][0][1][1] = 1;rules[93][1][0][0] = 1;rules[93][1][0][1] = 0;rules[93][1][1][0] = 1;rules[93][1][1][1] = 0;
rules[94][0][0][0] = 0;rules[94][0][0][1] = 1;rules[94][0][1][0] = 1;rules[94][0][1][1] = 1;rules[94][1][0][0] = 1;rules[94][1][0][1] = 0;rules[94][1][1][0] = 1;rules[94][1][1][1] = 0;
rules[95][0][0][0] = 1;rules[95][0][0][1] = 1;rules[95][0][1][0] = 1;rules[95][0][1][1] = 1;rules[95][1][0][0] = 1;rules[95][1][0][1] = 0;rules[95][1][1][0] = 1;rules[95][1][1][1] = 0;
rules[96][0][0][0] = 0;rules[96][0][0][1] = 0;rules[96][0][1][0] = 0;rules[96][0][1][1] = 0;rules[96][1][0][0] = 0;rules[96][1][0][1] = 1;rules[96][1][1][0] = 1;rules[96][1][1][1] = 0;
rules[97][0][0][0] = 1;rules[97][0][0][1] = 0;rules[97][0][1][0] = 0;rules[97][0][1][1] = 0;rules[97][1][0][0] = 0;rules[97][1][0][1] = 1;rules[97][1][1][0] = 1;rules[97][1][1][1] = 0;
rules[98][0][0][0] = 0;rules[98][0][0][1] = 1;rules[98][0][1][0] = 0;rules[98][0][1][1] = 0;rules[98][1][0][0] = 0;rules[98][1][0][1] = 1;rules[98][1][1][0] = 1;rules[98][1][1][1] = 0;
rules[99][0][0][0] = 1;rules[99][0][0][1] = 1;rules[99][0][1][0] = 0;rules[99][0][1][1] = 0;rules[99][1][0][0] = 0;rules[99][1][0][1] = 1;rules[99][1][1][0] = 1;rules[99][1][1][1] = 0;
rules[100][0][0][0] = 0;rules[100][0][0][1] = 0;rules[100][0][1][0] = 1;rules[100][0][1][1] = 0;rules[100][1][0][0] = 0;rules[100][1][0][1] = 1;rules[100][1][1][0] = 1;rules[100][1][1][1] = 0;
rules[101][0][0][0] = 1;rules[101][0][0][1] = 0;rules[101][0][1][0] = 1;rules[101][0][1][1] = 0;rules[101][1][0][0] = 0;rules[101][1][0][1] = 1;rules[101][1][1][0] = 1;rules[101][1][1][1] = 0;
rules[102][0][0][0] = 0;rules[102][0][0][1] = 1;rules[102][0][1][0] = 1;rules[102][0][1][1] = 0;rules[102][1][0][0] = 0;rules[102][1][0][1] = 1;rules[102][1][1][0] = 1;rules[102][1][1][1] = 0;
rules[103][0][0][0] = 1;rules[103][0][0][1] = 1;rules[103][0][1][0] = 1;rules[103][0][1][1] = 0;rules[103][1][0][0] = 0;rules[103][1][0][1] = 1;rules[103][1][1][0] = 1;rules[103][1][1][1] = 0;
rules[104][0][0][0] = 0;rules[104][0][0][1] = 0;rules[104][0][1][0] = 0;rules[104][0][1][1] = 1;rules[104][1][0][0] = 0;rules[104][1][0][1] = 1;rules[104][1][1][0] = 1;rules[104][1][1][1] = 0;
rules[105][0][0][0] = 1;rules[105][0][0][1] = 0;rules[105][0][1][0] = 0;rules[105][0][1][1] = 1;rules[105][1][0][0] = 0;rules[105][1][0][1] = 1;rules[105][1][1][0] = 1;rules[105][1][1][1] = 0;
rules[106][0][0][0] = 0;rules[106][0][0][1] = 1;rules[106][0][1][0] = 0;rules[106][0][1][1] = 1;rules[106][1][0][0] = 0;rules[106][1][0][1] = 1;rules[106][1][1][0] = 1;rules[106][1][1][1] = 0;
rules[107][0][0][0] = 1;rules[107][0][0][1] = 1;rules[107][0][1][0] = 0;rules[107][0][1][1] = 1;rules[107][1][0][0] = 0;rules[107][1][0][1] = 1;rules[107][1][1][0] = 1;rules[107][1][1][1] = 0;
rules[108][0][0][0] = 0;rules[108][0][0][1] = 0;rules[108][0][1][0] = 1;rules[108][0][1][1] = 1;rules[108][1][0][0] = 0;rules[108][1][0][1] = 1;rules[108][1][1][0] = 1;rules[108][1][1][1] = 0;
rules[109][0][0][0] = 1;rules[109][0][0][1] = 0;rules[109][0][1][0] = 1;rules[109][0][1][1] = 1;rules[109][1][0][0] = 0;rules[109][1][0][1] = 1;rules[109][1][1][0] = 1;rules[109][1][1][1] = 0;
rules[110][0][0][0] = 0;rules[110][0][0][1] = 1;rules[110][0][1][0] = 1;rules[110][0][1][1] = 1;rules[110][1][0][0] = 0;rules[110][1][0][1] = 1;rules[110][1][1][0] = 1;rules[110][1][1][1] = 0;
rules[111][0][0][0] = 1;rules[111][0][0][1] = 1;rules[111][0][1][0] = 1;rules[111][0][1][1] = 1;rules[111][1][0][0] = 0;rules[111][1][0][1] = 1;rules[111][1][1][0] = 1;rules[111][1][1][1] = 0;
rules[112][0][0][0] = 0;rules[112][0][0][1] = 0;rules[112][0][1][0] = 0;rules[112][0][1][1] = 0;rules[112][1][0][0] = 1;rules[112][1][0][1] = 1;rules[112][1][1][0] = 1;rules[112][1][1][1] = 0;
rules[113][0][0][0] = 1;rules[113][0][0][1] = 0;rules[113][0][1][0] = 0;rules[113][0][1][1] = 0;rules[113][1][0][0] = 1;rules[113][1][0][1] = 1;rules[113][1][1][0] = 1;rules[113][1][1][1] = 0;
rules[114][0][0][0] = 0;rules[114][0][0][1] = 1;rules[114][0][1][0] = 0;rules[114][0][1][1] = 0;rules[114][1][0][0] = 1;rules[114][1][0][1] = 1;rules[114][1][1][0] = 1;rules[114][1][1][1] = 0;
rules[115][0][0][0] = 1;rules[115][0][0][1] = 1;rules[115][0][1][0] = 0;rules[115][0][1][1] = 0;rules[115][1][0][0] = 1;rules[115][1][0][1] = 1;rules[115][1][1][0] = 1;rules[115][1][1][1] = 0;
rules[116][0][0][0] = 0;rules[116][0][0][1] = 0;rules[116][0][1][0] = 1;rules[116][0][1][1] = 0;rules[116][1][0][0] = 1;rules[116][1][0][1] = 1;rules[116][1][1][0] = 1;rules[116][1][1][1] = 0;
rules[117][0][0][0] = 1;rules[117][0][0][1] = 0;rules[117][0][1][0] = 1;rules[117][0][1][1] = 0;rules[117][1][0][0] = 1;rules[117][1][0][1] = 1;rules[117][1][1][0] = 1;rules[117][1][1][1] = 0;
rules[118][0][0][0] = 0;rules[118][0][0][1] = 1;rules[118][0][1][0] = 1;rules[118][0][1][1] = 0;rules[118][1][0][0] = 1;rules[118][1][0][1] = 1;rules[118][1][1][0] = 1;rules[118][1][1][1] = 0;
rules[119][0][0][0] = 1;rules[119][0][0][1] = 1;rules[119][0][1][0] = 1;rules[119][0][1][1] = 0;rules[119][1][0][0] = 1;rules[119][1][0][1] = 1;rules[119][1][1][0] = 1;rules[119][1][1][1] = 0;
rules[120][0][0][0] = 0;rules[120][0][0][1] = 0;rules[120][0][1][0] = 0;rules[120][0][1][1] = 1;rules[120][1][0][0] = 1;rules[120][1][0][1] = 1;rules[120][1][1][0] = 1;rules[120][1][1][1] = 0;
rules[121][0][0][0] = 1;rules[121][0][0][1] = 0;rules[121][0][1][0] = 0;rules[121][0][1][1] = 1;rules[121][1][0][0] = 1;rules[121][1][0][1] = 1;rules[121][1][1][0] = 1;rules[121][1][1][1] = 0;
rules[122][0][0][0] = 0;rules[122][0][0][1] = 1;rules[122][0][1][0] = 0;rules[122][0][1][1] = 1;rules[122][1][0][0] = 1;rules[122][1][0][1] = 1;rules[122][1][1][0] = 1;rules[122][1][1][1] = 0;
rules[123][0][0][0] = 1;rules[123][0][0][1] = 1;rules[123][0][1][0] = 0;rules[123][0][1][1] = 1;rules[123][1][0][0] = 1;rules[123][1][0][1] = 1;rules[123][1][1][0] = 1;rules[123][1][1][1] = 0;
rules[124][0][0][0] = 0;rules[124][0][0][1] = 0;rules[124][0][1][0] = 1;rules[124][0][1][1] = 1;rules[124][1][0][0] = 1;rules[124][1][0][1] = 1;rules[124][1][1][0] = 1;rules[124][1][1][1] = 0;
rules[125][0][0][0] = 1;rules[125][0][0][1] = 0;rules[125][0][1][0] = 1;rules[125][0][1][1] = 1;rules[125][1][0][0] = 1;rules[125][1][0][1] = 1;rules[125][1][1][0] = 1;rules[125][1][1][1] = 0;
rules[126][0][0][0] = 0;rules[126][0][0][1] = 1;rules[126][0][1][0] = 1;rules[126][0][1][1] = 1;rules[126][1][0][0] = 1;rules[126][1][0][1] = 1;rules[126][1][1][0] = 1;rules[126][1][1][1] = 0;
rules[127][0][0][0] = 1;rules[127][0][0][1] = 1;rules[127][0][1][0] = 1;rules[127][0][1][1] = 1;rules[127][1][0][0] = 1;rules[127][1][0][1] = 1;rules[127][1][1][0] = 1;rules[127][1][1][1] = 0;
rules[128][0][0][0] = 0;rules[128][0][0][1] = 0;rules[128][0][1][0] = 0;rules[128][0][1][1] = 0;rules[128][1][0][0] = 0;rules[128][1][0][1] = 0;rules[128][1][1][0] = 0;rules[128][1][1][1] = 1;
rules[129][0][0][0] = 1;rules[129][0][0][1] = 0;rules[129][0][1][0] = 0;rules[129][0][1][1] = 0;rules[129][1][0][0] = 0;rules[129][1][0][1] = 0;rules[129][1][1][0] = 0;rules[129][1][1][1] = 1;
rules[130][0][0][0] = 0;rules[130][0][0][1] = 1;rules[130][0][1][0] = 0;rules[130][0][1][1] = 0;rules[130][1][0][0] = 0;rules[130][1][0][1] = 0;rules[130][1][1][0] = 0;rules[130][1][1][1] = 1;
rules[131][0][0][0] = 1;rules[131][0][0][1] = 1;rules[131][0][1][0] = 0;rules[131][0][1][1] = 0;rules[131][1][0][0] = 0;rules[131][1][0][1] = 0;rules[131][1][1][0] = 0;rules[131][1][1][1] = 1;
rules[132][0][0][0] = 0;rules[132][0][0][1] = 0;rules[132][0][1][0] = 1;rules[132][0][1][1] = 0;rules[132][1][0][0] = 0;rules[132][1][0][1] = 0;rules[132][1][1][0] = 0;rules[132][1][1][1] = 1;
rules[133][0][0][0] = 1;rules[133][0][0][1] = 0;rules[133][0][1][0] = 1;rules[133][0][1][1] = 0;rules[133][1][0][0] = 0;rules[133][1][0][1] = 0;rules[133][1][1][0] = 0;rules[133][1][1][1] = 1;
rules[134][0][0][0] = 0;rules[134][0][0][1] = 1;rules[134][0][1][0] = 1;rules[134][0][1][1] = 0;rules[134][1][0][0] = 0;rules[134][1][0][1] = 0;rules[134][1][1][0] = 0;rules[134][1][1][1] = 1;
rules[135][0][0][0] = 1;rules[135][0][0][1] = 1;rules[135][0][1][0] = 1;rules[135][0][1][1] = 0;rules[135][1][0][0] = 0;rules[135][1][0][1] = 0;rules[135][1][1][0] = 0;rules[135][1][1][1] = 1;
rules[136][0][0][0] = 0;rules[136][0][0][1] = 0;rules[136][0][1][0] = 0;rules[136][0][1][1] = 1;rules[136][1][0][0] = 0;rules[136][1][0][1] = 0;rules[136][1][1][0] = 0;rules[136][1][1][1] = 1;
rules[137][0][0][0] = 1;rules[137][0][0][1] = 0;rules[137][0][1][0] = 0;rules[137][0][1][1] = 1;rules[137][1][0][0] = 0;rules[137][1][0][1] = 0;rules[137][1][1][0] = 0;rules[137][1][1][1] = 1;
rules[138][0][0][0] = 0;rules[138][0][0][1] = 1;rules[138][0][1][0] = 0;rules[138][0][1][1] = 1;rules[138][1][0][0] = 0;rules[138][1][0][1] = 0;rules[138][1][1][0] = 0;rules[138][1][1][1] = 1;
rules[139][0][0][0] = 1;rules[139][0][0][1] = 1;rules[139][0][1][0] = 0;rules[139][0][1][1] = 1;rules[139][1][0][0] = 0;rules[139][1][0][1] = 0;rules[139][1][1][0] = 0;rules[139][1][1][1] = 1;
rules[140][0][0][0] = 0;rules[140][0][0][1] = 0;rules[140][0][1][0] = 1;rules[140][0][1][1] = 1;rules[140][1][0][0] = 0;rules[140][1][0][1] = 0;rules[140][1][1][0] = 0;rules[140][1][1][1] = 1;
rules[141][0][0][0] = 1;rules[141][0][0][1] = 0;rules[141][0][1][0] = 1;rules[141][0][1][1] = 1;rules[141][1][0][0] = 0;rules[141][1][0][1] = 0;rules[141][1][1][0] = 0;rules[141][1][1][1] = 1;
rules[142][0][0][0] = 0;rules[142][0][0][1] = 1;rules[142][0][1][0] = 1;rules[142][0][1][1] = 1;rules[142][1][0][0] = 0;rules[142][1][0][1] = 0;rules[142][1][1][0] = 0;rules[142][1][1][1] = 1;
rules[143][0][0][0] = 1;rules[143][0][0][1] = 1;rules[143][0][1][0] = 1;rules[143][0][1][1] = 1;rules[143][1][0][0] = 0;rules[143][1][0][1] = 0;rules[143][1][1][0] = 0;rules[143][1][1][1] = 1;
rules[144][0][0][0] = 0;rules[144][0][0][1] = 0;rules[144][0][1][0] = 0;rules[144][0][1][1] = 0;rules[144][1][0][0] = 1;rules[144][1][0][1] = 0;rules[144][1][1][0] = 0;rules[144][1][1][1] = 1;
rules[145][0][0][0] = 1;rules[145][0][0][1] = 0;rules[145][0][1][0] = 0;rules[145][0][1][1] = 0;rules[145][1][0][0] = 1;rules[145][1][0][1] = 0;rules[145][1][1][0] = 0;rules[145][1][1][1] = 1;
rules[146][0][0][0] = 0;rules[146][0][0][1] = 1;rules[146][0][1][0] = 0;rules[146][0][1][1] = 0;rules[146][1][0][0] = 1;rules[146][1][0][1] = 0;rules[146][1][1][0] = 0;rules[146][1][1][1] = 1;
rules[147][0][0][0] = 1;rules[147][0][0][1] = 1;rules[147][0][1][0] = 0;rules[147][0][1][1] = 0;rules[147][1][0][0] = 1;rules[147][1][0][1] = 0;rules[147][1][1][0] = 0;rules[147][1][1][1] = 1;
rules[148][0][0][0] = 0;rules[148][0][0][1] = 0;rules[148][0][1][0] = 1;rules[148][0][1][1] = 0;rules[148][1][0][0] = 1;rules[148][1][0][1] = 0;rules[148][1][1][0] = 0;rules[148][1][1][1] = 1;
rules[149][0][0][0] = 1;rules[149][0][0][1] = 0;rules[149][0][1][0] = 1;rules[149][0][1][1] = 0;rules[149][1][0][0] = 1;rules[149][1][0][1] = 0;rules[149][1][1][0] = 0;rules[149][1][1][1] = 1;
rules[150][0][0][0] = 0;rules[150][0][0][1] = 1;rules[150][0][1][0] = 1;rules[150][0][1][1] = 0;rules[150][1][0][0] = 1;rules[150][1][0][1] = 0;rules[150][1][1][0] = 0;rules[150][1][1][1] = 1;
rules[151][0][0][0] = 1;rules[151][0][0][1] = 1;rules[151][0][1][0] = 1;rules[151][0][1][1] = 0;rules[151][1][0][0] = 1;rules[151][1][0][1] = 0;rules[151][1][1][0] = 0;rules[151][1][1][1] = 1;
rules[152][0][0][0] = 0;rules[152][0][0][1] = 0;rules[152][0][1][0] = 0;rules[152][0][1][1] = 1;rules[152][1][0][0] = 1;rules[152][1][0][1] = 0;rules[152][1][1][0] = 0;rules[152][1][1][1] = 1;
rules[153][0][0][0] = 1;rules[153][0][0][1] = 0;rules[153][0][1][0] = 0;rules[153][0][1][1] = 1;rules[153][1][0][0] = 1;rules[153][1][0][1] = 0;rules[153][1][1][0] = 0;rules[153][1][1][1] = 1;
rules[154][0][0][0] = 0;rules[154][0][0][1] = 1;rules[154][0][1][0] = 0;rules[154][0][1][1] = 1;rules[154][1][0][0] = 1;rules[154][1][0][1] = 0;rules[154][1][1][0] = 0;rules[154][1][1][1] = 1;
rules[155][0][0][0] = 1;rules[155][0][0][1] = 1;rules[155][0][1][0] = 0;rules[155][0][1][1] = 1;rules[155][1][0][0] = 1;rules[155][1][0][1] = 0;rules[155][1][1][0] = 0;rules[155][1][1][1] = 1;
rules[156][0][0][0] = 0;rules[156][0][0][1] = 0;rules[156][0][1][0] = 1;rules[156][0][1][1] = 1;rules[156][1][0][0] = 1;rules[156][1][0][1] = 0;rules[156][1][1][0] = 0;rules[156][1][1][1] = 1;
rules[157][0][0][0] = 1;rules[157][0][0][1] = 0;rules[157][0][1][0] = 1;rules[157][0][1][1] = 1;rules[157][1][0][0] = 1;rules[157][1][0][1] = 0;rules[157][1][1][0] = 0;rules[157][1][1][1] = 1;
rules[158][0][0][0] = 0;rules[158][0][0][1] = 1;rules[158][0][1][0] = 1;rules[158][0][1][1] = 1;rules[158][1][0][0] = 1;rules[158][1][0][1] = 0;rules[158][1][1][0] = 0;rules[158][1][1][1] = 1;
rules[159][0][0][0] = 1;rules[159][0][0][1] = 1;rules[159][0][1][0] = 1;rules[159][0][1][1] = 1;rules[159][1][0][0] = 1;rules[159][1][0][1] = 0;rules[159][1][1][0] = 0;rules[159][1][1][1] = 1;
rules[160][0][0][0] = 0;rules[160][0][0][1] = 0;rules[160][0][1][0] = 0;rules[160][0][1][1] = 0;rules[160][1][0][0] = 0;rules[160][1][0][1] = 1;rules[160][1][1][0] = 0;rules[160][1][1][1] = 1;
rules[161][0][0][0] = 1;rules[161][0][0][1] = 0;rules[161][0][1][0] = 0;rules[161][0][1][1] = 0;rules[161][1][0][0] = 0;rules[161][1][0][1] = 1;rules[161][1][1][0] = 0;rules[161][1][1][1] = 1;
rules[162][0][0][0] = 0;rules[162][0][0][1] = 1;rules[162][0][1][0] = 0;rules[162][0][1][1] = 0;rules[162][1][0][0] = 0;rules[162][1][0][1] = 1;rules[162][1][1][0] = 0;rules[162][1][1][1] = 1;
rules[163][0][0][0] = 1;rules[163][0][0][1] = 1;rules[163][0][1][0] = 0;rules[163][0][1][1] = 0;rules[163][1][0][0] = 0;rules[163][1][0][1] = 1;rules[163][1][1][0] = 0;rules[163][1][1][1] = 1;
rules[164][0][0][0] = 0;rules[164][0][0][1] = 0;rules[164][0][1][0] = 1;rules[164][0][1][1] = 0;rules[164][1][0][0] = 0;rules[164][1][0][1] = 1;rules[164][1][1][0] = 0;rules[164][1][1][1] = 1;
rules[165][0][0][0] = 1;rules[165][0][0][1] = 0;rules[165][0][1][0] = 1;rules[165][0][1][1] = 0;rules[165][1][0][0] = 0;rules[165][1][0][1] = 1;rules[165][1][1][0] = 0;rules[165][1][1][1] = 1;
rules[166][0][0][0] = 0;rules[166][0][0][1] = 1;rules[166][0][1][0] = 1;rules[166][0][1][1] = 0;rules[166][1][0][0] = 0;rules[166][1][0][1] = 1;rules[166][1][1][0] = 0;rules[166][1][1][1] = 1;
rules[167][0][0][0] = 1;rules[167][0][0][1] = 1;rules[167][0][1][0] = 1;rules[167][0][1][1] = 0;rules[167][1][0][0] = 0;rules[167][1][0][1] = 1;rules[167][1][1][0] = 0;rules[167][1][1][1] = 1;
rules[168][0][0][0] = 0;rules[168][0][0][1] = 0;rules[168][0][1][0] = 0;rules[168][0][1][1] = 1;rules[168][1][0][0] = 0;rules[168][1][0][1] = 1;rules[168][1][1][0] = 0;rules[168][1][1][1] = 1;
rules[169][0][0][0] = 1;rules[169][0][0][1] = 0;rules[169][0][1][0] = 0;rules[169][0][1][1] = 1;rules[169][1][0][0] = 0;rules[169][1][0][1] = 1;rules[169][1][1][0] = 0;rules[169][1][1][1] = 1;
rules[170][0][0][0] = 0;rules[170][0][0][1] = 1;rules[170][0][1][0] = 0;rules[170][0][1][1] = 1;rules[170][1][0][0] = 0;rules[170][1][0][1] = 1;rules[170][1][1][0] = 0;rules[170][1][1][1] = 1;
rules[171][0][0][0] = 1;rules[171][0][0][1] = 1;rules[171][0][1][0] = 0;rules[171][0][1][1] = 1;rules[171][1][0][0] = 0;rules[171][1][0][1] = 1;rules[171][1][1][0] = 0;rules[171][1][1][1] = 1;
rules[172][0][0][0] = 0;rules[172][0][0][1] = 0;rules[172][0][1][0] = 1;rules[172][0][1][1] = 1;rules[172][1][0][0] = 0;rules[172][1][0][1] = 1;rules[172][1][1][0] = 0;rules[172][1][1][1] = 1;
rules[173][0][0][0] = 1;rules[173][0][0][1] = 0;rules[173][0][1][0] = 1;rules[173][0][1][1] = 1;rules[173][1][0][0] = 0;rules[173][1][0][1] = 1;rules[173][1][1][0] = 0;rules[173][1][1][1] = 1;
rules[174][0][0][0] = 0;rules[174][0][0][1] = 1;rules[174][0][1][0] = 1;rules[174][0][1][1] = 1;rules[174][1][0][0] = 0;rules[174][1][0][1] = 1;rules[174][1][1][0] = 0;rules[174][1][1][1] = 1;
rules[175][0][0][0] = 1;rules[175][0][0][1] = 1;rules[175][0][1][0] = 1;rules[175][0][1][1] = 1;rules[175][1][0][0] = 0;rules[175][1][0][1] = 1;rules[175][1][1][0] = 0;rules[175][1][1][1] = 1;
rules[176][0][0][0] = 0;rules[176][0][0][1] = 0;rules[176][0][1][0] = 0;rules[176][0][1][1] = 0;rules[176][1][0][0] = 1;rules[176][1][0][1] = 1;rules[176][1][1][0] = 0;rules[176][1][1][1] = 1;
rules[177][0][0][0] = 1;rules[177][0][0][1] = 0;rules[177][0][1][0] = 0;rules[177][0][1][1] = 0;rules[177][1][0][0] = 1;rules[177][1][0][1] = 1;rules[177][1][1][0] = 0;rules[177][1][1][1] = 1;
rules[178][0][0][0] = 0;rules[178][0][0][1] = 1;rules[178][0][1][0] = 0;rules[178][0][1][1] = 0;rules[178][1][0][0] = 1;rules[178][1][0][1] = 1;rules[178][1][1][0] = 0;rules[178][1][1][1] = 1;
rules[179][0][0][0] = 1;rules[179][0][0][1] = 1;rules[179][0][1][0] = 0;rules[179][0][1][1] = 0;rules[179][1][0][0] = 1;rules[179][1][0][1] = 1;rules[179][1][1][0] = 0;rules[179][1][1][1] = 1;
rules[180][0][0][0] = 0;rules[180][0][0][1] = 0;rules[180][0][1][0] = 1;rules[180][0][1][1] = 0;rules[180][1][0][0] = 1;rules[180][1][0][1] = 1;rules[180][1][1][0] = 0;rules[180][1][1][1] = 1;
rules[181][0][0][0] = 1;rules[181][0][0][1] = 0;rules[181][0][1][0] = 1;rules[181][0][1][1] = 0;rules[181][1][0][0] = 1;rules[181][1][0][1] = 1;rules[181][1][1][0] = 0;rules[181][1][1][1] = 1;
rules[182][0][0][0] = 0;rules[182][0][0][1] = 1;rules[182][0][1][0] = 1;rules[182][0][1][1] = 0;rules[182][1][0][0] = 1;rules[182][1][0][1] = 1;rules[182][1][1][0] = 0;rules[182][1][1][1] = 1;
rules[183][0][0][0] = 1;rules[183][0][0][1] = 1;rules[183][0][1][0] = 1;rules[183][0][1][1] = 0;rules[183][1][0][0] = 1;rules[183][1][0][1] = 1;rules[183][1][1][0] = 0;rules[183][1][1][1] = 1;
rules[184][0][0][0] = 0;rules[184][0][0][1] = 0;rules[184][0][1][0] = 0;rules[184][0][1][1] = 1;rules[184][1][0][0] = 1;rules[184][1][0][1] = 1;rules[184][1][1][0] = 0;rules[184][1][1][1] = 1;
rules[185][0][0][0] = 1;rules[185][0][0][1] = 0;rules[185][0][1][0] = 0;rules[185][0][1][1] = 1;rules[185][1][0][0] = 1;rules[185][1][0][1] = 1;rules[185][1][1][0] = 0;rules[185][1][1][1] = 1;
rules[186][0][0][0] = 0;rules[186][0][0][1] = 1;rules[186][0][1][0] = 0;rules[186][0][1][1] = 1;rules[186][1][0][0] = 1;rules[186][1][0][1] = 1;rules[186][1][1][0] = 0;rules[186][1][1][1] = 1;
rules[187][0][0][0] = 1;rules[187][0][0][1] = 1;rules[187][0][1][0] = 0;rules[187][0][1][1] = 1;rules[187][1][0][0] = 1;rules[187][1][0][1] = 1;rules[187][1][1][0] = 0;rules[187][1][1][1] = 1;
rules[188][0][0][0] = 0;rules[188][0][0][1] = 0;rules[188][0][1][0] = 1;rules[188][0][1][1] = 1;rules[188][1][0][0] = 1;rules[188][1][0][1] = 1;rules[188][1][1][0] = 0;rules[188][1][1][1] = 1;
rules[189][0][0][0] = 1;rules[189][0][0][1] = 0;rules[189][0][1][0] = 1;rules[189][0][1][1] = 1;rules[189][1][0][0] = 1;rules[189][1][0][1] = 1;rules[189][1][1][0] = 0;rules[189][1][1][1] = 1;
rules[190][0][0][0] = 0;rules[190][0][0][1] = 1;rules[190][0][1][0] = 1;rules[190][0][1][1] = 1;rules[190][1][0][0] = 1;rules[190][1][0][1] = 1;rules[190][1][1][0] = 0;rules[190][1][1][1] = 1;
rules[191][0][0][0] = 1;rules[191][0][0][1] = 1;rules[191][0][1][0] = 1;rules[191][0][1][1] = 1;rules[191][1][0][0] = 1;rules[191][1][0][1] = 1;rules[191][1][1][0] = 0;rules[191][1][1][1] = 1;
rules[192][0][0][0] = 0;rules[192][0][0][1] = 0;rules[192][0][1][0] = 0;rules[192][0][1][1] = 0;rules[192][1][0][0] = 0;rules[192][1][0][1] = 0;rules[192][1][1][0] = 1;rules[192][1][1][1] = 1;
rules[193][0][0][0] = 1;rules[193][0][0][1] = 0;rules[193][0][1][0] = 0;rules[193][0][1][1] = 0;rules[193][1][0][0] = 0;rules[193][1][0][1] = 0;rules[193][1][1][0] = 1;rules[193][1][1][1] = 1;
rules[194][0][0][0] = 0;rules[194][0][0][1] = 1;rules[194][0][1][0] = 0;rules[194][0][1][1] = 0;rules[194][1][0][0] = 0;rules[194][1][0][1] = 0;rules[194][1][1][0] = 1;rules[194][1][1][1] = 1;
rules[195][0][0][0] = 1;rules[195][0][0][1] = 1;rules[195][0][1][0] = 0;rules[195][0][1][1] = 0;rules[195][1][0][0] = 0;rules[195][1][0][1] = 0;rules[195][1][1][0] = 1;rules[195][1][1][1] = 1;
rules[196][0][0][0] = 0;rules[196][0][0][1] = 0;rules[196][0][1][0] = 1;rules[196][0][1][1] = 0;rules[196][1][0][0] = 0;rules[196][1][0][1] = 0;rules[196][1][1][0] = 1;rules[196][1][1][1] = 1;
rules[197][0][0][0] = 1;rules[197][0][0][1] = 0;rules[197][0][1][0] = 1;rules[197][0][1][1] = 0;rules[197][1][0][0] = 0;rules[197][1][0][1] = 0;rules[197][1][1][0] = 1;rules[197][1][1][1] = 1;
rules[198][0][0][0] = 0;rules[198][0][0][1] = 1;rules[198][0][1][0] = 1;rules[198][0][1][1] = 0;rules[198][1][0][0] = 0;rules[198][1][0][1] = 0;rules[198][1][1][0] = 1;rules[198][1][1][1] = 1;
rules[199][0][0][0] = 1;rules[199][0][0][1] = 1;rules[199][0][1][0] = 1;rules[199][0][1][1] = 0;rules[199][1][0][0] = 0;rules[199][1][0][1] = 0;rules[199][1][1][0] = 1;rules[199][1][1][1] = 1;
rules[200][0][0][0] = 0;rules[200][0][0][1] = 0;rules[200][0][1][0] = 0;rules[200][0][1][1] = 1;rules[200][1][0][0] = 0;rules[200][1][0][1] = 0;rules[200][1][1][0] = 1;rules[200][1][1][1] = 1;
rules[201][0][0][0] = 1;rules[201][0][0][1] = 0;rules[201][0][1][0] = 0;rules[201][0][1][1] = 1;rules[201][1][0][0] = 0;rules[201][1][0][1] = 0;rules[201][1][1][0] = 1;rules[201][1][1][1] = 1;
rules[202][0][0][0] = 0;rules[202][0][0][1] = 1;rules[202][0][1][0] = 0;rules[202][0][1][1] = 1;rules[202][1][0][0] = 0;rules[202][1][0][1] = 0;rules[202][1][1][0] = 1;rules[202][1][1][1] = 1;
rules[203][0][0][0] = 1;rules[203][0][0][1] = 1;rules[203][0][1][0] = 0;rules[203][0][1][1] = 1;rules[203][1][0][0] = 0;rules[203][1][0][1] = 0;rules[203][1][1][0] = 1;rules[203][1][1][1] = 1;
rules[204][0][0][0] = 0;rules[204][0][0][1] = 0;rules[204][0][1][0] = 1;rules[204][0][1][1] = 1;rules[204][1][0][0] = 0;rules[204][1][0][1] = 0;rules[204][1][1][0] = 1;rules[204][1][1][1] = 1;
rules[205][0][0][0] = 1;rules[205][0][0][1] = 0;rules[205][0][1][0] = 1;rules[205][0][1][1] = 1;rules[205][1][0][0] = 0;rules[205][1][0][1] = 0;rules[205][1][1][0] = 1;rules[205][1][1][1] = 1;
rules[206][0][0][0] = 0;rules[206][0][0][1] = 1;rules[206][0][1][0] = 1;rules[206][0][1][1] = 1;rules[206][1][0][0] = 0;rules[206][1][0][1] = 0;rules[206][1][1][0] = 1;rules[206][1][1][1] = 1;
rules[207][0][0][0] = 1;rules[207][0][0][1] = 1;rules[207][0][1][0] = 1;rules[207][0][1][1] = 1;rules[207][1][0][0] = 0;rules[207][1][0][1] = 0;rules[207][1][1][0] = 1;rules[207][1][1][1] = 1;
rules[208][0][0][0] = 0;rules[208][0][0][1] = 0;rules[208][0][1][0] = 0;rules[208][0][1][1] = 0;rules[208][1][0][0] = 1;rules[208][1][0][1] = 0;rules[208][1][1][0] = 1;rules[208][1][1][1] = 1;
rules[209][0][0][0] = 1;rules[209][0][0][1] = 0;rules[209][0][1][0] = 0;rules[209][0][1][1] = 0;rules[209][1][0][0] = 1;rules[209][1][0][1] = 0;rules[209][1][1][0] = 1;rules[209][1][1][1] = 1;
rules[210][0][0][0] = 0;rules[210][0][0][1] = 1;rules[210][0][1][0] = 0;rules[210][0][1][1] = 0;rules[210][1][0][0] = 1;rules[210][1][0][1] = 0;rules[210][1][1][0] = 1;rules[210][1][1][1] = 1;
rules[211][0][0][0] = 1;rules[211][0][0][1] = 1;rules[211][0][1][0] = 0;rules[211][0][1][1] = 0;rules[211][1][0][0] = 1;rules[211][1][0][1] = 0;rules[211][1][1][0] = 1;rules[211][1][1][1] = 1;
rules[212][0][0][0] = 0;rules[212][0][0][1] = 0;rules[212][0][1][0] = 1;rules[212][0][1][1] = 0;rules[212][1][0][0] = 1;rules[212][1][0][1] = 0;rules[212][1][1][0] = 1;rules[212][1][1][1] = 1;
rules[213][0][0][0] = 1;rules[213][0][0][1] = 0;rules[213][0][1][0] = 1;rules[213][0][1][1] = 0;rules[213][1][0][0] = 1;rules[213][1][0][1] = 0;rules[213][1][1][0] = 1;rules[213][1][1][1] = 1;
rules[214][0][0][0] = 0;rules[214][0][0][1] = 1;rules[214][0][1][0] = 1;rules[214][0][1][1] = 0;rules[214][1][0][0] = 1;rules[214][1][0][1] = 0;rules[214][1][1][0] = 1;rules[214][1][1][1] = 1;
rules[215][0][0][0] = 1;rules[215][0][0][1] = 1;rules[215][0][1][0] = 1;rules[215][0][1][1] = 0;rules[215][1][0][0] = 1;rules[215][1][0][1] = 0;rules[215][1][1][0] = 1;rules[215][1][1][1] = 1;
rules[216][0][0][0] = 0;rules[216][0][0][1] = 0;rules[216][0][1][0] = 0;rules[216][0][1][1] = 1;rules[216][1][0][0] = 1;rules[216][1][0][1] = 0;rules[216][1][1][0] = 1;rules[216][1][1][1] = 1;
rules[217][0][0][0] = 1;rules[217][0][0][1] = 0;rules[217][0][1][0] = 0;rules[217][0][1][1] = 1;rules[217][1][0][0] = 1;rules[217][1][0][1] = 0;rules[217][1][1][0] = 1;rules[217][1][1][1] = 1;
rules[218][0][0][0] = 0;rules[218][0][0][1] = 1;rules[218][0][1][0] = 0;rules[218][0][1][1] = 1;rules[218][1][0][0] = 1;rules[218][1][0][1] = 0;rules[218][1][1][0] = 1;rules[218][1][1][1] = 1;
rules[219][0][0][0] = 1;rules[219][0][0][1] = 1;rules[219][0][1][0] = 0;rules[219][0][1][1] = 1;rules[219][1][0][0] = 1;rules[219][1][0][1] = 0;rules[219][1][1][0] = 1;rules[219][1][1][1] = 1;
rules[220][0][0][0] = 0;rules[220][0][0][1] = 0;rules[220][0][1][0] = 1;rules[220][0][1][1] = 1;rules[220][1][0][0] = 1;rules[220][1][0][1] = 0;rules[220][1][1][0] = 1;rules[220][1][1][1] = 1;
rules[221][0][0][0] = 1;rules[221][0][0][1] = 0;rules[221][0][1][0] = 1;rules[221][0][1][1] = 1;rules[221][1][0][0] = 1;rules[221][1][0][1] = 0;rules[221][1][1][0] = 1;rules[221][1][1][1] = 1;
rules[222][0][0][0] = 0;rules[222][0][0][1] = 1;rules[222][0][1][0] = 1;rules[222][0][1][1] = 1;rules[222][1][0][0] = 1;rules[222][1][0][1] = 0;rules[222][1][1][0] = 1;rules[222][1][1][1] = 1;
rules[223][0][0][0] = 1;rules[223][0][0][1] = 1;rules[223][0][1][0] = 1;rules[223][0][1][1] = 1;rules[223][1][0][0] = 1;rules[223][1][0][1] = 0;rules[223][1][1][0] = 1;rules[223][1][1][1] = 1;
rules[224][0][0][0] = 0;rules[224][0][0][1] = 0;rules[224][0][1][0] = 0;rules[224][0][1][1] = 0;rules[224][1][0][0] = 0;rules[224][1][0][1] = 1;rules[224][1][1][0] = 1;rules[224][1][1][1] = 1;
rules[225][0][0][0] = 1;rules[225][0][0][1] = 0;rules[225][0][1][0] = 0;rules[225][0][1][1] = 0;rules[225][1][0][0] = 0;rules[225][1][0][1] = 1;rules[225][1][1][0] = 1;rules[225][1][1][1] = 1;
rules[226][0][0][0] = 0;rules[226][0][0][1] = 1;rules[226][0][1][0] = 0;rules[226][0][1][1] = 0;rules[226][1][0][0] = 0;rules[226][1][0][1] = 1;rules[226][1][1][0] = 1;rules[226][1][1][1] = 1;
rules[227][0][0][0] = 1;rules[227][0][0][1] = 1;rules[227][0][1][0] = 0;rules[227][0][1][1] = 0;rules[227][1][0][0] = 0;rules[227][1][0][1] = 1;rules[227][1][1][0] = 1;rules[227][1][1][1] = 1;
rules[228][0][0][0] = 0;rules[228][0][0][1] = 0;rules[228][0][1][0] = 1;rules[228][0][1][1] = 0;rules[228][1][0][0] = 0;rules[228][1][0][1] = 1;rules[228][1][1][0] = 1;rules[228][1][1][1] = 1;
rules[229][0][0][0] = 1;rules[229][0][0][1] = 0;rules[229][0][1][0] = 1;rules[229][0][1][1] = 0;rules[229][1][0][0] = 0;rules[229][1][0][1] = 1;rules[229][1][1][0] = 1;rules[229][1][1][1] = 1;
rules[230][0][0][0] = 0;rules[230][0][0][1] = 1;rules[230][0][1][0] = 1;rules[230][0][1][1] = 0;rules[230][1][0][0] = 0;rules[230][1][0][1] = 1;rules[230][1][1][0] = 1;rules[230][1][1][1] = 1;
rules[231][0][0][0] = 1;rules[231][0][0][1] = 1;rules[231][0][1][0] = 1;rules[231][0][1][1] = 0;rules[231][1][0][0] = 0;rules[231][1][0][1] = 1;rules[231][1][1][0] = 1;rules[231][1][1][1] = 1;
rules[232][0][0][0] = 0;rules[232][0][0][1] = 0;rules[232][0][1][0] = 0;rules[232][0][1][1] = 1;rules[232][1][0][0] = 0;rules[232][1][0][1] = 1;rules[232][1][1][0] = 1;rules[232][1][1][1] = 1;
rules[233][0][0][0] = 1;rules[233][0][0][1] = 0;rules[233][0][1][0] = 0;rules[233][0][1][1] = 1;rules[233][1][0][0] = 0;rules[233][1][0][1] = 1;rules[233][1][1][0] = 1;rules[233][1][1][1] = 1;
rules[234][0][0][0] = 0;rules[234][0][0][1] = 1;rules[234][0][1][0] = 0;rules[234][0][1][1] = 1;rules[234][1][0][0] = 0;rules[234][1][0][1] = 1;rules[234][1][1][0] = 1;rules[234][1][1][1] = 1;
rules[235][0][0][0] = 1;rules[235][0][0][1] = 1;rules[235][0][1][0] = 0;rules[235][0][1][1] = 1;rules[235][1][0][0] = 0;rules[235][1][0][1] = 1;rules[235][1][1][0] = 1;rules[235][1][1][1] = 1;
rules[236][0][0][0] = 0;rules[236][0][0][1] = 0;rules[236][0][1][0] = 1;rules[236][0][1][1] = 1;rules[236][1][0][0] = 0;rules[236][1][0][1] = 1;rules[236][1][1][0] = 1;rules[236][1][1][1] = 1;
rules[237][0][0][0] = 1;rules[237][0][0][1] = 0;rules[237][0][1][0] = 1;rules[237][0][1][1] = 1;rules[237][1][0][0] = 0;rules[237][1][0][1] = 1;rules[237][1][1][0] = 1;rules[237][1][1][1] = 1;
rules[238][0][0][0] = 0;rules[238][0][0][1] = 1;rules[238][0][1][0] = 1;rules[238][0][1][1] = 1;rules[238][1][0][0] = 0;rules[238][1][0][1] = 1;rules[238][1][1][0] = 1;rules[238][1][1][1] = 1;
rules[239][0][0][0] = 1;rules[239][0][0][1] = 1;rules[239][0][1][0] = 1;rules[239][0][1][1] = 1;rules[239][1][0][0] = 0;rules[239][1][0][1] = 1;rules[239][1][1][0] = 1;rules[239][1][1][1] = 1;
rules[240][0][0][0] = 0;rules[240][0][0][1] = 0;rules[240][0][1][0] = 0;rules[240][0][1][1] = 0;rules[240][1][0][0] = 1;rules[240][1][0][1] = 1;rules[240][1][1][0] = 1;rules[240][1][1][1] = 1;
rules[241][0][0][0] = 1;rules[241][0][0][1] = 0;rules[241][0][1][0] = 0;rules[241][0][1][1] = 0;rules[241][1][0][0] = 1;rules[241][1][0][1] = 1;rules[241][1][1][0] = 1;rules[241][1][1][1] = 1;
rules[242][0][0][0] = 0;rules[242][0][0][1] = 1;rules[242][0][1][0] = 0;rules[242][0][1][1] = 0;rules[242][1][0][0] = 1;rules[242][1][0][1] = 1;rules[242][1][1][0] = 1;rules[242][1][1][1] = 1;
rules[243][0][0][0] = 1;rules[243][0][0][1] = 1;rules[243][0][1][0] = 0;rules[243][0][1][1] = 0;rules[243][1][0][0] = 1;rules[243][1][0][1] = 1;rules[243][1][1][0] = 1;rules[243][1][1][1] = 1;
rules[244][0][0][0] = 0;rules[244][0][0][1] = 0;rules[244][0][1][0] = 1;rules[244][0][1][1] = 0;rules[244][1][0][0] = 1;rules[244][1][0][1] = 1;rules[244][1][1][0] = 1;rules[244][1][1][1] = 1;
rules[245][0][0][0] = 1;rules[245][0][0][1] = 0;rules[245][0][1][0] = 1;rules[245][0][1][1] = 0;rules[245][1][0][0] = 1;rules[245][1][0][1] = 1;rules[245][1][1][0] = 1;rules[245][1][1][1] = 1;
rules[246][0][0][0] = 0;rules[246][0][0][1] = 1;rules[246][0][1][0] = 1;rules[246][0][1][1] = 0;rules[246][1][0][0] = 1;rules[246][1][0][1] = 1;rules[246][1][1][0] = 1;rules[246][1][1][1] = 1;
rules[247][0][0][0] = 1;rules[247][0][0][1] = 1;rules[247][0][1][0] = 1;rules[247][0][1][1] = 0;rules[247][1][0][0] = 1;rules[247][1][0][1] = 1;rules[247][1][1][0] = 1;rules[247][1][1][1] = 1;
rules[248][0][0][0] = 0;rules[248][0][0][1] = 0;rules[248][0][1][0] = 0;rules[248][0][1][1] = 1;rules[248][1][0][0] = 1;rules[248][1][0][1] = 1;rules[248][1][1][0] = 1;rules[248][1][1][1] = 1;
rules[249][0][0][0] = 1;rules[249][0][0][1] = 0;rules[249][0][1][0] = 0;rules[249][0][1][1] = 1;rules[249][1][0][0] = 1;rules[249][1][0][1] = 1;rules[249][1][1][0] = 1;rules[249][1][1][1] = 1;
rules[250][0][0][0] = 0;rules[250][0][0][1] = 1;rules[250][0][1][0] = 0;rules[250][0][1][1] = 1;rules[250][1][0][0] = 1;rules[250][1][0][1] = 1;rules[250][1][1][0] = 1;rules[250][1][1][1] = 1;
rules[251][0][0][0] = 1;rules[251][0][0][1] = 1;rules[251][0][1][0] = 0;rules[251][0][1][1] = 1;rules[251][1][0][0] = 1;rules[251][1][0][1] = 1;rules[251][1][1][0] = 1;rules[251][1][1][1] = 1;
rules[252][0][0][0] = 0;rules[252][0][0][1] = 0;rules[252][0][1][0] = 1;rules[252][0][1][1] = 1;rules[252][1][0][0] = 1;rules[252][1][0][1] = 1;rules[252][1][1][0] = 1;rules[252][1][1][1] = 1;
rules[253][0][0][0] = 1;rules[253][0][0][1] = 0;rules[253][0][1][0] = 1;rules[253][0][1][1] = 1;rules[253][1][0][0] = 1;rules[253][1][0][1] = 1;rules[253][1][1][0] = 1;rules[253][1][1][1] = 1;
rules[254][0][0][0] = 0;rules[254][0][0][1] = 1;rules[254][0][1][0] = 1;rules[254][0][1][1] = 1;rules[254][1][0][0] = 1;rules[254][1][0][1] = 1;rules[254][1][1][0] = 1;rules[254][1][1][1] = 1;
rules[255][0][0][0] = 1;rules[255][0][0][1] = 1;rules[255][0][1][0] = 1;rules[255][0][1][1] = 1;rules[255][1][0][0] = 1;rules[255][1][0][1] = 1;rules[255][1][1][0] = 1;rules[255][1][1][1] = 1;

  // Cargar un patrón inicial si existe un archivo "pattern.txt"
  loadPatternIfExists();
}

void draw() {
  background(255);

  // Inicializar el tamaño de la cuadrícula en función del número de celdas por lado (filas y columnas)
    cols = int(colsTextField.getText());
    rows = int(rowsTextField.getText());

  if (generateGrid) {
    generateGrid();
    generateGrid = false; // Evita regenerar la cuadrícula en cada frame
    hideGenerateButton = true; // Oculta el botón "Generar" después de generar la cuadrícula
  }

  if (showUI) {
  // Mostrar controles de usuario
  cp5.show();
  colsTextField.show();
  rowsTextField.show();
 
}

  // Dibujar la cuadrícula en cada frame
  displayGrid();

  if (!hideGenerateButton) {
    generateButton.display();
  }
  
 if (automaticMode && currentRow == rows - 2) {
  automaticMode = false;
  lastTime = millis();
  currentRow++;
 }
   
  if (automaticMode) {
      applyRule();
      displayGrid();
      lastTime = millis(); // Actualizar el último tiempo
      currentRow++;
    }
  
  fillRandomButton.display();
  saveConfigButton.display();
  applyRuleButton.display();
  loadPatternButton.display();
   applySizeButton.display();
  
}

void generateGrid() {
  // Ajusta el tamaño de la cuadrícula en función del número de celdas por lado (filas y columnas)
  generation = 1;
  cols = int(cp5.getController("cols").getValue());
  rows = int(cp5.getController("rows").getValue());
  grid = new color[cols][rows]; // Crear una nueva cuadrícula con el tamaño actualizado
  nextGeneration = new int[cols][rows]; // Crear una nueva matriz para la siguiente generación
  currentRow = 0; // Restablecer el número de fila actual cuando se genera una nueva cuadrícula
   // Restablecer los contadores
  resetCounters();
  
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = colorMuerta; // Inicializar todas las celdas como muertas
    }
  }
  // Ocultar selectores de color después de generar la cuadrícula
  colorPickerViva.hide();
  colorPickerMuerta.hide();
}

void displayGrid() {
  int cellSize = int(cp5.getController("cellSize").getValue()); // Obtener el tamaño de celda actual

  

  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      float x = i * cellSize;
      float y = j * cellSize;
      fill(grid[i][j]);
      rect(x, y, cellSize, cellSize);
    }
  }
}

void mousePressed() {
  int i = int(mouseX / int(cp5.getController("cellSize").getValue()));
  int j = int(mouseY / int(cp5.getController("cellSize").getValue()));

  if (i >= 0 && i < cols && j >= 0 && j < rows) {
    // Cambiar el color de la celda al hacer clic
    if (mouseButton == LEFT) {
      grid[i][j] = colorPickerViva.getColorValue(); // Celda viva
    } else if (mouseButton == RIGHT) {
      grid[i][j] = colorPickerMuerta.getColorValue(); // Celda muerta
    }
  }

  // Manejar clics en el botón y los selectores de color
  generateButton.mousePressed();
  fillRandomButton.mousePressed();
  saveConfigButton.mousePressed();
  applyRuleButton.mousePressed();
  loadPatternButton.mousePressed();
}

void loadPatternIfExists() {
  File file = new File("carga.txt"); // Nombre del archivo de patrón
  if (file.exists()) {
    loadPattern();
  }
}

void loadPattern() {
  File file = new File("carga.txt"); // Nombre del archivo de patrón
  BufferedReader reader;
  BufferedWriter writer;
  ArrayList<String> lines = new ArrayList<String>();

  try {
    reader = new BufferedReader(new FileReader(file));
    String line;

    // Lee todas las líneas del archivo
    while ((line = reader.readLine()) != null) {
      lines.add(line);
    }
    reader.close();

    if (lines.size() > 0) {
      // Procesa la primera línea como el patrón a cargar
      String firstLine = lines.get(0);
      String[] values = firstLine.split(",");
      if (values.length == cols) {
        for (int i = 0; i < cols; i++) {
          if (values[i].equals("0")) {
            grid[i][currentRow] = colorMuerta;
          } else if (values[i].equals("1")) {
            grid[i][currentRow] = colorViva;
          } else {
            println("Error: El archivo contiene valores no válidos.");
            return;
          }
        }
        println("Patrón cargado correctamente.");

        // Borra la primera línea del archivo
        lines.remove(0);
        
        // Reescribe el archivo con las líneas restantes
        writer = new BufferedWriter(new FileWriter(file));
        for (String remainingLine : lines) {
          writer.write(remainingLine);
          writer.newLine();
        }
     
        
        writer.close();
      } else {
        println("Error: El archivo no tiene el mismo número de celdas que la cuadrícula.");
      }
    } else {
      println("Error: El archivo está vacío.");
    }
  } catch (IOException e) {
    println("Error al cargar el archivo: " + e.getMessage());
  }
}


class Button {
  float x, y, w, h;
  String label;

  Button(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  }

  void display() {
    fill(200);
    rect(x, y, w, h);
    fill(0);
    textSize(12);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
  }

  boolean isMouseOver() {
    return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }

  void mousePressed() {
    if (isMouseOver() && label.equals("Generar")) {
      generateGrid = true;
      //num();
      hideGenerateButton = true; // Oculta el botón después de hacer clic
    } else if (isMouseOver() && label.equals("Llenar Aleatoriamente")) {
      fillRandomLine();
    } else if (isMouseOver() && label.equals("Guardar Configuración")) {
      saveConfiguration();
    } else if (isMouseOver() && label.equals("Aplicar Regla")) {
      applyRule();
    } else if (isMouseOver() && label.equals("Cargar Patrón")) {
      loadPattern();
    }
  }
}

void fillRandomLine() {
  color colorVivaActual = colorPickerViva.getColorValue(); // Obtener el color actual de celda viva
  color colorMuertaActual = colorPickerMuerta.getColorValue(); // Obtener el color actual de celda muerta

  for (int i = 0; i < cols; i++) {
    float randomValue = random(1); // Generar un valor aleatorio entre 0 y 1
    if (randomValue <= percentageOnes) { // Comprobar si el valor está dentro del porcentaje de unos deseado
      grid[i][0] = colorVivaActual; // Celda viva
    } else {
      grid[i][0] = colorMuertaActual; // Celda muerta
    }
  }
}

void saveConfiguration() {
  color colorVivaActual = colorPickerViva.getColorValue(); // Obtener el color actual de celda viva
  color colorMuertaActual = colorPickerMuerta.getColorValue(); // Obtener el color actual de celda muerta
  try {
    PrintWriter writer = new PrintWriter("config.txt");
    for (int j = 0; j < rows; j++) {
      for (int i = 0; i < cols; i++) {
        if (i == 0) {
          writer.print(grid[i][j] == colorMuertaActual ? "0" : "1");
        } else {
          writer.print("," + (grid[i][j] == colorMuertaActual ? "0" : "1"));
        }
      }
      writer.println(); // Nueva línea para la siguiente fila
    }
    writer.close();
    println("Configuración guardada en 'config.txt'");
  } catch (Exception e) {
    println("Error al guardar la configuración: " + e.getMessage());
  }
}

void applyRule() {
  color colorVivaActual = colorPickerViva.getColorValue(); // Obtener el color actual de celda viva
  color colorMuertaActual = colorPickerMuerta.getColorValue(); // Obtener el color actual de celda muerta
  
  float[] probabilities = new float[8];
  float entropy = 0.0;
  String[] subStrings = {"000", "001", "010", "011", "100", "101", "110", "111"};
  
  // Copiar el estado actual a la próxima generación
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      nextGeneration[i][j] = grid[i][j];
    }
  }

  // Contar unos y ceros en la generación actual
  for (int i = 0; i < cols; i++) {
    if (grid[i][generation - 1] == colorVivaActual) {
      unosGeneracion++;
    } else {
      cerosGeneracion++;
    }
  }

for (int i = 0; i < subStrings.length; i++) {
    String subString = subStrings[i];
    for (int z = 0; z < cols; z++) {
        String cellState = (grid[z][(generation - 1) % cols] == colorVivaActual) ? "1" : "0";
        String cellStateRight = (grid[(z + 1) % cols][(generation - 1) % cols] == colorVivaActual) ? "1" : "0";
        String cellStateLeft = (grid[(z - 1 + cols) % cols][(generation - 1) % cols] == colorVivaActual) ? "1" : "0";
        String neighborhood = cellStateLeft + cellState + cellStateRight;
        if (neighborhood.equals(subString)) {
            subStringCounts[i]++;
        }
    }
}
  
    // Calcular probabilidades
  for (int i = 0; i < 8; i++) {
    probabilities[i] = subStringCounts[i] / (float) (rows);
   
  }
  
  // Calcular la entropía de Shannon
  for (int i = 0; i < 8; i++) {
    if (probabilities[i] > 0) {
      entropy -= probabilities[i] * log(probabilities[i]) / log(2);
      
    }
  }
  
  // Guardar el resultado en un archivo de texto
  writer2.println(generation + "\t" + entropy);
  writer2.flush();

  // Calcular densidad y guardar en archivo
  calculateDensity();
  
  //Calcular media de unos y guarda en archivo
  calculateMedia();
  
  calculateVar();
  
  
  // Restablecer los contadores para la siguiente generación
  resetCounters();

  // Obtener la regla seleccionada desde el DropdownList
  int selectedRule = int(cp5.getController("Rule Selector").getValue());

  // Aplicar la regla seleccionada para calcular la siguiente generación
  for (int i = 0; i < cols; i++) {
    int left = (i - 1 + cols) % cols; // Usar módulo para obtener el vecino izquierdo
    int center = i;
    int right = (i + 1) % cols; // Usar módulo para obtener el vecino derecho

    int leftState = grid[left][generation - 1] == colorVivaActual ? 1 : 0;
    int centerState = grid[center][generation - 1] == colorVivaActual ? 1 : 0;
    int rightState = grid[right][generation - 1] == colorVivaActual ? 1 : 0;

    // Obtener el resultado de la regla actual desde la matriz de reglas
    int nextState = rules[selectedRule][leftState][centerState][rightState];

    // Actualizar la próxima generación
    nextGeneration[center][generation] = (nextState == 1) ? colorVivaActual : colorMuertaActual;
  }
  
  

  // Copiar la próxima generación de nuevo a la cuadrícula actual
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = nextGeneration[i][j];
      
    }
  }
  
  // Cambiar la generación actual a la siguiente generación
  generation++;
}

void controlEvent(ControlEvent event) {
  if (event.isController()) {
    String eventName = event.getController().getName();
    if (eventName.equals("atrac")) {
      atractor();
    } else if (eventName.equals("todo")) {
      todo();
    }  else if (eventName.equals("Guardar Última Fila")) {
      saveLastRow();
    } else if (eventName.equals("Automático")) {
      automaticMode = !automaticMode;
      if (automaticMode) {
        applyRule();
        lastTime = millis();
      }
    } else if (eventName.equals("2%")) {
      percentageOnes = 0.02;
    } else if (eventName.equals("50%")) {
      percentageOnes = 0.50;
    } else if (eventName.equals("75%")) {
      percentageOnes = 0.75;
    } else if (eventName.equals("95%")) {
      percentageOnes = 0.95;
    } else if (eventName.equals("Reiniciar")) {
      reiniciarGrid(); // Llama al método para reiniciar la cuadrícula
    }
  }
}

void saveLastRow() {
  color colorVivaActual = colorPickerViva.getColorValue(); // Obtener el color actual de celda viva
  color colorMuertaActual = colorPickerMuerta.getColorValue(); // Obtener el color actual de celda muerta
  try {
    PrintWriter writer = new PrintWriter("last_row.txt");
    for (int i = 0; i < cols; i++) {
      if (i == 0) {
        writer.print(grid[i][rows - 1] == colorMuertaActual ? "0" : "1");
      } else {
        writer.print("," + (grid[i][rows - 1] == colorMuertaActual ? "0" : "1"));
      }
    }
    writer.close();
    println("Última fila guardada en 'last_row.txt'");
  } catch (Exception e) {
    println("Error al guardar la última fila: " + e.getMessage());
  }
}

void resetCounters() {
  unosGeneracion = 0;
  cerosGeneracion = 0;
  for (int i = 0; i < 8; i++) {
  subStringCounts[i] = 0;
}
}

void calculateDensity() {
  float density = unosGeneracion / (float)cerosGeneracion; // Calcular densidad
  densidades.add(density); // Agregar densidad a la lista
  generaciones.add(generation); // Agregar número de generación a la lista
  writer.println(generation + "\t" + density);
  writer.flush();
}

void calculateMedia() {
  float media = unosGeneracion / (float) (cerosGeneracion + unosGeneracion); // Calcular densidad
  medias.add(media); // Agregar densidad a la lista
  generaciones.add(generation); // Agregar número de generación a la lista
  writer1.println(generation + "\t" + media);
  writer1.flush();
}

void calculateVar() {
  
  color colorMuertaActual = colorPickerMuerta.getColorValue(); // Obtener el color actual de celda muerta
  try {
    PrintWriter varWriter = createWriter("VARIANZA.txt");

    
      for (int j = 0; j < rows; j++) {
        for (int i = 0; i < cols; i++) {
          if (i == 0) {
            varWriter.print(grid[i][j] == colorMuertaActual ? "0" : "1");
          } else {
            varWriter.print((grid[i][j] == colorMuertaActual ? "0" : "1"));
          }
        }
        varWriter.println(); // Nueva línea para la siguiente fila
      }
 
    varWriter.flush();
    varWriter.close();
  } catch (Exception e) {
    println("Error al guardar las cadenas: " + e.getMessage());
  }
}


void exit() {
  // Cerrar el archivo "DENSIDAD.txt" al finalizar el programa
  writer.close();
  super.exit();
}

void ApplySize() {
  int newCols = int(colsTextField.getText());
  int newRows = int(rowsTextField.getText());

  if (newCols >= minCellsPerSide && newCols <= maxCellsPerSide && newRows >= minCellsPerSide && newRows <= maxCellsPerSide) {
    // Cambia el tamaño de la cuadrícula
    cols = newCols;
    rows = newRows;
    generateGrid = true; // Genera una nueva cuadrícula
    hideGenerateButton = false; // Muestra el botón "Generar" nuevamente
  } else {
    // Muestra un mensaje de error si los valores están fuera de los límites
    println("Los valores están fuera de los límites permitidos.");
  }
}

void atractor() {
  // Obtener los valores de la generación 0 y generación 1
  String gen0 = getGenerationBinary(0);
  String gen1 = getGenerationBinary(1);
  
  // Convertir los valores binarios a decimales
  int decimalGen0 = binaryToDecimal(gen0);
  int decimalGen1 = binaryToDecimal(gen1);
  
  // Cargar los datos existentes en el archivo "atractor.txt"
  String[] existingData = loadStrings("atractor.txt");
  
  // Crear una lista para mantener todos los datos, incluidos los existentes
  ArrayList<String> allData = new ArrayList<String>();
  
  // Agregar los datos existentes a la lista
  for (String line : existingData) {
    allData.add(line);
  }
  
  // Agregar los nuevos valores a la lista
  allData.add(decimalGen0 + " " + decimalGen1);
  
  // Guardar todos los datos en el archivo "atractor.txt"
  PrintWriter writer = createWriter("atractor.txt");
  for (String line : allData) {
    writer.println(line);
  }
  writer.flush();
  writer.close();
}

// Convierte una cadena binaria en un valor decimal
int binaryToDecimal(String binary) {
  int decimal = Integer.parseInt(binary, 2);
  return decimal;
}

// Obtiene la representación binaria de una generación específica (0 o 1)
String getGenerationBinary(int generation) {
  String binary = "";
  color colorVivaActual = colorPickerViva.getColorValue();
  for (int i = 0; i < cols; i++) {
    // Convierte el color de la celda en 0 o 1 (muerta o viva)
    if (grid[i][generation] == colorVivaActual) {
      binary += "1";
    } else {
      binary += "0";
    }
  }
  return binary;
}

void reiniciarGrid() {
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = colorMuerta; // Restablecer todas las celdas como muertas
    }
  }
  generation = 1; // Restablecer la generación actual
  currentRow = 0; // Restablecer la fila actual
  resetCounters(); // Restablecer los contadores
}

/*void num() {
 int n = 10;
  String filename = "combinaciones_binarias.txt";
  PrintWriter output = createWriter(filename);
  int maxCombinations = int(pow(2, n));
  for (int i = 0; i < maxCombinations; i++) {
    String binaryString = binary(i, n);
    String[] binaryArray = binaryString.split("");
    for (int j = 0; j < binaryArray.length; j++) {
      output.print(binaryArray[j]);

      if (j < binaryArray.length - 1) {
        output.print(",");
      }
    }
    output.println();
  }
  
  output.flush();
  output.close();
  
  println("Combinaciones binarias generadas y guardadas en " + filename);
}
*/
void todo() {
  
  loadPattern();
  applyRule();
  atractor();
  reiniciarGrid();
 
}
