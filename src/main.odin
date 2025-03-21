package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import "core:strings"
import time "core:time"
import rl "vendor:raylib"

CAMERA_POS_SMOOTHNESS :: 0.92

camera := rl.Camera2D{}

score := 0

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(1600, 900, "red bullet")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	bg_texture := rl.LoadTexture("assets/floor.png")
	defer rl.UnloadTexture(bg_texture)

	camera = rl.Camera2D {
		zoom   = 2.0,
	}

	player_spawn()
	defer free(g_player)

	enemy_spawn({400.0, 250.0})
	enemy_spawn({-400.0, 450.0})

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

		player_input(g_player)
		player_process(g_player, dt)

    camera.offset = {f32(rl.GetScreenWidth()) / 2.0, f32(rl.GetScreenHeight()) / 2.0}
		camera.target = linalg.lerp(g_player.position, camera.target, CAMERA_POS_SMOOTHNESS)

		vfx.position = g_player.position
		vfx_process(&vfx, dt)

		if rl.IsKeyPressed(.SPACE) {
			vfx_play(&vfx)
		}

		for &enemy, index in g_enemies {
			if enemy.is_dead {
				unordered_remove(&g_enemies, index)
				continue
			}

			enemy_process(&enemy, dt)
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(camera)

		draw_floor(&bg_texture)

		player_draw(g_player)
		vfx_draw(&vfx)
		for &enemy in g_enemies {
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

draw_floor :: proc(texture: ^rl.Texture2D) {
	width := f32(rl.GetScreenWidth()) / 2.0
	height := f32(rl.GetScreenHeight()) / 2.0
	x := width / 2.0
	y := height / 2.0
	u := camera.target.x
	w := camera.target.y
	// Using tricks with the UVs, we get an infinite scrolling bg texture
	rl.DrawTexturePro(texture^, {u, w, width, height}, {u, w, width, height}, {x, y}, 0, rl.WHITE)
}
