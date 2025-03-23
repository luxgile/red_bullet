package main

import fmt "core:fmt"
import linalg "core:math/linalg"
import rl "vendor:raylib"
import strings "core:strings"

Weapon :: struct {
	name:           string,
	desc:           string,
	position:       rl.Vector2,
	direction:      rl.Vector2,
	icon_path:      string,
	icon:           rl.Texture2D,
	on_shoot_start: proc(game: ^Game, wp: ^Weapon),
	on_shoot_end:   proc(game: ^Game, wp: ^Weapon),
	on_draw:        proc(game: ^Game, wp: ^Weapon),
}
WeaponPickup :: struct {
	weapon:    ^Weapon,
	icon_path: string,
	icon:      rl.Texture2D,
}

WeaponGunPickup := WeaponPickup {
	weapon    = &WeaponGun,
	icon_path = "assets/gun_pickup.png",
}
WeaponGun := Weapon {
	name           = "Revolver",
	desc           = "Powerful gun. Pew pew!",
	icon_path      = "assets/gun.png",
	on_shoot_start = gun_shoot_start,
	on_shoot_end   = {},
	on_draw        = gun_draw,
}
gun_shoot_start :: proc(game: ^Game, wp: ^Weapon) {
	mouse_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera)
	dir := linalg.normalize(mouse_pos - wp.position)
	bullet_spawn(game, wp.position, dir)
}
gun_draw :: proc(game: ^Game, wp: ^Weapon) {
	size := [2]f32{32, 32}
	angle := linalg.angle_between(rl.Vector2{0.0, 1.0}, wp.direction)
	if wp.direction.x > 0 do angle *= -1
  if !rl.IsTextureValid(wp.icon) do wp.icon = rl.LoadTexture(strings.clone_to_cstring(wp.icon_path))
	rl.DrawTexturePro(
    wp.icon,
    {0, 0, 32, 32},
		{wp.position.x, wp.position.y, size.x, size.y},
		{size.x / 2.0, size.y / 2.0},
		linalg.to_degrees(angle) + 90,
		rl.WHITE,
	)
}
