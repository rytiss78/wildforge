shader_type sky;
uniform vec3 top_color : source_color = vec3(.45,.78,.9);
uniform vec3 horizon_color : source_color = vec3(.86,.92,.83);
uniform float moon_strength=0.0;
uniform float space_strength=0.0;
uniform float fire_strength=0.0;
uniform sampler2D paint : source_color, filter_linear_mipmap, repeat_enable;

float sphere(vec3 direction, vec3 centre, float radius) {
 return 1.0-smoothstep(radius-.004,radius+.004,distance(direction,normalize(centre)));
}
vec3 planet(vec3 direction,vec3 centre,float radius,vec3 tint) {
 vec2 p=(direction.xz-normalize(centre).xz)/radius;
 float band=sin(p.y*14.0+sin(p.x*4.0)*1.4)*.10;
 vec3 grain=texture(paint,p*.48+.5).rgb;
 return tint*(.75+band)*mix(vec3(1.0),grain*1.4,.22);
}
void sky() {
 vec3 d=normalize(EYEDIR);
 float height=clamp(d.y,0.0,1.0);
 vec3 color=mix(horizon_color,top_color,pow(height,.55));
 float cloud=sin(d.x*21.0+sin(d.z*13.0+TIME*.007))*sin(d.z*17.0-d.y*20.0);
 float clouds=smoothstep(.62,.89,cloud)*smoothstep(.02,.15,d.y)*(1.0-space_strength)*.30;
 color=mix(color,vec3(.98,.94,.81),clouds);
 vec3 centre=vec3(-.52,.43,-.72);
 float moon=sphere(d,centre,.32)*moon_strength;
 color=mix(color,planet(d,centre,.32,vec3(.74,.83,.91)),moon);
 float large=sphere(d,vec3(.34,.33,-.8),.38)*space_strength;
 color=mix(color,planet(d,vec3(.34,.33,-.8),.38,vec3(.85,.68,.90)),large);
 float second=sphere(d,vec3(-.67,.46,-.35),.17)*space_strength;
 color=mix(color,planet(d,vec3(-.67,.46,-.35),.17,vec3(.96,.78,.52)),second);
 vec3 axis=normalize(vec3(.2,.9,.3));
 float ring=abs(dot(d-normalize(vec3(.34,.33,-.8)),axis));
 float span=distance(d,normalize(vec3(.34,.33,-.8)));
 color=mix(color,vec3(.88,.79,.65),space_strength*(1.0-smoothstep(.010,.017,ring))*smoothstep(.37,.40,span)*(1.0-smoothstep(.65,.68,span))*.75);
 float flame=sin(d.x*18.0+sin(d.z*11.0+TIME*.15)*2.0)*.04+sin(d.z*25.0+TIME*.3)*.025;
 float fire=(1.0-smoothstep(.14+flame,.25+flame,d.y))*smoothstep(.01,.05,d.y)*fire_strength;
 color=mix(color,mix(vec3(.94,.38,.16),vec3(1.0,.79,.40),clamp(d.y*4.0,0.0,1.0)),fire*.72);
 float star=pow(max(0.0,sin(d.x*663.0)*sin(d.z*491.0)*sin(d.y*731.0)),35.0);
 color+=vec3(.95,.88,.7)*star*(space_strength+moon_strength)*.9;
 COLOR=color;
}
