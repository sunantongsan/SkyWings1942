shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 albedo_color : source_color=vec4(1.0,0.4,0.05,0.7);
uniform float opacity=0.7;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),MODEL_MATRIX[3]);}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float n=noise(UV*5.0+vec2(0,TIME*3.0))*0.65+noise(UV*11.0+vec2(TIME,TIME*6.0))*0.35;
 float shape=max(0.0,1.0-length(p*vec2(1.1,0.9)));
 float heat=clamp(shape*1.5+n*0.55-0.25,0.0,1.0);
 ALBEDO=mix(vec3(0.6,0.08,0.005),mix(vec3(1.0,0.42,0.02),vec3(1.0,0.9,0.5),heat),heat);
 ALPHA=shape*heat*opacity;
}
