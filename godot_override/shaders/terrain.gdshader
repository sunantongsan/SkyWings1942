shader_type spatial;
render_mode diffuse_burley;
uniform vec4 soil_color : source_color = vec4(0.16,0.26,0.23,1.0);
uniform vec4 grass_color : source_color = vec4(0.26,0.39,0.29,1.0);
uniform bool deployment_active = false;
uniform bool deployment_available = true;
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float n=noise(world_pos.xz*0.23)*0.65+noise(world_pos.xz*1.4)*0.25+noise(world_pos.xz*3.0)*0.1;
 vec3 col=mix(soil_color.rgb,grass_color.rgb,smoothstep(0.28,0.72,n));
 float grain=noise(world_pos.xz*9.0);
 if(deployment_active){
  vec2 p=abs(world_pos.xz);
  bool inside=p.x<=22.0 && p.y<=20.0;
  bool outer=p.x>=16.0 || p.y>=13.0;
  if(p.x<=24.0 && p.y<=22.0){
   vec3 tint=(inside && outer && deployment_available)?vec3(0.12,0.95,0.32):vec3(0.95,0.12,0.15);
   vec2 cell=abs(fract(world_pos.xz/2.0)-0.5);
   float grid=step(0.46,max(cell.x,cell.y));
   float border=1.0-step(0.14,min(min(abs(p.x-22.0),abs(p.y-20.0)),outer?min(abs(p.x-16.0),abs(p.y-13.0)):100.0));
   col=mix(col,tint,0.25+grid*0.18+border*0.30);
   EMISSION=tint*(0.06+grid*0.09+border*0.22);
  }
 }
 ALBEDO=col*(0.96+grain*0.07);ROUGHNESS=0.96;METALLIC=0.0;
}
