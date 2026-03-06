# Demo 12: DAW Sync - Sincronización con DAW (Slave Clock)

**Nivel:** Intermedio | **Clock:** Slave (InputMidiClock)

## Descripción

En este demo, el **DAW controla el tempo** y musa-dsl actúa como esclavo. El script espera recibir MIDI Clock del DAW y sincroniza sus eventos al tempo del proyecto. Esto permite:

- Cambiar el tempo desde el DAW y musa-dsl sigue automáticamente
- Integrar musa-dsl en proyectos DAW existentes
- Sincronizar con otros dispositivos/plugins que también sigan el clock

Además de la sincronización, esta demo aplica patrones idiomáticos de MusaDSL:

- **`H()` + `play`** para combinar series de pitch, duration y velocity en datasets que el sequencer consume automáticamente
- **`Chord`** para construir acordes y arpegios desde la escala (la calidad se deduce del grado)
- **`on`/`launch` + `control.after`** para encadenar secciones sin posiciones absolutas
- **Re-carga del score en `on_start`** para reiniciar la pieza con cada Play del DAW (y permitir edición entre ciclos)
- **`Signal.trap('INT')`** para cierre limpio con `voices.panic`

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

**IMPORTANTE:** El script se bloquea esperando MIDI Start. Debes presionar PLAY en tu DAW.

## Configuración DAW

| Puerto | Dirección |
|--------|-----------|
| Clock | DAW → musa-dsl |
| Main | musa-dsl → DAW |

| Pista | Canal MIDI |
|-------|------------|
| Melodía | 1 |
| Acordes | 2 |

## Secciones de la composición

| Compases | Sección | Contenido |
|----------|---------|-----------|
| 1-2 | `:arpegio` | Arpegio ascendente/descendente desde `Chord(:seventh)` |
| 3-6 | `:acordes` | Progresión I-IV-V-I con `Chord` por grado |
| 7-8 | `:patron` | Patrón rítmico cíclico (sensible a cambios de tempo) |
| 9-12 | `:final` | Melodía final y acorde conclusivo |

## Comparación: Master vs Slave Clock

| Característica | Master (TimerClock) | Slave (InputMidiClock) |
|----------------|---------------------|------------------------|
| Control de tempo | musa-dsl | DAW |
| BPM definido en | código Ruby | proyecto DAW |
| Sincronización | musa-dsl → DAW | DAW → musa-dsl |
| Inicio | `transport.start` inmediato | espera MIDI Start |
| Uso típico | standalone, instalaciones | integración con DAW |

## API de InputMidiClock

### Crear clock esclavo
```ruby
# Obtener dispositivo de entrada MIDI
clock_input = MIDICommunications::Input.find_by_name('Clock')

# Crear InputMidiClock
clock = InputMidiClock.new(clock_input)
```

### Callbacks del Transport
```ruby
# Cuando el DAW envía MIDI Start — re-cargar el score fresco
transport.on_start do
  load 'score.rb'
  extend TheScore
  score
end

# Cuando el DAW envía MIDI Stop
transport.after_stop do
  voices.panic  # Silenciar todo
end
```

Cargar el score en `on_start` permite:
- Reiniciar la pieza con cada ciclo Stop/Play del DAW
- Editar `score.rb` con el DAW parado y oír los cambios al darle Play

### Selección dinámica de input
```ruby
# Crear sin input (se asigna después)
clock = InputMidiClock.new

# Mostrar opciones al usuario
input = MIDICommunications::Input.gets  # Interactivo

# Asignar (despierta el clock)
clock.input = input
```

## Buenas prácticas

- **`on_start` + `load` para hot-reload**: Usa `transport.on_start { load 'score.rb'; extend TheScore; score }` para recargar el score en cada MIDI Start. Esto permite editar `score.rb` entre ciclos de Stop/Play sin reiniciar el script.
- **`voices.panic` en `after_stop`**: Usa `transport.after_stop { voices.panic }` para silenciar todas las notas MIDI cuando el DAW envía Stop. Evita notas colgadas que sigan sonando.
- **`Signal.trap('INT')` para cierre limpio**: Captura Ctrl+C con `Signal.trap('INT') { voices.panic; exit }` para asegurar que las notas se silencian al cerrar el script, evitando notas MIDI colgadas en el DAW.
