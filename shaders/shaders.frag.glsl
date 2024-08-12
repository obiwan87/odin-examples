#version 410 core

// A fragment shader is for calculating the color output of our pixels. For simplicity,
// we keep using the same color.
out vec4 FragColor;

// Uniforms are global values that are shared by all shaders within the same shader program.
uniform vec4 ourColor;
uniform vec3 points[750];
uniform vec2 resolution;
uniform float time_value;
uniform float colors[750];

void main() {
    vec3 uv = vec3(gl_FragCoord.xy/resolution, 0.0);
  // Colors are represent using RGBA format where values are between 0.0 and 1.0.
    // Find closest point in points
    float minDist = 750000.0;
    int minIndex = -1;
    for (int i = 0; i < 750; i++) {
        vec3 point = vec3(points[i].xy, 0);

        float dist = length(point - uv);
        if (dist < minDist) {
            minDist = dist;
            minIndex = i;
        }
    }
    vec3 color = vec3(points[minIndex]);
    color.b = 1 - (abs(color.r - 0.5) + abs(color.g - 0.5));
    FragColor = vec4(color, 1.0);
}
