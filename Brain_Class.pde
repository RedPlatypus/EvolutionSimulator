class BrainInput extends InputComponent {
  //responsible for moving the ant around intelligently
  float[] outputs;
  float[] inputs;
  float feeler1Direction = 0.1;
  float feeler2Direction = -0.1;
  float memory1, memory2 = 0;
  Ant parent;
  BrainInput(float learningRate, Ant ant){
    this.brain = new NeuralNetwork(INPUTN, HIDDENN, OUTN, learningRate);
    this.parent = ant;
    outputs = new float[OUTN];
    inputs = new float[INPUTN];
  }
  BrainInput(){
    this.brain = new NeuralNetwork(INPUTN, HIDDENN, OUTN, LEARNING_RATE);
    outputs = new float[OUTN];
    inputs = new float[INPUTN];
  }
  BrainInput(BrainInput parentInput, Ant ant){
    this.brain = new NeuralNetwork(parentInput.brain);
    this.parent = ant;
    outputs = new float[OUTN];
    inputs = new float[INPUTN];
  }
  void setParent(Ant ant){
    this.parent = ant;
  }
  void mutate(){
    this.brain.mutate();
  }
  
  BrainInput clone(Ant parentAnt, BrainInput grandparentsbrain){
    //println("Coppied Brain!" + random(0,200));
    return new BrainInput(grandparentsbrain, parentAnt);
  }
  void update(){
    if(parent == null){return;}
    //gather inputs
    //size, biteSize,MAX_BITE_SIZE, currentTempreature, currentEnergy, mouthHue
    
    //feeler1hue, feeler1sat, feeler1bright, feeler2hue, feeler2sat, feeler2bright
    color sensor1 = parent.getSensorInfo(parent.feel1);
    color sensor2 = parent.getSensorInfo(parent.feel2);
    
    inputs[0] = map(parent.getSize(), 4,50,0,1);
    inputs[1] = map(parent.getBiteSize(), 0, 3, 0, 1);
    inputs[2] = map(parent.getWorldTemp(), -5,30, 0, 1);
    inputs[3] = map(parent.energy, DEATH_ENERGY, 400, 0,1);
    inputs[4] = map(parent.differenceBetweenHueAndMouthHue(hue(sensor1)), 0,MAX_DIFF,0,1); // difference between mouth hue and sensor 1 // what if it's water tile?
    inputs[5] = map(parent.differenceBetweenHueAndMouthHue(hue(sensor2)), 0,MAX_DIFF,0,1); // difference between mouth hue and sensor 2
    inputs[6] = map(parent.differenceBetweenHueAndMouthHue(parent.getHueUnderneath()), 0,MAX_DIFF,0,1); // difference between mouth hue and right below body
    inputs[7] = map(saturation(sensor1), 0,255,0,1);
    inputs[8] = map(brightness(sensor1), 0,255,0,1);
    inputs[9] = map(saturation(sensor2), 0,255,0,1);
    inputs[10] = map(brightness(sensor2), 0,255,0,1);
    //need saturation of tile underneath my face?
    inputs[11] = map(parent.feel1.fLength, 0, parent.feel1.maxFLength, 0,1);//distance away from body 2
    inputs[12] = map(parent.feel2.fLength, 0, parent.feel2.maxFLength, 0,1);//distance away from body 2
    inputs[13] = map(parent.body.velocity.mag(), -MAX_VELOCITY, MAX_VELOCITY, 0, 1);// our bias! ALWAYS stays at 1.
    inputs[14] = parent.feel1.rotation;
    inputs[15] = parent.feel2.rotation;
    inputs[16] = parent.body.velocity.heading();
    inputs[17] =  map(WORLD.worldMap.getAntPopulation(), MIN_ANTS, WORLD.worldMap.probableCarryingCapacity, 0, 1); // maybe the higher this is the lower chance of birth
    inputs[18] = memory1;
    if(!parent.birthAntNearby){
      inputs[19] = 0;
    }else{
      inputs[19] = 1;
    }
    inputs[20] = 1;
    
    //println(inputs[17]);
    
  
    outputs = this.brain.query(inputs);
    
    //use out 0 & 1 for rotation and velocity
    parent.body.rotateBy(outputs[0]);
    parent.body.accelerateBy(outputs[1]);
    if(outputs[2] > 0){
      parent.eat(parent.biteSize);
    }
    if(outputs[3] > 1){
      parent.feel1.growFeeler();
    } else if (outputs[3] < -1){
      parent.feel1.shrinkFeeler();
    }
    parent.feel1.rotateFeeler(outputs[4]);
    if(outputs[5] > 1){
      parent.feel2.growFeeler();
    } if (outputs[5] < -1){
      parent.feel2.shrinkFeeler();
    }
    parent.feel2.rotateFeeler(outputs[6]);
    if(outputs[7] > 1){
      parent.giveBirth();
    }
    this.memory1 = outputs[8];
    this.memory2 = outputs[9];
    
  }

  
}