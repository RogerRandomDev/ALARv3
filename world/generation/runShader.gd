extends Node

var input_data=[0]
var myCenterChunk=Vector2i.ZERO
var myChunks={}
var rd := RenderingServer.create_local_rendering_device()
var uniform := RDUniform.new()
var imgUniform := RDUniform.new()
var shader_file := preload("res://computeShaders/updateWater.glsl")
var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
var shader := rd.shader_create_from_spirv(shader_spirv)
var pipeline := rd.compute_pipeline_create(shader)
var bufferTex=null
func _ready():
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	imgUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	imgUniform.binding = 1
	uniform.binding = 0
	var fmt=RDTextureFormat.new()
	fmt.height=(world.renderDistance*2+1)*16
	fmt.width=(world.renderDistance*2+1)*16
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UINT
	fmt.usage_bits=RenderingDevice.TEXTURE_USAGE_STORAGE_BIT\
	| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT\
	| RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT\
	| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var view=RDTextureView.new()
	bufferTex=rd.texture_create(fmt,view,[world.worldShadows.img.get_data()])

func runCompute():
	uniform.clear_ids();imgUniform.clear_ids()
	
	# Create a local rendering device.
	myCenterChunk=world.mapGen.centerChunk
	myChunks=world.mapGen.loadedChunks.keys()
	# Load GLSL shader
	
	
	
	# Prepare our data. We use doubles in the shader, so we need 64 bit.
	var input := PackedInt32Array(input_data)
	var input_bytes := input.to_byte_array()
	# Create a storage buffer that can hold 10 double values. Each
	# double has 8 byte (64 bit) so 10 x 8 = 80 bytes
	var buffer := rd.storage_buffer_create(len(input_bytes), input_bytes)
	
	uniform.add_id(buffer);imgUniform.add_id(bufferTex)
	
	var uniform_set := rd.uniform_set_create([uniform, imgUniform], shader, 0)
	# Create a compute pipeline
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, (world.renderDistance*2+1)**2, 1, 1)
	rd.compute_list_end()
	
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	# Read back the data from the buffers
	var output_bytes := rd.buffer_get_data(buffer)
	var output := output_bytes.to_int32_array()
	var output_img := rd.texture_get_data(bufferTex,0)
	world.worldShadows.loadNewTex(output_img)
	
	rd.free_rid(buffer)
	
	return output
