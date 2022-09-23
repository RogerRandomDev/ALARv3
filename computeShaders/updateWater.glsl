#[compute]

#version 450


layout(local_size_x = 256) in;

layout(set = 0, binding = 0, std430) restrict buffer MyBuffer {
  int data[];
  
}

my_buffer;
//generates a random number
uint wang_hash(uint seed)
{
    seed = (seed ^ 61) ^ (seed >> 16);
    seed *= 9;
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return seed;
}


//grabs cell by starting position(index) and moves by the x and y coords
int getCell(int x, int y, uint index){
  if(index%112+x != (index+x)%112){return -2;}
  return my_buffer.data[index+x-(y*112)];
}
//checks if inp is inside the min and max
bool inRange(int inp, int minimum, int maximum){
  return (inp>=minimum && inp<=maximum);
}
//checks if inp is inside the min and max or it is negative
bool inRangeOrNegative(int inp, int minimum, int maximum){
  return (inp<0)||(inp>=minimum && inp<=maximum);
}


//water cell updates
int flowWater(int neighborCells[3][3], int cellID){
  int cellOut=cellID;
  
  if(inRange(neighborCells[0][1],7,11)&&cellOut!=8){cellOut=7;}
  bool fromLeft=inRange(neighborCells[1][0],7,11)&&!inRangeOrNegative(neighborCells[2][0],7,11);
  bool fromRight=inRange(neighborCells[1][2],7,11)&&!inRangeOrNegative(neighborCells[2][2],7,11);
  if(cellOut<0){cellOut=12;}
  
  if(fromLeft){cellOut=min(cellOut,neighborCells[1][0]+1);}
  if(fromRight){cellOut=min(cellOut,neighborCells[1][2]+1);}
  
  if(cellOut!=8&&!(
    inRange(neighborCells[0][1],7,11)||
    inRange(neighborCells[1][0],7,cellID-1)||
    inRange(neighborCells[1][2],7,cellID-1)
  )){
    cellOut+=1+int(cellOut==7);
    if(cellOut==12&&(neighborCells[1][0]==10||neighborCells[1][2]==10)){cellOut=11;}
    
    
    }
  
  if(cellOut==8&&cellID!=8){cellOut=9;}
  if(cellOut>11){cellOut=-2;}
  
return cellOut;
}
uint time;
//grass growth updates
int growGrass(int neighborCells[3][3],int cellID,uint index){
  int cellOut=cellID;
  bool doGrow=wang_hash(index+time)>4200000000;

  if(
    (neighborCells[1][0]==0||
    neighborCells[1][1]==0||
    neighborCells[1][2]==0||
    neighborCells[0][0]==0||
    neighborCells[0][2]==0)&&
    neighborCells[0][1]<0&&
    doGrow){cellOut=0;}
  if(neighborCells[0][1]>-1&&doGrow){cellOut=1;}
  return cellOut;
}







void main() {  
  time=uint(my_buffer.data[12544])*12544;
  uint index=gl_GlobalInvocationID.x;
  int cellID=my_buffer.data[index];
  int neighborCells[3][3]={
    {getCell(-1,1,index),getCell(0,1,index),getCell(1,1,index)},
    {getCell(-1,0,index),cellID,getCell(1,0,index)},
    {getCell(-1,-1,index),getCell(0,-1,index),getCell(1,-1,index)}
};
  //all water actions
  if(
    (inRangeOrNegative(cellID,7,11))
    ){cellID=flowWater(neighborCells,cellID);}
  //the growth of grass
  if(cellID==0||cellID==1){cellID=growGrass(neighborCells,cellID,index);}

  my_buffer.data[index] = cellID;
}

\

