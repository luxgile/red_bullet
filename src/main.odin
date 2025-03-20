package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import "core:strings"
import time "core:time"
import rl "vendor:raylib"

camera := rl.Camera2D{}
player := Player{}
enemies := [dynamic]Enemy{}

score := 0

main :: proc() {
	rl.InitWindow(1600, 900, "red bullet")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	camera = rl.Camera2D {
		offset = {f32(rl.GetScreenWidth()) / 2.0, f32(rl.GetScreenHeight()) / 2.0},
		zoom   = 1.0,
	}

	player = Player {
		size = 15.0,
	}

	enemy := Enemy {
		target   = &player,
		position = {500.0, 250.0},
		size     = 10.0,
	}
	append(&enemies, enemy)

	enemy2 := Enemy {
		target   = &player,
		position = {-500.0, 250.0},
		size     = 10.0,
	}
	append(&enemies, enemy2)

	vfx := VfxCpu {
		is_one_shot = true,
		spawn_rate = 1000.0,
		duration = 0.2,
		spawn_mode = SpawnCircle{radius = 1},
		max_lifetime = 0.4,
		max_particles = 100,
		size_mode = SizeOverLifetime{3.0, 0.0},
		color_mode = ColorOverLifetime{rl.RED, {0, 0, 0, 0}},
		spawn_velocity_mode = ExplosionSpawnVelocity{{100, 200}},
		gravity = {0, 10},
	}
	vfx_play(&vfx)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		player_input(&player)
		player_process(&player, dt)

		vfx.position = player.position
		vfx_process(&vfx, dt)

		if rl.IsKeyPressed(.SPACE) {
			vfx_play(&vfx)
		}

		for &enemy, index in enemies {
			if enemy.is_dead {
				unordered_remove(&enemies, index)
				continue
			}

			enemy_process(&enemy, dt)
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(camera)

		player_draw(&player)
		vfx_draw(&vfx)
		for &enemy in enemies {
			enemy_draw(&enemy)
		}

		rl.EndMode2D()

		rl.DrawFPS(10, 10)
		rl.DrawText(
			strings.clone_to_cstring(fmt.tprintf("Score: %v", score)),
			100,
			10,
			20,
			rl.WHITE,
		)
		if rl.GuiButton({f32(rl.GetScreenWidth()) - 90, 10, 80, 30}, "Exit") {
			break
		}
	}
}
