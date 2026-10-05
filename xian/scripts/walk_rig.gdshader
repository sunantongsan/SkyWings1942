shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
uniform sampler2D sheet : source_color, filter_linear_mipmap;
uniform float phase=0.0;
uniform float quadruped=0.0;
uniform float climbing=0.0;
void vertex(){
 VERTEX.x*=1.3;
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),MODEL_MATRIX[3]);
}
void fragment(){
 // Animate one identity-locked contact pose, not disconnected generated poses.
 vec2 p=UV*vec2(4.0,2.0);p.x=(p.x-0.5)*1.3+0.5;
 float split=smoothstep(0.25,0.75,p.x);
 float opposite=mix(sin(phase),sin(phase+3.14159265),split);
 if(quadruped>0.5){opposite=sin(phase+p.x*9.42477796);}
 float legs=smoothstep(quadruped>0.5?0.52:0.57,0.90,p.y);
 float arms=smoothstep(0.25,0.38,p.y)*(1.0-smoothstep(0.49,0.61,p.y));
 vec2 sample_pos=p;
 sample_pos.x-=opposite*((quadruped>0.5?0.035:0.07)*legs-0.018*arms);
 // The swing foot lifts; the support foot remains on the ground. Half a cycle later they swap.
 float lift=mix(max(0.0,sin(phase)),max(0.0,sin(phase+3.14159265)),split);
 sample_pos.y+=lift*(quadruped>0.5?0.02:0.04)*legs;
 sample_pos.y+=opposite*climbing*0.035*arms;
 vec4 color=texture(sheet,sample_pos/vec2(4.0,2.0));
 if(sample_pos.x<0.0||sample_pos.x>1.0||sample_pos.y<0.0||sample_pos.y>1.0)color.a=0.0;
 ALBEDO=color.rgb;ALPHA=color.a;
}
