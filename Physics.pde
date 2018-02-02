class PhysicsWorld{
  //responsible for holding bodies of physics, will check for collisions
  ArrayList <PhysicsBody> bodies = new ArrayList<PhysicsBody>();
  float mWidth, mHeight;
  float gridSize = MAP_SCALE * 2;
  float gridRows, gridCols;
  //float[][] multi;
  
  CollisionTester colider = new CollisionTester();
  PhysicsWorld(float width, float height){
    this.mWidth = width;
    this.mHeight = height;
    gridRows = mWidth / gridSize;
    gridCols = mHeight / gridSize;
    //multi = new float[gridCols][gridRows];
  }
  void update(){
    //body.update(); // taken care of by the array in ants.
    //body.display(); // taken care of by the array in ants.
    queryForCollisionPairs(); // just do it on everything!!!
    //create entity grid
    queryForWallCollision(); // just do it on everything!!!
  }


  void queryForWallCollision(){
    //check every ant one more time to see if they have collided with the worlds borders
    for(int i = 0; i < WORLD.worldMap.ants.size(); i++){
      Ant ant = WORLD.worldMap.ants.get(i);
      boolean hit = colider.circleVsEnclosingBox(ant.body, mWidth, mHeight);
      if(hit){
        //println("From physics ant is past wall!");
        //resolveWallTap(ant.body);
        resolveWallTapSwitch(ant.body);
      }
    }
  }
  boolean isWithinDistance(PhysicsCircle a, PhysicsCircle b, float distance){
    float d = colider.circlevsCircle(a, b);
    if(d <= distance){
      return true;
    }
    return false;
  }
  void queryForCollisionPairs(){
    //brute force method
    ArrayList<Ant> antCollision = new ArrayList<Ant>();
    
    for(int j = 0; j < WORLD.worldMap.ants.size(); j++){
      Ant el1 = WORLD.worldMap.ants.get(j); // 3
      for(int i = j + 1; i < WORLD.worldMap.ants.size(); i++){
        Ant el2 = WORLD.worldMap.ants.get(i); // 4,5,6,7,8,9
        float distance = colider.circlevsCircle((PhysicsCircle)el1.body, (PhysicsCircle)el2.body);
        //println(distance);
        if(distance <= 0){
          resolveConflict(el1.body, el2.body);
        }
        //they go in together or not at all..
        if (distance <= BREEDING_DISTANCE){
          if(el1.energy > BREEDING_ENERGY && el2.energy > BREEDING_ENERGY){
             if(!antCollision.contains(el1)){
               antCollision.add(el1);
             }
             if(!antCollision.contains(el2)){
               antCollision.add(el2);
             }
          }
        }
      }
      for(Ant ant: WORLD.worldMap.ants){
        //check if the ant is in antCollision 
        //if yes, set inBreeding = true, else set false
        if(antCollision.contains(ant)){
          ant.inBreedingDistance(true);
        }else{
          ant.inBreedingDistance(false);
        }
      }
    }
    
  }
  
  void resolveWallTapSwitch(PhysicsCircle a){
    if(a.r > a.position.x){
      a.position.x = this.mWidth - a.r;
    }else if(a.r > a.position.y){
      a.position.y = this.mHeight - a.r;
    }else if(mWidth < a.position.x + a.r){
      a.position.x = a.r;
    }else if(mHeight < a.position.y + a.r){
      a.position.y = a.r;
    } 
  }
  
   void resolveWallTap(PhysicsCircle a){
    PVector wall = new PVector(0,0); // closest point to wall and ball
    if(a.r > a.position.x){
      wall.y = a.position.y;
    }else if(a.r > a.position.y){
      wall.x = a.position.x;
    }else if(mWidth < a.position.x + a.r){
      wall.y = a.position.y;
      wall.x = mWidth;
    }else if(mHeight < a.position.y + a.r){
      wall.x = a.position.x;
      wall.y = mHeight;
    } 
    // the ant hit a wall!
    // Get distances between the balls components
    PVector distanceVect = PVector.sub(a.position, wall);
    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();
    //what do we need to correct
    float distanceCorrection = (a.r-distanceVectMag) * 2;
    PVector d = distanceVect.copy();
    PVector correctionVector = d.normalize().mult(distanceCorrection);
    a.position.add(correctionVector);
  }
  
  void resolveConflict(PhysicsCircle a, PhysicsCircle b ){
    // Get distances between the balls components
    PVector distanceVect = PVector.sub(a.position, b.position);
    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();
    // Minimum distance before they are touching
    float minDistance = a.r + b.r;
    //what do we need to correct
    float distanceCorrection = (minDistance-distanceVectMag)/2.0;
    PVector d = distanceVect.copy();
    PVector correctionVector = d.normalize().mult(distanceCorrection);
    a.position.add(correctionVector);
    b.position.sub(correctionVector);
  }
}

class PhysicsBody{
  //general physics body
  float m;
  float rotation = random(-PI, PI);
  float maxrotation = 0.08;
  PVector position;
  PVector velocity = new PVector(0,0);
  PVector acceleration = new PVector(0,0);
  
  PhysicsBody(float mass){ 
    this.m = mass;
  }
  
  void applyForce(PVector force){
    PVector f = force.copy();
    f.div(this.m);
    this.acceleration.add(f);
  }
  void rotateBy(float rotateBy){
    float myR = map(rotateBy, -5, 5, -maxrotation, maxrotation);
    rotation += myR;
  }
  void accelerateBy(float accelerateBy){
    PVector f = new PVector(accelerateBy, 0);
    f.limit(MAX_ACCELERATION);
    f.div(this.m);
    this.acceleration.add(f);
  }
  void update(){
    this.velocity.rotate(rotation);
    rotation = 0;
    this.velocity.add(this.acceleration);
    this.position.add(this.velocity);
    this.acceleration.mult(0);
    
    ////apply forces to ants after updating
    PVector friction = this.velocity.copy();
    friction.mult(-1);
    friction.mult(WORLD_FRICTION);
    this.applyForce(friction);
    ////apply wind, gravity whatver else.
  }
}

class PhysicsCircle extends PhysicsBody{
  //general physics body
  float r;// radius
  PhysicsCircle(float radius, PVector position){
    super(radius * 2);
    this.r = radius;
    this.position = position;
  }
  void updateSize(float radius){
    this.m = radius * 2;
    this.r = radius;
  }

}

static class CollisionTester{
  //returns the distance between two physics circles.
  float circlevsCircle( PhysicsCircle a, PhysicsCircle b ){    
    float minDist = a.r + b.r;
    minDist = pow(minDist, 2); // squaring radius
    PVector distVect = PVector.sub(a.position, b.position); //New
    float distMag = distVect.mag();
    distMag = pow(distMag, 2);
    float vectDiff = distMag - minDist;
    float returnDiff = 0;
    //return actual difference, and negatives should be included, those are our overlaps!
    if(vectDiff < 0){
      returnDiff = sqrt(abs(vectDiff)) * -1;
    }else{
      returnDiff = sqrt(vectDiff);
    }
    return returnDiff;
  }
  boolean circleVsEnclosingBox( PhysicsCircle a, float mWidth, float mHeight){
    //did the circle hit the wall?
    if(a.r > a.position.x){
      return true;
    }
    if(a.r > a.position.y){
      return true;
    }
    if(mWidth < a.position.x + a.r){
      return true;
    } 
    if(mHeight < a.position.y + a.r){
      return true;
    } 
    return false;
    
  }
}