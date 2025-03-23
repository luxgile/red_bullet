package main

import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import "core:strings"
import time "core:time"
import rl "vendor:raylib"

DRAW_COLLISIONS :: false

EventQueue :: [dynamic]rawptr

EventTable :: struct {
	table: map[typeid]EventQueue,
}

event_table := EventTable{}

listen :: proc($T: typeid, procedure: proc(event: T)) {
	queue := event_table.table[T]
	append(&queue, rawptr(procedure))
	event_table.table[T] = queue
}

raise :: proc(event: $T) {
	queue := event_table.table[T]
	for listener in queue {
		procedure := cast(proc(event: T))listener
		procedure(event)
	}
}

TestEventWithData :: struct {
	msg: string,
}

on_event_with_data :: proc(event: TestEventWithData) {
	fmt.println(event.msg)
}

CachedTexture :: struct {
	texture: rl.Texture2D,
	path:    cstring,
}
ctexture_get :: proc(texture: ^CachedTexture) -> rl.Texture2D {
	if !rl.IsTextureValid(texture.texture) do texture.texture = rl.LoadTexture(texture.path)
	return texture.texture
}

Game :: struct {
	camera:        rl.Camera2D,
	current_level: ^Level,
	score:         int,
	player:        ^Player,
	bullets:       [dynamic]Bullet,
	enemies:       [dynamic]Enemy,
	pickups:       [dynamic]^WeaponPickup,
	vfxs:          [dynamic]^VfxCpu,
	wave_timer:    f32,
	wave_count:    f32,
}

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(1600, 900, "red bullet")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	game := Game {
		camera = rl.Camera2D{zoom = 2.0},
	}

	// listen(TestEventWithData, on_event_with_data)
	// listen(TestEventWithData, proc(event: TestEventWithData) {fmt.println("Anonymous event!")})
	// raise(TestEventWithData{msg = "Hello World from Event!"})

	load_level(&game, &MainMenuLevel)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		game.current_level.on_process(&game, dt)

		rl.BeginDrawing()
		game.current_level.on_draw(&game)
		rl.DrawFPS(10, 10)
		rl.DrawText(
			strings.clone_to_cstring(fmt.tprint("Level: ", game.current_level.name)),
			(rl.GetScreenWidth() / 2) - 75,
			10,
			22,
			rl.WHITE,
		)
		rl.EndDrawing()
	}

	game.current_level.on_unload(&game)
}

load_level :: proc(using game: ^Game, level: ^Level) {
	if current_level != nil do current_level.on_unload(game)
	current_level = level
	current_level.on_load(game)
}

