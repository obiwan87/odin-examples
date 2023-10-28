package main

import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "vendor:raylib"
import "core:os"
import "core:fmt"
import "core:strconv"
import commons "../commons"


points : []commons.Point2D
colors:  []raylib.Color
main :: proc() {
    using commons
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

    points = make([]commons.Point2D, n)
    colors = make([]raylib.Color, n)
    defer delete(points)
    create_random_points(n, CIRCLE_RADIUS, CIRCLE_RADIUS, SCREEN_WIDTH - CIRCLE_RADIUS, SCREEN_HEIGHT - CIRCLE_RADIUS, &points)
    create_random_colors(n, &colors)

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
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Voronoi")
    SetTargetFPS(60)

    for !WindowShouldClose() {
        draw_frame()
    }
}


euclidean_distance :: proc(a : commons.Point2D, b : commons.Point2D) -> f32 {
    delta_x := a.x - b.x
    delta_y := a.y - b.y
    return delta_x * delta_x + delta_y * delta_y
}

manhattan_distance :: proc(a : commons.Point2D, b : commons.Point2D) -> f32 {
    delta_x := math.abs(a.x - b.x)
    delta_y := math.abs(a.y - b.y)
    return delta_x + delta_y
}


draw_frame :: proc () {
    using raylib
    using commons
    BeginDrawing()
    ClearBackground(BLACK)

    for y in 0 ..< SCREEN_HEIGHT {
        for x in 0 ..< SCREEN_WIDTH {
            current_point := create_point(f32(x), f32(y))
            // Find the closest point
            closest_point := points[0]
            closest_distance := manhattan_distance(closest_point, current_point)
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

