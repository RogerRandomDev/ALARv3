#[compute]

#version 450


layout(local_size_x = 256) in;

layout(set = 0, binding = 0, std430) restrict buffer MyBuffer {
  int data[];
}
my_buffer;
layout(set = 0, binding = 1, rgba8) writeonly uniform image2D target_image;



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
  
  return int(index%112+x == (index+x)%112)*(my_buffer.data[index+x-(y*112)]+2) -2;;
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
int flowWater(int neighborCells[3][3], int cellID,uint index){
  if(index<112){return cellID;}
  int cellOut=cellID;
  
  if(inRange(neighborCells[0][1],7,11)&&cellOut!=8){cellOut=7;}
  bool fromLeft=neighborCells[1][0]==8||inRange(neighborCells[1][0],7,11)&&!inRangeOrNegative(neighborCells[2][0],7,11);
  bool fromRight=neighborCells[1][2]==8||inRange(neighborCells[1][2],7,11)&&!inRangeOrNegative(neighborCells[2][2],7,11);
  cellOut+=int(cellOut<0)*(12-cellOut);
  
  if(fromLeft){cellOut=min(cellOut,neighborCells[1][0]+1);}
  if(fromRight){cellOut=min(cellOut,neighborCells[1][2]+1);}
  
  if(cellOut!=8&&!(
    inRange(neighborCells[0][1],7,11)||
    inRange(neighborCells[1][0],7,cellID-1)||
    inRange(neighborCells[1][2],7,cellID-1)
  )){
    cellOut+=1+int(cellOut==7);
    cellOut+=int(cellOut==12&&(neighborCells[1][0]==10||neighborCells[1][2]==10))*(11-cellOut);
    
    
    }
  cellOut+=int(cellOut==8&&cellID!=8)*(9-cellOut);
  if(cellOut>11){cellOut=-2;}
  //creates new source blocks
  cellOut+=int(
    (neighborCells[0][1]==8&&(neighborCells[1][0]==8||neighborCells[1][2]==8))||
    (neighborCells[1][2]==8&&(!inRangeOrNegative(neighborCells[2][2],7,11)||neighborCells[2][2]==8)&&
    neighborCells[1][0]==8&&(!inRangeOrNegative(neighborCells[2][0],7,11)||neighborCells[2][0]==8)
    )
    )*(8-cellOut);
  
return cellOut;
}
uint time;
//grass growth updates
int growGrass(int neighborCells[3][3],int cellID,uint index){
  int cellOut=cellID;
  bool doGrow=wang_hash(index+time)>4200000000;
  //creates grass if it can
  cellOut-=(
    int(
      doGrow&&neighborCells[0][1]<0&&
      (
      neighborCells[0][0]==0||
      neighborCells[0][2]==0||
      neighborCells[1][0]==0||
      neighborCells[1][2]==0||
      neighborCells[2][0]==0||
      neighborCells[2][2]==0
      )
    ))*(cellOut)-
    //turns grass to dirt if it is covered
    int(neighborCells[0][1]>-1&&doGrow)*(1-cellOut);

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
    ){cellID=flowWater(neighborCells,cellID,index);}
  //the growth of grass
  if(cellID==0||cellID==1){cellID=growGrass(neighborCells,cellID,index);}

  my_buffer.data[index] = cellID;
  //generates the shadow base texture
  ivec2 indexXY=ivec2(index%112,int(index/112));
  vec2 uv = (vec2(indexXY) + 0.5) / vec2(imageSize(target_image));
  //add another check for each cell that light passes through
  imageStore(target_image, indexXY, vec4(0.0,0.0,0.0,float(
    inRangeOrNegative(cellID,7,11)||cellID==13

  )));
}

\

