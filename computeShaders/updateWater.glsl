#[compute]

#version 450

layout(local_size_x = 4) in;

layout(set = 0, binding = 0, std430) restrict buffer MyBuffer {
  double data[];
}
my_buffer;

void main() {
	my_buffer.data[gl_GlobalInvocationID.x] *= 2;
}
