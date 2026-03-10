# Demo 01: Hello Musa

**Nivel:** Básico | **Clock:** Master (TimerClock)

## Descripción

Esta es la primera demo de musa-dsl. Introduce los conceptos fundamentales:

- **Escalas musicales** - Sistema de 12-TET con acceso por grados
- **TimerClock** - musa-dsl controla el tempo (master clock)
- **Transport** - Conexión entre clock y sequencer
- **Sequencer** - Programación de eventos musicales
- **MIDIVoices** - Gestión de salida MIDI

## Pieza Musical

Una melodía simple de 9 notas en Do Mayor seguida de un acorde final:

```
Beats 1-5:   Do Re Mi Fa Sol Fa Mi Re Do (cada nota dura 1/2 beat)
Beat 6:      Acorde Do Mayor (Do-Mi-Sol)
```

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Configuración DAW

Usa el proyecto DAW compartido (`daw-bitwig/` o `daw-live/`). Ver [README principal](../README.md#proyecto-daw-compartido).

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Piano | 1 | Piano |

## Recursos musa-dsl utilizados

```ruby
# Escala
Scales.et12[440.0].major[60]  # Do Mayor, La=440Hz

# Clock interno
TimerClock.new(bpm: 120, ticks_per_beat: 24)

# Transport
Transport.new(clock, 4, 24)  # 4 beats/compás, 24 ticks/beat

# Scheduling
at 1 do ... end  # Evento en compás 1

# Notas
voice.note(pitch, velocity: 80, duration: 3/8r)

# Chord API: obtener las 3 notas de la tríada directamente
scale[0].chord.pitches  # => [Do, Mi, Sol] como MIDI pitches
```

## Buenas prácticas

- **`scale[g].chord.pitches` para acordes**: Accede a las notas de un acorde directamente desde un grado de escala. La calidad del acorde (mayor, menor, disminuido) se deduce automáticamente del grado.
- **`at` para scheduling directo**: Usa `at bar do ... end` para programar eventos en posiciones absolutas del compás. Es la forma más simple de scheduling — ideal cuando sabes exactamente cuándo debe sonar algo.
