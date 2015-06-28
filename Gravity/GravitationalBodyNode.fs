#ifdef GL_ES
precision lowp float;
#endif

varying vec2 v_texCoord;
uniform sampler2D CC_Texture0;

void main()
{
    float d = max(0.0, 0.9 - length(v_texCoord)); // [-1,1]
    float e = d * d;
    
    gl_FragColor = vec4(e);
}
