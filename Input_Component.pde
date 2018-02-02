class InputComponent{
  float WALK_ACC = 0.1;
  float biteSize = MAX_BITE_SIZE;
  NeuralNetwork brain;
  Ant parent;
  InputComponent() { }
  void update(Ant ant){};
  void update(){};
  void mutate(){
    println("Shouldn't show up!");
  }; // only required for brain class
  void keyPressed(){};
  
  InputComponent clone(Ant parentAnt, BrainInput grandparentsbrain){
    println("Shouldn't show up!");
    InputComponent clone = this.copy();
    return clone;
  }
  
  InputComponent copy(){
    // return a copy of this. not this.
    return this.copy();// probably not right.
  }
  void setParent(Ant ant){
    this.parent = ant;
  }
}