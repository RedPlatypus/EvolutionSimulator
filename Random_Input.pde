class RandomInput extends InputComponent{
  
  RandomInput(){}
  void update(Ant ant){
    //test for certain conditions and program here!
    ant.eat(MAX_BITE_SIZE);
    computerAnt(ant);
    //rotateAntanee();
    ant.feel1.getSensorInfo();
    ant.feel1.updateFeeler();
    ant.feel2.getSensorInfo();
    ant.feel2.updateFeeler();
    if(ant.energy > BREEDING_ENERGY && random(0,1) < 0.003){
      ant.giveBirth();
    }
  } // end update

  void computerAnt(Ant ant){
    if( random(0,100) > 95 ){
      PVector acc = PVector.random2D();
      acc.limit(MAX_ACCELERATION);
      ant.body.applyForce(acc);
      //ant.speed.add(ant.acceleration);
    }
    
    if(!ant.isAntOnMap()){
      ant.body.position.sub(ant.body.velocity);
      ant.energy -= ENERGY_REQUIRED_SWIM * 3;
      ant.body.velocity.rotate(PI / 8);
      return;
    }
  }
}