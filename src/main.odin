package main

// Emscripten template taken from: https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template/tree/main

import "base:runtime"
import "core:c"
import fmt "core:fmt"
import math "core:math"
import "core:math/linalg"
import "core:mem"
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
	should_exit:   bool,
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

@(private = "file")
web_context: runtime.Context

@(private = "file")
game: Game

when ODIN_OS != .JS {
  main :: proc() {
    main_start()
    for main_update() {}
    main_end()
  }
}

@(export)
main_start :: proc "c" () {
	context = runtime.default_context()

	context.allocator = emscripten_allocator()
	runtime.init_global_temporary_allocator(1 * mem.Megabyte)

	context.logger = create_emscripten_logger()

	web_context = context
	game = Game {
		camera = rl.Camera2D{zoom = 2.0},
	}

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1600, 900, "red bullet")
	rl.SetTargetFPS(60)

	load_level(&game, &MainMenuLevel)
}

@(export)
main_update :: proc "c" () -> bool {
	context = web_context

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

  keep_running := !game.should_exit
  when ODIN_OS != .JS { keep_running &= !rl.WindowShouldClose() }

	return keep_running
}

@(export)
main_end :: proc "c" () {
	context = web_context
	game.current_level.on_unload(&game)
	rl.CloseWindow()
}

@(export)
web_window_size_changed :: proc "c" (w: c.int, h: c.int) {
	context = web_context
  rl.SetWindowSize(i32(w), i32(h))
}

load_level :: proc(using game: ^Game, level: ^Level) {
	if current_level != nil do current_level.on_unload(game)
	current_level = level
	current_level.on_load(game)
}
