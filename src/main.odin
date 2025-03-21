package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import "core:strings"
import time "core:time"
import rl "vendor:raylib"

Game :: struct {
	camera:        rl.Camera2D,
	current_level: ^Level,
	score:         int,
	player:        ^Player,
}

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(1600, 900, "red bullet")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	game := Game {
		camera = rl.Camera2D{zoom = 2.0},
	}

	load_level(&game, &GameplayLevel)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		game.current_level.on_process(&game, dt)

		rl.BeginDrawing()
		game.current_level.on_draw(&game)
		rl.DrawFPS(10, 10)
		rl.DrawText(
			strings.clone_to_cstring(fmt.tprint("Level: ", game.current_level.name)),
			(rl.GetScreenWidth() / 2) - 75,
			10,
			22,
			rl.WHITE,
		)
		rl.EndDrawing()
	}

	game.current_level.on_unload(&game)
}

load_level :: proc(using game: ^Game, level: ^Level) {
	if current_level != nil do current_level.on_unload(game)
	current_level = level
	current_level.on_load(game)
}
