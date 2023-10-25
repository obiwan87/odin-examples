package main

import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "vendor:raylib"
import "core:os"
import "core:fmt"
import "core:strconv"

points : []Point2D
colors:  []raylib.Color
main :: proc() {
    n : int
    if len(os.args) <= 1 {
        n = 20
    } else {
        ok : bool
        n, ok = strconv.parse_int(os.args[1])
        if !ok {
            fmt.printf("Invalid argument: '%s' is not an integer\n", os.args[1])
            fmt.printf("Usage: %s [n]\n", os.args[0])
            return
        }
    }

    points = make([]Point2D, n)
    defer delete(points)
    create_random_points(n);
    create_random_colors(n)

    for point in points {
        fmt.println(point)
    }

    init_window()
}


SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450
CIRCLE_RADIUS :: 10
// Window management
init_window :: proc() {
    using raylib
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Convex Hull")
    SetTargetFPS(60)

    for !WindowShouldClose() {
        draw_frame()
    }
}


// Generation of random points

Point2D :: struct {
    x : f32,
    y : f32,
}


create_random_points :: proc(n  : int = 10) {
    for i in 0..<n {
        x := rand.float32_uniform(0+CIRCLE_RADIUS, SCREEN_WIDTH -CIRCLE_RADIUS)
        y := rand.float32_uniform(0+CIRCLE_RADIUS, SCREEN_HEIGHT - CIRCLE_RADIUS)
        p := create_point(x, y)
        points[i] = p
    }
}

create_colors :: proc(start: raylib.Color, end: raylib.Color, n : int) {
    using raylib
    colors = make([]Color, n)
    for i in 0..<n {
        f := f32(i) / f32(n)
        colors[i] = Color {

        r = start.r + u8(f32(end.r) - f32(start.r) * f),
        g = start.g + u8(f32(end.g) - f32(start.g) * f),
        b = start.b + u8(f32(end.b) - f32(start.b) * f),
        a = 255,
        }
    }
}

create_random_colors :: proc(n : int) {
    using raylib
    colors = make([]Color, n)

    for i in 0..<n {
        colors[i] = Color {
        r = cast(u8)rand.float32_uniform(0, 255),
        g = cast(u8)rand.float32_uniform(0, 255),
        b = cast(u8)rand.float32_uniform(0, 255),
        a = 255,
        }
    }
}

create_point :: proc(x : f32, y : f32) -> Point2D {
    return Point2D { x, y }
}

euclidean_distance :: proc(a : Point2D, b : Point2D) -> f32 {
    delta_x := a.x - b.x
    delta_y := a.y - b.y
    return delta_x * delta_x + delta_y * delta_y
}

manhattan_distance :: proc(a : Point2D, b : Point2D) -> f32 {
    delta_x := math.abs(a.x - b.x)
    delta_y := math.abs(a.y - b.y)
    return delta_x + delta_y
}


draw_frame :: proc () {
    using raylib
    BeginDrawing()
    ClearBackground(BLACK)

    for y in 0..<SCREEN_HEIGHT {
        for x in 0..<SCREEN_WIDTH {
            current_point := create_point(f32(x), f32(y))
            // Find the closest point
            closest_point := points[0]
            closest_distance := manhattan_distance(closest_point,current_point)
            closest_index := 0
            for point, color_index in points[1:] {
                distance := manhattan_distance(point, current_point)
                if distance < closest_distance {
                    closest_distance = distance
                    closest_point = point
                    closest_index = color_index
                }
            }
            DrawCircle(cast(i32)x, cast(i32)y, 1, colors[closest_index])
        }
    }

    for point in points {
        DrawCircle(cast(i32)point.x, cast(i32)point.y, 5, WHITE)
    }

    EndDrawing()
}

