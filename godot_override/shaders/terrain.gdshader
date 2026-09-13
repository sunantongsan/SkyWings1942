shader_type spatial;
render_mode diffuse_burley;
uniform vec4 soil_color : source_color = vec4(0.16,0.26,0.23,1.0);
uniform vec4 grass_color : source_color = vec4(0.26,0.39,0.29,1.0);
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float n=noise(world_pos.xz*0.23)*0.65+noise(world_pos.xz*1.4)*0.25+noise(world_pos.xz*3.0)*0.1;
 vec3 col=mix(soil_color.rgb,grass_color.rgb,smoothstep(0.28,0.72,n));
 float grain=noise(world_pos.xz*9.0);
 ALBEDO=col*(0.96+grain*0.07);ROUGHNESS=0.96;METALLIC=0.0;
}
