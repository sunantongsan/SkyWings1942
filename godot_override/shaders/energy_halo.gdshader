shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 tint : source_color=vec4(0.18,0.85,1.0,1.0);
void vertex(){MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);}
void fragment(){vec2 p=UV*2.0-1.0;float d=dot(p,p);float glow=exp(-d*5.5)*smoothstep(1.0,0.3,d);ALBEDO=tint.rgb;ALPHA=glow*0.2*(0.88+0.12*sin(TIME*1.8));}
