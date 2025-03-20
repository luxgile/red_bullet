package main

import fmt "core:fmt"
import math "core:math"
import linalg "core:math/linalg"
import rand "core:math/rand"
import rl "vendor:raylib"

Particle :: struct {
	position: rl.Vector2,
	velocity: rl.Vector2,
	rotation: f32,
	lifetime: f32,
}

SpawnCircle :: struct {
	radius: f32,
}

ParticleSpawnMode :: union {
	SpawnCircle,
}

ConstantSize :: struct {
	size: f32,
}

SizeOverLifetime :: struct {
	start: f32,
	end:   f32,
}

ParticleSizeMode :: union {
	ConstantSize,
	SizeOverLifetime,
}

size_mode_eval :: proc(mode: ^ParticleSizeMode, particle: ^Particle, vfx: ^VfxCpu) -> f32 {
	switch size in mode {
	case ConstantSize:
		return size.size
	case SizeOverLifetime:
		return math.lerp(size.start, size.end, particle.lifetime / vfx.max_lifetime)
	}
	return 0.0
}

ConstantColor :: struct {
	color: rl.Color,
}

ColorOverLifetime :: struct {
	start: rl.Color,
	end:   rl.Color,
}

ParticleColorMode :: union {
	ConstantColor,
	ColorOverLifetime,
}
color_mode_eval :: proc(mode: ^ParticleColorMode, particle: ^Particle, vfx: ^VfxCpu) -> rl.Color {
	switch v in mode {
	case ConstantColor:
		return v.color
	case ColorOverLifetime:
		return rl.ColorLerp(v.start, v.end, particle.lifetime / vfx.max_lifetime)
	}
	return rl.WHITE
}

ExplosionSpawnVelocity :: struct {
	force: rl.Vector2,
}

ParticleSpawnVelocityMode :: union {
	ExplosionSpawnVelocity,
}
spawn_velocity_mode_eval :: proc(
	mode: ^ParticleSpawnVelocityMode,
	pos: rl.Vector2,
	vfx: ^VfxCpu,
) -> rl.Vector2 {
	switch v in mode {
	case ExplosionSpawnVelocity:
		return linalg.normalize(pos) * rand.float32_range(v.force.x, v.force.y)
	}
	return {0, 0}
}

VfxCpu :: struct {
	is_running:          bool,
	is_one_shot:         bool,
	position:            rl.Vector2,
	is_local_space:      bool,
	duration:            f32,
	time_running:        f32,
	spawn_rate:          f32,
	_spawn_rate_timer:   f32,
	max_lifetime:        f32,
	max_particles:       int,
	particles:           [dynamic]Particle,
	spawn_mode:          ParticleSpawnMode,
	size_mode:           ParticleSizeMode,
	color_mode:          ParticleColorMode,
	spawn_velocity_mode: ParticleSpawnVelocityMode,
	gravity:             rl.Vector2,
}

vfx_play :: proc(using vfx: ^VfxCpu) {
	is_running = true
}

vfx_pause :: proc(using vfx: ^VfxCpu) {
	is_running = false
}

vfx_restart :: proc(using vfx: ^VfxCpu) {
	is_running = false
	duration = 0
}

vfx_process :: proc(using vfx: ^VfxCpu, dt: f32) {
	for &particle, index in particles {
		particle.velocity += gravity * dt
		particle.position += particle.velocity * dt
		particle.lifetime += dt
		if particle.lifetime >= max_lifetime {
			unordered_remove(&particles, index)
		}
	}

	if !is_running do return

	time_running += dt
	if is_one_shot && time_running >= duration {
		is_running = false
		time_running = 0
	}

	_spawn_rate_timer += dt
	rate := 1.0 / spawn_rate
	for _spawn_rate_timer >= rate && len(&particles) < max_particles {
		_spawn_rate_timer -= rate
		vfx_spawn_particle(vfx)
	}
}

vfx_draw :: proc(using vfx: ^VfxCpu) {
	for &particle in particles {
		radius := size_mode_eval(&vfx.size_mode, &particle, vfx)
		color := color_mode_eval(&vfx.color_mode, &particle, vfx)
		pos := is_local_space ? position + particle.position : particle.position
		rl.DrawCircleV(pos, radius, color)
	}
}

vfx_spawn_particle :: proc(using vfx: ^VfxCpu) {
	switch spawn in vfx.spawn_mode {
	case SpawnCircle:
		spawn_pos :=
			linalg.normalize(rl.Vector2{rand.float32_range(-1, 1), rand.float32_range(-1, 1)}) *
			rand.float32_range(0, spawn.radius)
		velocity := spawn_velocity_mode_eval(&vfx.spawn_velocity_mode, spawn_pos, vfx)
		particle := Particle {
			position = spawn_pos + position,
      velocity = velocity,
		}
		append(&particles, particle)
	}
}
