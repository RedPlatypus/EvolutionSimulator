//home screen
final color BACKGROUND_COLOR = color(30,30,30);

//World
final float DAY_PROGRESS = 0.1; // 1/10 day every update
final float DAYS_IN_YEAR = 365;

//general setup
final int MIN_ANTS = 40;
final float WATER_MIN_BRIGHT = 95; // between 0 & 255 (adds more water)
final float MAP_SCALE = 14; // pixel size of tiles
final float HUE_MAP_NOISE = 0.04; // not a percentage, just how much change in noise! 0.1
final float SATURATION_MAP_NOISE = 0.5; // not a percentage, just how much change in noise! 0.1
final float BRIGHTNESS_MAP_NOISE = 0.3; // not a percentage, just how much change in noise! 0.3

//climate
final float MINIMUM_TEMP = -200; // rarely used
final float MAXIMUM_TEMP = 200; // rarely used
final float AVERAGE_TEMP = 20; //(20)
final float SEASON_STD = 5; //seasonal standard deviation (6)
//final float NUM_SEASONS = 2; // winter & summer
//final float EXTREME_OF_TEMP = 1; // should eventually be noise for how extreme the temp can get

//Tile
final float MIN_LAND_ENERGY = 30; // the minimum available energy left on a piece of land that ants can bite into or can be removed
final float MAX_SAT_VAL = 500;
final float REMOVE_FADE = 0.3; // how quickly does the ants trail of brightness fade away?
final float MIN_BRIGHT = WATER_MIN_BRIGHT + 80; // what should we fade down to?
final float ANT_SCENT = 240; // how bright can an ant make a trail?

//MAP
final boolean CLEAN_MAP = true; //clean up lakes
final boolean SHOW_TILE_INFO = false;
final float MAX_GROWTH_RATE = 0.12;
final float MAX_DEATH_RATE = 0.06;
//tile for grass growth, green 120 & yellow 60
final float IDEAL_GROWTH_GRASS = 25; // ideal temp for crops
final float FREEZING_TEMP_GRASS = 12; // temp when growth turns into death, from ideal to here it just slows down significantly
final float BURNING_TEMP_GRASS = 28; // temp when growth turns into death from heat.
//tile for blue grass growth, blue 240 & magenta 300
final float IDEAL_GROWTH_BLUE = 12; // ideal temp for crops
final float FREEZING_TEMP_BLUE = 3; // temp when growth turns into death, from ideal to here it just slows down significantly
final float BURNING_TEMP_BLUE = 20; // temp when growth turns into death from heat.
final float WORLD_FRICTION = 0.01; // if it is 1, nothing can move. if it is less, they slow down over time.
final float INITIAL_FOOD = 90; // How much food is initially on each tile (will still vary slightly).

//ANT SPECIFIC
final float ENERGY_REQUIRED_MOVE = 0.75;//1
final float ENERGY_REQUIRED_SWIM = 1.7;//3
final float ENERGY_REQUIRED_BIRTH = 30;//how much energy does the birthing process take? (just make sure this + starting aren't greater than death energy)
final float STARTING_ENERGY = 80; // when triple the starting energy you can birth (150)
final float DEATH_ENERGY = 30; // when do I die?
final float MAX_BITE_SIZE = 3.0; //bite size can't be changed by them.
final float SCOPE = 63.5; // How picky is the ant? 63.5 (255 / 4) for eating exactly 1/2 the spectrum. gets hurt by other 1/2 (Higher number for a less picky ant, that also gets hurt less!)
final float MAX_DIFF = 127.5; // will change if the color hue changes from 255
final float ANT_BRIGHTNESS = 150; //how bright is the ant?
final float BREEDING_ENERGY = STARTING_ENERGY * 3.2; // when can you even think about breeding.
final float MAX_VELOCITY = 0.40;//0.15
final float MAX_ACCELERATION = 0.5;//0.04
final boolean SMART_ANTS = true; // do we want the neural network ants turned on?
final float MIN_BREEDING_AGE = 8;
final float BREEDING_DISTANCE = MAP_SCALE * 1.2; // how far away do the ants need to be in order to breed?

//feeler
final float FEELER_GROWTH_RATIO = 0.03; // relative growth relative to body size ratio
final float FEELER_MAX_ROTATION_RATE = 0.05;

//GUI
final float GUI_MARGIN = 5;

//Neural Net
final int INPUTN = 21; // remember always 1 extra here for bias!
final int HIDDENN = 50; // 160
final int OUTN = 10;
final float LEARNING_RATE = 0.10;

// HELPER CLASSES
class Coordinate{
  int x, y;
  Coordinate(int x, int y){
    this.x = x;
    this.y = y;
  }
}
static class BRMath{
  static float gaussian(float x, float mean, float variance){
    return (1 / sqrt(TWO_PI * variance)) * exp(-sq(x - mean) / (2 * variance));
 }
 static float avg(float x, float y){
   return (x + y) / 2;
 }
}