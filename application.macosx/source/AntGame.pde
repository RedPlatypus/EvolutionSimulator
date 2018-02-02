final float SCREEN_WIDTH = 1100;//check size in setup is same! (1920)
final float SCREEN_HEIGHT = 800;//check size in setup is same! (1000)
final float GUI_PERCENT_OF_SCREEN = 0.26;

final World WORLD = new World(SCREEN_WIDTH * (1-GUI_PERCENT_OF_SCREEN), SCREEN_HEIGHT);
final GUI antGUI = new GUI(SCREEN_WIDTH * (1-GUI_PERCENT_OF_SCREEN), 0, SCREEN_WIDTH * GUI_PERCENT_OF_SCREEN, SCREEN_HEIGHT);
final InputComponent playerInput = new InputComponent();
//final NeuralNet brain = new NeuralNet(); //need to give to every ant!

void setup() {
  size(1100,800); // needs to be same as screen_width & screen_height!
  //surface.setResizable(true);

  //noLoop();
}

void draw() {
  background(BACKGROUND_COLOR);
  WORLD.updateWorld();
  WORLD.drawWorld();
  antGUI.updateGUI().drawGUI();
}

void mouseWheel(MouseEvent event) {
  float delta = event.getCount() > 0 ? 1.05 : event.getCount() < 0 ? 1.0/1.05 : 1.0;
  if(WORLD.worldMap.scaleBy / delta < 1){
    WORLD.worldMap.scaleBy = 1;
    return;
  } else if(WORLD.worldMap.scaleBy / delta > 9){
    WORLD.worldMap.scaleBy = 9;
    return;
  }
  WORLD.worldMap.x -= mouseX;
  WORLD.worldMap.y -= mouseY;
  WORLD.worldMap.scaleBy /= delta;
  WORLD.worldMap.x /= delta;
  WORLD.worldMap.y /= delta;
  WORLD.worldMap.x += mouseX;
  WORLD.worldMap.y += mouseY;
  
}

void mouseDragged() 
{
  //check if mouse is over map
  if(WORLD.worldMap.containsMouse(mouseX, mouseY)){
    WORLD.worldMap.stopTrackingAnt();
    //drag the map
    WORLD.worldMap.x += mouseX - pmouseX;
    WORLD.worldMap.y += mouseY - pmouseY;
  }
}
void keyPressed(){
   if(keyPressed){
      if (key == 'r') {
        //reset the zoom
        WORLD.worldMap.scaleBy = 1.0;
        WORLD.worldMap.x = 0;
        WORLD.worldMap.y = 0;
      } else if (key == 'f') {
        //follow the selected ant!
        WORLD.worldMap.followAnt();
      }
   }
}
void mouseClicked(){
  //did we click over the map or gui?
  //println(event.toString);
  if(WORLD.worldMap.containsMouse(mouseX, mouseY)){
    
    if ((mouseButton == LEFT)) {
       WORLD.worldMap.leftClicked(mouseX,mouseY);
    } else if ((mouseButton == RIGHT)) {
       //WORLD.worldMap.rightClicked(mouseX,mouseY);
    } 
   
    //1. we clicked the map, are what's the first "Ant" we see
    //1a. was it a right click?
    // yes? -transfer control to human & display stats on gui. 
    //      -Remove human controls from other ants.
    //1b. no?
    //2.  display stats on gui and follow and rotate according to ant
    
  } else{
    //1. check gui for any buttons that contain the click!
    if ((mouseButton == LEFT)) {
      antGUI.leftClicked();
    } else if ((mouseButton == RIGHT)) {
       //WORLD.worldMap.rightClicked(mouseX,mouseY);
    } 
  }
}