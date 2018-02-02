import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.Comparator; 

import org.jbox2d.collision.broadphase.*; 
import org.jbox2d.pooling.*; 
import org.jbox2d.particle.*; 
import org.jbox2d.dynamics.contacts.*; 
import org.jbox2d.pooling.stacks.*; 
import org.jbox2d.dynamics.joints.*; 
import org.jbox2d.pooling.normal.*; 
import org.jbox2d.common.*; 
import org.jbox2d.dynamics.*; 
import org.jbox2d.callbacks.*; 
import org.jbox2d.collision.*; 
import org.jbox2d.pooling.arrays.*; 
import org.jbox2d.collision.shapes.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class AntGame extends PApplet {

final float SCREEN_WIDTH = 1100;//check size in setup is same! (1920)
final float SCREEN_HEIGHT = 800;//check size in setup is same! (1000)
final float GUI_PERCENT_OF_SCREEN = 0.26f;

final World WORLD = new World(SCREEN_WIDTH * (1-GUI_PERCENT_OF_SCREEN), SCREEN_HEIGHT);
final GUI antGUI = new GUI(SCREEN_WIDTH * (1-GUI_PERCENT_OF_SCREEN), 0, SCREEN_WIDTH * GUI_PERCENT_OF_SCREEN, SCREEN_HEIGHT);
final InputComponent playerInput = new InputComponent();
//final NeuralNet brain = new NeuralNet(); //need to give to every ant!

public void setup() {
   // needs to be same as screen_width & screen_height!
  //surface.setResizable(true);

  //noLoop();
}

public void draw() {
  background(BACKGROUND_COLOR);
  WORLD.updateWorld();
  WORLD.drawWorld();
  antGUI.updateGUI().drawGUI();
}

public void mouseWheel(MouseEvent event) {
  float delta = event.getCount() > 0 ? 1.05f : event.getCount() < 0 ? 1.0f/1.05f : 1.0f;
  if(WORLD.worldMap.scaleBy / delta < 1){
    WORLD.worldMap.scaleBy = 1;
    return;
  } else if(WORLD.worldMap.scaleBy / delta > 9){
    WORLD.worldMap.scaleBy = 9;
    return;
  }
  WORLD.worldMap.x -= mouseX;
  WORLD.worldMap.y -= mouseY;
  WORLD.worldMap.scaleBy /= delta;
  WORLD.worldMap.x /= delta;
  WORLD.worldMap.y /= delta;
  WORLD.worldMap.x += mouseX;
  WORLD.worldMap.y += mouseY;
  
}

public void mouseDragged() 
{
  //check if mouse is over map
  if(WORLD.worldMap.containsMouse(mouseX, mouseY)){
    WORLD.worldMap.stopTrackingAnt();
    //drag the map
    WORLD.worldMap.x += mouseX - pmouseX;
    WORLD.worldMap.y += mouseY - pmouseY;
  }
}
public void keyPressed(){
   if(keyPressed){
      if (key == 'r') {
        //reset the zoom
        WORLD.worldMap.scaleBy = 1.0f;
        WORLD.worldMap.x = 0;
        WORLD.worldMap.y = 0;
      } else if (key == 'f') {
        //follow the selected ant!
        WORLD.worldMap.followAnt();
      }
   }
}
public void mouseClicked(){
  //did we click over the map or gui?
  //println(event.toString);
  if(WORLD.worldMap.containsMouse(mouseX, mouseY)){
    
    if ((mouseButton == LEFT)) {
       WORLD.worldMap.leftClicked(mouseX,mouseY);
    } else if ((mouseButton == RIGHT)) {
       //WORLD.worldMap.rightClicked(mouseX,mouseY);
    } 
   
    //1. we clicked the map, are what's the first "Ant" we see
    //1a. was it a right click?
    // yes? -transfer control to human & display stats on gui. 
    //      -Remove human controls from other ants.
    //1b. no?
    //2.  display stats on gui and follow and rotate according to ant
    
  } else{
    //1. check gui for any buttons that contain the click!
    if ((mouseButton == LEFT)) {
      antGUI.leftClicked();
    } else if ((mouseButton == RIGHT)) {
       //WORLD.worldMap.rightClicked(mouseX,mouseY);
    } 
  }
}
class Ant {  
  final float MAX_ROTATION = 0.1f;
  float energy; // the raw energy an ant has
  float bodySize; // a relationship between energy, & scale
  float mHue;
  boolean alive = true;
  float breedingSize = mapEnergyToSize(BREEDING_ENERGY);
  float deathSize = mapEnergyToSize(DEATH_ENERGY);
  float modifier = 0, mm = 0.1f;
  int myColor = color(random(0,255),150,150);
  float generation;
  float spawn; // how many young has this ant birthed
  Feeler feel1 = new Feeler(0, 0, this);
  Feeler feel2 = new Feeler(0, 0, this);
  InputComponent _input;
  float biteSize; // current bite Size.
  float birthYear, birthDay, totalDaysBirth, accumulativeDeathDay;
  PhysicsCircle body;

//constructor - initalizes the variables or the setting of the object the class creates
  Ant(PVector location, InputComponent input, int generation){
    this.energy = STARTING_ENERGY;
    convertEnergyToBodySize(this.energy);
    body = new PhysicsCircle(bodySize / 2, location);
    _input = input;
    this.generation = generation;
    //this.position = location;
    this.mHue = random(0,255);
    this.biteSize = MAX_BITE_SIZE / 2;
    setBirthday();
  }
  //constructor - initalizes the variables or the setting of the object the class creates
  Ant(PVector location, int generation){ 
    this.energy = STARTING_ENERGY;
    convertEnergyToBodySize(this.energy);
    body = new PhysicsCircle(bodySize / 2, location);
    //create a new smart ant, no parent
    if(SMART_ANTS){
      _input = new BrainInput(INPUTN, HIDDENN, OUTN, LEARNING_RATE, this);
    } else {
      _input = new RandomInput();
    }
    this.generation = generation;
    //this.position = location;
    this.mHue = random(0,255);
    this.biteSize = MAX_BITE_SIZE / 2;
    setBirthday();
  }
  
  Ant(Ant parent){
    this.energy = STARTING_ENERGY;
    convertEnergyToBodySize(this.energy);
    body = new PhysicsCircle(bodySize / 2, parent.body.position.copy());
    //this.position = parent.position.copy();
    if(parent._input instanceof BrainInput){
      this._input = parent._input.clone(this, (BrainInput)parent._input);
      //this._input = new BrainInput(parent._input, this);
      this._input.mutate();
    } else if(parent._input instanceof PlayerInput){
      if(SMART_ANTS){
        _input = new BrainInput(INPUTN, HIDDENN, OUTN, LEARNING_RATE, this);
      } else{
        _input = new RandomInput();
      }
    } else if(parent._input instanceof RandomInput){
      _input = new RandomInput();
    }
    
    this.generation = parent.generation + 1;
    this.mHue = parent.mHue + (randomGaussian() * 20);
    if(this.mHue > 255){
      this.mHue = this.mHue - 255;
    } else if(this.mHue < 0){
      this.mHue = 255 + this.mHue;
    }
    this.myColor = parent.myColor;
    PVector birthForce = new PVector(random(-2.5f,2.5f), random(-2.5f,2.5f));
    //applyForce(birthForce);
    this.body.applyForce(birthForce);
    this.biteSize = MAX_BITE_SIZE / 2;
    setBirthday();
  }
  public void setBirthday(){
    if(WORLD == null){
      this.birthYear = 0;
      this.birthDay = 0;
      this.totalDaysBirth = 0;
      this.accumulativeDeathDay = 0;
    } else{
    this.birthYear = WORLD.getYear();
    this.birthDay = WORLD.getDay();
    this.totalDaysBirth = WORLD.getTotalDays();
    }
  }
  public float getAge(){
    if(this.alive){
      return WORLD.getTotalDays() - this.totalDaysBirth;
    } else{
      float age3 =  this.accumulativeDeathDay - this.totalDaysBirth;
      //println(age3 + "called at get age in ant class!");
      return age3;
    }
  }
  public void switchToRandomInput(){
    _input = new RandomInput();
  }
  public void vomit(){
    //if we light up 10
    //this.energy -= 4.0;
    //println("Vomiting");
  }
  public void keyPressed(){
    println(" AntClass Key Pressed");
    if(_input instanceof PlayerInput){
        _input.keyPressed();
        println("Inside.");
      }
  }
  //methods - functions of the object that the class creates. (abilities)
  public Ant updateAnt(){
    feel1.updateFeeler();
    feel2.updateFeeler();
    if(isAlive()){
      //get input from player, random, or neural net
      if(_input instanceof RandomInput){
        _input.update(this);
      } else if(_input instanceof BrainInput){
        _input.update();
      }
      this.body.updateSize(bodySize / 2);
      //takes energy to move
      TileType tType = WORLD.getTypeOfTileAt(this.body.position);
      if(tType == TileType.tWater){
         convertEnergyToBodySize(-ENERGY_REQUIRED_SWIM);
      }else if(tType == TileType.tLand){
         convertEnergyToBodySize(-ENERGY_REQUIRED_MOVE);
      } else{
        convertEnergyToBodySize(-ENERGY_REQUIRED_MOVE);
      }
      animate();
    } else {
      die();
    }
    return this;
  }
  
  public void drawAnt(){
    feel1.drawFeeler(); // should be drawn before ant, to hide underneath.
    feel2.drawFeeler();
    pushMatrix();
    translate(this.body.position.x, this.body.position.y);
    drawAntBody();
    popMatrix();
  }
  // HELPER functions
  public void animate(){
    this.modifier += this.mm;
    if(this.modifier > 1.5f || this.modifier < -1.5f){
      this.mm *= -1;
    }
    this.modifier += mm;
  }
  public void drawAntBody(){
    pushMatrix();
    float rotation = this.body.velocity.heading();
    rotate(rotation);
    stroke(0);
    strokeWeight(0.5f);
    colorMode(HSB, 255);
    fill(this.myColor);
    ellipse(0, 0, bodySize, bodySize);
    if(this.energy > BREEDING_ENERGY){
      noFill();
      stroke(255);
      ellipse(0,0, this.breedingSize, this.breedingSize); 
    }
    if(this.energy < DEATH_ENERGY * 1.15f){
      noStroke();
      fill(color(255,150,80));
      ellipse(0,0, this.deathSize, this.deathSize); 
    }
    stroke(0);
    strokeWeight(0.25f);
    colorMode(HSB,255);
    fill(this.mHue,200, 200);
    ellipse(0.5f * bodySize + this.modifier, 0, bodySize * 0.3f, bodySize * 0.5f); // mouth or something.
    popMatrix();
  }
  public boolean isAlive(){
    return this.alive;
  }
  
  public float mapEnergyToSize(float val){
    return map(val, DEATH_ENERGY, STARTING_ENERGY * 8, MAP_SCALE / 2.5f, MAP_SCALE * 1.5f);
  }
  
  public void convertEnergyToBodySize(float energy){
    //used for any energy related needs
    //also a good place to check for energy reserves
    this.energy += energy;
    if(this.energy < DEATH_ENERGY){
      die();
    }
    //this.bodySize = map(DEATH_ENERGY, DEATH_ENERGY, STARTING_ENERGY * 4, MAP_SCALE / 4, MAP_SCALE / 2);
    this.bodySize = mapEnergyToSize(this.energy);
  }
  public PVector getPosition(){
    return this.body.position;
  }
  
  public boolean isAntOnMap(){
    float radius = this.bodySize / 2;
    return WORLD.worldMap.worldContainsObject(this.body.position.x, this.body.position.y, radius);
  }

  public float getSize(){
    return this.bodySize;
  }
  
  //useful information for smart players
  public int getSensorInfo(Feeler feeler){
    return feeler.getSensorInfo();
  }
  public float getHueUnderneath(){
    int tCol = WORLD.getColorAtLocation(this.body.position.x, this.body.position.y);
    if(tCol == -1){
      return -1;
    }
    return hue(tCol);
  }
  public float differenceBetweenHueAndMouthHue(float hue){
    float difference = 0;
      if(mHue < MAX_DIFF){
        //calc numerical dif
        if(abs(mHue - hue) > MAX_DIFF){
          difference = mHue + 255 - hue;
        } else{
          difference = abs(mHue - hue);
        }
      } else {
        if(hue + 255 - mHue > MAX_DIFF){
          difference = abs(mHue - hue);
        } else{
          difference = hue + 255 - mHue;
        }
      }
      return difference;
  }
  public void increaseBiteSize(){
    this.biteSize += 0.1f;
    if(this.biteSize > MAX_BITE_SIZE){
      this.biteSize = MAX_BITE_SIZE;
    }
  }
  public void decreaseBiteSize(){
    this.biteSize -= 0.1f;
    if(this.biteSize < 0){
      this.biteSize = 0;
    }
  }
  public float getBiteSize(){
    return this.biteSize;
  }
  public float getWorldTemp(){
    return WORLD.getTemp();
  }
  public Ant eat(float biteSize){
    if(biteSize > MAX_BITE_SIZE){ biteSize = MAX_BITE_SIZE; } else if(biteSize < 0){ biteSize = 0; return this;}
    //open mouth and eat what's under you.
    float energyReturned = eatTileUnderneath( biteSize);
    convertEnergyToBodySize(energyReturned);
    return this;
  }
  public float eatTileUnderneath(float biteSize){
    //returns nutrients at location
    Tile tTile = WORLD.worldMap.getTileAtLocation(this.body.position);
    if(tTile == null){
      return -1.0f;
    }
    if(tTile.type == TileType.tWater){
      return 0;
    }
    if(tTile.type == TileType.tLand){
      if(tTile.saturation <= MIN_LAND_ENERGY){
        return 0; // no nutrients on land for that bite size.
      }
      //desaturate the land by remaining energy onland
      float rEnergy = tTile.saturation;
      if(rEnergy < MIN_LAND_ENERGY + 1){
        return 0;
      }
      float cEnergy = 0;
      if(rEnergy - MIN_LAND_ENERGY < biteSize){
        cEnergy = rEnergy;
      } else{
        cEnergy = biteSize;
      }
      tTile.saturation = tTile.saturation - cEnergy;
      
      //always take bite size from land, but only return energy that is digestable SCOPE
      float percentDif = 0;
      float difference = differenceBetweenHueAndMouthHue(tTile.hue);
      tTile.eat(biteSize);
      //this.eatingColor = color(tTile.hue, MAX_DIFF, ANT_BRIGHTNESS);
      percentDif = (SCOPE - difference) / SCOPE;
      return cEnergy * percentDif;
    }
    return 0;
  }
  public void growFeeler(Feeler feeler){
    feeler.growFeeler();
  } 
  public void shrinkFeeler(Feeler feeler){
    feeler.shrinkFeeler();
  }
  public void rotateFeeler(Feeler feeler, float direction){
    feeler.rotateFeeler(direction);
  }
  public void giveBirth(){
    //if you can divide by more than min weight, go for it
    if(this.energy < BREEDING_ENERGY){
      return;
    }
    if(getAge() < MIN_BREEDING_AGE){
      return;
    }
    this.energy = this.energy - STARTING_ENERGY - ENERGY_REQUIRED_BIRTH;
    this.spawn++;
    WORLD.sendInfo(this);
    WORLD.worldMap.birthAnt(this);
  }
  public void die(){
    this.alive = false;
    this.accumulativeDeathDay = WORLD.getTotalDays();
    WORLD.worldMap.removeAnt(this);
  }

}
class BRDisplay{
  float width;
  float height;
  float x, y;
  String title;
  boolean displayTitle;
  PFont f;
  float fontSize;
  float rotation; // amount to rotate graph by in radians?
  int titleColor, positive, negative, background, stroke, barColor;
  boolean showBorderBox, displayValues;
  BRDisplay(float x, float y, float width, float height){
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.rotation = 0;
    this.titleColor = color(50); 
    this.showBorderBox = true;
    this.positive = color(116,178,127);
    this.barColor = this.positive;
    this.negative = color(201,104,100);
    this.background = color(230);
    this.stroke = color(177,184,176);
    this.title = "title here";
  }
  public void setTitleColor(int tColor){
    this.titleColor = tColor;
  }
  public void showTitle(){
    displayTitle = true;
  }
  public void hideTitle(){
    displayTitle = false;
  }
  public void changeTitle(String newTitle){
    this.title = newTitle;
  }
  public void rotateChart(float rot){
    this.rotation = rot;
  }
  public void setFont(PFont nf, float size){
    this.f = nf;
    this.fontSize = size;
  }
  public void setPositiveColor(int pColor){
    this.positive = pColor;
  }
  public void setNegativeColor(int pColor){
    this.negative = pColor;
  }
  public void setBarColor(int pColor){
    this.barColor = pColor;
  }
  public void setBackgroundColor(int pColor){
    this.background = pColor;
  }
  public void setStrokeColor(int pColor){
    this.stroke = pColor;
  }
  public void showBorderBox(){
    this.showBorderBox = true;
  } 
  public void hideBorderBox(){
    this.showBorderBox = false;
  }
  public void displayValues(){
    this.displayValues = true;
  } 
  public void hideValues(){
    this.displayValues = false;
  }
}

class BRMidGraph extends BRDisplay{
  //at a mid point changes color
  //stays within
  float mean, min, max, value;
  float padding;
  BRMidGraph(float x, float y, float width, float height, float min, float mean, float max){
    super(x,y,width,height);
    // mean will be middle of graph
    // min & max are expected lows and highs.
    this.mean = mean;
    this.min = min;
    this.max = max;
    this.padding = this.height / 8;
    this.value = mean;
  }
  public void updateValue(float val){
    this.value = val;
  }
  public void drawDisplay(){
    
    float valWidth = calculateValueWidth();    
    pushMatrix();
    translate(this.x, this.y);
    if(this.rotation != 0){
      translate(this.width / 2, this.height / 2);
      rotate(this.rotation);
      translate(- this.width / 2, - this.height / 2);
    }
    if(this.displayTitle){
      //f = createFont("Arial", 24);
      noStroke();
      fill(this.titleColor);
      textFont(this.f, this.fontSize);
      text(this.title, 0, -3);
    }
    strokeWeight(1);
    if(this.showBorderBox){
      stroke(this.stroke);
      fill(this.background);
      rect(0,0, this.width, this.height);
    }
    line(this.width / 2, 0, this.width / 2, this.height);
    if(this.value > this.mean){
      fill(this.positive);
      rect(this.width / 2, this.padding, valWidth, this.height - this.padding * 2);
    } else if(this.value < this.mean){
      fill(this.negative);
      float xm = this.width / 2 - valWidth + this.padding;
      float widthm = valWidth;
      rect(xm, this.padding, widthm, this.height - this.padding * 2);
    }
    popMatrix();
  }
  public float calculateValueWidth(){
    float dist = this.value - this.mean;
    if(dist < 0){
      float te = this.mean - this.min;
      return map(abs(dist), 0, te, 0, this.width / 2);
    } else if( dist > 0 ) {
      return map(dist, 0, this.max - this.mean, 0, this.width / 2);
    } else{
      return 0;
    }
  }
}
class BRHistogram extends BRDisplay{
  ArrayList data = new ArrayList();
  float mean, min, max, average;
  float padding;
  float barWidth;
  boolean showAverage;
  float firstValue; // needed for determining initial max that everythign else is based off of.
  
  BRHistogram(float x, float y, float width, float height){
    super(x,y,width,height);
    this.padding = this.height / 8;
    this.barWidth = 0.02f * width;
    this.showAverage = false;
    this.max = 0;
  }
  public void setBarWidth(float wid){
    this.barWidth = wid;
  }
  public void setPadding(float pad){
    this.padding = pad;
  }
  public void update(float val){
    this.data.add(val);
    if(val > this.max){
      this.max = val;
    }
    computeAverage(val);
  }
  public void toggleAverage(){
    if(this.showAverage){
      this.showAverage = false;
    } else {
      this.showAverage = true;
    }
  }
  public void computeAverage(float val){
    if(this.data.size() == 1){
      this.average = val;
      this.firstValue = val;
      return;
    }
    float avgOver = this.data.size();
    if(this.data.size() > 365){
      avgOver = 365; // 30 days or ticks or however fast I'm feeding in information!
    }
    this.average -= this.average / avgOver;
    this.average += val / avgOver;
  }
  public void drawDisplay(){
    fill(this.background);
    pushMatrix();
    translate(this.x, this.y);
    rect(0,0, this.width, this.height);
    pushMatrix();
     ///INSIDE THE CHART!
     float shift = 0;
     float shiftBy = 0;
     if(data.size() * this.barWidth > this.width){
       //We need to apply a shift.
       float linesInView = this.width / this.barWidth;
       shiftBy = data.size() - linesInView;
       shift = shiftBy * this.barWidth;
     }
     float scaleBy = 0;
     
     float tmpMx = this.max /  map(height, 20,400,0.1f,4.1f); // height = 100 was 200 / somehting to do with first value
     for(int i = data.size() - 1; i > shiftBy; i--){
       scaleBy = ((float)data.get(i) / tmpMx * 100);
       fill(color(116,178,127));
       stroke(this.background);
       strokeWeight(0.5f);
       rect(width - i * this.barWidth + shift, this.height - scaleBy,this.barWidth, scaleBy);
     }
     if(this.showAverage){
       stroke(255);
       strokeWeight(1);
       scaleBy = (this.average / tmpMx * 100);
       line(0, height - scaleBy, this.width, height - scaleBy);
     }
    popMatrix();
    popMatrix();
  }
}

class BRStaticHistogram extends BRHistogram{
  final float MIN_WIDTH = 15; // 15 px min width for a bar.
  int columns; // num of columns.
  float [] columnVals; // how many values have we accumulated in this equivilant table. Parallel tables. 0,25,50,25,0
  float [] columnUnits; // from 0-99.999, 100 - 199.999 etc...
  float barWorth;// how valuable is each bar on the graph?
  int maxVals;// what is the highest val of any column?
  boolean displayXAxis = false;
  
  BRStaticHistogram(float x, float y, float width, float height, int columns){
    super(x,y,width,height);
    this.columns = columns;
    this.barWidth = width / columns; // px val
    if(this.barWidth < MIN_WIDTH){
      this.barWidth = MIN_WIDTH;
      columns = (int)(width / MIN_WIDTH);
    }
    columnUnits = new float[columns];
    columnVals = new float[columns];
    this.maxVals = 0;
  }
  public void displayXaxis(){
    this.displayXAxis = true;
  }
  public void hideXaxis(){
    this.displayXAxis = false;
  }
  
  public void update(float val){
    this.data.add(val);
    if(val > this.max){
      this.max = val;
      reIndexValues();
    } else if(val < this.min){
      this.min = val;
      reIndexValues();
    }else{
      assignValueToGrid(val);
    }
    computeAverage(val);
  }
  
  public void computeAverage(float val){
    for(int i = 0; i < columns; i++){
      this.average += columnVals[i];
    }
    this.average /= columns;
  }
  
  public void reIndexValues(){
    //we've had something larger than we've ever had to store, put it in the left most column, and each column is now worth a different amount!
    calculateBarWorth();
    columnUnits[0] = 0;
    columnVals[0] = 0;
    this.maxVals = 0;
    
    for(int i = 0; i < columns; i++){
      columnUnits[i] = this.barWorth * i + this.min;
      columnVals[i] = 0;
    }
    for(int i = 0; i < this.data.size(); i++){
      //place every data into the histogram
      assignValueToGrid((float)this.data.get(i));
    }
  }
  
  public void calculateBarWorth(){
    this.barWorth = (this.max - this.min) / columns;// determines the worth of every column
  }
  public void assignValueToGrid(float value){    
    int grid = 0;
    for(int i = 1; i < columns; i++){
      if(value < columnUnits[i]){
        break;
      }
      grid++;
    }
    
    
    if(grid >= this.columns){
      grid = this.columns - 1;
    }
    if(grid < 0){
      grid = 0;
    }
    columnVals[grid] += 1;
    if(columnVals[grid] > this.maxVals){
      this.maxVals = (int)columnVals[grid];
    }
  }
  public void drawDisplay(){
    fill(this.background);
    pushMatrix();
    translate(this.x, this.y);
    rect(0,0, this.width, this.height);
    pushMatrix();
    
     ///INSIDE THE CHART!
     float scaleBy = 0;
     float tmpMx = this.maxVals / map(height, 20,400,0.1f,4.1f);
     
     for(int i = 0; i < columns; i++){
       scaleBy = (columnVals[i] / tmpMx * 100);
       fill(this.barColor);
       stroke(this.background);
       strokeWeight(0.5f);
       rect(this.barWidth * i, this.height - scaleBy,this.barWidth, scaleBy);
       if(this.displayXAxis){
         pushMatrix();
         translate(this.barWidth * i + this.barWidth / 3, height - 5);
         rotate(QUARTER_PI);
         noStroke();
         fill(this.titleColor);
         textFont(this.f, 12);
         text(floor(this.columnUnits[i]), 10, 10);
         popMatrix();
       }
       if(this.displayValues){
         pushMatrix();
         fill(255);
         translate(this.barWidth * i - this.barWidth / 2.5f, this.height - scaleBy - 10);
         noStroke();
         fill(this.titleColor);
         textFont(this.f, 6);
         text(floor(this.columnVals[i]), 10,10);
         popMatrix();
       }
     }
     
     if(this.showAverage){
       stroke(255);
       strokeWeight(1);
       scaleBy = (this.average / tmpMx * 100);
       line(0, height - scaleBy, this.width, height - scaleBy);
     }
     if(this.displayTitle){
         pushMatrix();
         translate(20, -this.padding);
         noStroke();
         fill(this.titleColor);
         textFont(this.f,  this.fontSize);
         text(this.title, 0,0);
         popMatrix();
       }
    popMatrix();
    popMatrix();
  }
}
class NeuralDisplay extends BRDisplay{
  int inNodes, hidNodes, outNodes;
  float spacingIn, spacingHid, spacingOut, inPosX, hidPosX, outPosX;
  float nodeSize = 10;
  float padding = 5;
  ArrayList<ArrayList<Neuron>> biDemArrList;
  NeuralNetwork brain;

  NeuralDisplay(float x, float y, float width, float height, NeuralNetwork brain){
    super(x,y,width,height);
    //neurons = new ArrayList<Neuron>();
    biDemArrList = new ArrayList<ArrayList<Neuron>>();
    this.brain = brain;
    this.inNodes = brain.inNodes;
    this.hidNodes = brain.hiddenNodes;
    this.outNodes = brain.outNodes;
    setSpacing();
    addNeurons();
    connectNeurons();
  }
  public void setSpacing(){
    spacingIn = this.height / (inNodes + 1);
    spacingHid = this.height / (hidNodes + 1);
    spacingOut = this.height / (outNodes + 1);
    inPosX = nodeSize / 2  + padding;
    hidPosX = this.width / 2;
    outPosX = this.width - nodeSize / 2  - padding;
  }
  public void addNeurons(){
    addColumnOfNeurons(inPosX, spacingIn, inNodes, 0);
    addColumnOfNeurons(hidPosX, spacingHid, hidNodes, 1);
    addColumnOfNeurons(outPosX, spacingOut, outNodes, 2);
  }
  public void addColumnOfNeurons(float xPos, float vSpace, int numNodes, int layer){
    ArrayList<Neuron> neurons = new ArrayList<Neuron>();
    for(int i = 0; i < numNodes; i++){
        Neuron newN = new Neuron(new PVector(xPos, vSpace * (i + 1)), nodeSize, layer, i);
        neurons.add(newN);
    }
    biDemArrList.add(neurons);
  }

  public void connectNeurons(){
    //only need to add connections for the first 2/3 rows or 3/4 rows...
    for(int i = 0; i < biDemArrList.size() - 1 ; i++){
      //which level are we at?
      ArrayList<Neuron> tarr = biDemArrList.get(i);
      float sizeOfNext = 0;
      Matrix weights = transposeMatrix(this.brain.wih);
      if(i == 0){
        sizeOfNext = hidNodes;
      } else{
        sizeOfNext = outNodes;
        weights = transposeMatrix(this.brain.who);
      }
      for(int j = 0; j < tarr.size(); j++){
        //which neuron are we at on the level
        Neuron neuronA = tarr.get(j);
        ArrayList<Neuron> nextLevelAL = biDemArrList.get(i + 1);
        for(int k = 0; k < sizeOfNext; k++){
          float weight = weights.matrix[j][k];
          Neuron neuronB = nextLevelAL.get(k);
          //neuronA.connect(neuronB, weight);
          neuronA.connect(neuronB, weight);
        }
      }
    }
  }
  
  //void update(NeuralNetwork br){
  public void update(){
    //only need to add connections for the first 2/3 rows or 3/4 rows...
    for(int i = 0; i < biDemArrList.size() - 1 ; i++){
      //which level are we at?
      ArrayList<Neuron> tarr = biDemArrList.get(i);
      float sizeOfNext = 0;
      Matrix weights = transposeMatrix(this.brain.wih);
      if(i == 0){
        sizeOfNext = hidNodes;
      } else{
        sizeOfNext = outNodes;
        weights = transposeMatrix(this.brain.who);
      }
      for(int j = 0; j < tarr.size(); j++){
        //which neuron are we at on the level
        Neuron neuronA = tarr.get(j);
        if(i == 0){
           neuronA.setStrength(this.brain.inputsNodesM[j]);
        } else {
          neuronA.setStrength(this.brain.hiddenNodesM[j]);
        }
        //ArrayList<Neuron> nextLevelAL = biDemArrList.get(i + 1);
        for(int k = 0; k < sizeOfNext; k++){
          float weight = weights.matrix[j][k];
          //Neuron neuronB = nextLevelAL.get(k);
          neuronA.setWeight(k, weight);
        }
      }
    }
    for(int i = 0; i < outNodes; i++){
      Neuron outNeuron = biDemArrList.get(2).get(i);
      outNeuron.setStrength(this.brain.outputNodesM[i]);
    }
  }
  
  public void drawDisplay(){
    update();
    fill(this.background);
    pushMatrix();
    translate(this.x, this.y);
    rect(0,0, this.width, this.height);
    pushMatrix();
    for (ArrayList layer: biDemArrList) {
      for(int i = 0; i < layer.size(); i++){
        Neuron n = (Neuron)layer.get(i);
        n.display();
      }
    }
     if(this.displayTitle){
       pushMatrix();
       translate(20, - 10);
       noStroke();
       fill(this.titleColor);
       textFont(this.f,  this.fontSize);
       text(this.title, 0,0);
       popMatrix();
    }
    popMatrix();
    popMatrix();
  }
  
}

class Neuron{
  float size;
  PVector location;
  int layer; // in, mid, out? 0,1,2
  int vPos; // 0,1,2...
  ArrayList<Connection> connections;
  float sum = 0; // sum of all incoming connections
  Neuron(PVector loc, float size, int layer, int pos){
    this.location = loc;
    this.size = size;
    this.layer = layer;
    this.vPos = pos;
    connections = new ArrayList<Connection>();
  }
  public void connect(Neuron nextNeuron, float weight){
    //need to throw in weight some how?
    connections.add(new Connection(this, nextNeuron, weight));
  }
  public void setWeight(int con, float weight){
    connections.get(con).setWeight(weight);
  }
  public void setStrength(float str){
    this.sum = str;
  }
  public void display(){
    pushMatrix();
    translate(location.x, location.y);
    fill(map(sum, -1,1, 0,255));
    strokeWeight(1);
    stroke(0);
    ellipse(0,0,10,10);        
    popMatrix();
    for(Connection c : connections){
      c.display();
    }
  }
}
class Connection{
  float weight;
  Neuron a;
  Neuron b;
  float blackness; // the darker the line, the stronger the connection. (strong 0 - 255 weak)
  Connection(Neuron from, Neuron to, float w) {
    weight = w;
    a = from;
    b = to;
    this.blackness = map(w, -1, 1, 255, 0);
  }
  public void setWeight(float wei){
    this.weight = wei;
  }
  public void display(){
    strokeWeight(0.7f);
    stroke(blackness);
    line(a.location.x, a.location.y, b.location.x, b.location.y);
  }
}
class BrainInput extends InputComponent {
  //responsible for moving the ant around intelligently
  float[] outputs;
  float[] inputs;
  float feeler1Direction = 0.1f;
  float feeler2Direction = -0.1f;
  float memory1, memory2 = 0;
  Ant parent;
  BrainInput(int inputNodes,int hiddenNodes,int outputNodes,float learningRate, Ant ant){
    this.brain = new NeuralNetwork(INPUTN, hiddenNodes, OUTN, learningRate);
    this.parent = ant;
    outputs = new float[OUTN];
    inputs = new float[INPUTN];
  }
  BrainInput(BrainInput pBrain, Ant ant){
    this.brain = new NeuralNetwork(pBrain.brain);
    //this.brain.mutate(); // when I get my parents brain I need to mutate it a bit to evolve new behaviours.
    this.parent = ant;
    outputs = new float[OUTN];
    inputs = new float[INPUTN];
  }
  public void mutate(){
    this.brain.mutate();
  }
  
  public BrainInput clone(Ant parentAnt, BrainInput grandparentsbrain){
    //println("Coppied Brain!" + random(0,200));
    return new BrainInput(grandparentsbrain, parentAnt);
  }
  public void update(){
    //gather inputs
    //size, biteSize,MAX_BITE_SIZE, currentTempreature, currentEnergy, mouthHue
    
    //feeler1hue, feeler1sat, feeler1bright, feeler2hue, feeler2sat, feeler2bright
    int sensor1 = parent.getSensorInfo(parent.feel1);
    int sensor2 = parent.getSensorInfo(parent.feel2);
    
    inputs[0] = map(parent.getSize(), 4,50,0,1);
    inputs[1] = map(parent.getBiteSize(), 0, 3, 0, 1);
    inputs[2] = map(parent.getWorldTemp(), -5,30, -1, 1);
    inputs[3] = map(parent.energy, DEATH_ENERGY, 400, 0,1);
    inputs[4] = map(parent.differenceBetweenHueAndMouthHue(hue(sensor1)), 0,MAX_DIFF,0,1); // difference between mouth hue and sensor 1
    inputs[5] = map(parent.differenceBetweenHueAndMouthHue(hue(sensor2)), 0,MAX_DIFF,0,1); // difference between mouth hue and sensor 2
    inputs[6] = map(parent.differenceBetweenHueAndMouthHue(parent.getHueUnderneath()), 0,MAX_DIFF,0,1); // difference between mouth hue and right below body
    inputs[7] = map(saturation(sensor1), 0,255,0,1);
    inputs[8] = map(brightness(sensor1), 0,255,0,1);
    inputs[9] = map(saturation(sensor2), 0,255,0,1);
    inputs[10] = map(brightness(sensor2), 0,255,0,1);
    inputs[11] = map(parent.feel1.fLength, 0, parent.feel1.maxFLength, 0,1);//distance away from body 2
    inputs[12] = map(parent.feel2.fLength, 0, parent.feel2.maxFLength, 0,1);//distance away from body 2
    inputs[13] = map(parent.body.velocity.mag(), -MAX_VELOCITY, MAX_VELOCITY, -1, 1);// our bias! ALWAYS stays at 1.
    inputs[14] = parent.feel1.rotation;
    inputs[15] = parent.feel2.rotation;
    inputs[16] = parent.body.velocity.heading();
    inputs[17] = memory1;
    inputs[18] = memory2;
    inputs[19] = 1;
    
    //println(inputs);
  
    outputs = this.brain.query(inputs);
    
    //use out 0 & 1 for rotation and velocity
    parent.body.rotateBy(outputs[0]);
    parent.body.accelerateBy(outputs[1]);
    
    if(outputs[2] > 0){
      parent.eat(parent.biteSize);
    }

    feeler1Direction = outputs[3];
    feeler2Direction = outputs[4];
    
    if(outputs[5] > 0){
      parent.feel1.growFeeler();
    }
    if(outputs[6] > 0){
      parent.feel1.shrinkFeeler();
    }
    parent.feel1.rotateFeeler(outputs[7]);
    
    if(outputs[8] > 0){
      parent.feel2.growFeeler();
    }
    if(outputs[9] > 0){
      parent.feel2.shrinkFeeler();
    }
    parent.feel2.rotateFeeler(outputs[10]);

    if(outputs[11] > 1.5f){
      parent.giveBirth();
    }
    
    this.memory1 = outputs[12];
    this.memory2 = outputs[13];
    
  }
  
  
  

  
}
static enum  Weather {
  Rain,
  Snow,
  Sunny,
  Cloudy
};

class Climate{
  Weather weather;
  float temp; //weather in degrees C
  float inc;
  boolean seasonsOn;
  
  
  Climate(){
    this.weather = Weather.Sunny;
    this.temp = 20;
    seasonsOn = true;
    this.inc = TWO_PI / DAYS_IN_YEAR;
  }
  
  public void update(){
    if(this.temp > MAXIMUM_TEMP){
      this.temp = MAXIMUM_TEMP;
    } else if(this.temp < MINIMUM_TEMP){
      this.temp = MINIMUM_TEMP;
    }
    
    if(seasonsOn){
      //roll through days of year
      adjustTemp();
    }
    
  }
  
  public void adjustTemp(){
    //max & min temp will go up and down along a sin wave varyign by noise;
    //this.temp = -1.1;
    this.temp = map(sin(WORLD.getDay() * this.inc),-1,1,AVERAGE_TEMP - 4 * SEASON_STD,AVERAGE_TEMP + 2 * SEASON_STD);  
    
  }
  
  public float getTemp(){
    return this.temp;
  }
  
}
class Feeler{
  //each ant has 2 feelers sticking out from their heads. 
  //They can make them 2x as long as their body
  //They sense what is at the end of the feeler (both other ants and ground)
  float fLength;
  float maxFLength; // can't be more than 3x the size of the ant
  float colorPresent;
  float objectPresent;
  float attachX, attachY; // can't be more than the radius away from 0,0 of ant size, if Ant Shrinks/ grows, this moves proportionally.
  float sensorY, sensorX;
  float rotation; // current rotation
  float growthRate; // how fast and slow can the feeler extend & contract
  int sensorColor;
  
  float sensorSize;
  Ant parent;
  
  Feeler(float x, float y, Ant parent){
    this.attachX = x;
    this.attachY = y;
    this.parent = parent;
    this.maxFLength = parent.getSize() * 2.5f;
    this.fLength = maxFLength; // just for testing, set to 0 when works
    this.rotation = random(0,0);
    calculateGrowthRate();
    this.sensorSize = parent.bodySize / 2.5f;
    if(this.sensorSize <= 0.2f){
      this.sensorSize = 0.2f;
    }
    this.sensorColor = color(0,0,255);
    
  }
  
  public float calculateGrowthRate(){
    float gRate = FEELER_GROWTH_RATIO * this.parent.getSize();
    this.growthRate = gRate;
    return this.growthRate;
  }
  
  public Feeler updateFeeler(){
    maxFLength = parent.getSize() * 2.5f;
    sensorSize = parent.getSize() / 3;
    if(sensorSize > 10){
      sensorSize = 10;
    } else if(this.sensorSize <= 0.2f){
      sensorSize = 0.2f;
    }
    return this;
  }
  
  public void calculateSensorPos(){
    sensorX = this.parent.body.position.x + this.fLength * cos(this.rotation);
    sensorY = this.parent.body.position.y + this.fLength * sin(this.rotation);
  }
  public void drawFeeler(){
    calculateSensorPos();
    strokeWeight(0.5f);
    colorMode(HSB, 255);
    stroke(0);
    if(brightness(this.sensorColor) < WATER_MIN_BRIGHT){
      stroke(255);
    } 
    fill(this.sensorColor);
    line(this.attachX + this.parent.body.position.x, this.attachY + this.parent.body.position.y, sensorX, sensorY);
    strokeWeight(0.25f);
    ellipse(sensorX, sensorY, sensorSize, sensorSize);
  }
  
  public int getSensorInfo(){
    int tCol = WORLD.getColorAtLocation(sensorX, sensorY);
    if(tCol == -1){
      return -1;
    }
    this.sensorColor = tCol;
    
    sensorSize = parent.getSize() / 3;
    if(sensorSize > 10){
      sensorSize = 10;
    } else if(this.sensorSize <= 0.2f){
      sensorSize = 0.2f;
    }
    
    return this.sensorColor;
  }
  
  public void rotateFeeler(float amount){
    //give me direction and amount
    if(amount > FEELER_MAX_ROTATION_RATE){
      rotation += FEELER_MAX_ROTATION_RATE;
    } else if(amount < FEELER_MAX_ROTATION_RATE * -1){
      rotation -= FEELER_MAX_ROTATION_RATE;
    } else{
      rotation += amount;
    }
  }
  public void growFeeler(){
    // try to grow the feeler by an amount
    calculateGrowthRate();
    fLength += growthRate;  
    if(fLength > maxFLength){
      fLength = maxFLength;
    }
    //parent.energy -= abs(growthRate / 30);
  }
  public void shrinkFeeler(){
    calculateGrowthRate();
    fLength -= growthRate;
    if(fLength < 0){
      fLength = 0;
    }
    //parent.energy -= abs(growthRate / 15);
  }
}
class GUI{
  float x,y, width, height;
  float VSpacing = 25;
  BRMidGraph mgGG, mgBG;
  BRHistogram popHistShort, popHistLong;
  NeuralDisplay nd;
  PVector antReportLocation = new PVector(0, this.VSpacing * 6 + 310 + GUI_MARGIN);
  float antDisplayHieght;
  BRStaticHistogram dAge, bAge;
  float ticks = 0;
  int backgroundColor = color(0,0,0, 150);
  int textColor = color(255);
  int chartColor = color(10);
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
    topAnts = new DisplayTable(antReportLocation.x, antReportLocation.y, width - GUI_MARGIN * 2, antDisplayHieght);
    topAntData = new ArrayList<Ant>();
    antDisplayHieght = height * 0.37f;
  }
  
  public void createRollingHistogram(){
    popHistShort = new BRHistogram(0, this.VSpacing * 6 + 10, this.width - GUI_MARGIN * 2, 50);
    popHistShort.toggleAverage();    
    popHistShort.setBackgroundColor(chartColor);

    popHistLong = new BRHistogram(0, this.VSpacing * 6 + 60 + GUI_MARGIN, this.width - GUI_MARGIN * 2, 50);
    popHistLong.toggleAverage();
    popHistLong.setTitleColor(textColor);
    popHistLong.setBackgroundColor(chartColor);
  }
  public void createGrassGraphs(){
    mgGG = new BRMidGraph(width - GUI_MARGIN - this.VSpacing * 6.5f, 60, 150, this.VSpacing * 0.7f, -MAX_DEATH_RATE,0,MAX_GROWTH_RATE);
    mgGG.showTitle();
    mgGG.changeTitle("green crop growth");
    mgGG.setTitleColor(textColor);
    mgGG.rotateChart(-HALF_PI);
    
    mgBG = new BRMidGraph(width - GUI_MARGIN - this.VSpacing * 4.5f, 60, 150, this.VSpacing * 0.7f, -MAX_DEATH_RATE,0,MAX_GROWTH_RATE);
    mgBG.showTitle();
    mgBG.changeTitle("blue crop growth");
    mgBG.rotateChart(-HALF_PI);
    mgBG.setTitleColor(textColor);
  }
  public void createHistograms(){
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
  
  public GUI drawGUI(){
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

  public void drawInside(){
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
  
  public void drawAntsTable(){
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
  
  public void drawAntReport(PFont f){
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
  
  public void displayNeuralNet(Ant ant){
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
  public void removeNeuralNet(){
    antReport = false;
  }
  public GUI updateGUI(){
    this.backgroundMap.update();
    return this;
  }
  public void setBackgroundColor(int col){
    this.backgroundColor = col;
  }
  public void anotherAntDied(float ageOfAnt){
    // TODO sub for notifications
    dAge.update(ageOfAnt);
  }
  public void anotherAntBirthed(float ageOfAnt){
    bAge.update(ageOfAnt);
  }
  
  public void drawStaticHistograms(PFont f){
    dAge.setFont(f,10);
    dAge.drawDisplay();
    bAge.setFont(f,10);
    bAge.drawDisplay();
  }
  
  public void drawHistograms(PFont f, float population){
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
  public void drawTitleText(PFont f, float population){
    textFont(f,25);
    fill(textColor);
    stroke(1);
    text("circle simulator", 0, 0);
    textFont(f,11);
    text("and now with brains", 0, 14);
    textFont(f,15);
    fill(textColor);
    text("temperature:    " + floor(WORLD.getTemp()) + "\u00baC", 0, this.VSpacing * 2);
    text("population:       " + population, 0, this.VSpacing * 3);
    float year = WORLD.getYear();
    text("year:                  " + round(year), 0, this.VSpacing * 4);
    float day = WORLD.getDay();
    text("day:                   " + floor(day), 0, this.VSpacing * 5);
  }
  
  public void leftClicked(){
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
//home screen
final int BACKGROUND_COLOR = color(30,30,30);

//World
final float DAY_PROGRESS = 0.1f; // 1/10 day every update
final float DAYS_IN_YEAR = 365;

//general setup
final int MIN_ANTS = 25;
final float WATER_MIN_BRIGHT = 95; // between 0 & 255 (adds more water)
final float MAP_SCALE = 14; // pixel size of tiles
final float HUE_MAP_NOISE = 0.04f; // not a percentage, just how much change in noise! 0.1
final float SATURATION_MAP_NOISE = 0.5f; // not a percentage, just how much change in noise! 0.1
final float BRIGHTNESS_MAP_NOISE = 0.3f; // not a percentage, just how much change in noise! 0.3

//climate
final float MINIMUM_TEMP = -200;
final float MAXIMUM_TEMP = 200;
final float AVERAGE_TEMP = 20; //(20)
final float SEASON_STD = 5; //seasonal standard deviation (6)
//final float NUM_SEASONS = 2; // winter & summer
//final float EXTREME_OF_TEMP = 1; // should eventually be noise for how extreme the temp can get

//Tile
final float MIN_LAND_ENERGY = 30; // the minimum available energy left on a piece of land that ants can bite into or can be removed
final float MAX_SAT_VAL = 500;
final float REMOVE_FADE = 0.3f; // how quickly does the ants trail of brightness fade away?
final float MIN_BRIGHT = WATER_MIN_BRIGHT + 80; // what should we fade down to?
final float ANT_SCENT = 240; // how bright can an ant make a trail?

//MAP
final boolean CLEAN_MAP = true; //clean up lakes
final boolean SHOW_TILE_INFO = false;
final float MAX_GROWTH_RATE = 0.15f;
final float MAX_DEATH_RATE = 0.03f;
//tile for grass growth, green 120 & yellow 60
final float IDEAL_GROWTH_GRASS = 25; // ideal temp for crops
final float FREEZING_TEMP_GRASS = 12; // temp when growth turns into death, from ideal to here it just slows down significantly
final float BURNING_TEMP_GRASS = 28; // temp when growth turns into death from heat.
//tile for blue grass growth, blue 240 & magenta 300
final float IDEAL_GROWTH_BLUE = 12; // ideal temp for crops
final float FREEZING_TEMP_BLUE = 3; // temp when growth turns into death, from ideal to here it just slows down significantly
final float BURNING_TEMP_BLUE = 20; // temp when growth turns into death from heat.
final float WORLD_FRICTION = 0.01f; // if it is 1, nothing can move. if it is less, they slow down over time.
final float INITIAL_FOOD = 30; // How much food is initially on each tile (will still vary slightly).

//ANT SPECIFIC
final float ENERGY_REQUIRED_MOVE = 0.8f;//1
final float ENERGY_REQUIRED_SWIM = 1.8f;//3
final float ENERGY_REQUIRED_BIRTH = 30;//how much energy does the birthing process take? (just make sure this + starting aren't greater than death energy)
final float STARTING_ENERGY = 80; // when triple the starting energy you can birth (150)
final float DEATH_ENERGY = 30; // when do I die?
final float MAX_BITE_SIZE = 6.0f; //bite size can't be changed by them.
final float SCOPE = 70.0f; // How picky is the ant? 63.5 (255 / 4) for eating exactly 1/2 the spectrum. gets hurt by other 1/2 (Higher number for a less picky ant, that also gets hurt less!)
final float MAX_DIFF = 127.5f; // will change if the color hue changes from 255
final float ANT_BRIGHTNESS = 150; //how bright is the ant?
final float BREEDING_ENERGY = STARTING_ENERGY * 3.2f; // when can you even think about breeding.
final float MAX_VELOCITY = 0.5f;//0.15
final float MAX_ACCELERATION = 0.5f;//0.04
final boolean SMART_ANTS = true; // do we want the neural network ants turned on?
final float MIN_BREEDING_AGE = 8;

//feeler
final float FEELER_GROWTH_RATIO = 0.03f; // relative growth relative to body size ratio
final float FEELER_MAX_ROTATION_RATE = 0.05f;

//GUI
final float GUI_MARGIN = 5;

//Neural Net
final int INPUTN = 20; // remember always 1 extra here for bias!
final int HIDDENN = 35; // 160
final int OUTN = 14;
final float LEARNING_RATE = 0.13f;

// HELPER CLASSES
class Coordinate{
  int x, y;
  Coordinate(int x, int y){
    this.x = x;
    this.y = y;
  }
}
static class BRMath{
  public static float gaussian(float x, float mean, float variance){
    return (1 / sqrt(TWO_PI * variance)) * exp(-sq(x - mean) / (2 * variance));
 }
 public static float avg(float x, float y){
   return (x + y) / 2;
 }
}
class InputComponent{
  float WALK_ACC = 0.1f;
  float biteSize = MAX_BITE_SIZE;
  NeuralNetwork brain;
  
  InputComponent() { }
  public void update(Ant ant){};
  public void update(){};
  public void mutate(){
    println("Shouldn't show up!");
  }; // only required for brain class
  public void keyPressed(){};
  
  public InputComponent clone(Ant parentAnt, BrainInput grandparentsbrain){
    println("Shouldn't show up!");
    InputComponent clone = this.copy();
    return clone;
  }
  
  public InputComponent copy(){
    // return a copy of this. not this.
    return this.copy();// probably not right.
    
  }
}
class Map{
  
  ArrayList <Ant> ants = new ArrayList<Ant>();
  float mWidth, mHeight;
  final int mColor = color(255,255,255);
  int cols, rows;
  Tile[][] tiles; // where we keep our list of tiles.
  float x, y, scaleBy;
  Ant trackAnt; // a reference to a potential ant you need to follow
  boolean trackingAnt = false;
  int ticks = 0, numOfAnts = 0;
  
  Map(float width, float height, int numAnts){
    this.numOfAnts = numAnts;
    this.mWidth = width;
    this.mHeight = height;
    this.rows = (int)Math.floor(mHeight / MAP_SCALE);
    this.cols = (int)Math.floor(mWidth / MAP_SCALE);
    this.mWidth = cols * MAP_SCALE;
    this.mHeight = rows * MAP_SCALE;
    
    this.tiles = new Tile[cols][rows];
    
    this.x = 0;
    this.y = 0;
    this.scaleBy = 1;
    
    createMap();
    if(CLEAN_MAP){
      removeLakes();
    }
    for(int i = 0; i < numOfAnts; i++){
      if(SMART_ANTS){
        ants.add(createNewSmartAnt());
      } else{
        ants.add(createNewRandomAnt());
      }
    }
  }
  
  public void update(){
    //increase saturation accordin to current climate!
    for(int x = 0; x < cols; x++){
      for(int y = 0; y < rows; y++){
        Tile tile = tiles[x][y];
        tile.update();
      }
    }
    for(int i = 0; i < ants.size(); i++){
      Ant ant = ants.get(i);
      ant.body.update();
      ant.updateAnt();
    }
    if(getAntPopulation() < numOfAnts){
      if(SMART_ANTS){ ants.add(createNewSmartAnt()); } else{ ants.add(createNewRandomAnt()); }
    }
    showTileWithCursor();
  }
  
  public PVector convertTileCoordsToWorldCoords(float xcoord, float ycoord){
    return new PVector(this.scaleBy * xcoord + this.x, this.scaleBy * ycoord + this.y);
  }
  
  public void drawMap(){
    pushMatrix();
    if(trackingAnt){
      if(trackAnt == null){
        trackingAnt = false;
      } else{
        this.x = this.mWidth / 2 - trackAnt.body.position.x * scaleBy;
        this.y = this.mHeight / 2 - trackAnt.body.position.y * scaleBy;
        this.scaleBy = 8.9f;
      }
    }
    
    //if(ticks > 20){
    //  println("XY: " + this.x + "," + this.y);
    //  println("mapWidth / height: " + this.mWidth + "," + this.mHeight);
    //  ticks = 0;
    //}
    //ticks ++;
    translate(this.x, this.y);
    scale(this.scaleBy);
     noFill();
     stroke(mColor);
     for(int r = 0; r < rows; r++){
       for(int c = 0; c < cols; c++){
         pushMatrix();
         translate(c * MAP_SCALE, r * MAP_SCALE);
         tiles[c][r].drawTile();
         popMatrix();
       }
     }
     
     for(int i = 0; i < ants.size(); i++){
        ants.get(i).drawAnt();
      }
     
     popMatrix();
  }
  
  public void followAnt(){
    trackingAnt = true;
  }
  
  public void stopTrackingAnt(){ //different ways of cancelling the follow can call this
    trackingAnt = false;
  }
  
  public void leftClicked(float x, float y){ //human Left clicked a point. find the first ant under that place.
    //TODO: flash their data on println.
    PVector point = convertWorldCoordsToTileCoords(x,y);
    Ant ant = findAntAtPosition(point);
    if(ant != null){
      antGUI.displayNeuralNet(ant);
      this.trackAnt = ant;
    } else{
      antGUI.removeNeuralNet();
      this.trackAnt = null;
    }
    //println(point);
  }
  
  public Ant findAntAtPosition(PVector pt){
    Ant ant = ants.get(0);
    for(int i = 0; i < ants.size(); i++){
      ant = ants.get(i);
      PVector antPos = ant.getPosition();
      if(sqrt((pt.x - antPos.x)*(pt.x - antPos.x) + (pt.y - antPos.y)*(pt.y - antPos.y)) < ant.getSize()){
        return ant;
      }
    }
    return null;
  }
  
  public PVector convertWorldCoordsToTileCoords(float xcord, float ycord){
    //converts from mouse position and graphical coordinates, not x & y coordinates in game
     return new PVector(xcord / this.scaleBy - this.x / this.scaleBy, ycord / this.scaleBy - this.y / this.scaleBy);
  }
  
  public PVector convertXYtoTileCoords(PVector location){
    float col = location.x / (MAP_SCALE * this.scaleBy);
    float row = location.y / (MAP_SCALE * this.scaleBy);
    return new PVector(col, row);
  }
  public void showTileWithCursor(){
    if(this.scaleBy < 1.34f){
      return; // font so small it doesn't matter anyways
    }
    Tile tTile = getTileAtLocation(convertWorldCoordsToTileCoords(mouseX, mouseY));
    if(tTile == null){
      return;
    } else{
      tTile.showDebugInfo();
    }
  }
  
  public boolean worldContainsObject(float centerX, float centerY, float radius){
    //centerX *= this.scaleBy;
    //centerY *= this.scaleBy;
    if(centerX > radius && centerY > radius && centerY + radius < this.mHeight * this.scaleBy && centerX + radius < this.mWidth * this.scaleBy){
      return true;
    }
    return false;
  }
  
  public boolean containsMouse(float mX, float mY){
    //need to transla
    if(mX > this.x && mX < this.x + mWidth * this.scaleBy && mY > this.y && mY < this.y + this.mHeight * this.scaleBy
      && mX < SCREEN_WIDTH - SCREEN_WIDTH * GUI_PERCENT_OF_SCREEN
    ){
      return true;
    }
    return false;
  }
  
  public PVector getLocationWithoutWater(){
    boolean onWater = true;
    PVector loc = new PVector(random(MAP_SCALE * 4, mWidth - MAP_SCALE * 4), random(MAP_SCALE * 4, mHeight - MAP_SCALE * 4));
    Tile tTile = getTileAtLocation(loc);
    if(tTile.type == null){
      return loc;
    }
    if(tTile.type == TileType.tLand){
      return loc;
    }
    while(onWater){
      loc.x =  random(MAP_SCALE * 4, mWidth - MAP_SCALE * 4);
      loc.y =  random(MAP_SCALE * 4, mHeight - MAP_SCALE * 4);
      tTile = getTileAtLocation(loc);
      if(tTile == null || tTile.type == TileType.tLand){
        onWater = false;
      }
    }
    return loc;
  }
  
  public Ant createNewRandomAnt(){
    return new Ant(getLocationWithoutWater(), new RandomInput(), 0);
  }
  public Ant createNewSmartAnt(){
    return new Ant(getLocationWithoutWater(), 0);
  }
  public void birthAnt(Ant parent){
    //ants.add(new Ant(new PVector(parent.position.x, parent.position.y), parent.mHue + (randomGaussian() * 40) - 20, new RandomInput(), parent.generation++));
    antGUI.anotherAntBirthed(parent.getAge());
    ants.add(new Ant(parent));
  }
  public void removeAnt(Ant ant){
    float age2 = ant.getAge();
    antGUI.anotherAntDied(age2);////////////////////// called in the GUIanotherAntDied
    ants.remove(ant);
  }
  public float getAntPopulation(){
    return ants.size();
  }

  public Tile getTileAtLocation(PVector location){
    //Must require a tile coordinate in the map system already scaled
    if(location.x >= mWidth || location.x <= 0 || location.y >= mHeight || location.y <=0){
      //you're off the map
      return null;
    }
    //get tile from coordinates
    int col = (int)location.x / (int)MAP_SCALE;
    int row = (int)location.y / (int)MAP_SCALE;
    if(col < 0 || row < 0 || col >= cols || row >= rows){
      println("Mistake. Called at getTileAtLocation -> Map_Class");
      return null;
    }
    return tiles[col][row];
  }
  
  public void removeLakes(){
    for(int x = 1; x < cols - 1; x++){
      for(int y = 1; y < rows - 1; y++){
        TileType[] type;
        type = new TileType[8];
        type = getTileTypeBetweenCoords(new Coordinate(x-1,y-1), new Coordinate(x+1,y+1));
        //type at position 4.. (the middle)
        TileType testType = type[4];
        //only check if water
        if(testType == TileType.tWater){
          int waterTouching = 0; // how many other bodies of water touching me?
          for(int i = 0; i < 8 ; i++ ){
            if(type[i] == TileType.tWater){
              waterTouching += 1;
            }
          }
          if(waterTouching == 1){
            tiles[x][y].brightness = 100;
            tiles[x][y].type = TileType.tLand;
          }
        }
      }
    }
  }
  
  private TileType[] getTileTypeBetweenCoords(Coordinate start, Coordinate end){
    int xLen = end.x - start.x + 1;
    int yLen = end.y - start.y + 1;
    TileType[] returnType = new TileType[xLen * yLen];
    int i = 0;
    for(int x = start.x; x <= end.x; x++){
      for(int y = start.y; y <= end.y; y++){
        //println("x: " + x + " y: " + y);
        returnType[i] = this.tiles[x][y].type;
        //println(returnType[i]);
        i++;
      }
    }
    return returnType;
  }
  
  public void createMap(){
    float hueSeed = random(0,100);
    float satSeed = random(0,100);
    float brightSeed = random(0,100);
    
    float xOffH = hueSeed;
    float xOffS = satSeed;
    float xOffB = brightSeed;
    
    for(int x = 0; x < cols; x++){
      float yOffH = hueSeed;
      float yOffS = satSeed;
      float yOffB = brightSeed;
      for(int y = 0; y < rows; y++){
        //hue in any range, if brightness below MIN WATER BRIGHT set to 0 for water.
        float brightVal = 0;
        if(noise(xOffB, yOffB) * 255 > WATER_MIN_BRIGHT){
          brightVal = noise(xOffB, yOffB) * 255;
        }
        //println("(" + x + ", " + y + ")");
        tiles[x][y] = new Tile(MAP_SCALE, noise(xOffH, yOffH) * 255, noise(xOffS, yOffS) * INITIAL_FOOD, brightVal, x, y);
        yOffH += HUE_MAP_NOISE;
        yOffS += SATURATION_MAP_NOISE;
        yOffB += BRIGHTNESS_MAP_NOISE;
      }
      xOffH += HUE_MAP_NOISE;
      xOffS += SATURATION_MAP_NOISE;
      xOffB += BRIGHTNESS_MAP_NOISE;
   }
 }
}
//This file is developed elsewhere for testing and pasted here
//Written by Brendan Robertson based off of works & videos by Daniel Shiffman!
final float LIKLEYHOOD_MUTATION = 0.1f;

class NeuralNetwork{
  float[] inputsNodesM, hiddenNodesM, outputNodesM;
  Boolean display = false;
  int inNodes, hiddenNodes, outNodes;
  float lr; //learning rate
  Matrix wih; //weights input to hidden
  Matrix who; //weights hidden to output
  float bias = 1;
  
  //constructors, from parent or a new neural net
  NeuralNetwork(int inputNodes,int hiddenNodes,int outputNodes,float learningRate){
    //no extra activation function for now, as we will simply use sigmoid by default.
    this.inNodes = inputNodes;
    this.outNodes = outputNodes;
    this.hiddenNodes = hiddenNodes;
    this.lr = learningRate; // default this to 0.1;
    this.wih = new Matrix(hiddenNodes, inputNodes);
    this.who = new Matrix(outputNodes, hiddenNodes);
    this.inputsNodesM = new float[inputNodes];
    this.hiddenNodesM = new float[hiddenNodes];
    this.outputNodesM = new float[outputNodes];
    
    //start with random weights, could change over time.
    this.wih.randomize();
    this.who.randomize();
  }
  NeuralNetwork(NeuralNetwork parent){
    //we can construct by simply passing in another network i.e. our parents weights
    this.inNodes = parent.inNodes;
    this.outNodes = parent.outNodes;
    this.hiddenNodes = parent.hiddenNodes;
    
    //Weights passing on!!!
    this.wih = parent.wih.copy();
    this.who = parent.who.copy();
    this.lr = parent.lr;
  }
  
  //for when we need a copy
  public NeuralNetwork copy(){
    return new NeuralNetwork(this);
  }
  public void displayNodes(){
    //call when you want to save the matricies for display!
    this.display = true;
  }
  public void hideNodes(){
    this.display = false;
  }
  public void mutate(){
    //pass the matrix a mutator function
    //this.wih = Matrix.map(this.wih); //uses the mutate function found below
    //this.who = Matrix.map(this.who); //uses the mutate function below
    this.wih = mapMatrixMutate(this.wih);
    this.who = mapMatrixMutate(this.who);
  }
  
  //not sure if I will use this.
  public void train(float []inputsArray, float []targetsArray){
    //Convert our inputs and target to a matrix that we can do matrix math with.
    Matrix inputs = new Matrix(inputsArray);
    Matrix targets = new Matrix(targetsArray);
    
    //the inputs to hidden = wih * inputs
    Matrix hiddenInputs = dotMatrix(this.wih, inputs);
    
    //the hidden outputs pass through sigmoid (0 or 1);
    Matrix hiddenOutputs = mapMatrixSigmoid(hiddenInputs);
    
    //we need some way of getting the output nodes our who (weights, and our outputs)
    Matrix outputInputs = dotMatrix(this.who, hiddenOutputs);
    
    //do the same thing again we map our output to our activation function
    Matrix outputs = mapMatrixSigmoid(outputInputs);
    
    //now what's the error?
    Matrix outputErrors = subtractMatrix(targets, outputs);
    
    //great... now start back propogation
    Matrix whoT = transposeMatrix(this.who);
    //hidden errors
    Matrix hiddenErrors = dotMatrix(whoT, outputErrors);
    
    Matrix gradientOutput = mapMatrixSigmoidDerivative(outputs);
    
    //weight by errors and learning rate
    gradientOutput.multiply(hiddenErrors);
    gradientOutput.multiply(this.lr);
    
    //next layer back
    Matrix gradientHidden = mapMatrixSigmoidDerivative(hiddenOutputs);
    //weights again by errors and learning rate
    gradientHidden.multiply(hiddenErrors);
    gradientHidden.multiply(this.lr);
    
    //change in weights from hidden --> output who
    Matrix hiddenOutputs_T = transposeMatrix(hiddenOutputs);
    Matrix deltaW_output = dotMatrix(gradientOutput, hiddenOutputs_T);
    this.who.addMatrix(deltaW_output);
    
    //change in weights from input --> hidden wih
    Matrix inputs_T = transposeMatrix(inputs);
    Matrix deltaW_hidden = dotMatrix(gradientHidden, inputs_T);
    this.wih.addMatrix(deltaW_hidden);
  }
  
  //query the network
  public float[] query(float []inputsArray){
    // OUR INPUT BIAS SHOULD HAVE COME IN WITH THE INPUTS ARRAY
    if(inputsArray[inputsArray.length - 1] != 1){
      //println("Need to have last input set to 1. Neural Net Error. In Query.");
    }
    
    //1
    Matrix inputs = new Matrix(inputsArray);
    //inputs = mapMatrixTanh(inputs);
    
    //2 get hidden inputs from two arrays
    Matrix hiddenInputs = dotMatrix(this.wih, inputs);
    //3
    //Matrix hiddenOutputs = mapMatrixSigmoid(hiddenInputs);
    Matrix hiddenOutputs = mapMatrixTanh(hiddenInputs);
    //4
    Matrix outputInputs = dotMatrix(this.who, hiddenOutputs);
    //
    //Matrix outputs = mapMatrixSigmoid(outputInputs);
    Matrix outputs = mapMatrixTanh(outputInputs);
    //6
    //println("Wights to output");
    //println(this.who.toString());
    if(this.display){
      inputsNodesM = inputs.toArray();
      hiddenNodesM = hiddenInputs.toArray();
      outputNodesM = outputs.toArray();
    }
    return outputs.toArray();
  }
  
}

class Matrix{
  int rows, cols; // our grid
  float[][] matrix;
  //ways to get a new matrix
  Matrix(int rows, int cols){
    this.rows = rows;
    this.cols = cols;
    this.matrix = new float[rows][cols];
    //initalize all values to 0!
    for(int i = 0; i < rows; i++){
      for( int j = 0; j < cols; j++){
        this.matrix[i][j] = 0;
      }
    }
  }
 public String toString(){
   String lines = "";
   for(int i = 0; i < rows; i++){
     lines += "[";
      for( int j = 0; j < cols; j++){
        lines += "[" + this.matrix[i][j] + "]";
      }
     lines += "]\n";
    }
    return lines;
    
 }
  Matrix(float arr[]){
    this.rows = arr.length;
    this.cols = 1;
    this.matrix = new float[rows][cols];
    //initalize all values to array!
    for(int i = 0; i < arr.length; i++){
      this.matrix[i][0] = arr[i];
    }
  }

  
  public Matrix copy(){
    Matrix copy = new Matrix(this.rows, this.cols);
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        copy.matrix[i][j] = this.matrix[i][j];
      }
    }
    return copy;
  }
  
  // methods
  public void randomize(){
    for(int i = 0; i < rows; i++){
      for( int j = 0; j < cols; j++){
        this.matrix[i][j] = randomGaussian();
      }
    }
  }
  
  //For multiply we can either multiply a scalar (single value)
  public void multiply(float x){
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        this.matrix[i][j] *= x;
      }
    }
  }
  public void multiply(Matrix b){
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        this.matrix[i][j] *= b.matrix[i][j];
      }
    }
  }
  public void addMatrix(Matrix b){
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        this.matrix[i][j] += b.matrix[i][j];
      }
    }
  }  
  public void addMatrix(Float x){
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        this.matrix[i][j] += x;
      }
    }
  }
  
  public float[] toArray(){
    float size = this.rows * this.cols;
    float[] array;
    array = new float[(int)size];
    int x = 0;
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        array[x] = this.matrix[i][j];
        x ++;
      }
    }
    return array;
  }
}

//can't figure out how to mix and match static methods with non-static classes.

//static methods for matrix's ends in Matrix.
public Matrix mapMatrixMutate(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  //[[0],[0],[0],[0]]
  //[[],[],[],[]]
  //[[],[],[],[]]
  //[[],[],[],[]]
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = mutateMatrix(a.matrix[i][j]);
    }
  }
  return result;
}

public Matrix mapMatrixSigmoid(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = sigmoid(a.matrix[i][j]);
    }
  }
  return result;
}
public Matrix mapMatrixSigmoidDerivative(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = sigmoidDerivative(a.matrix[i][j]);
    }
  }
  return result;
}
//tanh for +-1
public Matrix mapMatrixTanh(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = tanh(a.matrix[i][j]);
    }
  }
  return result;
}
public Matrix mapMatrixTanhDerivative(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = tanhDerivative(a.matrix[i][j]);
    }
  }
  return result;
}

public Matrix transposeMatrix(Matrix a){
  Matrix result = new Matrix(a.cols, a.rows);
  for(int i = 0; i < result.rows; i++){
    for( int j = 0; j < result.cols; j++){
      result.matrix[i][j] = a.matrix[j][i];
    }
  }
  return result;
}

public Matrix subtractMatrix(Matrix a, Matrix b){
  Matrix result = new Matrix(a.rows, b.cols);
  for(int i = 0; i < result.rows; i++){
      for( int j = 0; j < result.cols; j++){
        result.matrix[i][j] = a.matrix[i][j] - b.matrix[i][j];
      }
    }
  return result;
}

public Matrix addMatrix(Matrix a, Matrix b){
  Matrix result = new Matrix(a.rows, b.cols);
  for(int i = 0; i < result.rows; i++){
    for( int j = 0; j < result.cols; j++){
      result.matrix[i][j] = a.matrix[i][j] + b.matrix[i][j];
    }
  }
  return result;
}

public Matrix addMatrix(Matrix a, float x){
  Matrix result = new Matrix(a.rows, a.cols);
  for(int i = 0; i < result.rows; i++){
    for( int j = 0; j < result.cols; j++){
      result.matrix[i][j] = a.matrix[i][j] + x;
    }
  }
  return result;
}

public Matrix dotMatrix(Matrix a, Matrix b){
  if(a.cols != b.rows){
    //println(a.toString());
    //println(a.cols);
    //println(b.toString());
    //println(b.rows);
    println("Incompatiable Sizes");
  }
  Matrix result = new Matrix(a.rows, b.cols);
  for(int i = 0; i < a.rows; i++){
      for( int j = 0; j < b.cols; j++){
        //sup all the rows of A rows times columns of B
        float sum = 0;
        for(int k = 0; k < a.cols; k++){
          sum += a.matrix[i][k] * b.matrix[k][j];
        }
        result.matrix[i][j] = sum;
      }
    }
  return result;
}


public Matrix multiplyMatrix(Matrix a, Matrix b){
  Matrix result = new Matrix(a.rows, a.cols);
  for(int i = 0; i < result.rows; i++){
      for( int j = 0; j < result.cols; j++){
        result.matrix[i][j] = a.matrix[i][j] * b.matrix[i][j];
      }
    }
  return result;
}
public Matrix multiplyMatrix(Matrix a, Float x){
  Matrix result = new Matrix(a.rows, a.cols);
  for(int i = 0; i < result.rows; i++){
    for( int j = 0; j < result.cols; j++){
      result.matrix[i][j] = a.matrix[i][j] * x;
    }
  }
  return result;
}


// This is how we adjust weights ever so slightly
public float mutateMatrix(float x) {
  if (random(1) < LIKLEYHOOD_MUTATION) { // ten percent chance we mutate the value
    float offset = randomGaussian() * 0.5f;
    // var offset = random(-0.1, 0.1);
    float newx = x + offset;
    return newx;
  } else {
    return x; // we didn't adjust the weight afterall...
  }
}

//our activation function
//https://en.wikipedia.org/wiki/Sigmoid_function the constant is Euelers Constant
public float sigmoid(float x) {
  float y = 1 / (1 + pow(2.71828182845904523536028747135266249775724709369995957496696762772407663035354759457138217852516642742746f, -x));
  return y;
}
public float sigmoidDerivative(float x){
  return x * (1 - x);
}
public float tanh(float x){
  float y = tan(x);
  return y;
}
public float tanhDerivative(float x){
  float y = 1 / (pow(cos(x),2));
  return y;
}
class PhysicsWorld{
  //responsible for holding bodies of physics, will check for collisions
  ArrayList <PhysicsBody> bodies = new ArrayList<PhysicsBody>();
  float mWidth, mHeight;
  float gridSize = MAP_SCALE * 2;
  float gridRows, gridCols;
  //float[][] multi;
  
  CollisionTester colider = new CollisionTester();
  PhysicsWorld(float width, float height){
    this.mWidth = width;
    this.mHeight = height;
    gridRows = mWidth / gridSize;
    gridCols = mHeight / gridSize;
    //multi = new float[gridCols][gridRows];
  }
  public void update(){
    //body.update(); // taken care of by the array in ants.
    //body.display(); // taken care of by the array in ants.
    queryForCollisionPairs(); // just do it on everything!!!
    //create entity grid
    
    queryForWallCollision(); // just do it on everything!!!
  }
  

  public void queryForWallCollision(){
    //check every ant one more time to see if they have collided with the worlds borders
    for(int i = 0; i < WORLD.worldMap.ants.size(); i++){
      Ant ant = WORLD.worldMap.ants.get(i);
      boolean hit = colider.CircleVsEnclosingBox(ant.body, mWidth, mHeight);
      if(hit){
        //println("From physics ant is past wall!");
        //resolveWallTap(ant.body);
        resolveWallTapSwitch(ant.body);
      }
    }
  }
  public void queryForCollisionPairs(){
    //brute force method
    for(int j = 0; j < WORLD.worldMap.ants.size(); j++){
      Ant el1 = WORLD.worldMap.ants.get(j); //3
      for(int i = j + 1; i < WORLD.worldMap.ants.size(); i++){
      Ant el2 = WORLD.worldMap.ants.get(i); // 4,5,6,7,8,9
        boolean avoided = colider.CirclevsCircle((PhysicsCircle)el1.body, (PhysicsCircle)el2.body);
        if(!avoided){
          resolveConflict(el1.body, el2.body);
        }
      }
    }
  }
  
  public void resolveWallTapSwitch(PhysicsCircle a){
    if(a.r > a.position.x){
      a.position.x = this.mWidth - a.r;
    }else if(a.r > a.position.y){
      a.position.y = this.mHeight - a.r;
    }else if(mWidth < a.position.x + a.r){
      a.position.x = a.r;
    }else if(mHeight < a.position.y + a.r){
      a.position.y = a.r;
    } 
  }
  
   public void resolveWallTap(PhysicsCircle a){
    PVector wall = new PVector(0,0); // closest point to wall and ball
    if(a.r > a.position.x){
      wall.y = a.position.y;
    }else if(a.r > a.position.y){
      wall.x = a.position.x;
    }else if(mWidth < a.position.x + a.r){
      wall.y = a.position.y;
      wall.x = mWidth;
    }else if(mHeight < a.position.y + a.r){
      wall.x = a.position.x;
      wall.y = mHeight;
    } 
    // the ant hit a wall!
    // Get distances between the balls components
    PVector distanceVect = PVector.sub(a.position, wall);
    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();
    //what do we need to correct
    float distanceCorrection = (a.r-distanceVectMag) * 2;
    PVector d = distanceVect.copy();
    PVector correctionVector = d.normalize().mult(distanceCorrection);
    a.position.add(correctionVector);
  }
  
  public void resolveConflict(PhysicsCircle a, PhysicsCircle b ){
    // Get distances between the balls components
    PVector distanceVect = PVector.sub(a.position, b.position);
    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();
    // Minimum distance before they are touching
    float minDistance = a.r + b.r;
    //what do we need to correct
    float distanceCorrection = (minDistance-distanceVectMag)/2.0f;
    PVector d = distanceVect.copy();
    PVector correctionVector = d.normalize().mult(distanceCorrection);
    a.position.add(correctionVector);
    b.position.sub(correctionVector);
  }
}

class PhysicsBody{
  //general physics body
  float m;
  float rotation = random(-PI, PI);
  float maxrotation = 0.08f;
  PVector position;
  PVector velocity = new PVector(0,0);
  PVector acceleration = new PVector(0,0);
  
  PhysicsBody(float mass){ 
    this.m = mass;
  }
  
  public void applyForce(PVector force){
    PVector f = force.copy();
    f.div(this.m);
    this.acceleration.add(f);
  }
  public void rotateBy(float rotateBy){
    float myR = map(rotateBy, -5, 5, -maxrotation, maxrotation);
    rotation += myR;
  }
  public void accelerateBy(float accelerateBy){
    PVector f = new PVector(accelerateBy, 0);
    f.limit(MAX_ACCELERATION);
    f.div(this.m);
    this.acceleration.add(f);
  }
  public void update(){
    this.velocity.rotate(rotation);
    rotation = 0;
    this.velocity.add(this.acceleration);
    this.position.add(this.velocity);
    this.acceleration.mult(0);
    
    ////apply forces to ants after updating
    PVector friction = this.velocity.copy();
    friction.mult(-1);
    friction.mult(WORLD_FRICTION);
    this.applyForce(friction);
    ////apply wind, gravity whatver else.
  }
}

class PhysicsCircle extends PhysicsBody{
  //general physics body
  float r;// radius
  PhysicsCircle(float radius, PVector position){
    super(radius * 2);
    this.r = radius;
    this.position = position;
  }
  public void updateSize(float radius){
    this.m = radius * 2;
  }
}

static class CollisionTester{
  //float Distance( Vec2 a, Vec2 b ) {
  //  return sqrt( (a.x - b.x)*(a.x - b.x) + (a.y - b.y)*(a.y - b.y) );
  //}
  public boolean CirclevsCircle( PhysicsCircle a, PhysicsCircle b ){
    float radus = a.r + b.r;
    radus *= radus; // squaring radius
    float dist = (a.position.x - b.position.x) * (a.position.x - b.position.x) + (a.position.y - b.position.y) * (a.position.y - b.position.y);
    if(radus > dist){ return false; }
    return true;
  }
  public boolean CircleVsEnclosingBox( PhysicsCircle a, float mWidth, float mHeight){
    //did the circle hit the wall?
    if(a.r > a.position.x){
      return true;
    }
    if(a.r > a.position.y){
      return true;
    }
    if(mWidth < a.position.x + a.r){
      return true;
    } 
    if(mHeight < a.position.y + a.r){
      return true;
    } 
    return false;
    
  }
}
class PlayerInput extends InputComponent{
  float rotationAmount = 0.02f;
  float controlAntanee = 0;
  Ant ant;
  PlayerInput(){
  }
  public void update(Ant ant){
    if(keyPressed){
      if (key == CODED) {
        //  The variable keyCode is used to detect special keys such as the arrow keys (UP, DOWN, LEFT, and RIGHT) as well as ALT, CONTROL, and SHIFT. 
        //check for 
        if (keyCode == UP) {
          ant.body.applyForce(new PVector(0,-WALK_ACC));
        } else if (keyCode == DOWN) {
          ant.body.applyForce(new PVector(0,WALK_ACC));
        }  else if (keyCode == LEFT) {
          ant.body.applyForce(new PVector(-WALK_ACC, 0));
        }  else if (keyCode == RIGHT) {
          ant.body.applyForce(new PVector(WALK_ACC, 0));
        } else if (keyCode == SHIFT){
          //should be space
          ant.feel1.getSensorInfo();
          ant.feel2.getSensorInfo();
        }
      }
      
      //Non CODED keys
      if(key == '1'){
          controlAntanee = 1;
          println("Controlling antane 1");
        } else if(key == '2'){
          controlAntanee = 2;
          println("Controlling antane 2");
        } else if(key == 'e'){
          ant.eat(biteSize);
        } else if(key == 'b'){
          ant.giveBirth();
          println("Giving Birth");
        } else if (key == 'r'){
          biteSize += 1;
          if(biteSize > MAX_BITE_SIZE){
            biteSize = MAX_BITE_SIZE;
          }
        } else if (key == 'd'){
          biteSize -= 1;
          if(biteSize < 0){
            biteSize = 0;
          } 
        } else if (key == 'q'){
          if(controlAntanee == 0){
            ant.feel1.rotateFeeler(-rotationAmount);
          } else{
            ant.feel2.rotateFeeler(-rotationAmount);
          }
        } else if (key == 'w'){
          if(controlAntanee == 0){
            ant.feel1.rotateFeeler(rotationAmount);
          } else{
            ant.feel2.rotateFeeler(rotationAmount);
          }
        } else if (key == 'a'){
          if(controlAntanee == 0){
            ant.feel1.growFeeler();
          } else{
            ant.feel2.growFeeler();
          }
        } else if (key == 's'){
          if(controlAntanee == 0){
            ant.feel1.shrinkFeeler();
          } else{
            ant.feel2.shrinkFeeler();
          }
        } 
        
    }
  } // end update
}
  
  
class RandomInput extends InputComponent{
  
  RandomInput(){}
  public void update(Ant ant){
    //test for certain conditions and program here!
    ant.eat(MAX_BITE_SIZE);
    computerAnt(ant);
    //rotateAntanee();
    ant.feel1.getSensorInfo();
    ant.feel1.updateFeeler();
    ant.feel2.getSensorInfo();
    ant.feel2.updateFeeler();
    if(ant.energy > BREEDING_ENERGY && random(0,1) < 0.003f){
      ant.giveBirth();
    }
  } // end update

  public void computerAnt(Ant ant){
    if( random(0,100) > 95 ){
      PVector acc = PVector.random2D();
      acc.limit(MAX_ACCELERATION);
      ant.body.applyForce(acc);
      //ant.speed.add(ant.acceleration);
    }
    
    if(!ant.isAntOnMap()){
      ant.body.position.sub(ant.body.velocity);
      ant.energy -= ENERGY_REQUIRED_SWIM * 3;
      ant.body.velocity.rotate(PI / 8);
      return;
    }
  }
}
//future place for table class and cell class
//custom classes and heavily tied to data
class DisplayTable{
  //custom
  float width; float height; float x; float y;
  float padding = 0;
  float cellHeight = 50;
  // table holds a collection of cells
  ArrayList<TableCell> cells;
  int tableColor = color(0,0,0,150);
  DisplayTable(float x, float y, float width, float height){
    this.width = width;
    this.height = height;
    this.x = x;
    this.y = y;
    cells = new ArrayList<TableCell>();
  }
  
  public void drawTable(){
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
  public void updateTable(ArrayList<Ant>topData){
    //we need to determine if cells contain the ants in topData
    cells.clear();
    for(int i = 0; i < topData.size(); i++){
      TableCell cell = new TableCell(this.padding, cellHeight * cells.size(), this.width, this.cellHeight, topData.get(i));
      cells.add(cell);
    }
  }
  public int cellCount(){
    return cells.size();
  }
  public void removeCell(int index){
    cells.remove(index);
  }
}
class TableCell{
  //used for displaying cells in a table.
  int backgroundColor = color(0,0,0,50);
  int cellBorderColor = color(30);
  int headingColor = color(255);
  int textColor = color(200);
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
  public void setCellData(Ant cellD){
    if(this.cellData != cellD){
      this.cellData = cellD;
    }
  }
  public void drawCell(){
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
  public void updateCell(){
    //update data, update index.
    
  }
}
static enum  TileType {
  tWater, // takes more energy to move over
  tLand // can grow food over time
};


class Tile{
  float hue, saturation, brightness;
  float size;
  int x, y;
  float globalBlueGrowth;
  float globalGreenGrowth;
  boolean debugInfoOn;
  TileType type;
  // brightness is set
  // saturation is amount of food on tile
  // hue is type of food
  
  Tile(float size, float hue, float saturation, float brightness, int x, int y){
    this.size = size;    
    //will set how much food etc we have
    this.hue = hue;
    this.saturation = saturation;
    this.brightness = brightness;
    this.x = x;
    this.y = y;
    setTileType();
    this.globalBlueGrowth = 0;
    this.globalGreenGrowth = 0;
    debugInfoOn = false;
  }
  public void showDebugInfo(){
    debugInfoOn = true;
    
  }
  public void setTileType(){
    //dependant on the HSB value, especially the Hue, this could be a rock, water, fire, or land
    if(this.brightness <= 0){
      this.type = TileType.tWater;
    } else{
      this.type = TileType.tLand;
    }
  }
  
  public void update(){
    growGrass();
    removeTrails();
    this.debugInfoOn = false;
  }
  
  public void eat(float biteSize){
    //increase brightness by how much ant is slobbering on me
    this.brightness += biteSize * 2;
    if(this.brightness > ANT_SCENT){
      this.brightness = ANT_SCENT;
    }
  }
  
  public void removeTrails(){
    //REMOVE_FADE
    //MIN_BRIGHT
    
    if(this.brightness <= MIN_BRIGHT){
      return;
    }
    this.brightness -= REMOVE_FADE;
    
  }
  
  public void growGrass(){
    if(this.type != TileType.tLand){ return; }
    // over time increase or decrease saturation based on climate. (Maybe is different based on type of tile).
    float temp = WORLD.getTemp();
    //check type of grass
    if(this.hue < 127.50f){
      growGreenGrass(temp);
    } else{
      growBlueGrass(temp);
    }
  }
  private void growGreenGrass(float temp){
    float growth = getGrowthWith(FREEZING_TEMP_GRASS, IDEAL_GROWTH_GRASS, BURNING_TEMP_GRASS, temp);
    desaturateLand(growth);
    WORLD.setGlobalGrassGrowth(0, growth);
  } 
  private void growBlueGrass(float temp){
    float growth = getGrowthWith(FREEZING_TEMP_BLUE, IDEAL_GROWTH_BLUE, BURNING_TEMP_BLUE, temp);
    growth = desaturateLand(growth);
    WORLD.setGlobalGrassGrowth(1, growth);
  }
  private float desaturateLand(float growth){
    if(growth + this.saturation > MAX_SAT_VAL){
       this.saturation = MAX_SAT_VAL;
       growth = 0;
     } else if(growth + this.saturation < MIN_LAND_ENERGY){
       this.saturation = MIN_LAND_ENERGY;
       growth = 0;
     } else{
       this.saturation += growth;
     }
     return growth;
  }
  private float getGrowthWith(float freeze, float ideal, float burn, float temp){
    //MAX_DEATH_RATE, MAX_GROWTH_RATE (both positive)
    float growthRange = burn - freeze;
    float g = 0;
    if(temp < freeze - growthRange){
      //100% death
      g = -MAX_DEATH_RATE;
    } else if ( temp < freeze ){
      //% of way to full death * MAX_DEATH
      g = ((freeze - temp) / growthRange) * -MAX_DEATH_RATE;
    } else if ( temp < ideal ){
      //% from freeze to ideal X MAX_GROWTH
      g = ((temp - freeze) / (ideal - freeze)) * MAX_GROWTH_RATE;
    } else if( temp < burn ){
      //% from ideal to burn X MAX_GROWTH
      g = ((burn - temp) / (burn - ideal)) * MAX_GROWTH_RATE;
    } else if ( temp < burn + growthRange ){
      //% of way to full death * MAX_DEATH
      g = ((temp - burn) / growthRange) * -MAX_DEATH_RATE;
    } else if ( temp > burn + growthRange ){
      //100% death
      g = -MAX_DEATH_RATE;
    }
    return g;
  }

  public void drawTile(){
    //draw tile
    //stroke(255);
    noStroke();
    colorMode(HSB,255);
    fill(this.hue,this.saturation, this.brightness);
    rect(0,0,size,size);
    
    if(SHOW_TILE_INFO && !this.debugInfoOn){
      if((this.type == TileType.tLand && this.hue > 150) || (this.type == TileType.tLand && this.hue < 100)){
        //output coords
        PFont f;
        f = createFont("Arial", 10, true);
        textFont(f,10);
        fill(255);
        //text("(" + this.x + ", " + this.y + ")", this.size / 2, this.size / 5  * 1);
        //text("(" + floor(this.hue) + "," + floor(this.saturation) + "," + floor(this.brightness) + ")", this.size / 2, this.size / 5  * 2);
        text("" + floor(this.saturation), this.size / 2,this.size/5 *2);
        //text("" + this.type, this.size / 2, this.size / 5  * 3);
      }
    }
    if(this.debugInfoOn){
       //output coords
        PFont f;
        f = createFont("Arial", MAP_SCALE / 2, true);
        textAlign(CENTER, CENTER);
        textFont(f, MAP_SCALE / 2);
        fill(255);
        textSize(MAP_SCALE / 5);
        if(this.brightness > 200){
          fill(0);
        }
        if(this.type == TileType.tWater){
          text("Splish", this.size / 2, this.size / 12  * 4);
          text("Splash", this.size / 2, this.size / 12  * 8);
        } else{
          text("(" + this.x + ", " + this.y + ")", this.size / 2, this.size / 12  * 3);
          textSize(MAP_SCALE / 7);
          float sat =  floor(this.saturation) - MIN_LAND_ENERGY + 1;
          text("Noms:" + sat, this.size / 2, this.size / 12  * 6);
          text("FoodType:" + floor(this.hue), this.size / 2,this.size/12 *9);
        }
    }
  }
  
  //float getAmountOfFood(){
  //  //converts saturation to food
  //  return this.saturation;
  //}
  
  //float getClimate(){
  //  //climate determines what type of food grows here, essentially the hue
  //  return this.hue;
  //}
  
  //float getCurrentFood(){
  //  //returns what is currently on the tile (what is the food of the dead person) (slowly over time this fades back to natural climate);
  //  return this.hue; // when we can change the food type this won't be true;
  //}
  
  //void setCurrentFood(float newFood){
  //  //requires a hue
  //  this.hue = newFood;
  //}
  
}
class World{
  //PROPERTIES
  Map worldMap;
  Climate climate;
  PhysicsWorld physicsWorld;
  StatsClass statistics = new StatsClass();
  
  float dayOfYear = 0, year = 0, totalDay = 0;
  float gGreenGrowth, gBlueGrowth;
  float x, y, scaledBy; //for map
  float highestGen = 0, highestGenThisYear = 0, mostSpawn = 0, mostSpawnThisYear = 0;
  int lastProfile = 0, profileFrequency = 50;
  //CONSTRUCTOR
  World(float worldWidth, float worldHeight){
    physicsWorld = new PhysicsWorld(worldWidth, worldHeight);
    worldMap = new Map(worldWidth, worldHeight, MIN_ANTS);
    climate = new Climate();
    dayOfYear = 0;
    year = 0;
    totalDay = 0;
    lastProfile = profileFrequency + 1;
  }
  
  //METHODS
  public void updateWorld(){
    totalDay += DAY_PROGRESS;
    dayOfYear += DAY_PROGRESS;
    if(dayOfYear > DAYS_IN_YEAR){
      dayOfYear = 0;
      reportOnYear();
      year ++;
    }
    climate.update();
    worldMap.update();
    physicsWorld.update();
    
    lastProfile += 1;
    if(lastProfile > profileFrequency){
      lastProfile = 0;
      statistics.profile(worldMap.ants);
    }
  }
  public void reportOnYear(){
    println("Another year has passed");
    println("Year: " + year);
    float eldestAnt = 0, spawn = 0, generation = 0, highestGeneration = 0, highestSpawn = 0;
    for(Ant tant : worldMap.ants){
      if(tant.generation > highestGeneration){
        highestGeneration = tant.generation;
      }
      if(tant.spawn > highestSpawn){
        highestSpawn = tant.spawn;
      }
      if(tant.getAge() > eldestAnt){
        eldestAnt = tant.getAge();
        spawn = tant.spawn;
        generation = tant.generation;
      }
    }
    
   println("Current Info");
   println("Eldest Ant Currently: " + floor(eldestAnt));
   println("Has spawned: " + floor(spawn) + "ants");
   println("Is generation: " + floor(generation));
   println("The highest generation is currently: " + floor(highestGeneration));
   println("The highest spawned is currently: " + floor(highestSpawn));
   
   println("Yearly Info");
   println("Highest spawn: " + floor(mostSpawnThisYear));
   println("Highest generation this year: " + floor(highestGenThisYear));
   
   println("All Time Info");
   println("Highest spawn A.T.: " + floor(mostSpawn));
   println("Longest Generation to reproduce A.T.: " + floor(highestGen));
   
   
   mostSpawnThisYear = 0;
   highestGenThisYear = 0;
  }
  
  public void sendInfo(Ant ant){
    if(ant.spawn > mostSpawnThisYear){
      mostSpawnThisYear = ant.spawn;
    }
    if(ant.spawn > mostSpawn){
      mostSpawn = ant.spawn;
    }
    if(ant.generation > highestGenThisYear){
      highestGenThisYear = ant.generation;
    }
    if(ant.generation > highestGen){
      highestGen = ant.generation;
    }
  }
  public float getTotalDays(){
    return this.totalDay;
  }
  public float getDay(){
    return this.dayOfYear;
  }
  public float getYear(){
    return this.year;
  }
  public float getTemp(){
    return this.climate.getTemp();
  }
  public void drawWorld(){
    worldMap.drawMap();
  }
  //tiles
  public TileType getTypeOfTileAt(PVector location){
    Tile tile = worldMap.getTileAtLocation(location);
    if(tile == null){
      return null;
    } else{
      return tile.type;
    }
  }
  
  public int getColorAtLocation(float x, float y){
    PVector location = new PVector(x,y);
    Tile tTile = worldMap.getTileAtLocation(location);
    if(tTile == null){
     return -1;
    }
    colorMode(HSB, 255);
    int tColor = color(tTile.hue, tTile.saturation, tTile.brightness);
    return tColor;
  }
  
  public void setGlobalGrassGrowth(int col, float amt){
    if(col == 0){
      this.gGreenGrowth = (this.gGreenGrowth + amt) /2;
    }else if(col == 1){
      this.gBlueGrowth = (this.gBlueGrowth + amt) /2;
    }
  }
  public float getGlobalGrassGrowth(int col){
    float val = 100;
    if(col == 0){
      val = this.gGreenGrowth;
    }else if(col == 1){
      val = this.gBlueGrowth;
    }
    return val;
  }
}




  //import java.util.Collections;
  //Responsible for keeping track of stats
  //Needs to search all ants every 20 frames
  /*
    Array of top 5 ants in the following categories
      Age
      Size/Energy
      Spawn
      Generation
      
    Eldest Ant Currently: 54
      Has spawned: 2ants
      Is generation: 0
      
    The highest generation is currently: 1
    The highest spawned is currently: 2
    Yearly Info
      Highest spawn: 4
      Highest generation this year: 1
    
    All Time Info
      Highest spawn.: 4
      Longest Generation to reproduce: 2
    
  */

class StatsClass{
  boolean sortBiggest = true; // true: get biggest/most first, false: get smallest/least first
  int category = 0; // 0age, 1size, 2spawn, 3generation
  ArrayList<Ant> topAnts;
  int numOfTopAnts = 6;
  StatsClass(){
    topAnts = new ArrayList<Ant>();
  }
  public void sortBiggest(){
    this.sortBiggest = true;
  }
  public void sortSmallest(){
    this.sortBiggest = false;
  }
  public void sortByCategory(int category){
    if(category > 3){
      category = 0;
      println("ERROR: We are sorting by age. We don't have that many categories to sort by. Called from Stats class. ");
    } else{
      this.category = category;
    }
  }
  
  public ArrayList<Ant> getTopAnts(){
    return this.topAnts;
  }
  
  public void profile(ArrayList<Ant> ants){ //profile these ants and see who is the top according to class conditions, (Sort Biggest, & category)
    //ArrayList<Ant> test;
    //this.topAnts.copy(ants);
    this.topAnts.clear();
    //for(int i = 0; i < ants.size(); i++){
    for(int i = ants.size() - 1; i > 0; i--){
      Ant ukAnt = ants.get(i);
      if(topAnts.size() == 0){
        topAnts.add(ukAnt);
      }else{
        switch(category){
          case 0:
            getSortedAge(ukAnt);
            break;
          case 1:
            getSortedSize(ukAnt);
            break;
          case 2:
            getSortedSpawn(ukAnt);
            break;
          case 3:
            getSortedGeneration(ukAnt);
            break;
          default:
            getSortedAge(ukAnt);
            break;
        }
        
      }
    }
  }
  public void getSortedSpawn(Ant ukAnt){
    for(int x = 0; x < numOfTopAnts; x++){
      if(x >= topAnts.size()){
        topAnts.add(ukAnt);
        if(topAnts.size() > numOfTopAnts){
            topAnts.remove(topAnts.size() - 1);
          }
          break;
      }else{
        Ant tAnt = topAnts.get(x);
        //compare top with unknownAnt // for now just ant with largest age
        if(tAnt.spawn <= ukAnt.spawn){
          topAnts.add(x, ukAnt);
          if(topAnts.size() > numOfTopAnts){
            topAnts.remove(topAnts.size() - 1);
          }
          break;
        }
      }
    }
  }
  public void getSortedGeneration(Ant ukAnt){
    for(int x = 0; x < numOfTopAnts; x++){
      
      if(x >= topAnts.size()){
        topAnts.add(ukAnt);
        if(topAnts.size() > numOfTopAnts){
            topAnts.remove(topAnts.size() - 1);
          }
          break;
      }else{
        Ant tAnt = topAnts.get(x);
        //compare top with unknownAnt // for now just ant with largest age
        if(tAnt.generation <= ukAnt.generation){
          topAnts.add(x, ukAnt);
          if(topAnts.size() > numOfTopAnts){
            topAnts.remove(topAnts.size() - 1);
          }
          break;
        }
      }
    }
  }
  public void getSortedSize(Ant ukAnt){
    for(int x = 0;  x < numOfTopAnts; x++){
      if(x >= topAnts.size()){
        topAnts.add(ukAnt);
        if(topAnts.size() > numOfTopAnts){
            topAnts.remove(topAnts.size() - 1);
          }
          break;
      }else{
        Ant tAnt = topAnts.get(x);
        //compare top with unknownAnt // for now just ant with largest age
        if(tAnt.bodySize <= ukAnt.bodySize){
          topAnts.add(x, ukAnt);
          if(topAnts.size() > numOfTopAnts){
            topAnts.remove(topAnts.size() - 1);
          }
          break;
        }
      }
    }
  }
  public void getSortedAge(Ant ukAnt){
    for(int x = 0; x < numOfTopAnts; x++){
      if(x >= topAnts.size()){
        topAnts.add(ukAnt);
        if(topAnts.size() > numOfTopAnts){
          topAnts.remove(topAnts.size() - 1);
        }
        break;
      }else{
        Ant tAnt = topAnts.get(x);
        //compare top with unknownAnt // for now just ant with largest age
        if(tAnt.getAge() <= ukAnt.getAge()){
          topAnts.add(x, ukAnt);
          if(topAnts.size() > numOfTopAnts){
            topAnts.remove(topAnts.size() - 1);
          }
          break;
        }
      }
    }
  }

}



class AntComparatorByAge implements Comparator {
 public int compare(Object o1, Object o2) {
   Float age1 = ((Ant) o1).getAge();
   Float age2 = ((Ant) o2).getAge();
   return age1.compareTo(age2);
 }
}
  public void settings() {  size(1100,800); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#646464", "--hide-stop", "AntGame" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
