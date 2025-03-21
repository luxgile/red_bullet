package main

import fmt "core:fmt"
import linalg "core:math/linalg"
import strings "core:strings"
import rl "vendor:raylib"

Level :: struct {
	name:       string,
	on_load:    proc(),
	on_process: proc(dt: f32),
	on_draw:    proc(),
	on_unload:  proc(),
}

MainMenuLevel := Level {
	name = "Main Menu",
	on_load = proc() {},
	on_process = proc(dt: f32) {},
	on_draw = main_menu_draw,
	on_unload = proc() {},
}
main_menu_draw :: proc() {
	rl.ClearBackground(rl.BLACK)

	width: f32 = 200.0
	height: f32 = 130.0
	position := rl.Vector2 {
		f32(rl.GetScreenWidth() / 2.0) - width / 2.0,
		f32(rl.GetScreenHeight() / 2.0) - height / 2.0,
	}
	rl.GuiGroupBox({position.x, position.y, width, height}, nil)
  if rl.GuiButton({position.x + 10, position.y + 10, width - 20, 50}, "Play") do load_level(&GameplayLevel)
  if rl.GuiButton({position.x + 10, position.y + 70, width - 20, 50}, "Exit") do rl.CloseWindow()
}

bg_texture: rl.Texture2D
GameplayLevel := Level {
	name = "Gameplay",
	on_load = proc() {
		fmt.println("### Loaded Gameplay")
		bg_texture = rl.LoadTexture("assets/floor.png")

		player_spawn()

		enemy_spawn({400.0, 250.0})
		enemy_spawn({-400.0, 450.0})
	},
	on_process = proc(dt: f32) {
		player_input(g_player)
		player_process(g_player, dt)

		g_camera.offset = {f32(rl.GetScreenWidth()) / 2.0, f32(rl.GetScreenHeight()) / 2.0}
		g_camera.target = linalg.lerp(g_player.position, g_camera.target, CAMERA_POS_SMOOTHNESS)

		for &enemy, index in g_enemies {
			if enemy.is_dead {
				unordered_remove(&g_enemies, index)
				continue
			}

			enemy_process(&enemy, dt)
		}
	},
	on_draw = proc() {
		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(g_camera)

		draw_floor(&bg_texture)

		player_draw(g_player)

		for &enemy in g_enemies {
			enemy_draw(&enemy)
		}

		rl.EndMode2D()

		rl.DrawText(
			strings.clone_to_cstring(fmt.tprintf("Score: %v", score)),
			100,
			10,
			20,
			rl.WHITE,
		)
	},
	on_unload = proc() {
		rl.UnloadTexture(bg_texture)
		free(g_player)
	},
}

draw_floor :: proc(texture: ^rl.Texture2D) {
	width := f32(rl.GetScreenWidth()) / 2.0
	height := f32(rl.GetScreenHeight()) / 2.0
	x := width / 2.0
	y := height / 2.0
	u := g_camera.target.x
	w := g_camera.target.y
	// Using tricks with the UVs, we get an infinite scrolling bg texture
	rl.DrawTexturePro(texture^, {u, w, width, height}, {u, w, width, height}, {x, y}, 0, rl.WHITE)
}
