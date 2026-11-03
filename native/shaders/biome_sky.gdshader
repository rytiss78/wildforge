shader_type sky;
uniform vec3 top_color : source_color = vec3(.45,.78,.9);
uniform vec3 horizon_color : source_color = vec3(.86,.92,.83);
uniform float moon_strength=0.0;
uniform float space_strength=0.0;
uniform float fire_strength=0.0;
// Per-map skies (user, November 3: "maps should have their own sky, inspired by
// Destiny 2"), set by SkyLook. base_bodies fades the old shared moons/ribbon.
uniform float base_bodies=1.0;
uniform vec3 giant_dir=vec3(.3,.3,-.9);
uniform float giant_radius=0.0;
uniform vec3 giant_tint : source_color=vec3(.8,.6,.4);
uniform vec3 giant_band : source_color=vec3(.95,.85,.7);
uniform float giant_bands=0.0;
uniform float giant_ring=0.0;
uniform vec3 giant_glow : source_color=vec3(.6,.8,1.0);
uniform vec3 small_dir=vec3(-.6,.4,-.6);
uniform float small_radius=0.0;
uniform vec3 small_tint : source_color=vec3(.9,.9,.95);
uniform float aurora=0.0;
uniform vec3 aurora_a : source_color=vec3(.2,.9,.8);
uniform vec3 aurora_b : source_color=vec3(.9,.4,.9);
uniform float black_sun=0.0;
uniform vec3 sun_dir=vec3(-.2,.35,-.9);
uniform vec3 corona : source_color=vec3(1.0,.5,.15);
uniform float star_field=0.0;
uniform sampler2D paint : source_color, filter_linear_mipmap, repeat_enable;

float sphere(vec3 direction, vec3 centre, float radius) {
 return 1.0-smoothstep(radius-.004,radius+.004,distance(direction,normalize(centre)));
}
vec3 planet(vec3 direction,vec3 centre,float radius,vec3 tint) {
 vec3 forward=normalize(centre);
 vec3 right=normalize(cross(vec3(0.0,1.0,0.0),forward));
 vec3 up=normalize(cross(forward,right));
 vec2 p=vec2(dot(direction-forward,right),dot(direction-forward,up))/radius;
 vec3 normal=vec3(p,sqrt(max(0.0,1.0-dot(p,p))));
 float light=max(0.0,dot(normal,normalize(vec3(-.78,.26,.42))));
 float band=sin(p.y*18.0+sin(p.x*4.0)*1.4)*.05;
 vec3 grain=texture(paint,p*.48+.5).rgb;
 return tint*(.10+light*.85+band*light)*mix(vec3(1.0),grain*1.4,.18);
}
void sky() {
 vec3 d=normalize(EYEDIR);
 float height=clamp(d.y,0.0,1.0);
 vec3 color=mix(horizon_color,top_color,pow(height,.55));
 float cloud=sin(d.x*21.0+sin(d.z*13.0+TIME*.007))*sin(d.z*17.0-d.y*20.0);
 float clouds=smoothstep(.62,.89,cloud)*smoothstep(.02,.15,d.y)*(1.0-space_strength)*.30;
 color=mix(color,horizon_color*1.15,clouds*.45);
 vec3 centre=vec3(-.52,.43,-.72);
 float moon=sphere(d,vec3(-.52,.21,-.82),.18)*max(.7,moon_strength)*base_bodies;
 color=mix(color,planet(d,vec3(-.52,.21,-.82),.18,vec3(.74,.83,.91)),moon);
 float large=sphere(d,vec3(.34,.24,-.8),.13)*max(.45,space_strength)*base_bodies;
 color=mix(color,planet(d,vec3(.34,.24,-.8),.13,vec3(.85,.68,.90)),large);
 float second=sphere(d,vec3(-.67,.46,-.35),.17)*space_strength;
 color=mix(color,planet(d,vec3(-.67,.46,-.35),.17,vec3(.96,.78,.52)),second);
 vec3 axis=normalize(vec3(.2,.9,.3));
 float ring=abs(dot(d-normalize(vec3(.34,.24,-.8)),axis));
 float span=distance(d,normalize(vec3(.34,.24,-.8)));
 color=mix(color,vec3(.88,.79,.65),base_bodies*max(.35,space_strength)*(1.0-smoothstep(.004,.008,ring))*smoothstep(.14,.17,span)*(1.0-smoothstep(.28,.30,span))*.75);
 float flame=sin(d.x*18.0+sin(d.z*11.0+TIME*.15)*2.0)*.04+sin(d.z*25.0+TIME*.3)*.025;
 float fire=(1.0-smoothstep(.14+flame,.25+flame,d.y))*smoothstep(.01,.05,d.y)*fire_strength;
 color=mix(color,mix(vec3(.94,.38,.16),vec3(1.0,.79,.40),clamp(d.y*4.0,0.0,1.0)),fire*.72);
 float star=pow(max(0.0,sin(d.x*663.0)*sin(d.z*491.0)*sin(d.y*731.0)),35.0);
 color+=vec3(.95,.88,.7)*star*(space_strength+moon_strength+star_field)*.9;
 // Low-horizon celestial ribbon remains visible at the unchanged third-person camera.
 float ribbon=exp(-pow((d.y-.12-.035*sin(d.x*9.0+d.z*5.0))/.018,2.0));
 float threads=.8+.2*sin(d.x*17.0+d.z*11.0);
 color+=vec3(.12,.58,.48)*ribbon*threads*.48*base_bodies;
 float halo=exp(-abs(distance(d,normalize(vec3(-.52,.21,-.82)))-.18)*160.0);
 color+=vec3(.58,.84,1.0)*halo*.27*base_bodies;
 // Aurora curtains (Dreaming City, Europa): vertical folds over the horizon.
 if(aurora>0.0){
  float fold=sin(atan(d.z,d.x)*14.0+sin(atan(d.z,d.x)*5.0+TIME*.05)*2.2);
  float band=smoothstep(.08,.22,d.y)*(1.0-smoothstep(.35,.62,d.y));
  float curtain=pow(max(0.0,fold*.5+.5),3.0)*band;
  color+=mix(aurora_a,aurora_b,clamp((d.y-.1)*3.0,0.0,1.0))*curtain*aurora*.55;
 }
 // An eclipsed black sun with a burning corona (the red worlds).
 if(black_sun>0.0){
  float sd=distance(d,normalize(sun_dir));
  float rim=exp(-pow((sd-.085)/.012,2.0))+exp(-(sd-.085)*14.0)*step(.085,sd)*.6;
  float flare=(.6+.4*sin(atan(d.y-normalize(sun_dir).y,d.x-normalize(sun_dir).x)*9.0+TIME*.2))*exp(-(sd-.085)*7.0)*step(.085,sd);
  color+=corona*(rim*1.3+flare*.35)*black_sun;
  color=mix(color,vec3(.01,.0,.0),(1.0-smoothstep(.081,.087,sd))*black_sun);
 }
 // The map's giant world in the sky: banded, lit from one side, with an
 // atmosphere glow and an optional ring (Nessus, Europa's gas giant, Titan's).
 if(giant_radius>0.0){
  vec3 gd=normalize(giant_dir);
  float gm=sphere(d,gd,giant_radius);
  vec3 right=normalize(cross(vec3(0.0,1.0,0.0),gd));vec3 up=normalize(cross(gd,right));
  vec2 q=vec2(dot(d-gd,right),dot(d-gd,up))/giant_radius;
  float bands=sin(q.y*11.0+sin(q.x*3.0+q.y*7.0)*1.3)*.5+.5;
  vec3 surface=mix(giant_tint,giant_band,bands*giant_bands+(1.0-giant_bands)*.0);
  vec3 normal=vec3(q,sqrt(max(0.0,1.0-dot(q,q))));
  float light=clamp(dot(normal,normalize(vec3(-.7,.35,.6)))*.9+.18,0.0,1.0);
  vec3 grain=texture(paint,q*.45+.5).rgb;
  vec3 body=surface*light*mix(vec3(1.0),grain*1.35,.16);
  float glow=exp(-max(0.0,distance(d,gd)-giant_radius)*55.0)*(1.0-gm);
  color+=giant_glow*glow*.55;
  vec3 axis=normalize(vec3(.18,.95,.25));
  float ringd=abs(dot(d-gd,axis));float span=distance(d,gd)/giant_radius;
  float ring=giant_ring*(1.0-smoothstep(.003,.009,ringd))*smoothstep(1.25,1.35,span)*(1.0-smoothstep(2.1,2.25,span));
  float behind=step(0.0,dot(d-gd,cross(axis,right)));
  color=mix(color,giant_band*1.05,ring*.8*(1.0-gm*behind));
  color=mix(color,body,gm);
  color=mix(color,giant_band*1.05,ring*.8*gm*(1.0-behind));
 }
 if(small_radius>0.0){
  float sm=sphere(d,small_dir,small_radius);
  color=mix(color,planet(d,small_dir,small_radius,small_tint),sm);
  color+=small_tint*exp(-max(0.0,distance(d,normalize(small_dir))-small_radius)*90.0)*(1.0-sm)*.35;
 }
 COLOR=color;
}
