package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import time "core:time"
import rl "vendor:raylib"

ENEMY_SPEED :: 100.0

Enemy :: struct {
	target:   ^Player,
	position: rl.Vector2,
	size:     f32,
  is_dead: bool,
}

enemy_process :: proc(enemy: ^Enemy, dt: f32) {
  if enemy.target == nil do return 
  if linalg.distance(enemy.target.position, enemy.position) < 0.01 do return

  direction := linalg.normalize(enemy.target.position - enemy.position)
  enemy.position += direction * ENEMY_SPEED * dt
}

enemy_draw :: proc(enemy: ^Enemy) {
	rl.DrawCircleV(enemy.position, enemy.size, rl.RED)
}
