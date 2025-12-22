precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);
    gl_FragColor = vec4(pixColor.rgb * 0.2, pixColor.a);
}
