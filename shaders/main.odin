package main

import "core:fmt"
import "core:math"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "../commons/"

import "core:math/rand"

SCREEN_TITLE :: "GLFW"
SCREEN_WIDTH :: 512
SCREEN_HEIGHT :: 512

// Set the viewport of OpenGL such that it covers the entire window.
gl_reset_viewport :: proc "c" (window: glfw.WindowHandle) {
    w, h := glfw.GetFramebufferSize(window)
    gl.Viewport(0, 0, w, h)
}

cb_frame_buffer_size :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
// Reset the viewport if the window's size is changed.
    gl_reset_viewport(window)
}

cb_key :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
// Exit program on escape pressed
    if key == glfw.KEY_ESCAPE do glfw.SetWindowShouldClose(window, true)
}

main :: proc() {

// Initialize GLFW.
    if glfw.Init() != 1 {
        fmt.println("Failed to initialize GLFW.")
        return
    }
    defer glfw.Terminate()

    n := 50

    points := make([]commons.Point2D, n)
    commons.create_random_points(n, 0, 0, 1., 1., &points)

    points_arr := make([]f32, 3 * n)
    for i := 0; i < n; i += 3 {
        points_arr[3 * i] = points[i].x
        points_arr[3 * i + 1] = points[i].y
        points_arr[3 * i + 2] = 0.
    }

    // Configure window settings.
    commons.glfw_window_hints()

    // Create a render window.
    window := glfw.CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_TITLE, nil, nil)
    if window == nil {
        fmt.println("Failed to create window.")
        return
    }
    defer glfw.DestroyWindow(window)

    // Use window in current context.
    glfw.MakeContextCurrent(window)
    // Enable vsync.
    glfw.SwapInterval(1)
    // Set callbacks.
    glfw.SetKeyCallback(window, cb_key)
    glfw.SetFramebufferSizeCallback(window, cb_frame_buffer_size)

    // Load OpenGL.
    commons.gl_load()

    // Compile and link the shader program.
    shader_program, is_program_ok := commons.gl_load_source(
    string(#load("shaders.vert.glsl")),
    string(#load("shaders.frag.glsl")));
    if !is_program_ok do return

    // A vertex array object (VAO) can be bound and any subsequent vertex attribute calls will be
    // stored inside the VAO. This means we only have to setup the VAO once, and whenever we want to
    // draw the object, we can just bind the corresponding VAO.
    vao: u32
    gl.GenVertexArrays(1, &vao)
    // Create one vertex buffer object (VBO). Any buffer calls we make (on the GL_ARRAY_BUFFER target)
    // will be used to configure the currently bound buffer, which is VBO.
    vbo: u32
    gl.GenBuffers(1, &vbo)
    // An element buffer object (EBO) stores vertex indices that OpenGL uses to draw.
    ebo: u32
    gl.GenBuffers(1, &ebo)

    // Bind the vertex array object so our attributed pointers configuration are store in our VAO.
    gl.BindVertexArray(vao)

    // Coordinates for the 4 vertices that compose the 2 triangles that make up a quad.
    // OpenGL use normalized coordinates that range between [-1, 1].
    vertices := [12]f32 {
    // 1st vertex
    1.0, 1.0, 0.0,
    // 2nd vertex
    1.0, -1.0, 0.0,
    // 3rd vertex
    -1., -1., 0.0,
    // 4th vertex
    -1., 1., 0.0,
    };
    // Copy the coordinates above into the array buffer.
    // + GL_STREAM_DRAW: the data is set only once and used by the GPU at most a few times.
    // + GL_STATIC_DRAW: the data is set only once and used many times.
    // + GL_DYNAMIC_DRAW: the data is changed a lot and used many times.
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(
    gl.ARRAY_BUFFER,
    size_of(vertices),
    &vertices,
    gl.STATIC_DRAW)

    // A list of vertex indices that are used to make the triangles.
    indices := [6]u32 {
    // First triangle
    0, 1, 3,
    // Second triangle
    1, 2, 3,
    }
    // Copy the indices into the buffer.
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(
    gl.ELEMENT_ARRAY_BUFFER,
    size_of(indices),
    &indices,
    gl.STATIC_DRAW)

    // Tell OpenGL how the vertex data should be interpreted.
    // We're using a 9-element array of i32s to represent 3 vertices.
    gl.VertexAttribPointer(
    0, // input start at index 0.
    3, // each vertex contains 3 elements.
    gl.FLOAT, // vertex coordinates are given as floats.
    gl.FALSE, // whether we need to normalize the coordinates.
    3 * size_of(f32), // stride of 12 bytes (3 * 32bit = 3 * 4bytes).
    0) // offset into VBO.
    // Enable the vertex attribute at the given VBO offset.
    gl.EnableVertexAttribArray(0)

    // Unbind VAO.
    gl.BindVertexArray(0)
    // Unbind EBO.
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
    // Unbind VBO.
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)

    for !glfw.WindowShouldClose(window) {
    // Check for user's inputs
        glfw.PollEvents()

        // Changing green color according to the sin function.
        time_value := glfw.GetTime()
        green_intensity := f32((math.sin(time_value) / 2.0) + 0.5)
        // Find the location of the uniform using its name.
        vertex_color_location := gl.GetUniformLocation(shader_program, "ourColor")
        points_location := gl.GetUniformLocation(shader_program, "points")
        resolution_location := gl.GetUniformLocation(shader_program, "resolution")
        time_value_location := gl.GetUniformLocation(shader_program, "time_value")
        width, height := glfw.GetWindowSize(window)

        // Clear screen with color. Pink: 0.9, 0.2, 0.8.
        gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        for i := 0; i < n; i += 3 {
            direction := f32(i % 2 == 0? 1 : -1);
            points_arr[3 * i] = points[i].x + math.sin(f32(time_value)) * 0.1 *direction;
            points_arr[3 * i + 1] = points[i].y + math.cos(f32(time_value)) * 0.1*direction;
            points_arr[3 * i + 2] = 0.
        }

        // Bind data.
        gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
        gl.BindVertexArray(vao)

        // Draw triangles.
        gl.UseProgram(shader_program)
        // Set the uniform value. This must be done after calling `gl.UseProgram`.
        gl.Uniform4f(vertex_color_location, 0.0, green_intensity, 0.0, 1.0)
        gl.Uniform3fv(points_location, i32(n), &points_arr[0])
        gl.Uniform2f(resolution_location, f32(width), f32(height))
        gl.Uniform1d(time_value_location, time_value)

        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, rawptr(uintptr(0)))

        // Unbind data.
        gl.BindVertexArray(0)
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
        gl.BindBuffer(gl.ARRAY_BUFFER, 0)

        // OpenGL has 2 buffer where only 1 is active at any given time. When rendering,
        // we first modify the back buffer then swap it with the front buffer, where the
        // front buffer is the active one.
        glfw.SwapBuffers(window)
    }
}
