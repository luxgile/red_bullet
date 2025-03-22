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

enemy_spawn :: proc(game: ^Game, pos: rl.Vector2) {
  append(&game.enemies, Enemy {
    position = pos,
    size = 10.0
  })
}

enemy_process :: proc(using game: ^Game, enemy: ^Enemy, dt: f32) {
  if player == nil do return 
  player_distance := linalg.distance(player.position, enemy.position)
  if player_distance < enemy.size * 2.0 do load_level(game, &MainMenuLevel)

  direction := linalg.normalize(player.position - enemy.position)
  enemy.position += direction * ENEMY_SPEED * dt
}

enemy_draw :: proc(enemy: ^Enemy) {
	rl.DrawCircleV(enemy.position, enemy.size, rl.RED)
}
