#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D CC_Texture0;
uniform float u_threshold;

void main()
{
    vec4 c = texture2D(CC_Texture0, v_texCoord);
    float threshold = u_threshold;
    
    if (c.r >= threshold) {
        gl_FragColor = v_fragmentColor * ((c - vec4(threshold)) / (1.0 - threshold));
    } else {
        discard;
    }
}
