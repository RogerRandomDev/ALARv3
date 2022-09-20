#[compute]

#version 450


layout(local_size_x = 256) in;

layout(set = 0, binding = 0, std430) restrict buffer MyBuffer {
  int data[];
}
my_buffer;
uint renderDistance=784;
void main() {
    uint index=gl_GlobalInvocationID.x;
    int cellID=my_buffer.data[index];
    for(int x=-1;x<2;x+=1){
      for(int y=-1;y<2;y+=1){
        if(((x==0&&y==0)||index%renderDistance + x <0 ||index%renderDistance + x >renderDistance||
        index%renderDistance + y*renderDistance <0 ||index%renderDistance + y*renderDistance >12544)){continue;}
        /*
        I need different handlers for each type of update,
        but for now i'll just do the water in here
        */
        if(cellID==-1&&my_buffer.data[index+x+y*renderDistance]==7){cellID=7;}
        
    }
    }
    my_buffer.data[index] = cellID;
}

\

