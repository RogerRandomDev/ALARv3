#[compute]

#version 450


layout(local_size_x = 256) in;

layout(set = 0, binding = 0, std430) restrict buffer MyBuffer {
  int data[];
}
my_buffer;
uint renderDistance=112;

int getCell(int x, int y, uint index){
  if(index%112+x != (index+x)%112){return -2;}
  return my_buffer.data[index+x-(y*112)];
}
bool inRange(int inp, int minimum, int maximum){
  return (inp>=minimum && inp<=maximum);
}
bool inRangeOrNegative(int inp, int minimum, int maximum){
  return !(inp>-1)||(inp>=minimum && inp<=maximum);
}
//water cell updates
int flowWater(int neighborCells[3][3], int cellID){
  int cellOut=cellID;
  
  if(inRange(neighborCells[0][1],7,11)&&cellOut!=8){cellOut=7;}
  if(cellOut<0){cellOut=13;}
  if(inRange(neighborCells[1][0],7,11)&&!inRangeOrNegative(neighborCells[2][0],7,11)){cellOut=min(cellOut,neighborCells[1][0]+1);}
  if(inRange(neighborCells[1][2],7,11)&&!inRangeOrNegative(neighborCells[2][2],7,11)){cellOut=min(cellOut,neighborCells[1][2]+1);}
  
  if(!(
    inRange(neighborCells[0][1],7,11)||
    inRange(neighborCells[1][0],7,10)||
    inRange(neighborCells[1][2],7,10)
    
  )){
    cellOut+=1;
    if(cellOut==8){cellOut+=1;}
    if(cellOut>11){cellOut=-2;}
    }
  if(cellOut==8&&cellID!=8){cellOut=9;}
 return cellOut;
}



void main() {
    uint index=gl_GlobalInvocationID.x;
    int cellID=my_buffer.data[index];
    int neighborCells[3][3]={
      {getCell(-1,1,index),getCell(0,1,index),getCell(1,1,index)},
      {getCell(-1,0,index),cellID,getCell(1,0,index)},
      {getCell(-1,-1,index),getCell(0,-1,index),getCell(1,-1,index)}
};
    /*
    I need different handlers for each type of update,
    but for now i'll just do the water in here
    */
    /*
    checks above, left, anr right to be in the water range
    */
    if(
      (cellID<0||inRange(cellID,7,11))&&
      (inRange(neighborCells[1][0],7,11)||
      inRange(neighborCells[1][2],7,11)||
      inRange(neighborCells[0][1],7,11))
      ){cellID=flowWater(neighborCells,cellID);}
    
    my_buffer.data[index] = cellID;
}

\

