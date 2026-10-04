#include <flutter/runtime_effect.glsl>
precision mediump float;
uniform vec2 uSize;
uniform float uTime;
uniform float uBlend;
uniform float uFlow;
uniform sampler2D uBase;
uniform sampler2D uFirst;
uniform sampler2D uSecond;
out vec4 fragColor;

// Flutter image samples already have premultiplied alpha.
float flame(vec4 p) {
  vec4 c = vec4(p.rgb / max(p.a, .001), p.a);
  return smoothstep(.13,.43,c.b-c.r)*smoothstep(.20,.58,c.g)
    *smoothstep(.25,.65,max(c.g,c.b))*smoothstep(.015,.15,c.a);
}
void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 anchor = texture(uBase,uv);
  bool outerRim=uv.x>.069&&uv.x<.936&&uv.y>.105&&uv.y<.898;
  bool innerHole=uv.x>.170&&uv.x<.831&&uv.y>.157&&uv.y<.823;
  if (outerRim && !innerHole) { fragColor=anchor; return; }
  vec4 a=texture(uFirst,uv), b=texture(uSecond,uv);
  float mask=max(flame(anchor),max(flame(a),flame(b)));
  float edge=1.-smoothstep(.14,.23,min(min(uv.x,1.-uv.x),min(uv.y,1.-uv.y)));
  vec2 wave=vec2(sin(uv.y*48.+uTime*5.3+uv.x*13.)+.45*sin(uv.y*91.+uTime*8.1),sin(uv.x*31.+uv.y*19.+uTime*4.1));
  vec2 sampleUv=clamp(uv+wave*vec2(.010,.0048)*mask*edge*uFlow,vec2(0.),vec2(1.));
  vec4 animated=mix(texture(uFirst,sampleUv),texture(uSecond,sampleUv),uBlend);
  fragColor=mix(anchor,animated,smoothstep(.10,.65,mask));
}
