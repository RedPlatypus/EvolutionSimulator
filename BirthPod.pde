class BirthPod{
  //its a class that two ants enter to produce a copy of themselves!
  ArrayList<Ant> birthingAnts;
  BirthPod(){
    //creats a new birth pod
    birthingAnts = new ArrayList<Ant>();
    
  }
  
  void add(Ant ant){
    //adds a new ant to be a parent
    birthingAnts.add(ant);
  }
  
  void birth(){
    if(birthingAnts.size() <= 0){ //<>//
      return; // no one to perform birth on...
    }
    float energyExpendature = (STARTING_ENERGY + ENERGY_REQUIRED_BIRTH) / birthingAnts.size();
    //create a combination of everything needed for new ant!
    PVector pos = new PVector(100,200);
    ArrayList<PVector> positions = new ArrayList<PVector>(); // list of all parent pvectors
    
    BrainInput newBrain = new BrainInput();
    ArrayList<Matrix> weightsInHidden = new ArrayList<Matrix>();
    ArrayList<Matrix> weightsHiddenOut = new ArrayList<Matrix>();
    
    int gen = 0;
    float mouthHue = 0;
    color antColor = birthingAnts.get(0).myColor;
    float hue = 0, sat = 0, bright = 0;
    //combineMatrixAlternateArray
    //if(birthingAnts.size() > 1){
    //  println("Parents Birthing: " + birthingAnts.size());
    //}
    for(Ant ant: birthingAnts){
      ant.energy -= energyExpendature;
      ant.spawn ++;
      WORLD.sendInfo(ant);
      antGUI.anotherAntBirthed(ant.getAge());
      //cumulative combination from parent
      //position is average position of parents
      positions.add(ant.body.position);
      //brain combines weights from all parents
      weightsInHidden.add(ant._input.brain.wih);
      weightsHiddenOut.add(ant._input.brain.who);
      //gen = lowest generation of the lowest parent
      gen = max(gen, ant.generation);
      //mouth hue is average of parents (not a true average... can fix later, the last ant is always weighted more heavily)
      mouthHue += ant.mHue;
      //antColor
      hue += hue(ant.myColor);
      sat += saturation(ant.myColor);
      bright += brightness(ant.myColor);
    }
    mouthHue /= birthingAnts.size();
    hue /= birthingAnts.size();
    sat /= birthingAnts.size();
    bright /= birthingAnts.size();
    antColor = color(hue, sat, bright);
    Matrix wih = combineMatrixAlternateArray(weightsInHidden);
    Matrix who = combineMatrixAlternateArray(weightsHiddenOut);
    gen ++; // because it is still 1 generation above the lowest generation!
    newBrain.brain.wih = wih;
    newBrain.brain.who = who;
    pos = averagePositions(positions);
    WORLD.worldMap.ants.add(new Ant(pos, newBrain, gen, mouthHue, antColor));
  }
  PVector averagePositions(ArrayList<PVector> list){
    if(list.size() == 0){
      println("ERROR: AVERAGE POSITIONS: BIRTH POD: YOU HAVE TO SUBMIT AT LEAST ONE vector to be multiplied");
      return new PVector(0,0);
    }
    float x = 0, y = 0;
    for(PVector vect: list){
      x += vect.x;
      y += vect.y;
    }
    x /= list.size();
    y /= list.size();
    return new PVector(x,y);
  }
}