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
  color sensorColor;
  
  float sensorSize;
  Ant parent;
  
  Feeler(float x, float y, Ant parent){
    this.attachX = x;
    this.attachY = y;
    this.parent = parent;
    this.maxFLength = parent.getSize() * 2.5;
    this.fLength = maxFLength; // just for testing, set to 0 when works
    this.rotation = random(0,0);
    calculateGrowthRate();
    this.sensorSize = parent.bodySize / 2.5;
    if(this.sensorSize <= 0.2){
      this.sensorSize = 0.2;
    }
    this.sensorColor = color(0,0,255);
    
  }
  
  float calculateGrowthRate(){
    float gRate = FEELER_GROWTH_RATIO * this.parent.getSize();
    this.growthRate = gRate;
    return this.growthRate;
  }
  
  Feeler updateFeeler(){
    maxFLength = parent.getSize() * 2.5;
    sensorSize = parent.getSize() / 3;
    if(sensorSize > 10){
      sensorSize = 10;
    } else if(this.sensorSize <= 0.2){
      sensorSize = 0.2;
    }
    return this;
  }
  
  void calculateSensorPos(){
    sensorX = this.parent.body.position.x + this.fLength * cos(this.rotation);
    sensorY = this.parent.body.position.y + this.fLength * sin(this.rotation);
  }
  void drawFeeler(){
    calculateSensorPos();
    strokeWeight(0.5);
    colorMode(HSB, 255);
    stroke(0);
    if(brightness(this.sensorColor) < WATER_MIN_BRIGHT){
      stroke(255);
    } 
    fill(this.sensorColor);
    line(this.attachX + this.parent.body.position.x, this.attachY + this.parent.body.position.y, sensorX, sensorY);
    strokeWeight(0.25);
    ellipse(sensorX, sensorY, sensorSize, sensorSize);
  }
  
  color getSensorInfo(){
    color tCol = WORLD.getColorAtLocation(sensorX, sensorY);
    if(tCol == -1){
      return -1;
    }
    this.sensorColor = tCol;
    
    sensorSize = parent.getSize() / 3;
    if(sensorSize > 10){
      sensorSize = 10;
    } else if(this.sensorSize <= 0.2){
      sensorSize = 0.2;
    }
    
    return this.sensorColor;
  }
  
  void rotateFeeler(float amount){
    //give me direction and amount
    if(amount > FEELER_MAX_ROTATION_RATE){
      rotation += FEELER_MAX_ROTATION_RATE;
    } else if(amount < FEELER_MAX_ROTATION_RATE * -1){
      rotation -= FEELER_MAX_ROTATION_RATE;
    } else{
      rotation += amount;
    }
  }
  void growFeeler(){
    // try to grow the feeler by an amount
    calculateGrowthRate();
    fLength += growthRate;  
    if(fLength > maxFLength){
      fLength = maxFLength;
    }
    //parent.energy -= abs(growthRate / 30);
  }
  void shrinkFeeler(){
    calculateGrowthRate();
    fLength -= growthRate;
    if(fLength < 0){
      fLength = 0;
    }
    //parent.energy -= abs(growthRate / 15);
  }
}