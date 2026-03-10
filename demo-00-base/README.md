# Demo 00: Template

**Nivel:** Plantilla | **Clock:** Slave (InputMidiClock)

## Descripción

Plantilla base para empezar proyectos de composición algorítmica con MusaDSL. Incluye:

- Configuración MIDI completa (4 canales)
- Transcriptor con ornamentos barrocos
- Hot-reload para editar el fuente sin reiniciar

## Estructura

```
demo-00/
├── musa/
    ├── main.rb      # Setup: clock, voces, helpers
    ├── score.rb     # Tu composición (hot-reloadable)
    ├── Gemfile      # Dependencias
    └── Gemfile.lock
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

Usa el proyecto DAW compartido (`daw-bitwig/` o `daw-live/`). Ver [README principal](../README.md#proyecto-daw-compartido).

**Modo Slave**: esta demo requiere dos puertos MIDI virtuales (Main + Clock). El DAW controla el tempo. Pulsa Play en el DAW para iniciar.

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Melodía | 1          | Melodía |
| Melodía | 2          | Melodía |
| Melodía | 3          | Melodía |
| Melodía | 4          | Melodía |

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

## Buenas prácticas

- **Hot-reload con `on_start`**: Usa `transport.on_start { load 'score.rb'; extend TheScore; score }` para recargar el score en cada MIDI Start del DAW, permitiendo editar sin reiniciar el script.
- **`using` refinements por archivo**: `using Musa::Extension::Neumas` debe declararse en cada archivo `.rb` que use `.to_neumas`. Los refinements de Ruby son de ámbito de archivo — declararlo en `main.rb` no lo activa en `score.rb`.
- **Transcriptor para ornamentos**: Sin un `Transcriptor`, los ornamentos (`tr`, `mor`, `st`, `turn`) se ignoran silenciosamente. Siempre crea un `Transcriptor` y pásalo al `NeumaDecoder` si vas a usar ornamentos.
