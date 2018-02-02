class BrainInput extends InputComponent {
  //responsible for moving the ant around intelligently
  float[] outputs;
  float[] inputs;
  float feeler1Direction = 0.1;
  float feeler2Direction = -0.1;
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
  void mutate(){
    this.brain.mutate();
  }
  
  BrainInput clone(Ant parentAnt, BrainInput grandparentsbrain){
    //println("Coppied Brain!" + random(0,200));
    return new BrainInput(grandparentsbrain, parentAnt);
  }
  void update(){
    //gather inputs
    //size, biteSize,MAX_BITE_SIZE, currentTempreature, currentEnergy, mouthHue
    
    //feeler1hue, feeler1sat, feeler1bright, feeler2hue, feeler2sat, feeler2bright
    color sensor1 = parent.getSensorInfo(parent.feel1);
    color sensor2 = parent.getSensorInfo(parent.feel2);
    
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

    if(outputs[11] > 1.5){
      parent.giveBirth();
    }
    
    this.memory1 = outputs[12];
    this.memory2 = outputs[13];
    
  }
  
  
  

  
}