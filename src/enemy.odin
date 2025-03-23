package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import time "core:time"
import rl "vendor:raylib"

ENEMY_SPEED :: 100.0

Enemy :: struct {
	position:  rl.Vector2,
	size:      f32,
	death_vfx: VfxCpu,
	is_dead:   bool,
}

enemy_spawn :: proc(game: ^Game, pos: rl.Vector2) {
	death_vfx := VfxCpu {
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
	append(&game.enemies, Enemy{position = pos, size = 10.0, death_vfx = death_vfx})
}

enemy_process :: proc(using game: ^Game, enemy: ^Enemy, dt: f32) {
	if player == nil do return
	player_distance := linalg.distance(player.position, enemy.position)
	if player.movement_state != .Dashing && player_distance < enemy.size * 2.0 {
		load_level(game, &MainMenuLevel)
		return
	}

	direction := linalg.normalize(player.position - enemy.position)
	enemy.position += direction * ENEMY_SPEED * dt
}

enemy_draw :: proc(enemy: ^Enemy) {
	rl.DrawCircleV(enemy.position, enemy.size, rl.RED)
}
