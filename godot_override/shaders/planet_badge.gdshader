shader_type canvas_item;
uniform vec4 planet_color:source_color=vec4(0.2,0.65,0.7,1);
uniform float seed=1.0;
void fragment(){
 vec2 p=UV*2.0-1.0;float r=dot(p,p);
 if(r>1.0){COLOR=vec4(0.0);}else{
  vec3 n=vec3(p,sqrt(1.0-r));
  float continents=sin(p.x*7.0+seed+sin(p.y*8.0))*cos(p.y*6.0+seed*0.4);
  vec3 base=mix(planet_color.rgb*0.35,planet_color.rgb,smoothstep(-0.25,0.1,continents));
  float light=max(0.0,dot(n,normalize(vec3(-0.7,-0.5,1.0))));
  float rim=pow(1.0-n.z,3.0);
  COLOR=vec4(base*(0.24+0.9*light)+planet_color.rgb*rim*0.4,smoothstep(1.0,0.97,r));
 }
}
