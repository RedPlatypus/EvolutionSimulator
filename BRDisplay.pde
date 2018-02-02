class BRDisplay{
  float width;
  float height;
  float x, y;
  String title;
  boolean displayTitle;
  PFont f;
  float fontSize;
  float rotation; // amount to rotate graph by in radians?
  color titleColor, positive, negative, background, stroke, barColor;
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
  void setTitleColor(color tColor){
    this.titleColor = tColor;
  }
  void showTitle(){
    displayTitle = true;
  }
  void hideTitle(){
    displayTitle = false;
  }
  void changeTitle(String newTitle){
    this.title = newTitle;
  }
  void rotateChart(float rot){
    this.rotation = rot;
  }
  void setFont(PFont nf, float size){
    this.f = nf;
    this.fontSize = size;
  }
  void setPositiveColor(color pColor){
    this.positive = pColor;
  }
  void setNegativeColor(color pColor){
    this.negative = pColor;
  }
  void setBarColor(color pColor){
    this.barColor = pColor;
  }
  void setBackgroundColor(color pColor){
    this.background = pColor;
  }
  void setStrokeColor(color pColor){
    this.stroke = pColor;
  }
  void showBorderBox(){
    this.showBorderBox = true;
  } 
  void hideBorderBox(){
    this.showBorderBox = false;
  }
  void displayValues(){
    this.displayValues = true;
  } 
  void hideValues(){
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
  void updateValue(float val){
    this.value = val;
  }
  void drawDisplay(){
    
    textAlign(LEFT);
    float valWidth = calculateValueWidth();    
    pushMatrix();
    //=
    if(this.rotation != 0){
      translate(this.x, this.y);
      translate(this.width / 2, this.height / 2);
      rotate(this.rotation);
      translate(- this.width / 2, - this.width / 2);
    } else{
      translate(this.x, this.y);
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
  float calculateValueWidth(){
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
    this.barWidth = 0.02 * width;
    this.showAverage = false;
    this.max = 0;
  }
  void setBarWidth(float wid){
    this.barWidth = wid;
  }
  void setPadding(float pad){
    this.padding = pad;
  }
  void update(float val){
    this.data.add(val);
    if(val > this.max){
      this.max = val;
    }
    computeAverage(val);
  }
  void toggleAverage(){
    if(this.showAverage){
      this.showAverage = false;
    } else {
      this.showAverage = true;
    }
  }
  void computeAverage(float val){
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
  void drawDisplay(){
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
     
     float tmpMx = this.max /  map(height, 20,400,0.1,4.1); // height = 100 was 200 / somehting to do with first value
     for(int i = data.size() - 1; i > shiftBy; i--){
       scaleBy = ((float)data.get(i) / tmpMx * 100);
       fill(color(116,178,127));
       stroke(this.background);
       strokeWeight(0.5);
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
    //if(this.barWidth < MIN_WIDTH){
    //  this.barWidth = MIN_WIDTH; //<>//
    //  columns = (int)floor((width / (MIN_WIDTH + 1)));
    //}
    columnUnits = new float[columns];
    columnVals = new float[columns];
    this.maxVals = 0;
  }
  void displayXaxis(){
    this.displayXAxis = true;
  }
  void hideXaxis(){
    this.displayXAxis = false;
  }
  
  void update(float val){
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
  
  void computeAverage(float val){
    for(int i = 0; i < columns; i++){
      this.average += columnVals[i];
    }
    this.average /= columns;
  }
  
  void reIndexValues(){
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
  
  void calculateBarWorth(){
    this.barWorth = (this.max - this.min) / columns;// determines the worth of every column
  }
  void assignValueToGrid(float value){    
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
  void drawDisplay(){
    fill(this.background);
    pushMatrix();
    translate(this.x, this.y);
    rect(0,0, this.width, this.height);
    pushMatrix();
    
     ///INSIDE THE CHART!
     float scaleBy = 0;
     float tmpMx = this.maxVals / map(height, 20,400,0.1,4.1);
     
     for(int i = 0; i < columns; i++){
       scaleBy = (columnVals[i] / tmpMx * 100);
       fill(this.barColor);
       stroke(this.background);
       strokeWeight(0.5);
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
         translate(this.barWidth * i - this.barWidth / 2.5, this.height - scaleBy - 10);
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
  void setSpacing(){
    spacingIn = this.height / (inNodes + 1);
    spacingHid = this.height / (hidNodes + 1);
    spacingOut = this.height / (outNodes + 1);
    inPosX = nodeSize / 2  + padding;
    hidPosX = this.width / 2;
    outPosX = this.width - nodeSize / 2  - padding;
  }
  void addNeurons(){
    addColumnOfNeurons(inPosX, spacingIn, inNodes, 0);
    addColumnOfNeurons(hidPosX, spacingHid, hidNodes, 1);
    addColumnOfNeurons(outPosX, spacingOut, outNodes, 2);
  }
  void addColumnOfNeurons(float xPos, float vSpace, int numNodes, int layer){
    ArrayList<Neuron> neurons = new ArrayList<Neuron>();
    for(int i = 0; i < numNodes; i++){
        Neuron newN = new Neuron(new PVector(xPos, vSpace * (i + 1)), nodeSize, layer, i);
        neurons.add(newN);
    }
    biDemArrList.add(neurons);
  }

  void connectNeurons(){
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
  void update(){
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
  
  void drawDisplay(){
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
  void connect(Neuron nextNeuron, float weight){
    //need to throw in weight some how?
    connections.add(new Connection(this, nextNeuron, weight));
  }
  void setWeight(int con, float weight){
    connections.get(con).setWeight(weight);
  }
  void setStrength(float str){
    this.sum = str;
  }
  void display(){
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
  void setWeight(float wei){
    this.weight = wei;
  }
  void display(){
    strokeWeight(0.7);
    stroke(blackness);
    line(a.location.x, a.location.y, b.location.x, b.location.y);
  }
}