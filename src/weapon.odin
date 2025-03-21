package main

Weapon :: struct {
  name: string,
  desc: string,
  on_shoot_start: proc(),
  on_shoot_end: proc(),
  on_draw: proc(),
}

WeaponGun := Weapon {
  name = "Revolver",
  desc = "Powerful gun. Pew pew!",
  on_shoot_start = gun_shoot_start,
  on_shoot_end = {},
  on_draw = gun_draw,
}
gun_shoot_start :: proc() {
  
}
gun_draw :: proc() {

}
