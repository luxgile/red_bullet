package main

import fmt "core:fmt"
import linalg "core:math/linalg"
import strings "core:strings"
import rl "vendor:raylib"

Weapon :: struct {
	name:           string,
	desc:           string,
	position:       rl.Vector2,
	direction:      rl.Vector2,
	icon:           CachedTexture,
	on_shoot_start: proc(game: ^Game, wp: ^Weapon),
	on_shoot_end:   proc(game: ^Game, wp: ^Weapon),
	on_draw:        proc(game: ^Game, wp: ^Weapon),
}
WeaponPickup :: struct {
	weapon:   ^Weapon,
	icon:     CachedTexture,
	position: rl.Vector2,
	size:     rl.Vector2,
}

wpickup_new :: proc(game: ^Game, pickup: WeaponPickup, position: rl.Vector2) {
	p := new_clone(pickup)
	p.position = position
	append(&game.pickups, p)
}
wpickup_check_collision :: proc(using pickup: ^WeaponPickup, player: ^Player) -> bool {
	return rl.CheckCollisionCircleRec(
		player.position,
		player.size,
		{position.x, position.y, size.x, size.y},
	)
}
wpickup_draw :: proc(using pickup: ^WeaponPickup) {
	when DRAW_COLLISIONS do rl.DrawRectangleV(position, size, rl.PINK)

	texture := ctexture_get(&pickup.icon)
	rl.DrawTextureV(texture, position, rl.WHITE)
}

WeaponGunPickup := WeaponPickup {
	weapon = &WeaponGun,
	icon   = {{}, "assets/gun_pickup.png"},
	size   = {28, 28},
}
WeaponGun := Weapon {
	name           = "Revolver",
	desc           = "Powerful gun. Pew pew!",
	icon           = {{}, "assets/gun.png"},
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

	icon := ctexture_get(&wp.icon)
	rl.DrawTexturePro(
		icon,
		{0, 0, 32, 32},
		{wp.position.x, wp.position.y, size.x, size.y},
		{size.x / 2.0, size.y / 2.0},
		linalg.to_degrees(angle) + 90,
		rl.WHITE,
	)
}
