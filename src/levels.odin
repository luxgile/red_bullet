package main

import fmt "core:fmt"
import linalg "core:math/linalg"
import rand "core:math/rand"
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
	when ODIN_OS != .JS {
		if rl.GuiButton({position.x + 10, position.y + 70, width - 20, 50}, "Exit") do game.should_exit = true
	}
}

bg_texture: rl.Texture2D
GameplayLevel := Level {
	name = "Gameplay",
	on_load = proc(game: ^Game) {
		fmt.println("### Loaded Gameplay")
		bg_texture = rl.LoadTexture("assets/floor.png")

		if !player_spawn(game) do fmt.println("!!!Issue spawning player")
	},
	on_process = gameplay_process,
	on_draw = proc(game: ^Game) {
		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(game.camera)

		draw_floor(&game.camera, &bg_texture)

		player_draw(game.player)

		for &pickup in game.pickups {
			wpickup_draw(pickup)
		}

		for &bullet in game.bullets {
			bullet_draw(&bullet)
		}

		for &enemy in game.enemies {
			enemy_draw(&enemy)
		}

		for vfx in game.vfxs {
			vfx_draw(vfx)
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
		game.wave_count = 0
		game.wave_timer = 0
		game.score = 0
		clear(&game.enemies)
		clear(&game.bullets)
		for pickup in game.pickups {
			free(pickup)
		}
		clear(&game.pickups)
		rl.UnloadTexture(bg_texture)
		// free(game.player)
		game.player = nil
	},
}

TIME_TO_SPAWN_WAVE :: 10
WAVE_START :: 10
WAVE_PROGRESSION :: 5

gameplay_process :: proc(game: ^Game, dt: f32) {
	player_input(game, game.player)
	player_process(game, game.player, dt)

	game.camera.offset = {f32(rl.GetScreenWidth()) / 2.0, f32(rl.GetScreenHeight()) / 2.0}
	game.camera.target = linalg.lerp(
		game.player.position,
		game.camera.target,
		CAMERA_POS_SMOOTHNESS,
	)

	game.wave_timer += dt
	if game.wave_timer > TIME_TO_SPAWN_WAVE || len(game.enemies) == 0 {
		game.wave_count += 1
		game.wave_timer = 0
		enemy_count := WAVE_START + WAVE_PROGRESSION * game.wave_count
		for i in 0 ..< enemy_count {
			range: f32 = f32(rl.GetScreenWidth()) / 2.0
			dir := linalg.normalize(
				rl.Vector2{rand.float32_range(-1, 1), rand.float32_range(-1, 1)},
			)
			spawn_pos := game.player.position + dir * range
			enemy_spawn(game, spawn_pos)
		}
	}

	// Only interact with pickups if the player does not have a weapon
	if game.player.weapon == nil {
		for &pickup, index in game.pickups {
			if wpickup_check_collision(pickup, game.player) {
				game.player.weapon = pickup.weapon
				free(pickup)
				unordered_remove(&game.pickups, index)
			}
		}
	}

	for &bullet, index in game.bullets {
		bullet_process(game, &bullet, dt)

		if bullet.is_dead {
			unordered_remove(&game.bullets, index)
		}
	}

	for &enemy, index in game.enemies {
		if enemy.is_dead {
			should_spawn_pickup := len(game.pickups) == 0 || rand.float32() < 0.2
			if should_spawn_pickup do wpickup_new(game, WeaponGunPickup, enemy.position)

			death_vfx := new_clone(enemy.death_vfx)
			death_vfx.position = enemy.position
			vfx_play(death_vfx)
			append(&game.vfxs, death_vfx)

			unordered_remove(&game.enemies, index)
			continue
		}

		enemy_process(game, &enemy, dt)
	}

	for vfx, index in game.vfxs {
		vfx_process(vfx, dt)
		if !vfx.is_running {
			free(vfx)
			unordered_remove(&game.vfxs, index)
		}
	}
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
