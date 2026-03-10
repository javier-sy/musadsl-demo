# Demo 17: Event Architecture - Sistema launch/on

**Nivel:** Intermedio | **Clock:** Master | **Inspirado en:** Estudio para clave nº1 (2019), Piezoreflections (2017)

## Descripción

Sistema de eventos para composiciones estructuradas por fases con transiciones automáticas. Demuestra cómo usar `on :event` y `launch :event` para crear composiciones modulares y reactivas.

## Configuración DAW

Usa el proyecto DAW compartido (`daw-bitwig/` o `daw-live/`). Ver [README principal](../README.md#proyecto-daw-compartido).

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Melodía | 1 | Línea melódica |

## Requisitos

- Ruby con gems: `musa-dsl`, `midi-communications`
- Salida MIDI configurada (DAW, synth, etc.)

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Conceptos Clave

### Sistema de Eventos

```ruby
# Definir un handler de evento
on :my_event do |param1, param2|
  puts "Evento recibido: #{param1}, #{param2}"
end

# Disparar el evento
launch :my_event, "valor1", "valor2"
```

### Callback `.after`

```ruby
control = play(serie) { |note| voice.note(**note) }

# Se ejecuta cuando la reproducción termina
control.after do
  launch :next_phase
end
```

## Estructura de la Demo

### Fases

| Fase | Evento | Descripción |
|------|--------|-------------|
| 1 | `:intro` | Introducción melódica |
| 2 | `:development` | 3 episodios con transposición |
| 3 | `:climax` | Intensidad máxima |
| 4 | `:coda` | Final tranquilo |

### Eventos auxiliares

| Evento | Descripción |
|--------|-------------|
| `:transition` | Router central: recibe la siguiente fase y la lanza |
| `:finish` | Mensaje final y detención del transport |
| `:status` | Debugging: imprime fase actual, episodio y controls activos |

### Flujo de Eventos

```
at 1 ──► launch :intro
              │
              ▼
         on :intro
              │ (play + .after)
              ▼
    launch :transition, :development
              │
              ▼
    on :development (episode 1)
              │ (.after)
              ▼
    on :development (episode 2)
              │ (.after)
              ▼
    on :development (episode 3)
              │ (.after)
              ▼
    launch :transition, :climax
              │
              ▼
         on :climax
              │ (.after)
              ▼
    launch :transition, :coda
              │
              ▼
          on :coda
              │ (.after)
              ▼
        launch :finish
```

## Patrones Demostrados en Esta Demo

### 1. Helper para eliminar repetición

Las 4 fases usan el mismo patrón (crear `H()` → `play` → `voice.note`). Un método `play_phase` centraliza la lógica:

```ruby
def play_phase(grades, durations, velocities, transpose: 0)
  melody = H(grade: grades.instance, duration: durations.instance, velocity: velocities.instance)

  control = play melody do |note|
    pitch = scale[note[:grade] + transpose].pitch
    voice.note(pitch: pitch, duration: note[:duration], velocity: note[:velocity].to_i)
  end

  @playing_controls << control
  control.on_stop { @playing_controls.delete(control) }

  control
end
```

### 2. Transiciones de fase con router central

```ruby
on :transition do |next_phase|
  case next_phase
  when :development then launch :development, 1
  when :climax then launch :climax
  when :coda then launch :coda
  end
end

# Uso: launch :transition, :development
```

### 3. Episodios con contador

```ruby
on :development do |episode|
  return launch :transition, :climax if episode > 3

  # ... reproducir episodio con transposición ...

  control.after do
    wait 1/2r { launch :development, episode + 1 }
  end
end
```

### 4. Cleanup de controls con on_stop

```ruby
@playing_controls << control
control.on_stop { @playing_controls.delete(control) }

# En :status, @playing_controls siempre refleja los activos reales
```

## Otros Patrones Posibles con launch/on

Estos patrones no se usan en esta demo pero ilustran otras aplicaciones del sistema de eventos.

### Handler con keyword arguments

```ruby
on :configure do |channel:, volume:|
  set_channel(channel)
  set_volume(volume)
end

launch :configure, channel: 0, volume: 100
```

### Self-scheduling loop

```ruby
on :rhythm do
  play_beat

  wait @beat_duration do
    launch :rhythm unless @stopped
  end
end

launch :rhythm
```

### Sincronización de voces

```ruby
@voices_finished = 0

on :voice_finished do |voice_id|
  @voices_finished += 1
  launch :all_finished if @voices_finished >= TOTAL_VOICES
end
```

### Canon con delay

```ruby
on :melody do |voice_num|
  play_melody(voice_num)

  if voice_num < 4
    wait 2 { launch :melody, voice_num + 1 }
  end
end

launch :melody, 1
```

### Forma ternaria ABA

```ruby
on :A do
  play_section_A
  control.after { launch :B }
end

on :B do
  play_section_B
  control.after { launch :A_reprise }
end

on :A_reprise do
  play_section_A_variation
  control.after { launch :coda }
end
```

## Comparación con `at`

| `at` | `launch/on` |
|------|-------------|
| Tiempo absoluto | Eventos reactivos |
| Fijo al programar | Dinámico |
| Simple | Modular y extensible |
| Lineal | Puede ser no-lineal |

### Cuándo usar cada uno

- **`at`**: Eventos en tiempos específicos conocidos de antemano
- **`launch/on`**: Transiciones que dependen de condiciones o duración variable

## Buenas prácticas

- **`on`/`launch` con parámetros para transiciones de fase**: Pasa el nombre de la siguiente fase como argumento: `launch :transition, :development`. El handler `on :transition` usa `case` para decidir qué hacer, centralizando la lógica de flujo.
- **`control.after` para encadenamiento reactivo**: Usa `.after { launch :next }` en vez de `at` con tiempos calculados. Esto hace la composición resiliente a cambios de duración — si una melodía se alarga o acorta, la transición se adapta automáticamente.
- **Helper para fases repetitivas**: Cuando varias fases comparten la misma estructura (crear serie → play → note), extraer un proc o método elimina duplicación y facilita cambios globales.
- **`on_stop` para cleanup de estado**: Registrar `control.on_stop { @list.delete(control) }` mantiene las listas de estado siempre actualizadas, sin necesidad de filtrar manualmente.
- **Variables de instancia para estado entre eventos**: Usa `@counter`, `@phase`, `@playing_controls` etc. para mantener estado que los handlers necesitan compartir. Los handlers se ejecutan en el mismo contexto del sequencer.
