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

## Configuración DAW (Bitwig/Ableton)

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | `Main` | musa-dsl → DAW |

### Conexión MIDI

1. Crear un puerto MIDI virtual:
   - **macOS:** Usar IAC Driver (Audio MIDI Setup → IAC Driver → activar)
   - **Windows:** Instalar loopMIDI

2. En el DAW, crear una pista MIDI que reciba del puerto virtual

### Pistas necesarias

| Pista | Canal MIDI | Instrumento sugerido |
|-------|------------|---------------------|
| Piano | 1 | Piano acústico o eléctrico |

### Diagrama de conexión

```
┌─────────────┐         MIDI          ┌─────────────┐
│  main.rb    │ ────────────────────► │    DAW      │
│ (musa-dsl)  │     Puerto virtual    │  (Bitwig/   │
│             │                       │   Ableton)  │
│ TimerClock  │                       │             │
│ BPM: 120    │                       │  Piano      │
└─────────────┘                       └─────────────┘
```

### Notas

- musa-dsl controla el tempo (120 BPM)
- El DAW solo recibe notas MIDI, no necesita enviar clock
- Puedes grabar la salida MIDI en el DAW

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
```

## Próximos pasos

- **Demo 02:** Explora los constructores de series (S, FOR, RND, etc.)
- **Demo 03:** Crea un canon usando series buffered
