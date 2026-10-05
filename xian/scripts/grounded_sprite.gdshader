shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D artwork : source_color, filter_linear_mipmap;
uniform float surface_y=0.075;
varying vec3 artwork_world;
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(
  INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),
  INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),
  INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),
  MODEL_MATRIX[3]);
 artwork_world=(INV_VIEW_MATRIX*MODELVIEW_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
 vec4 ink=texture(artwork,UV)*COLOR;
 if(ink.a<0.15){discard;}
 ALBEDO=ink.rgb;
 // Move depth along the orthographic viewing ray. Screen position and artwork
 // pixels do not change. Below-ground pixels sit on the ground, not inside it.
 vec3 toward_camera=normalize(INV_VIEW_MATRIX[2].xyz);
 float distance_to_surface=max(0.0,(surface_y-artwork_world.y)/max(toward_camera.y,0.001));
 vec3 depth_world=artwork_world+toward_camera*distance_to_surface;
 vec4 clip=PROJECTION_MATRIX*VIEW_MATRIX*vec4(depth_world,1.0);
 float ndc=clip.z/clip.w;
 if(OUTPUT_IS_SRGB){DEPTH=ndc*0.5+0.5;}else{DEPTH=ndc;}
}
