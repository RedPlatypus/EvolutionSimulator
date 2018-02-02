class Map{
  
  ArrayList <Ant> ants = new ArrayList<Ant>();
  float mWidth, mHeight;
  final color mColor = color(255,255,255);
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
  
  void update(){
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
  
  PVector convertTileCoordsToWorldCoords(float xcoord, float ycoord){
    return new PVector(this.scaleBy * xcoord + this.x, this.scaleBy * ycoord + this.y);
  }
  
  void drawMap(){
    pushMatrix();
    if(trackingAnt){
      if(trackAnt == null){
        trackingAnt = false;
      } else{
        this.x = this.mWidth / 2 - trackAnt.body.position.x * scaleBy;
        this.y = this.mHeight / 2 - trackAnt.body.position.y * scaleBy;
        this.scaleBy = 8.9;
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
  
  void followAnt(){
    trackingAnt = true;
  }
  
  void stopTrackingAnt(){ //different ways of cancelling the follow can call this
    trackingAnt = false;
  }
  
  void leftClicked(float x, float y){ //human Left clicked a point. find the first ant under that place.
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
  
  Ant findAntAtPosition(PVector pt){
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
  
  PVector convertWorldCoordsToTileCoords(float xcord, float ycord){
    //converts from mouse position and graphical coordinates, not x & y coordinates in game
     return new PVector(xcord / this.scaleBy - this.x / this.scaleBy, ycord / this.scaleBy - this.y / this.scaleBy);
  }
  
  PVector convertXYtoTileCoords(PVector location){
    float col = location.x / (MAP_SCALE * this.scaleBy);
    float row = location.y / (MAP_SCALE * this.scaleBy);
    return new PVector(col, row);
  }
  void showTileWithCursor(){
    if(this.scaleBy < 1.34){
      return; // font so small it doesn't matter anyways
    }
    Tile tTile = getTileAtLocation(convertWorldCoordsToTileCoords(mouseX, mouseY));
    if(tTile == null){
      return;
    } else{
      tTile.showDebugInfo();
    }
  }
  
  boolean worldContainsObject(float centerX, float centerY, float radius){
    //centerX *= this.scaleBy;
    //centerY *= this.scaleBy;
    if(centerX > radius && centerY > radius && centerY + radius < this.mHeight * this.scaleBy && centerX + radius < this.mWidth * this.scaleBy){
      return true;
    }
    return false;
  }
  
  boolean containsMouse(float mX, float mY){
    //need to transla
    if(mX > this.x && mX < this.x + mWidth * this.scaleBy && mY > this.y && mY < this.y + this.mHeight * this.scaleBy
      && mX < SCREEN_WIDTH - SCREEN_WIDTH * GUI_PERCENT_OF_SCREEN
    ){
      return true;
    }
    return false;
  }
  
  PVector getLocationWithoutWater(){
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
  
  Ant createNewRandomAnt(){
    return new Ant(getLocationWithoutWater(), new RandomInput(), 0);
  }
  Ant createNewSmartAnt(){
    return new Ant(getLocationWithoutWater(), 0);
  }
  void birthAnt(Ant parent){
    //ants.add(new Ant(new PVector(parent.position.x, parent.position.y), parent.mHue + (randomGaussian() * 40) - 20, new RandomInput(), parent.generation++));
    antGUI.anotherAntBirthed(parent.getAge());
    ants.add(new Ant(parent));
  }
  void removeAnt(Ant ant){
    float age2 = ant.getAge();
    antGUI.anotherAntDied(age2);////////////////////// called in the GUIanotherAntDied
    ants.remove(ant);
  }
  float getAntPopulation(){
    return ants.size();
  }

  Tile getTileAtLocation(PVector location){
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
  
  void removeLakes(){
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
  
  void createMap(){
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