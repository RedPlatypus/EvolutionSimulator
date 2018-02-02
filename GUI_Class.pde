class GUI{
  float x,y, width, height;
  float VSpacing = 25;
  BRMidGraph mgGG, mgBG;
  BRHistogram popHistShort, popHistLong;
  NeuralDisplay nd;
  PVector antReportLocation;
  float antDisplayHieght;
  BRStaticHistogram dAge, bAge;
  float ticks = 0;
  color backgroundColor = color(0,0,0, 150);
  color textColor = color(255);
  color chartColor = color(10);
  boolean antReport = false;
  int antReportScreen = 0, tableSortCategory = 0;
  Ant antData;
  Map backgroundMap;
  DisplayTable topAnts; int cellsInTable = 5, tableRefresh = 30, tableTick = 31;
  ArrayList<Ant>topAntData;
  
  GUI(float x, float y, float width, float height){
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    createGrassGraphs();
    createRollingHistogram();
    createHistograms();
    this.backgroundMap = new Map(this.width + MAP_SCALE, this.height + MAP_SCALE,0);
    //float ratio = (height - (this.VSpacing * 6 + 220 + GUI_MARGIN + 150)) / height;
    antDisplayHieght = 515;
    antReportLocation = new PVector(0,this.VSpacing * 6 + 220 + GUI_MARGIN + 80);
    
    topAnts = new DisplayTable(antReportLocation.x, antReportLocation.y, width - GUI_MARGIN * 2, antDisplayHieght);
    topAntData = new ArrayList<Ant>();
  }
  
  void createRollingHistogram(){
    popHistShort = new BRHistogram(0, this.VSpacing * 6 + 10, this.width - GUI_MARGIN * 2, 50);
    popHistShort.toggleAverage();    
    popHistShort.setBackgroundColor(chartColor);

    popHistLong = new BRHistogram(0, this.VSpacing * 6 + 60 + GUI_MARGIN, this.width - GUI_MARGIN * 2, 50);
    popHistLong.toggleAverage();
    popHistLong.setTitleColor(textColor);
    popHistLong.setBackgroundColor(chartColor);
  }
  void createGrassGraphs(){
    float histogramHeight = this.VSpacing * 0.6;
    mgGG = new BRMidGraph(width - GUI_MARGIN * 2 - histogramHeight, 130 / 2, 130, histogramHeight, -MAX_DEATH_RATE,0,MAX_GROWTH_RATE);
    mgGG.showTitle();
    mgGG.changeTitle("green crop growth");
    mgGG.setTitleColor(textColor);
    mgGG.rotateChart(-HALF_PI);
    mgGG.setBackgroundColor(color(50,150,50));
    
    mgBG = new BRMidGraph(width - GUI_MARGIN * 2 - histogramHeight - this.VSpacing * 1.3, 130 / 2, 130, histogramHeight, -MAX_DEATH_RATE,0,MAX_GROWTH_RATE);
    mgBG.showTitle();
    mgBG.changeTitle("blue crop growth");
    mgBG.rotateChart(-HALF_PI);
    mgBG.setTitleColor(textColor);
    mgBG.setBackgroundColor(color(50,50,150));
  }
  void createHistograms(){
    //creating static hist's
    dAge = new BRStaticHistogram(0,this.VSpacing * 6 + 130 + GUI_MARGIN,this.width - GUI_MARGIN * 2,50, 15); 
    dAge.toggleAverage();
    dAge.displayValues();
    dAge.displayXaxis();
    dAge.showTitle();
    dAge.changeTitle("age of death");
    dAge.showBorderBox();
    dAge.setBarColor(color(100));
    dAge.setBackgroundColor(chartColor);
    dAge.setTitleColor(textColor);
    
    bAge = new BRStaticHistogram(0,this.VSpacing * 6 + 220 + GUI_MARGIN,this.width - GUI_MARGIN * 2,50, 11); 
    bAge.toggleAverage();
    bAge.displayValues();
    bAge.displayXaxis();
    bAge.showTitle();
    bAge.changeTitle("birth age");
    bAge.showBorderBox();
    bAge.setBackgroundColor(chartColor);
    bAge.setTitleColor(textColor);
  }
  
  GUI drawGUI(){
    //starts drawing background, then begins inside
    pushMatrix();
    translate(this.x,this.y);
    
    noStroke();
    colorMode(HSB,255);
    this.backgroundMap.drawMap();
    fill(this.backgroundColor);
    rect(0,0,this.width, this.height);
    drawInside();
    
    popMatrix();
    return this;
  }

  void drawInside(){
    textAlign(LEFT);
    pushMatrix();
    translate(GUI_MARGIN,GUI_MARGIN + 25); //add title font size
    PFont f;
    f = createFont("Arial", 20, true);
    float population = floor((float)WORLD.worldMap.getAntPopulation());
    
    //if we have right clicked and selected an ant to view draw the single ant report.
    
    //draw the full screen ant GUI for checking on 
    drawTitleText(f, population);
    drawHistograms(f, population);
    drawStaticHistograms(f);
    
    if(antReport){
      switch(antReportScreen){
        case 0:
          pushMatrix();
          translate(antReportLocation.x, antReportLocation.y);
          nd.drawDisplay();
          popMatrix();
          break;
        case 1:
          drawAntReport(f);
          break;
      }
    } else{
      drawAntsTable();
    }
    
    popMatrix();
  }
  
  void drawAntsTable(){
    if(tableTick > tableRefresh){
      tableTick = 0;
    //get sorted list
     
      ArrayList<Ant>newTopAntData = WORLD.statistics.getTopAnts();
      
      //compare newTopAntdata, and see if it's the same as topAntdata. if it is just keep on showing what we got.
      //topAntData.clear();
      
      topAntData = newTopAntData;
      topAnts.updateTable(topAntData); // pass in sorted list of objects
    }
    tableTick++;
    topAnts.drawTable();
  }
  
  void drawAntReport(PFont f){
    pushMatrix();
    translate(antReportLocation.x, antReportLocation.y);
    textFont(f,15); fill(textColor);
    //todo put ant info here!
    float generation = floor(antData.generation);
    String gen = generation + "";
    if(generation == 0){
      gen = "primal ant";
    }
    String name = "who am i";
    if(!antData.alive){
      name += " - DECEASED";
    }
    
    //and print those lines
    text("name:            " + name, 0, this.VSpacing);
    text("born:              " + floor(antData.birthYear) + "."  + floor(antData.birthDay), 0, this.VSpacing * 2);
    text("generation:    " + gen, 0, this.VSpacing * 3);
    text("spawn:          " + floor(antData.spawn), 0, this.VSpacing * 4);
    text("likes food:     " + floor(antData.mHue), 0, this.VSpacing * 5);
    text("age:              " + floor(antData.getAge()), 0, this.VSpacing * 6);
    text("energy:         " + ceil(antData.energy - DEATH_ENERGY), 0, this.VSpacing * 7);
    popMatrix();
  }
  
  void displayNeuralNet(Ant ant){
    //println("display this ant's neural net");
    if(ant._input instanceof BrainInput){
      ant._input.brain.displayNodes();
      PFont f;
      f = createFont("Arial", 20, true);
      nd = new NeuralDisplay(0, 0,this.width - GUI_MARGIN * 2, antDisplayHieght, ant._input.brain);
      nd.setFont(f, 10);
      //nd.showTitle();
      //nd.changeTitle("the brain");
      nd.hideBorderBox();
      nd.setBackgroundColor(color(200));
      antReport = true;
    }
    antData = ant;
  }
  void removeNeuralNet(){
    antReport = false;
  }
  GUI updateGUI(){
    this.backgroundMap.update();
    return this;
  }
  void setBackgroundColor(color col){
    this.backgroundColor = col;
  }
  void anotherAntDied(float ageOfAnt){
    // TODO sub for notifications
    dAge.update(ageOfAnt);
  }
  void anotherAntBirthed(float ageOfAnt){
    bAge.update(ageOfAnt);
  }
  
  void drawStaticHistograms(PFont f){
    dAge.setFont(f,10);
    dAge.drawDisplay();
    bAge.setFont(f,10);
    bAge.drawDisplay();
  }
  
  void drawHistograms(PFont f, float population){
    mgGG.setFont(f, 10);
    mgGG.drawDisplay();
    mgGG.updateValue(WORLD.getGlobalGrassGrowth(0));
    mgBG.setFont(f, 10);
    mgBG.drawDisplay();
    mgBG.updateValue(WORLD.getGlobalGrassGrowth(1));
    
    if(this.ticks % 20 == 0){
      popHistShort.update(population);
    }
    if(this.ticks % 160 == 0){
      popHistLong.update(population);
      ticks = 1;
    }
    noStroke();
    popHistShort.drawDisplay();
    popHistLong.drawDisplay();
    ticks++;
  }
  void drawTitleText(PFont f, float population){
    textFont(f,25);
    fill(textColor);
    stroke(1);
    text("circle simulator", 0, 0);
    textFont(f,11);
    text("and now with brains", 0, 14);
    textFont(f,15);
    fill(textColor);
    text("temperature:    " + floor(WORLD.getTemp()) + "ºC", 0, this.VSpacing * 2);
    text("population:       " + population, 0, this.VSpacing * 3);
    float year = WORLD.getYear();
    text("year:                  " + round(year), 0, this.VSpacing * 4);
    float day = WORLD.getDay();
    text("day:                   " + floor(day), 0, this.VSpacing * 5);
  }
  
  void leftClicked(){
    if(antReport){
      antReportScreen ++;
      if(antReportScreen > 1){
        antReportScreen = 0;
      }
    }else{
      
      tableSortCategory ++;
      if(tableSortCategory > 3){
        tableSortCategory = 0;
      }
      WORLD.statistics.sortByCategory(tableSortCategory);
      WORLD.statistics.profile(WORLD.worldMap.ants);
    }
  }
}