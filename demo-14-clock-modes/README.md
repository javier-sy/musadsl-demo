# Demo 14: Clock Modes - Comparativa Master vs Slave

**Nivel:** Intermedio | **Clock:** Ambos modos

## Descripción

Esta demo muestra la **misma composición** ejecutada en dos modos diferentes de sincronización. Esto permite entender cuándo usar cada modo y cómo afecta al flujo de trabajo.

## Ejecutar

### Modo MASTER (musa-dsl controla el tempo)
```bash
cd musa
bundle install
ruby main_master.rb
```

### Modo SLAVE (DAW controla el tempo)
```bash
cd musa
bundle install
ruby main_slave.rb
# Presiona PLAY en el DAW
```

## Archivos

| Archivo | Propósito |
|---------|-----------|
| `main_master.rb` | Configuración con TimerClock |
| `main_slave.rb` | Configuración con InputMidiClock |
| `score.rb` | Composición compartida |

## Configuración DAW

Usa el proyecto DAW compartido (`daw-bitwig/` o `daw-live/`). Ver [README principal](../README.md#proyecto-daw-compartido).

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Melodía | 1 | Línea melódica |
| Acordes | 2 | Progresión armónica |

**Modo Master** (`main_master.rb`): musa-dsl controla el tempo con TimerClock. Solo se necesita el puerto Main.

**Modo Slave** (`main_slave.rb`): el DAW controla el tempo. Se necesitan dos puertos MIDI virtuales (Main + Clock). Pulsa Play en el DAW para iniciar.

## Comparación de modos

| Aspecto | Master (TimerClock) | Slave (InputMidiClock) |
|---------|---------------------|------------------------|
| **Control de tempo** | musa-dsl | DAW |
| **BPM definido en** | Código Ruby | Proyecto DAW |
| **Inicio** | Inmediato | Espera MIDI Start |
| **Sincronización** | musa-dsl → DAW | DAW → musa-dsl |
| **Cambio de tempo** | Modificar código | Cambiar en DAW |
| **Uso típico** | Standalone, instalaciones | Integración con DAW |

## Cuándo usar cada modo

### Usar MASTER cuando:
- musa-dsl es la aplicación principal
- No hay DAW o el DAW debe seguir a musa-dsl
- Instalaciones sonoras autónomas
- Prototipado rápido sin configurar DAW
- El tempo está definido algorítmicamente

### Usar SLAVE cuando:
- El DAW es la aplicación principal
- Quieres cambiar el tempo desde el DAW
- Integración con proyectos DAW existentes
- Colaboración con otros músicos usando el DAW
- Grabación en el DAW sincronizada

## Estructura del código

### main_master.rb (extracto)
```ruby
# TimerClock: musa-dsl define el tempo
BPM = 110
clock = TimerClock.new(bpm: BPM, ticks_per_beat: 24)

transport = Transport.new(clock, 4, 24)

# Inicia inmediatamente
transport.start
```

### main_slave.rb (extracto)
```ruby
# InputMidiClock: el DAW define el tempo
clock_input = MIDICommunications::Input.gets
clock = InputMidiClock.new(clock_input)

transport = Transport.new(clock, 4, 24)

# Hot-reload: cada MIDI Start recarga score.rb
transport.sequencer.with scale: scale, voices: voices do |scale:, voices:|
  on_start do
    load 'score.rb'
    extend TheScore
    score
  end
end

transport.start  # Espera MIDI Start del DAW
```

### score.rb (compartido)
```ruby
module TheScore
  def score
    melody = v(0)
    chords = v(1)

    # Secciones encadenadas con on/launch
    on :melodia do
      serie = H(grade: S(0, 2, 4, 5, 7, 5, 4, 2),
                duration: S(1/8r).repeat)
      control = play serie do |grade:, duration:|
        melody.note(scale[grade].pitch, velocity: 75, duration: 3/32r)
      end
      control.after { launch :acordes }
    end

    on :acordes do
      # ... progresión I-V-vi-IV con scale[root].chord ...
      control.after { launch :patron }
    end

    # ... :patron → :finale → :finished

    at 1 do
      launch :melodia
    end
  end
end
```

La composición es idéntica en ambos modos. Cada `main_*.rb` maneja el evento `:finished` de forma diferente: master detiene el transport, slave espera al DAW.

## Experimentar

1. **Ejecutar ambos modos** con la misma composición
2. **En modo Slave**, cambiar el tempo en el DAW mientras suena
3. **En modo Slave**, editar `score.rb`, hacer stop/play en el DAW y escuchar los cambios (hot-reload)
4. **En modo Master**, modificar BPM en el código y reiniciar
5. **Comparar** la experiencia de cada flujo de trabajo

## API Reference

### TimerClock (Master)
```ruby
clock = TimerClock.new(
  bpm: 120,           # Tempo en BPM
  ticks_per_beat: 24  # Resolución (24 = estándar MIDI)
)
```

### InputMidiClock (Slave)
```ruby
clock_input = MIDICommunications::Input.find_by_name('Clock')
clock = InputMidiClock.new(clock_input)
```

### Transport (común)
```ruby
transport = Transport.new(
  clock,              # TimerClock o InputMidiClock
  4,                  # Beats por compás
  24,                 # Ticks por beat
  do_log: true        # Mostrar info de posición
)

transport.on_start { puts "Iniciado" }
transport.after_stop { puts "Detenido" }

transport.start      # En Master: inmediato
                     # En Slave: espera MIDI Start
```

## Buenas prácticas

- **Score compartido entre modos**: Separa la configuración de clock (`main_master.rb` / `main_slave.rb`) de la composición (`score.rb`). El mismo score funciona sin cambios en ambos modos.
- **Evento `:finished` para terminación agnóstica**: El score lanza `:finished` al terminar; cada main lo maneja según su modo (master: `transport.stop`, slave: puede ignorarlo y esperar al DAW). Esto desacopla la composición del ciclo de vida del transport.
- **`every` para capas de fondo**: Usa `every` para patrones repetitivos independientes (acordes sostenidos, drones) y `.stop` para detenerlos cuando la capa principal termine.
- **`on`/`launch` + `control.after` para secciones**: Prefiere encadenamiento por eventos sobre `at` absolutos. Esto hace la composición resiliente a cambios de tempo y duración de secciones.
- **Hot-reload con `on_start` + `load`**: En modo slave, carga el score dentro de `on_start` para que cada stop/play del DAW recargue `score.rb`. Esto permite editar la composición sin reiniciar el proceso.
- **TimerClock para prototipado, InputMidiClock para producción**: Desarrolla con TimerClock (sin depender de DAW), luego cambia a InputMidiClock para integrar con tu proyecto DAW.
