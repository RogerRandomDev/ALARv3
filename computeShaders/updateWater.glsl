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

void main() {
    uint index=gl_GlobalInvocationID.x;
    int cellID=my_buffer.data[index];
    
    /*
    I need different handlers for each type of update,
    but for now i'll just do the water in here
    */
    if(cellID==-1&&(
    getCell(-1,0,index)==7||
    getCell(1,0,index)==7||
    getCell(0,1,index)==7
    )){cellID=7;}
    if(my_buffer.data[index]!=cellID){
      my_buffer.data[index] = cellID;
      }
}

\

