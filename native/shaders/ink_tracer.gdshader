shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled;
// Shot trail on a unit quad. The model Y column is the trail (head at +Y, tail at
// -Y); the X column length is the head width. The quad turns about that axis to
// face the camera, and tapers to the tail.
uniform vec4 pigment:source_color=vec4(1.0,.9,.6,1.0);
varying float along;
void vertex(){
 vec3 axis=MODEL_MATRIX[1].xyz;
 vec3 origin=MODEL_MATRIX[3].xyz;
 float width=length(MODEL_MATRIX[0].xyz);
 vec3 view=normalize(INV_VIEW_MATRIX[3].xyz-origin);
 vec3 side=cross(normalize(axis+vec3(1e-5)),view);
 side=length(side)<.001?INV_VIEW_MATRIX[0].xyz:normalize(side);
 along=VERTEX.y+.5;
 float taper=mix(.18,1.0,along);
 vec3 world=origin+axis*VERTEX.y+side*VERTEX.x*width*taper;
 POSITION=PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
}
void fragment(){
 float d=abs(UV.x-.5)*2.0;
 float core=1.0-smoothstep(.0,.45,d);
 float ink=smoothstep(.72,.86,d);
 vec3 color=mix(pigment.rgb,vec3(1.0,.98,.9),core*along);
 color=mix(color,vec3(.05,.02,.04),ink*.85);
 ALBEDO=color;EMISSION=color*.6;
 ALPHA=(1.0-smoothstep(.9,1.0,d))*pow(along,1.3);
}
