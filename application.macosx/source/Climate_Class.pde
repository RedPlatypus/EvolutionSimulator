static enum  Weather {
  Rain,
  Snow,
  Sunny,
  Cloudy
};

class Climate{
  Weather weather;
  float temp; //weather in degrees C
  float inc;
  boolean seasonsOn;
  
  
  Climate(){
    this.weather = Weather.Sunny;
    this.temp = 20;
    seasonsOn = true;
    this.inc = TWO_PI / DAYS_IN_YEAR;
  }
  
  void update(){
    if(this.temp > MAXIMUM_TEMP){
      this.temp = MAXIMUM_TEMP;
    } else if(this.temp < MINIMUM_TEMP){
      this.temp = MINIMUM_TEMP;
    }
    
    if(seasonsOn){
      //roll through days of year
      adjustTemp();
    }
    
  }
  
  void adjustTemp(){
    //max & min temp will go up and down along a sin wave varyign by noise;
    //this.temp = -1.1;
    this.temp = map(sin(WORLD.getDay() * this.inc),-1,1,AVERAGE_TEMP - 4 * SEASON_STD,AVERAGE_TEMP + 2 * SEASON_STD);  
    
  }
  
  float getTemp(){
    return this.temp;
  }
  
}