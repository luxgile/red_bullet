package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import time "core:time"
import rl "vendor:raylib"

BULLET_SPEED :: 400.0
BULLET_LIFETIME :: 10.0

Bullet :: struct {
	sprite_sheet:   SpriteSheet,
	position:       rl.Vector2,
	speed:          f32,
	direction:      rl.Vector2,
	size:           f32,
	lifetime_timer: time.Stopwatch,
	is_dead:        bool,
}

bullet_spawn :: proc(game: ^Game, position, direction: rl.Vector2) -> ^Bullet {
	sprite_sheet := sprite_sheet_new(rl.LoadTexture("assets/bullet.png"), 4, {32, 32})
	sprite_sheet_set_animation(&sprite_sheet, "idle", {16, 0, 4})
	sprite_sheet_play(&sprite_sheet, "idle")
	bullet := Bullet {
		sprite_sheet = sprite_sheet,
		position     = position,
		direction    = direction,
		speed        = BULLET_SPEED,
		size         = 4.0,
	}
	append(&game.bullets, bullet)
	return &game.bullets[len(&game.bullets) - 1]
}

bullet_process :: proc(game: ^Game, bullet: ^Bullet, dt: f32) {
	if time.duration_seconds(time.stopwatch_duration(bullet.lifetime_timer)) > BULLET_LIFETIME {
		bullet.is_dead = true
		return
	}

	bullet.position += bullet.speed * dt * bullet.direction

	for &enemy in game.enemies {
		if bullet_check_collision(bullet, &enemy) {
			enemy.is_dead = true
			bullet.is_dead = true
			game.score += 1
		}
	}

  sprite_sheet_process(&bullet.sprite_sheet, dt)
}

bullet_check_collision :: proc(bullet: ^Bullet, enemy: ^Enemy) -> bool {
	return rl.CheckCollisionCircles(bullet.position, bullet.size, enemy.position, enemy.size)
}

bullet_draw :: proc(bullet: ^Bullet) {
	sprite_sheet_draw(&bullet.sprite_sheet, bullet.position, scale = {1.5, 1.5})
}
