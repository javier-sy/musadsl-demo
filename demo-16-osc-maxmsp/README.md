# Demo 16: OSC Max/MSP - Secuenciador Reactivo

**Nivel:** Intermedio | **Protocolo:** OSC | **Clock:** Master

## Descripción

Secuenciador algorítmico controlado en tiempo real desde Max/MSP via OSC. Max envía parámetros (escala, densidad, registro) y recibe notas generadas por musa-dsl. Demuestra comunicación OSC bidireccional integrada con el sequencer de musa-dsl.

## Requisitos

- Max/MSP (o Max Runtime gratuito)
- Ruby con gems: `musa-dsl`, `osc-ruby`

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

Abrir el patch en Max/MSP (ver `max/README.md` para construcción del patch).

## Archivos

| Archivo | Propósito |
|---------|-----------|
| `main.rb` | Entry point: TimerClock, Transport, OSC setup |
| `score.rb` | Generador de notas con `every` + handlers reactivos |
| `input_handler.rb` | `InputHandler`: recibe params y lanza eventos en el sequencer |
| `osc_output.rb` | `OscOutput`: envía notas a Max (`OSC::Client`) |

## Conexión OSC

| Puerto | Dirección | Contenido |
|--------|-----------|-----------|
| 8000 | Max → musa-dsl | Parámetros de control |
| 8001 | musa-dsl → Max | Notas generadas |

### Parámetros (Max → musa-dsl)

| Mensaje | Rango | Descripción |
|---------|-------|-------------|
| `/root` | 0-11 | Nota raíz (0=C, 1=C#, ..., 11=B) |
| `/mode` | 0-3 | 0=Mayor, 1=Menor, 2=Dórico, 3=Mixolidio |
| `/density` | 1-8 | Notas por compás |
| `/register` | -2..2 | Desplazamiento de octava |

### Notas (musa-dsl → Max)

| Mensaje | Argumentos | Descripción |
|---------|------------|-------------|
| `/note` | pitch, velocity, duration_ms | Nota MIDI generada |

## Cómo funciona

1. `InputHandler` (`OSC::Server`) escucha en puerto 8000 en un thread separado
2. Cuando un parámetro cambia, `InputHandler` llama `sequencer.launch` con el evento específico (`:root_changed`, `:mode_changed`, `:density_changed`, `:register_changed`)
3. Los handlers `on :root_changed`, `on :density_changed`, etc. actualizan variables locales (escala, patrón, offset)
4. El `every 1/8r` genera notas leyendo esas variables — no pollea inputs
5. Cada nota se envía a Max via `OscOutput` (`OSC::Client`)
6. Max recibe `/note` y lo hace sonar con un synth simple

Arquitectura **push**: los cambios de slider llegan como eventos al sequencer, no se samplean.

## Patrones de densidad

Cada nivel de densidad tiene un patrón rítmico fijo (8 slots = corcheas):

| Densidad | Patrón | Notas/compás |
|----------|--------|-------------|
| 1 | `x . . . . . . .` | 1 |
| 2 | `x . . . x . . .` | 2 |
| 3 | `x . . x . . x .` | 3 |
| 4 | `x . x . x . x .` | 4 |
| 5 | `x x . x . x . x` | 5 |
| 6 | `x x . x x . x x` | 6 |
| 7 | `x x x x x x x .` | 7 |
| 8 | `x x x x x x x x` | 8 |

## Código clave

```ruby
# input_handler.rb — lanza eventos en el sequencer al recibir OSC
def update(key, value, event)
  old = @params[key]
  @params[key] = value
  if old != value
    @sequencer.launch(event, @params.dup)
  end
end
```

```ruby
# score.rb — handlers reactivos + generador rítmico
on :root_changed do |params|
  current_scale = Scales.et12[440.0].send(params[:mode])[60 + params[:root]]
end

on :density_changed do |params|
  current_pattern = patterns[params[:density]]
end

# El every solo genera notas — no pollea inputs
at 1 do
  every 1/8r do
    bar_pos = ((position * 8).to_i) % 8
    next unless current_pattern[bar_pos] == 1
    pitch = current_scale[grade].pitch.to_i + octave_offset
    osc_out.send_note(pitch, velocity, dur_ms)
  end
end
```

## Buenas prácticas

- **`InputHandler` con `sequencer.launch` (push, no pull)**: El InputHandler recibe el sequencer y lanza eventos cuando un parámetro cambia. Los handlers `on` actualizan variables locales. El `every` solo se ocupa del ritmo, sin saber que existe el OSC.
- **Separar input y output**: `InputHandler` (recibe + lanza eventos) y `OscOutput` (envía notas) son clases independientes, como `MIDICommunications::Input`/`Output`.
- **`every` como motor rítmico puro**: Usa `every` del sequencer para timing, pero no para samplear inputs. Lee variables locales que los event handlers ya actualizaron.
- **Patrones rítmicos predefinidos por densidad**: En lugar de probabilidades aleatorias, cada nivel de densidad mapea a un patrón fijo. Esto da resultados musicales predecibles y rítmicamente coherentes.
- **Escala dinámica con `Scales.et12[440.0].send(mode)[root]`**: La escala se reconstruye en el handler `on :root_changed` / `on :mode_changed`, sin reiniciar el generador.
