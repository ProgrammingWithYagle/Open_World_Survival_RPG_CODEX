shader_type canvas_item;

uniform sampler2D kind_map : filter_nearest, repeat_disable;
uniform ivec2 tile_origin;
varying vec2 world_pixel;
varying vec4 tint;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
int kind_at(ivec2 cell) {
	vec2 uv=(vec2(cell-tile_origin)+vec2(1.5))/98.0;
	return int(round(texture(kind_map,uv).r*255.0));
}
int priority(int kind) {
	if(kind==7) { return 9; }
	if(kind==5 || kind==6) { return 0; }
	return 3;
}
void vertex() {
	world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;
	tint=COLOR;
}
void fragment() {
	ivec2 cell=ivec2(floor(world_pixel/32.0));
	vec2 pixel=mod(floor(world_pixel),32.0);
	int kind=kind_at(cell);
	int original_priority=priority(kind);
	float edge=2.0+floor(hash(floor(world_pixel/4.0))*5.0);
	ivec2 sample_cell=cell;
	int left=kind_at(cell+ivec2(-1,0));
	int right=kind_at(cell+ivec2(1,0));
	int above=kind_at(cell+ivec2(0,-1));
	int below=kind_at(cell+ivec2(0,1));
	if(pixel.x<edge && priority(left)>original_priority) { kind=left; sample_cell=cell+ivec2(-1,0); }
	if(pixel.x>31.0-edge && priority(right)>original_priority) { kind=right; sample_cell=cell+ivec2(1,0); }
	if(pixel.y<edge && priority(above)>original_priority) { kind=above; sample_cell=cell+ivec2(0,-1); }
	if(pixel.y>31.0-edge && priority(below)>original_priority) { kind=below; sample_cell=cell+ivec2(0,1); }
	int variant=int(hash(vec2(sample_cell))*2.0);
	int index=kind*2+variant;
	vec2 atlas_pixel=vec2(float(index%4),float(index/4))*32.0+pixel+vec2(.5);
	COLOR=texture(TEXTURE,atlas_pixel/128.0)*tint;
}
