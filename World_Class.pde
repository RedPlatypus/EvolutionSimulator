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
  int lastProfile = 0, profileFrequency = 30;
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
  void updateWorld(){
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
  
  void reportOnYear(){
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
    println("---------------------------------------------------------");
   
    mostSpawnThisYear = 0;
    highestGenThisYear = 0;
  }
  
  void sendInfo(Ant ant){
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
  float getTotalDays(){
    return this.totalDay;
  }
  float getDay(){
    return this.dayOfYear;
  }
  float getYear(){
    return this.year;
  }
  float getTemp(){
    return this.climate.getTemp();
  }
  void drawWorld(){
    worldMap.drawMap();
  }
  //tiles
  TileType getTypeOfTileAt(PVector location){
    Tile tile = worldMap.getTileAtLocation(location);
    if(tile == null){
      return null;
    } else{
      return tile.type;
    }
  }
  
  color getColorAtLocation(float x, float y){
    PVector location = new PVector(x,y);
    Tile tTile = worldMap.getTileAtLocation(location);
    if(tTile == null){
     return -1;
    }
    colorMode(HSB, 255);
    color tColor = color(tTile.hue, tTile.saturation, tTile.brightness);
    return tColor;
  }
  
  void setGlobalGrassGrowth(int col, float amt){
    if(col == 0){
      this.gGreenGrowth = (this.gGreenGrowth + amt) /2;
    }else if(col == 1){
      this.gBlueGrowth = (this.gBlueGrowth + amt) /2;
    }
  }
  float getGlobalGrassGrowth(int col){
    float val = 100;
    if(col == 0){
      val = this.gGreenGrowth;
    }else if(col == 1){
      val = this.gBlueGrowth;
    }
    return val;
  }
}

class StatsClass{
  boolean sortBiggest = true; // true: get biggest/most first, false: get smallest/least first
  int category = 0; // 0age, 1size, 2spawn, 3generation
  ArrayList<Ant> topAnts;
  int numOfTopAnts = 10;
  StatsClass(){
    topAnts = new ArrayList<Ant>();
  }
  void sortBiggest(){
    this.sortBiggest = true;
  }
  void sortSmallest(){
    this.sortBiggest = false;
  }
  void sortByCategory(int category){
    if(category > 3){
      category = 0;
      println("ERROR: We are sorting by age. We don't have that many categories to sort by. Called from Stats class. ");
    } else{
      this.category = category;
    }
  }
  
  ArrayList<Ant> getTopAnts(){
    return this.topAnts;
  }
  
  void profile(ArrayList<Ant> ants){ //profile these ants and see who is the top according to class conditions, (Sort Biggest, & category)
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
  void getSortedSpawn(Ant ukAnt){
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
  void getSortedGeneration(Ant ukAnt){
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
  void getSortedSize(Ant ukAnt){
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
  void getSortedAge(Ant ukAnt){
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


import java.util.Comparator;
class AntComparatorByAge implements Comparator {
 int compare(Object o1, Object o2) {
   Float age1 = ((Ant) o1).getAge();
   Float age2 = ((Ant) o2).getAge();
   return age1.compareTo(age2);
 }
}