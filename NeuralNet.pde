//This file is developed elsewhere for testing and pasted here
//Written by Brendan Robertson based off of works & videos by Daniel Shiffman!
final float LIKLEYHOOD_MUTATION = 0.2;

class NeuralNetwork{
  float[] inputsNodesM, hiddenNodesM, outputNodesM;
  Boolean display = false;
  int inNodes, hiddenNodes, outNodes;
  float lr; //learning rate
  Matrix wih; //weights input to hidden
  Matrix who; //weights hidden to output
  float bias = 1;
  
  //constructors, from parent or a new neural net
  NeuralNetwork(int inputNodes,int hiddenNodes,int outputNodes,float learningRate){
    //no extra activation function for now, as we will simply use sigmoid by default.
    this.inNodes = inputNodes;
    this.outNodes = outputNodes;
    this.hiddenNodes = hiddenNodes;
    this.lr = learningRate; // default this to 0.1;
    this.wih = new Matrix(hiddenNodes, inputNodes);
    this.who = new Matrix(outputNodes, hiddenNodes);
    this.inputsNodesM = new float[inputNodes];
    this.hiddenNodesM = new float[hiddenNodes];
    this.outputNodesM = new float[outputNodes];
    
    //start with random weights, could change over time.
    this.wih.randomize();
    this.who.randomize();
  }
  NeuralNetwork(NeuralNetwork parent){
    //we can construct by simply passing in another network i.e. our parents weights
    this.inNodes = parent.inNodes;
    this.outNodes = parent.outNodes;
    this.hiddenNodes = parent.hiddenNodes;
    
    //Weights passing on!!!
    this.wih = parent.wih.copy();
    this.who = parent.who.copy();
    this.lr = parent.lr;
  }
  
  //for when we need a copy
  NeuralNetwork copy(){
    return new NeuralNetwork(this);
  }
  void displayNodes(){
    //call when you want to save the matricies for display!
    this.display = true;
  }
  void hideNodes(){
    this.display = false;
  }
  void mutate(){
    //pass the matrix a mutator function
    //this.wih = Matrix.map(this.wih); //uses the mutate function found below
    //this.who = Matrix.map(this.who); //uses the mutate function below
    this.wih = mapMatrixMutate(this.wih);
    this.who = mapMatrixMutate(this.who);
  }
  
  //not sure if I will use this.
  void train(float []inputsArray, float []targetsArray){
    //Convert our inputs and target to a matrix that we can do matrix math with.
    Matrix inputs = new Matrix(inputsArray);
    Matrix targets = new Matrix(targetsArray);
    
    //the inputs to hidden = wih * inputs
    Matrix hiddenInputs = dotMatrix(this.wih, inputs);
    
    //the hidden outputs pass through sigmoid (0 or 1);
    Matrix hiddenOutputs = mapMatrixSigmoid(hiddenInputs);
    
    //we need some way of getting the output nodes our who (weights, and our outputs)
    Matrix outputInputs = dotMatrix(this.who, hiddenOutputs);
    
    //do the same thing again we map our output to our activation function
    Matrix outputs = mapMatrixSigmoid(outputInputs);
    
    //now what's the error?
    Matrix outputErrors = subtractMatrix(targets, outputs);
    
    //great... now start back propogation
    Matrix whoT = transposeMatrix(this.who);
    //hidden errors
    Matrix hiddenErrors = dotMatrix(whoT, outputErrors);
    
    Matrix gradientOutput = mapMatrixSigmoidDerivative(outputs);
    
    //weight by errors and learning rate
    gradientOutput.multiply(hiddenErrors);
    gradientOutput.multiply(this.lr);
    
    //next layer back
    Matrix gradientHidden = mapMatrixSigmoidDerivative(hiddenOutputs);
    //weights again by errors and learning rate
    gradientHidden.multiply(hiddenErrors);
    gradientHidden.multiply(this.lr);
    
    //change in weights from hidden --> output who
    Matrix hiddenOutputs_T = transposeMatrix(hiddenOutputs);
    Matrix deltaW_output = dotMatrix(gradientOutput, hiddenOutputs_T);
    this.who.addMatrix(deltaW_output);
    
    //change in weights from input --> hidden wih
    Matrix inputs_T = transposeMatrix(inputs);
    Matrix deltaW_hidden = dotMatrix(gradientHidden, inputs_T);
    this.wih.addMatrix(deltaW_hidden);
  }
  
  //query the network
  float[] query(float []inputsArray){
    // OUR INPUT BIAS SHOULD HAVE COME IN WITH THE INPUTS ARRAY
    if(inputsArray[inputsArray.length - 1] != 1){
      //println("Need to have last input set to 1. Neural Net Error. In Query.");
    }
    
    //1
    Matrix inputs = new Matrix(inputsArray);
    //inputs = mapMatrixTanh(inputs);
    
    //2 get hidden inputs from two arrays
    Matrix hiddenInputs = dotMatrix(this.wih, inputs);
    //3
    //Matrix hiddenOutputs = mapMatrixSigmoid(hiddenInputs);
    Matrix hiddenOutputs = mapMatrixTanh(hiddenInputs);
    //4
    Matrix outputInputs = dotMatrix(this.who, hiddenOutputs);
    //
    //Matrix outputs = mapMatrixSigmoid(outputInputs);
    Matrix outputs = mapMatrixTanh(outputInputs);
    //6
    //println("Wights to output");
    //println(this.who.toString());
    if(this.display){
      inputsNodesM = inputs.toArray();
      hiddenNodesM = hiddenInputs.toArray();
      outputNodesM = outputs.toArray();
    }
    return outputs.toArray();
  }
  
}

class Matrix{
  int rows, cols; // our grid
  float[][] matrix;
  //ways to get a new matrix
  Matrix(int rows, int cols){
    this.rows = rows;
    this.cols = cols;
    this.matrix = new float[rows][cols];
    //initalize all values to 0!
    for(int i = 0; i < rows; i++){
      for( int j = 0; j < cols; j++){
        this.matrix[i][j] = 0;
      }
    }
  }
 String toString(){
   String lines = "";
   for(int i = 0; i < rows; i++){
     lines += "[";
      for( int j = 0; j < cols; j++){
        lines += "[" + this.matrix[i][j] + "]";
      }
     lines += "]\n";
    }
    return lines;
    
 }
  Matrix(float arr[]){
    this.rows = arr.length;
    this.cols = 1;
    this.matrix = new float[rows][cols];
    //initalize all values to array!
    for(int i = 0; i < arr.length; i++){
      this.matrix[i][0] = arr[i];
    }
  }

  
  Matrix copy(){
    Matrix copy = new Matrix(this.rows, this.cols);
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        copy.matrix[i][j] = this.matrix[i][j];
      }
    }
    return copy;
  }
  
  // methods
  void randomize(){
    for(int i = 0; i < rows; i++){
      for( int j = 0; j < cols; j++){
        this.matrix[i][j] = randomGaussian();
      }
    }
  }
  
  //For multiply we can either multiply a scalar (single value)
  void multiply(float x){
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        this.matrix[i][j] *= x;
      }
    }
  }
  void multiply(Matrix b){
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        this.matrix[i][j] *= b.matrix[i][j];
      }
    }
  }
  void addMatrix(Matrix b){
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        this.matrix[i][j] += b.matrix[i][j];
      }
    }
  }  
  void addMatrix(Float x){
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        this.matrix[i][j] += x;
      }
    }
  }
  
  float[] toArray(){
    float size = this.rows * this.cols;
    float[] array;
    array = new float[(int)size];
    int x = 0;
    for(int i = 0; i < this.rows; i++){
      for( int j = 0; j < this.cols; j++){
        array[x] = this.matrix[i][j];
        x ++;
      }
    }
    return array;
  }
}

//can't figure out how to mix and match static methods with non-static classes.

//average two matricies
Matrix averageMatrix(Matrix a, Matrix b){
  if(a.rows != b.rows || a.cols != b.cols){
    println("ERROR average matrix. Rows and Column mismatch between the two matrix's!");
  }
  Matrix result = new Matrix(a.rows, a.cols);
  for(int i = 0; i < result.rows; i++){
    for(int j = 0; j < result.cols; j++){
      result.matrix[i][j] = (a.matrix[i][j] + b.matrix[i][j]) / 2;
    }
  }
  return result;
}

Matrix combineMatrixAlternate(Matrix a, Matrix b){
  if(a.rows != b.rows || a.cols != b.cols){
    println("ERROR average matrix. Rows and Column mismatch between the two matrix's!");
  }
  Matrix result = new Matrix(a.rows, a.cols);
  int oddCounter = 1;
  for(int i = 0; i < result.rows; i++){
    for(int j = 0; j < result.cols; j++){
      if(oddCounter % 2 == 1){
        result.matrix[i][j] = a.matrix[i][j];
      } else{
        result.matrix[i][j] = b.matrix[i][j];
      }
      oddCounter++;
    }
  }
  return result;
}
Matrix combineMatrixAlternateArray(ArrayList<Matrix> matArr){
  if(matArr.size() == 1){ // didn't need to combine a matrix after all
    return matArr.get(0);
  }
  int rows = matArr.get(0).rows;
  int cols = matArr.get(0).cols;
  for(Matrix mat: matArr){
    if(mat.rows != rows){
      println("Row mismatch on combining array");
    } else if(mat.cols != cols){
      println("Cols mismatch on combining array");
    }
  }
  Matrix result = new Matrix(rows, cols);
  int matrixChoice = 0;
  for(int i = 0; i < result.rows; i++){
    for(int j = 0; j < result.cols; j++){
      result.matrix[i][j] = matArr.get(matrixChoice).matrix[i][j];
      matrixChoice++;
      if(matrixChoice == matArr.size()){
        matrixChoice = 0;
      }
    }
  }
  return result;
}

//static methods for matrix's ends in Matrix.
Matrix mapMatrixMutate(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = mutateMatrix(a.matrix[i][j]);
    }
  }
  return result;
}

Matrix mapMatrixSigmoid(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = sigmoid(a.matrix[i][j]);
    }
  }
  return result;
}
Matrix mapMatrixSigmoidDerivative(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = sigmoidDerivative(a.matrix[i][j]);
    }
  }
  return result;
}
//tanh for +-1
Matrix mapMatrixTanh(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = tanh(a.matrix[i][j]);
    }
  }
  return result;
}
Matrix mapMatrixTanhDerivative(Matrix a){
  Matrix result = new Matrix(a.rows, a.cols);
  // apply the mutate function to all values in the matrix
  for(int i = 0; i < a.rows; i++){
    for( int j = 0; j < a.cols; j++){
      result.matrix[i][j] = tanhDerivative(a.matrix[i][j]);
    }
  }
  return result;
}

Matrix transposeMatrix(Matrix a){
  Matrix result = new Matrix(a.cols, a.rows);
  for(int i = 0; i < result.rows; i++){
    for( int j = 0; j < result.cols; j++){
      result.matrix[i][j] = a.matrix[j][i];
    }
  }
  return result;
}

Matrix subtractMatrix(Matrix a, Matrix b){
  Matrix result = new Matrix(a.rows, b.cols);
  for(int i = 0; i < result.rows; i++){
      for( int j = 0; j < result.cols; j++){
        result.matrix[i][j] = a.matrix[i][j] - b.matrix[i][j];
      }
    }
  return result;
}

Matrix addMatrix(Matrix a, Matrix b){
  Matrix result = new Matrix(a.rows, b.cols);
  for(int i = 0; i < result.rows; i++){
    for( int j = 0; j < result.cols; j++){
      result.matrix[i][j] = a.matrix[i][j] + b.matrix[i][j];
    }
  }
  return result;
}

Matrix addMatrix(Matrix a, float x){
  Matrix result = new Matrix(a.rows, a.cols);
  for(int i = 0; i < result.rows; i++){
    for( int j = 0; j < result.cols; j++){
      result.matrix[i][j] = a.matrix[i][j] + x;
    }
  }
  return result;
}

Matrix dotMatrix(Matrix a, Matrix b){
  if(a.cols != b.rows){
    //println(a.toString());
    //println(a.cols);
    //println(b.toString());
    //println(b.rows);
    println("Incompatiable Sizes");
  }
  Matrix result = new Matrix(a.rows, b.cols);
  for(int i = 0; i < a.rows; i++){
      for( int j = 0; j < b.cols; j++){
        //sup all the rows of A rows times columns of B
        float sum = 0;
        for(int k = 0; k < a.cols; k++){
          sum += a.matrix[i][k] * b.matrix[k][j];
        }
        result.matrix[i][j] = sum;
      }
    }
  return result;
}


Matrix multiplyMatrix(Matrix a, Matrix b){
  Matrix result = new Matrix(a.rows, a.cols);
  for(int i = 0; i < result.rows; i++){
      for( int j = 0; j < result.cols; j++){
        result.matrix[i][j] = a.matrix[i][j] * b.matrix[i][j];
      }
    }
  return result;
}
Matrix multiplyMatrix(Matrix a, Float x){
  Matrix result = new Matrix(a.rows, a.cols);
  for(int i = 0; i < result.rows; i++){
    for( int j = 0; j < result.cols; j++){
      result.matrix[i][j] = a.matrix[i][j] * x;
    }
  }
  return result;
}


// This is how we adjust weights ever so slightly
float mutateMatrix(float x) {
  if (random(1) < LIKLEYHOOD_MUTATION) { // ten percent chance we mutate the value
    float offset = randomGaussian() * 0.6;
    // var offset = random(-0.1, 0.1);
    float newx = x + offset;
    return newx;
  } else {
    return x; // we didn't adjust the weight afterall...
  }
}

//our activation function
//https://en.wikipedia.org/wiki/Sigmoid_function the constant is Euelers Constant
float sigmoid(float x) {
  float y = 1 / (1 + pow(2.71828182845904523536028747135266249775724709369995957496696762772407663035354759457138217852516642742746, -x));
  return y;
}
float sigmoidDerivative(float x){
  return x * (1 - x);
}
float tanh(float x){
  float y = tan(x);
  return y;
}
float tanhDerivative(float x){
  float y = 1 / (pow(cos(x),2));
  return y;
}