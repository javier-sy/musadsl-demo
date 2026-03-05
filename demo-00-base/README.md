# Demo 00: Template

**Nivel:** Plantilla | **Clock:** Slave (InputMidiClock)

## Descripción

Plantilla base para empezar proyectos de composición algorítmica con MusaDSL. Incluye:

- Configuración MIDI completa (4 canales)
- Transcriptor con ornamentos barrocos
- Hot-reload para editar el fuente sin reiniciar
- Proyecto Bitwig Studio preconfigurado

## Estructura

```
demo-00/
├── musa/
│   ├── main.rb      # Setup: clock, voces, helpers
│   ├── score.rb     # Tu composición (hot-reloadable)
│   ├── Gemfile      # Dependencias
│   └── Gemfile.lock
└── bw/
    └── demo/        # Proyecto Bitwig Studio
```

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
# Presiona PLAY en el DAW
```

**IMPORTANTE:** El script espera MIDI Clock del DAW. Debes presionar PLAY en tu DAW.

## Configuración DAW

| Puerto | Dirección |
|--------|-----------|
| Clock | DAW → musa-dsl |
| Main | musa-dsl → DAW |

| Pista | Canal MIDI |
|-------|------------|
| Melodía | 1          |
| Melodía | 2          |
| Melodía | 3          |
| Melodía | 4          |

## Uso

### Archivo score.rb

Edita `score.rb` para tu composición:

```ruby
module TheScore
  using Musa::Extension::Neumas

  def score
    # Tu composición aquí
    melody = '(0 1 mf) (+2 1) (+2 1) (+1 1)'.to_neumas

    at 1 do
      neuma melody, voice: v(0)
    end
    
    # ...
  end
end
```

### Helpers disponibles

| Helper | Uso |
|--------|-----|
| `v(n)` | Acceso a voz n (0-3) |
| `scale` | Escala actual (Do Mayor) |
| `decoder` | Decoder de neumas |
| `neuma(serie, voice:)` | Reproduce neumas en una voz |
| `reload` | Recarga score.rb en caliente |

### Hot-reload

Mientras la música suena:
1. Modifica `score.rb`
2. El score se recarga automáticamente cada vez que el DAW envía MIDI Start (presiona STOP y luego PLAY)

**Nota:** El helper `reload` está definido en main.rb y se ejecuta internamente cuando el DAW envía MIDI Start. Si usas MusaLCE REPL, puedes llamar `reload` manualmente.

## Características técnicas

### Transcriptor con ornamentos

Soporta ornamentos barrocos en notación neuma:

| Ornamento | Notación | Descripción |
|-----------|----------|-------------|
| Trill | `tr` | Alternancia rápida con nota superior |
| Mordent | `mor` | Nota + inferior + nota |
| Turn | `turn` | Grupeto |
| Appogiatura | `app` | Nota de gracia |

### Ejemplo con ornamentos

```ruby
melody = '(0 1/2 mf tr) (+2 1/4 mor) (+2 1/4) (+1 1)'.to_neumas
```

### Escala

Escala base: **Do Mayor** desde C4 (MIDI 60)

```ruby
scale = Scales.et12[440.0].major[60]
```

Para cambiar la escala, edita `main.rb`.

## Personalización

### Cambiar puertos MIDI

Edita en `main.rb`:

```ruby
clock_input = MIDICommunications::Input.find_by_name('TuPuertoClock')
output = MIDICommunications::Output.find_by_name('TuPuertoOutput')
```

### Cambiar número de canales

```ruby
voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0, 1]  # Reduce a 2 canales
)
```

### Cambiar escala

```ruby
scale = Scales.et12[440.0].minor[57]      # La menor
scale = Scales.et12[440.0].dorian[62]     # Re dórico
scale = Scales.et12[440.0].pentatonic_major[60]  # Pentatónica
```

## Proyecto Bitwig incluido

El directorio `bw/demo/` contiene un proyecto Bitwig Studio preconfigurado:

1. Abrir `bw/demo/demo.bwproject` en Bitwig
2. Verificar que los puertos MIDI `Clock` y `Main` están conectados
3. Ajustar las 4 pistas MIDI recibiendo en canales 1-4
4. Presionar PLAY

## Buenas prácticas

- **Hot-reload con `on_start`**: Usa `transport.on_start { load 'score.rb'; extend TheScore; score }` para recargar el score en cada MIDI Start del DAW, permitiendo editar sin reiniciar el script.
- **`using` refinements por archivo**: `using Musa::Extension::Neumas` debe declararse en cada archivo `.rb` que use `.to_neumas`. Los refinements de Ruby son de ámbito de archivo — declararlo en `main.rb` no lo activa en `score.rb`.
- **Transcriptor para ornamentos**: Sin un `Transcriptor`, los ornamentos (`tr`, `mor`, `st`, `turn`) se ignoran silenciosamente. Siempre crea un `Transcriptor` y pásalo al `NeumaDecoder` si vas a usar ornamentos.
