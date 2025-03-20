package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import time "core:time"
import rl "vendor:raylib"

BULLET_LIFETIME :: 10.0

Bullet :: struct {
	position:       rl.Vector2,
	speed:          f32,
	direction:      rl.Vector2,
	size:           f32,
	lifetime_timer: time.Stopwatch,
	is_dead:        bool,
}

bullet_process :: proc(bullet: ^Bullet, dt: f32) {
	if time.duration_seconds(time.stopwatch_duration(bullet.lifetime_timer)) > BULLET_LIFETIME {
		bullet.is_dead = true
		return
	}

	bullet.position += bullet.speed * dt * bullet.direction

	for &enemy in enemies {
		if bullet_check_collision(bullet, &enemy) {
			enemy.is_dead = true
			bullet.is_dead = true
      score += 1
		}
	}
}

bullet_check_collision :: proc(bullet: ^Bullet, enemy: ^Enemy) -> bool {
	return rl.CheckCollisionCircles(bullet.position, bullet.size, enemy.position, enemy.size)
}

bullet_draw :: proc(bullet: ^Bullet) {
	rl.DrawCircleV(bullet.position, bullet.size, rl.WHITE)
}
