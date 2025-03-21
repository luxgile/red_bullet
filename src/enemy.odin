package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import time "core:time"
import rl "vendor:raylib"

ENEMY_SPEED :: 100.0

Enemy :: struct {
	position: rl.Vector2,
	size:     f32,
  is_dead: bool,
}

g_enemies := [dynamic]Enemy{}

enemy_spawn :: proc(pos: rl.Vector2) {
  append(&g_enemies, Enemy {
    position = pos,
    size = 10.0
  })
}

enemy_process :: proc(enemy: ^Enemy, dt: f32) {
  if g_player == nil do return 
  player_distance := linalg.distance(g_player.position, enemy.position)
  if player_distance < enemy.size * 2.0 do load_level(&MainMenuLevel)

  direction := linalg.normalize(g_player.position - enemy.position)
  enemy.position += direction * ENEMY_SPEED * dt
}

enemy_draw :: proc(enemy: ^Enemy) {
	rl.DrawCircleV(enemy.position, enemy.size, rl.RED)
}
