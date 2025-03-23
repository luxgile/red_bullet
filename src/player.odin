package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import time "core:time"
import rl "vendor:raylib"

PLAYER_ACC :: 1500.0
PLAYER_SPEED_LIMIT :: 200.0
PLAYER_DAMPING :: 0.01

PLAYER_DASH_FORCE :: 2000.0
PLAYER_DASH_SPEED_LIMIT :: 350.0
PLAYER_DASH_TIME :: 0.4

MovementState :: enum {
	Default,
	Dashing,
	Knockback,
}

Player :: struct {
	sprite_sheet:   SpriteSheet,
	input:          rl.Vector2,
	prev_velocity:  rl.Vector2,
	velocity:       rl.Vector2,
	position:       rl.Vector2,
	size:           f32,
	movement_state: MovementState,
	dash_timer:     time.Stopwatch,
	dash_vfx:       VfxCpu,
	weapon:         ^Weapon,
}

player_spawn :: proc(game: ^Game) -> (ok: bool) {
	if game.player != nil do return false

	sprite_sheet := sprite_sheet_new(rl.LoadTexture("assets/player.png"), 8, {32, 32})
	sprite_sheet_set_animation(&sprite_sheet, "idle", {8, 0, 8})
	sprite_sheet_set_animation(&sprite_sheet, "run", {12, 9, 16})
	sprite_sheet_set_animation(&sprite_sheet, "dash", {8, 17, 24})
	sprite_sheet_play(&sprite_sheet, "idle")
	game.player = new(Player)
	game.player^ = Player {
		size = 15.0,
		sprite_sheet = sprite_sheet,
		weapon = &WeaponGun,
		dash_vfx = VfxCpu {
			is_one_shot = true,
			spawn_rate = 1000.0,
			duration = 0.2,
			spawn_mode = SpawnCircle{radius = 1},
			max_lifetime = 0.4,
			max_particles = 20,
			size_mode = SizeOverLifetime{3.0, 0.0},
			color_mode = ColorOverLifetime{rl.WHITE, {0, 0, 0, 0}},
			spawn_velocity_mode = ExplosionSpawnVelocity{{50, 100}},
			gravity = {0, 10},
		},
	}

	return true
}

player_input :: proc(game: ^Game, player: ^Player) {
	input: rl.Vector2
	if rl.IsKeyDown(.W) do input.y = -1
	if rl.IsKeyDown(.S) do input.y = 1
	if rl.IsKeyDown(.A) do input.x = -1
	if rl.IsKeyDown(.D) do input.x = 1
	player.input = input

	if rl.IsKeyPressed(.SPACE) && player.movement_state != .Dashing && linalg.length(input) > 0.1 {
		direction := linalg.normalize(player.input)
		player.velocity += PLAYER_DASH_FORCE * direction
		player.movement_state = .Dashing
		time.stopwatch_reset(&player.dash_timer)
		time.stopwatch_start(&player.dash_timer)
		vfx_play(&player.dash_vfx)
		sprite_sheet_play(&player.sprite_sheet, "dash")
	}

	if rl.IsMouseButtonPressed(.LEFT) && player.weapon != nil {
		player.weapon.on_shoot_start(game, player.weapon)
		player.weapon = nil
	}
}

player_process :: proc(game: ^Game, player: ^Player, dt: f32) {
	player.dash_vfx.position = player.position
	vfx_process(&player.dash_vfx, dt)

	sprite_sheet_process(&player.sprite_sheet, dt)

	// Move weapon
	if player.weapon != nil {
		mouse_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera)
		mouse_dir := linalg.normalize(mouse_pos - player.position)
		player.weapon.position = player.position + mouse_dir * 25.0
		player.weapon.direction = mouse_dir
	}

	// Stop dash
	if player.movement_state == .Dashing && time.duration_seconds(time.stopwatch_duration(player.dash_timer)) > PLAYER_DASH_TIME {
		player.movement_state = .Default
    sprite_sheet_play(&player.sprite_sheet, "run")
	}

	// Movement
	player.prev_velocity = player.velocity
	if linalg.length(player.input) > 0.01 {
		limit: f32 =
			player.movement_state == .Default ? PLAYER_SPEED_LIMIT : PLAYER_DASH_SPEED_LIMIT
		acceleration := linalg.normalize(player.input) * dt * PLAYER_ACC
		player.velocity = linalg.clamp_length(player.velocity + acceleration, limit)
	}

	player.position += player.velocity * dt
	player.velocity *= math.pow(PLAYER_DAMPING, dt)

	ANIMATION_THRESHOLD :: 50.0
	if player.movement_state == .Default {
		if linalg.length(player.velocity) < ANIMATION_THRESHOLD &&
		   linalg.length(player.prev_velocity) > ANIMATION_THRESHOLD {
			sprite_sheet_play(&player.sprite_sheet, "idle")
		}
		if linalg.length(player.velocity) > ANIMATION_THRESHOLD &&
		   linalg.length(player.prev_velocity) < ANIMATION_THRESHOLD {
			sprite_sheet_play(&player.sprite_sheet, "run")
		}
	}
}

player_draw :: proc(player: ^Player) {
	sprite_sheet_draw(&player.sprite_sheet, player.position, 0, invert_x = player.velocity.x < 0)

	if player.weapon != nil {
		player.weapon.on_draw(nil, player.weapon)
	}

	vfx_draw(&player.dash_vfx)
}
