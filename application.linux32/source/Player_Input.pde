class PlayerInput extends InputComponent{
  float rotationAmount = 0.02;
  float controlAntanee = 0;
  Ant ant;
  PlayerInput(){
  }
  void update(Ant ant){
    if(keyPressed){
      if (key == CODED) {
        //  The variable keyCode is used to detect special keys such as the arrow keys (UP, DOWN, LEFT, and RIGHT) as well as ALT, CONTROL, and SHIFT. 
        //check for 
        if (keyCode == UP) {
          ant.body.applyForce(new PVector(0,-WALK_ACC));
        } else if (keyCode == DOWN) {
          ant.body.applyForce(new PVector(0,WALK_ACC));
        }  else if (keyCode == LEFT) {
          ant.body.applyForce(new PVector(-WALK_ACC, 0));
        }  else if (keyCode == RIGHT) {
          ant.body.applyForce(new PVector(WALK_ACC, 0));
        } else if (keyCode == SHIFT){
          //should be space
          ant.feel1.getSensorInfo();
          ant.feel2.getSensorInfo();
        }
      }
      
      //Non CODED keys
      if(key == '1'){
          controlAntanee = 1;
          println("Controlling antane 1");
        } else if(key == '2'){
          controlAntanee = 2;
          println("Controlling antane 2");
        } else if(key == 'e'){
          ant.eat(biteSize);
        } else if(key == 'b'){
          ant.giveBirth();
          println("Giving Birth");
        } else if (key == 'r'){
          biteSize += 1;
          if(biteSize > MAX_BITE_SIZE){
            biteSize = MAX_BITE_SIZE;
          }
        } else if (key == 'd'){
          biteSize -= 1;
          if(biteSize < 0){
            biteSize = 0;
          } 
        } else if (key == 'q'){
          if(controlAntanee == 0){
            ant.feel1.rotateFeeler(-rotationAmount);
          } else{
            ant.feel2.rotateFeeler(-rotationAmount);
          }
        } else if (key == 'w'){
          if(controlAntanee == 0){
            ant.feel1.rotateFeeler(rotationAmount);
          } else{
            ant.feel2.rotateFeeler(rotationAmount);
          }
        } else if (key == 'a'){
          if(controlAntanee == 0){
            ant.feel1.growFeeler();
          } else{
            ant.feel2.growFeeler();
          }
        } else if (key == 's'){
          if(controlAntanee == 0){
            ant.feel1.shrinkFeeler();
          } else{
            ant.feel2.shrinkFeeler();
          }
        } 
        
    }
  } // end update
}
  
  