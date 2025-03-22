package main

import fmt "core:fmt"
import linalg "core:math/linalg"
import strings "core:strings"
import rl "vendor:raylib"

CAMERA_POS_SMOOTHNESS :: 0.92

Level :: struct {
	name:       string,
	on_load:    proc(game: ^Game),
	on_process: proc(game: ^Game, dt: f32),
	on_draw:    proc(game: ^Game),
	on_unload:  proc(game: ^Game),
}

MainMenuLevel := Level {
	name = "Main Menu",
	on_load = proc(game: ^Game) {},
	on_process = proc(game: ^Game, dt: f32) {},
	on_draw = main_menu_draw,
	on_unload = proc(game: ^Game) {},
}
main_menu_draw :: proc(game: ^Game) {
	rl.ClearBackground(rl.BLACK)

	width: f32 = 200.0
	height: f32 = 130.0
	position := rl.Vector2 {
		f32(rl.GetScreenWidth() / 2.0) - width / 2.0,
		f32(rl.GetScreenHeight() / 2.0) - height / 2.0,
	}
	rl.GuiGroupBox({position.x, position.y, width, height}, nil)
	if rl.GuiButton({position.x + 10, position.y + 10, width - 20, 50}, "Play") do load_level(game, &GameplayLevel)
	if rl.GuiButton({position.x + 10, position.y + 70, width - 20, 50}, "Exit") do rl.CloseWindow()
}

bg_texture: rl.Texture2D
GameplayLevel := Level {
	name = "Gameplay",
	on_load = proc(game: ^Game) {
		fmt.println("### Loaded Gameplay")
		bg_texture = rl.LoadTexture("assets/floor.png")

		player_spawn(game)

		// enemy_spawn(game, {400.0, 250.0})
		// enemy_spawn(game, {-400.0, 450.0})
	},
	on_process = proc(game: ^Game, dt: f32) {
		player_input(game, game.player)
		player_process(game, game.player, dt)

		game.camera.offset = {f32(rl.GetScreenWidth()) / 2.0, f32(rl.GetScreenHeight()) / 2.0}
		game.camera.target = linalg.lerp(
			game.player.position,
			game.camera.target,
			CAMERA_POS_SMOOTHNESS,
		)

		for &bullet, index in game.bullets {
			bullet_process(game, &bullet, dt)

			if bullet.is_dead {
				unordered_remove(&game.bullets, index)
			}
		}

		for &enemy, index in game.enemies {
			if enemy.is_dead {
				unordered_remove(&game.enemies, index)
				continue
			}

			enemy_process(game, &enemy, dt)
		}
	},
	on_draw = proc(game: ^Game) {
		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(game.camera)

		draw_floor(&game.camera, &bg_texture)

		player_draw(game.player)

		for &bullet in game.bullets {
			bullet_draw(&bullet)
		}

		for &enemy in game.enemies {
			enemy_draw(&enemy)
		}

		rl.EndMode2D()

		rl.DrawText(
			strings.clone_to_cstring(fmt.tprintf("Score: %v", game.score)),
			100,
			10,
			20,
			rl.WHITE,
		)
	},
	on_unload = proc(game: ^Game) {
		rl.UnloadTexture(bg_texture)
		free(game.player)
	},
}

draw_floor :: proc(camera: ^rl.Camera2D, texture: ^rl.Texture2D) {
	width := f32(rl.GetScreenWidth()) / 2.0
	height := f32(rl.GetScreenHeight()) / 2.0
	x := width / 2.0
	y := height / 2.0
	u := camera.target.x
	w := camera.target.y
	// Using tricks with the UVs, we get an infinite scrolling bg texture
	rl.DrawTexturePro(texture^, {u, w, width, height}, {u, w, width, height}, {x, y}, 0, rl.WHITE)
}
