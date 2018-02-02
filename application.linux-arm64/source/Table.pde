//future place for table class and cell class
//custom classes and heavily tied to data
class DisplayTable{
  //custom
  float width; float height; float x; float y;
  float padding = 0;
  float cellHeight = 50;
  // table holds a collection of cells
  ArrayList<TableCell> cells;
  color tableColor = color(0,0,0,150);
  DisplayTable(float x, float y, float width, float height){
    this.width = width;
    this.height = height;
    this.x = x;
    this.y = y;
    cells = new ArrayList<TableCell>();
  }
  
  void drawTable(){
    pushMatrix();
    translate(this.x, this.y);
    
    PFont f;
    f = createFont("Arial", 15, true);
    textFont(f,12); fill(255);
    textAlign(LEFT);
    int cat = WORLD.statistics.category;
    String txt = "";
    // 0age, 1size, 2spawn, 3generation
    if(cat == 0){
      txt = "age";
    } else if(cat == 1){
      txt = "size";
    } else if(cat == 2){
      txt = "spawn";
    } else if(cat == 3){
      txt = "generation";
    }
    text("circles by " + txt,20,-5);
    
    fill(tableColor);
    rect(0,0,width, height);
    for(TableCell cell: cells){
      cell.updateCell();
      cell.drawCell();
    }
    popMatrix();
  }
  void updateTable(ArrayList<Ant>topData){
    //we need to determine if cells contain the ants in topData
    cells.clear();
    for(int i = 0; i < topData.size(); i++){
      TableCell cell = new TableCell(this.padding, cellHeight * cells.size(), this.width, this.cellHeight, topData.get(i));
      cells.add(cell);
    }
  }
  int cellCount(){
    return cells.size();
  }
  void removeCell(int index){
    cells.remove(index);
  }
}
class TableCell{
  //used for displaying cells in a table.
  color backgroundColor = color(0,0,0,50);
  color cellBorderColor = color(30);
  color headingColor = color(255);
  color textColor = color(200);
  int index;
  
  //custom
  float x, y, width, height;
  
  //cell data
  Ant cellData;
  
  TableCell(float x, float y, float width, float height, Ant cellD){
    this.width = width;
    this.height = height;
    this.x = x;
    this.y = y;
    this.cellData = cellD;
  }
  void setCellData(Ant cellD){
    if(this.cellData != cellD){
      this.cellData = cellD;
    }
  }
  void drawCell(){
    pushMatrix();
    translate(this.x, this.y);
    fill(backgroundColor);
    stroke(cellBorderColor);
    rect(0,0,width, height);
    
    pushMatrix();
    translate(20,height / 2);
    scale(2);
    cellData.drawAntBody();
    popMatrix();
    
    PFont f;
    f = createFont("Arial", 15, true);
    textFont(f,12); fill(headingColor);
    float horizSpacing = 45;
    textAlign(CENTER);
    
    //titles
    pushMatrix();
    translate(60, 17);//font size + 2
    text("energy", 0,0);
    translate(horizSpacing, 0);//font size + 2
    text("age", 0,0);
    translate(horizSpacing, 0);//font size + 2
    text("food :)", 0,0);
    translate(horizSpacing, 0);//font size + 2
    text("spawn", 0,0);
    translate(horizSpacing, 0);//font size + 2
    text("gen", 0,0);
    popMatrix();
    
    //data
    textFont(f,10); fill(textColor);
    pushMatrix();
    translate(60, 34);//font size * 2 + 4
    text(floor(cellData.energy), 0,0);
    translate(horizSpacing, 0);//font size + 2
    text(floor(cellData.getAge()), 0,0);
    translate(horizSpacing, 0);//font size + 2
    text(floor(cellData.mHue), 0,0);
    translate(horizSpacing, 0);//font size + 2
    text(floor(cellData.spawn), 0,0);
    translate(horizSpacing, 0);//font size + 2
    text(floor(cellData.generation), 0,0);
    popMatrix();
    
    popMatrix();
  }
  void updateCell(){
    //update data, update index.
    
  }
}