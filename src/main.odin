package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import "core:strings"
import time "core:time"
import rl "vendor:raylib"

CAMERA_POS_SMOOTHNESS :: 0.92

g_camera := rl.Camera2D{}
g_current_level: ^Level

score := 0

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(1600, 900, "red bullet")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	g_camera = rl.Camera2D {
		zoom = 2.0,
	}

	load_level(&MainMenuLevel)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		g_current_level.on_process(dt)

		rl.BeginDrawing()
		g_current_level.on_draw()
		rl.DrawFPS(10, 10)
		rl.DrawText(
			strings.clone_to_cstring(fmt.tprint("Level: ", g_current_level.name)),
			(rl.GetScreenWidth() / 2) - 75,
			10,
			22,
			rl.WHITE,
		)
		rl.EndDrawing()
	}

	g_current_level.on_unload()
}

load_level :: proc(level: ^Level) {
	if g_current_level != nil do g_current_level.on_unload()
	g_current_level = level
	g_current_level.on_load()
}
