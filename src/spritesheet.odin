package main

import rl "vendor:raylib"

SpriteSheetAnimation :: struct {
	fps:   f32,
	start: uint,
	end:   uint,
}

SpriteSheet :: struct {
	texture:    rl.Texture2D,
	cell_size:  rl.Vector2,
	columns:    uint,
	animations: map[cstring]SpriteSheetAnimation,
	_current:   ^SpriteSheetAnimation,
	_timer:     f32,
	_frame:     uint,
}

sprite_sheet_new :: proc(
	texture: rl.Texture2D,
	columns: uint,
	cell_size: rl.Vector2,
) -> SpriteSheet {
	return SpriteSheet{texture = texture, columns = columns, cell_size = cell_size}
}

sprite_sheet_set_animation :: proc(
	using sprite_sheet: ^SpriteSheet,
	name: cstring,
	animation: SpriteSheetAnimation,
) {
	animations[name] = animation
}

sprite_sheet_play :: proc(using sprite_sheet: ^SpriteSheet, name: cstring) {
	_current = &animations[name]
	_timer = 0
	_frame = _current.start
}

sprite_sheet_process :: proc(using sprite_sheet: ^SpriteSheet, dt: f32) {
	if _current == nil do return

	_timer += dt
  time_per_frame := 1 / _current.fps
	for _current.fps > 0 && _timer >= time_per_frame {
		_timer -= time_per_frame
		_frame += 1
		if _frame >= _current.end {
			_frame = _current.start
		}
	}
}

sprite_sheet_draw :: proc(
	using sprite_sheet: ^SpriteSheet,
	position: rl.Vector2,
	rotation: f32 = 0,
	scale: rl.Vector2 = {1.0, 1.0},
  invert_x := false,
  invert_y := false,
) {
	x, y: f32 = f32(_frame % columns) * cell_size.x, f32(_frame / columns) * cell_size.y
  size_x := invert_x ? -cell_size.x : cell_size.x
  size_y := invert_y ? -cell_size.y : cell_size.y
	rl.DrawTexturePro(
		texture,
		{x, y, size_x, size_y},
		{position.x, position.y, cell_size.x * scale.x, cell_size.y * scale.y},
		{cell_size.x * scale.x / 2, cell_size.y * scale.y / 2},
		rotation,
		rl.WHITE,
	)
}
