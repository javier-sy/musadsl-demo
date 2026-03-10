# Demo 18: Parameter Automation - SIN() y move

**Nivel:** Intermedio | **Clock:** Master | **Inspirado en:** Estudio para piano nº3 (2019)

## Descripción

Automatización de parámetros musicales usando `SIN()` para envolventes sinusoidales, `move` para rampas lineales, y números primos para períodos no repetitivos.

## Configuración DAW

Usa el proyecto DAW compartido (`daw-bitwig/` o `daw-live/`). Ver [README principal](../README.md#proyecto-daw-compartido).

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Voz principal | 1 | Melodía con automatización |
| Voz secundaria | 2 | Acompañamiento |

### Control Changes utilizados

| CC | Nombre | Uso en la demo |
|----|--------|----------------|
| CC1 | Modulation Wheel | Fade in/out automático |
| CC64 | Sustain Pedal | On/off para legato |

**Nota:** El proyecto DAW compartido ya responde a CC1. Para CC64 (sustain), verifica que el instrumento lo soporta.

## Requisitos

- Ruby con gems: `musa-dsl`, `midi-communications`
- Salida MIDI configurada

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Conceptos Clave

### SIN() - Envolvente Sinusoidal

```ruby
envelope = SIN(
  steps: 16,        # Número de pasos por ciclo
  center: 70,       # Valor central
  amplitude: 50,    # Distancia del centro al pico
  start_value: 70   # Valor inicial (default: center)
).instance

# Obtener valores
value = envelope.next_value  # Oscila entre 20 y 120
```

### move - Rampa Lineal

```ruby
# Rampa básica (de 0 a 127 en 4 compases)
move from: 0, to: 127, duration: 4 do |value|
  voice.controller[1] = value.to_i
end

# Rampa con step específico
move from: 48, to: 72, step: 1, duration: 2 do |pitch|
  voice.note(pitch: pitch.to_i, duration: 1/16r, velocity: 60)
end
```

### Primes - Períodos No Repetitivos

```ruby
PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41...]

# SIN() con período primo
vel = SIN(steps: PRIMES[7], center: 70, amplitude: 40)  # 19 pasos
dur = SIN(steps: PRIMES[5], center: 8, amplitude: 4)    # 13 pasos

# 19 y 13 son coprimos → nunca se sincronizan exactamente
```

## Secciones de la Demo

| Sección | Compases | Descripción |
|---------|----------|-------------|
| 1 | 1-2 | SIN() básico para velocity |
| 2 | 3-4 | SIN() con primes (no repetitivo) |
| 3 | 5-7 | move para fade in/out de CC |
| 4 | 7-8 | move con step (glissando) |
| 5 | 9-11 | Combinación de automatizaciones |
| 6 | 12-13 | SIN().repeat() ida y vuelta |

## Patrones de Automatización

### 1. Velocity con SIN()

```ruby
vel_env = SIN(steps: 16, center: 70, amplitude: 50).instance

16.times do |i|
  at 1 + i * (1/4r) do
    vel = vel_env.next_value
    voice.note(pitch: 60 + i, velocity: vel.to_i, duration: 1/4r)
  end
end
```

### 2. Duración con transformación

```ruby
# SIN() genera valores, .eval() los transforma
dur_env = SIN(steps: PRIMES[8], center: 8, amplitude: 4)
  .eval { |d| Rational(d.to_i, 32) }
  .instance

duration = dur_env.next_value  # Devuelve Rational
```

### 3. Múltiples parámetros no sincronizados

```ruby
# Períodos primos diferentes → polirritmia de parámetros
vel_s = SIN(steps: PRIMES[7], center: 70, amplitude: 40).instance   # 19
dur_s = SIN(steps: PRIMES[5], center: 8, amplitude: 4).instance     # 13
pan_s = SIN(steps: PRIMES[6], center: 64, amplitude: 60).instance   # 17

# Los tres parámetros evolucionan independientemente
```

### 4. Ida y vuelta con .repeat()

```ruby
# .repeat(2) crea un ciclo completo: sube + baja
vel_wave = SIN(steps: 17, center: 70, amplitude: 50)
  .repeat(2)   # 34 valores: 0→peak→0
  .instance
```

### 5. CC automation con move

```ruby
# Fade in de sustain pedal
move from: 0, to: 127, duration: 4 do |v|
  voice.controller[64] = (v > 64 ? 127 : 0)
end

# Fade out de modulation
move from: 127, to: 0, duration: 4 do |v|
  voice.controller[1] = v.to_i
end
```

### 6. Glissando con move

```ruby
# Glissando cromático ascendente
move from: 48, to: 72, step: 1, duration: 2 do |pitch|
  voice.note(pitch: pitch.to_i, duration: 1/16r, velocity: 60)
end

# Glissando por tonos descendente
move from: 84, to: 60, step: -2, duration: 2 do |pitch|
  voice.note(pitch: pitch.to_i, duration: 1/16r, velocity: 70)
end
```

## Tabla de Primos Útiles

| Índice | Prime | Uso típico |
|--------|-------|------------|
| 5 | 13 | Período corto |
| 6 | 17 | Período corto-medio |
| 7 | 19 | Período medio |
| 8 | 23 | Período medio-largo |
| 10 | 31 | Período largo |
| 12 | 41 | Período muy largo |

## Combinaciones Interesantes

### Primos coprimos (máxima variación)

```ruby
# GCD(17, 13) = 1 → se sincronizan cada 17×13 = 221 notas
vel = SIN(steps: 17, ...)
dur = SIN(steps: 13, ...)
```

### Primos consecutivos (variación suave)

```ruby
# 17 y 19 están cerca pero no coinciden
vel1 = SIN(steps: 17, ...)
vel2 = SIN(steps: 19, ...)
```

### Series de series

```ruby
# Diferentes SIN() para cada sección
amplitude_ss = [
  SIN(steps: PRIMES[10], center: 60, amplitude: 50).repeat(2),
  SIN(steps: PRIMES[9], center: 60, amplitude: 50).repeat(2),
  SIN(steps: PRIMES[8], center: 60, amplitude: 50).repeat(2)
].to_serie.instance

# Obtener la siguiente serie cuando la actual termina
current_env = amplitude_ss.next_value.instance
```

## Buenas prácticas

- **`SIN()` con períodos primos para envolventes no repetitivas**: Usa números primos como `steps` en `SIN()`. Cuando combinas varios `SIN()` con períodos primos diferentes, los ciclos nunca se sincronizan exactamente, creando variación continua sin repetición audible.
- **`move` para rampas lineales de CC y pitch**: Usa `move from:, to:, duration:` para automatizar control changes (fade in/out, pedal) o para glissandos. Es más limpio que calcular valores intermedios manualmente.
- **`.eval()` para transformar valores de `SIN()`**: `SIN()` genera floats. Usa `.eval { |v| Rational(v.to_i, 32) }` para convertir a Rational (duraciones) o `.eval { |v| v.to_i.clamp(0, 127) }` para MIDI velocity.
- **`.repeat(2)` para ciclo completo ida y vuelta**: Un solo `SIN()` genera medio ciclo (subida). Con `.repeat(2)` obtienes el ciclo completo: subida + bajada.
