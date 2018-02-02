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
  void showDebugInfo(){
    debugInfoOn = true;
    
  }
  void setTileType(){
    //dependant on the HSB value, especially the Hue, this could be a rock, water, fire, or land
    if(this.brightness <= 0){
      this.type = TileType.tWater;
    } else{
      this.type = TileType.tLand;
    }
  }
  
  void update(){
    growGrass();
    removeTrails();
    this.debugInfoOn = false;
  }
  
  void eat(float biteSize){
    //increase brightness by how much ant is slobbering on me
    this.brightness += biteSize * 2;
    if(this.brightness > ANT_SCENT){
      this.brightness = ANT_SCENT;
    }
  }
  
  void removeTrails(){
    //REMOVE_FADE
    //MIN_BRIGHT
    
    if(this.brightness <= MIN_BRIGHT){
      return;
    }
    this.brightness -= REMOVE_FADE;
    
  }
  
  void growGrass(){
    if(this.type != TileType.tLand){ return; }
    // over time increase or decrease saturation based on climate. (Maybe is different based on type of tile).
    float temp = WORLD.getTemp();
    //check type of grass
    if(this.hue < 127.50){
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

  void drawTile(){
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