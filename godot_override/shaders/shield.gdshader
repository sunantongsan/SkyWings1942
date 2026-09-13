shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 shield_color : source_color = vec4(0.2,0.86,1.0,1.0);
void fragment(){
 float rim=pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),3.5);
 float scan=pow(max(0.0,sin(UV.y*95.0-TIME*1.7)),18.0);
 float pulse=0.85+0.15*sin(TIME*1.8);
 ALBEDO=shield_color.rgb;EMISSION=shield_color.rgb*(0.25+rim);
 ALPHA=(rim*0.32+scan*0.05+0.012)*pulse;
}
