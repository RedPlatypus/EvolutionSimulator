class Ant {  
  final float MAX_ROTATION = 0.1;
  float energy; // the raw energy an ant has
  float bodySize; // a relationship between energy, & scale
  float mHue;
  boolean alive = true;
  float breedingSize = mapEnergyToSize(BREEDING_ENERGY);
  float deathSize = mapEnergyToSize(DEATH_ENERGY);
  float modifier = 0, mm = 0.1;
  color myColor = color(random(0,255),150,150);
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
    PVector birthForce = new PVector(random(-2.5,2.5), random(-2.5,2.5));
    //applyForce(birthForce);
    this.body.applyForce(birthForce);
    this.biteSize = MAX_BITE_SIZE / 2;
    setBirthday();
  }
  void setBirthday(){
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
  float getAge(){
    if(this.alive){
      return WORLD.getTotalDays() - this.totalDaysBirth;
    } else{
      float age3 =  this.accumulativeDeathDay - this.totalDaysBirth;
      //println(age3 + "called at get age in ant class!");
      return age3;
    }
  }
  void switchToRandomInput(){
    _input = new RandomInput();
  }
  void vomit(){
    //if we light up 10
    //this.energy -= 4.0;
    //println("Vomiting");
  }
  void keyPressed(){
    println(" AntClass Key Pressed");
    if(_input instanceof PlayerInput){
        _input.keyPressed();
        println("Inside.");
      }
  }
  //methods - functions of the object that the class creates. (abilities)
  Ant updateAnt(){
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
  
  void drawAnt(){
    feel1.drawFeeler(); // should be drawn before ant, to hide underneath.
    feel2.drawFeeler();
    pushMatrix();
    translate(this.body.position.x, this.body.position.y);
    drawAntBody();
    popMatrix();
  }
  // HELPER functions
  void animate(){
    this.modifier += this.mm;
    if(this.modifier > 1.5 || this.modifier < -1.5){
      this.mm *= -1;
    }
    this.modifier += mm;
  }
  void drawAntBody(){
    pushMatrix();
    float rotation = this.body.velocity.heading();
    rotate(rotation);
    stroke(0);
    strokeWeight(0.5);
    colorMode(HSB, 255);
    fill(this.myColor);
    ellipse(0, 0, bodySize, bodySize);
    if(this.energy > BREEDING_ENERGY){
      noFill();
      stroke(255);
      ellipse(0,0, this.breedingSize, this.breedingSize); 
    }
    if(this.energy < DEATH_ENERGY * 1.15){
      noStroke();
      fill(color(255,150,80));
      ellipse(0,0, this.deathSize, this.deathSize); 
    }
    stroke(0);
    strokeWeight(0.25);
    colorMode(HSB,255);
    fill(this.mHue,200, 200);
    ellipse(0.5 * bodySize + this.modifier, 0, bodySize * 0.3, bodySize * 0.5); // mouth or something.
    popMatrix();
  }
  boolean isAlive(){
    return this.alive;
  }
  
  float mapEnergyToSize(float val){
    return map(val, DEATH_ENERGY, STARTING_ENERGY * 8, MAP_SCALE / 2.5, MAP_SCALE * 1.5);
  }
  
  void convertEnergyToBodySize(float energy){
    //used for any energy related needs
    //also a good place to check for energy reserves
    this.energy += energy;
    if(this.energy < DEATH_ENERGY){
      die();
    }
    //this.bodySize = map(DEATH_ENERGY, DEATH_ENERGY, STARTING_ENERGY * 4, MAP_SCALE / 4, MAP_SCALE / 2);
    this.bodySize = mapEnergyToSize(this.energy);
  }
  PVector getPosition(){
    return this.body.position;
  }
  
  boolean isAntOnMap(){
    float radius = this.bodySize / 2;
    return WORLD.worldMap.worldContainsObject(this.body.position.x, this.body.position.y, radius);
  }

  float getSize(){
    return this.bodySize;
  }
  
  //useful information for smart players
  color getSensorInfo(Feeler feeler){
    return feeler.getSensorInfo();
  }
  float getHueUnderneath(){
    color tCol = WORLD.getColorAtLocation(this.body.position.x, this.body.position.y);
    if(tCol == -1){
      return -1;
    }
    return hue(tCol);
  }
  float differenceBetweenHueAndMouthHue(float hue){
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
  void increaseBiteSize(){
    this.biteSize += 0.1;
    if(this.biteSize > MAX_BITE_SIZE){
      this.biteSize = MAX_BITE_SIZE;
    }
  }
  void decreaseBiteSize(){
    this.biteSize -= 0.1;
    if(this.biteSize < 0){
      this.biteSize = 0;
    }
  }
  float getBiteSize(){
    return this.biteSize;
  }
  float getWorldTemp(){
    return WORLD.getTemp();
  }
  Ant eat(float biteSize){
    if(biteSize > MAX_BITE_SIZE){ biteSize = MAX_BITE_SIZE; } else if(biteSize < 0){ biteSize = 0; return this;}
    //open mouth and eat what's under you.
    float energyReturned = eatTileUnderneath( biteSize);
    convertEnergyToBodySize(energyReturned);
    return this;
  }
  float eatTileUnderneath(float biteSize){
    //returns nutrients at location
    Tile tTile = WORLD.worldMap.getTileAtLocation(this.body.position);
    if(tTile == null){
      return -1.0;
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
  void growFeeler(Feeler feeler){
    feeler.growFeeler();
  } 
  void shrinkFeeler(Feeler feeler){
    feeler.shrinkFeeler();
  }
  void rotateFeeler(Feeler feeler, float direction){
    feeler.rotateFeeler(direction);
  }
  void giveBirth(){
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
  void die(){
    this.alive = false;
    this.accumulativeDeathDay = WORLD.getTotalDays();
    WORLD.worldMap.removeAnt(this);
  }

}