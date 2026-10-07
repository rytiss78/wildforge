shader_type spatial;
uniform vec4 base_color : source_color = vec4(1.0);
uniform int surface_kind = 0;
varying vec3 local_position;
void vertex(){local_position=VERTEX;}
void fragment(){
    vec3 color=base_color.rgb;
    float grain=sin(local_position.x*83.0+sin(local_position.z*37.0))*sin(local_position.y*97.0);
    if(surface_kind==1){
        // Broad woven threads remain quiet at gameplay distance.
        float weave=sin(UV.x*260.0)*sin(UV.y*260.0);
        float aa=1.0-smoothstep(.002,.025,length(fwidth(UV)));
        color*=.94+.035*grain+.045*weave*aa;
        float edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
        float hem=1.0-smoothstep(.012,.023,edge);
        color=mix(color,color*.55+vec3(.18,.12,.055),hem*.7);
        ROUGHNESS=.88;SPECULAR=.18;
    }else if(surface_kind==2){
        color*=.93+.06*grain;
        ROUGHNESS=.64;SPECULAR=.3;
    }else if(surface_kind==3){
        color*=.97+.025*sin(local_position.y*145.0);
        METALLIC=.42;ROUGHNESS=.36;SPECULAR=.5;
    }else{
        ROUGHNESS=.28;SPECULAR=.4;
    }
    ALBEDO=color;
}
