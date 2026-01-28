# Demo 00: Template

**Nivel:** Plantilla | **Clock:** Slave (InputMidiClock)

## Descripción

Plantilla base para empezar proyectos de composición algorítmica con MusaDSL. Incluye:

- Configuración MIDI completa (4 canales)
- Transcriptor con ornamentos barrocos
- Hot-reload para live coding
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

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección | Propósito |
|--------|--------|-----------|-----------|
| Clock | `Clock` | DAW → musa-dsl | MIDI Clock, Start/Stop |
| Main | `Main` | musa-dsl → DAW | Notas MIDI |

### Crear puertos virtuales (macOS)

1. Abrir **Audio MIDI Setup**
2. Menú **Window → Show MIDI Studio**
3. Doble-clic en **IAC Driver**
4. Marcar "Device is online"
5. Crear dos puertos: `Clock` y `Main`

### Canales MIDI

| Canal MIDI | Instrumento sugerido |
|------------|---------------------|
| 1 | Piano, Synth |

**Pistas a crear:** 1 pista MIDI recibiendo en canal 1.

**Nota:** El template tiene 4 canales disponibles (1-4) para cuando amplíes tu composición.

### Configurar MIDI Clock en el DAW

**Bitwig Studio:**
1. Settings → Controllers → Add "Generic MIDI Clock Transmitter"
2. MIDI Output: seleccionar puerto `Clock`
3. Habilitar Send Clock, Start/Stop

**Ableton Live:**
1. Preferences → Link/Tempo/MIDI
2. En puerto de salida `Clock`, activar **Sync**

**Sincronización:** SLAVE - El DAW controla el tempo.

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

## Flujo de señales

```
┌─────────────┐     MIDI Clock (24 ppqn)    ┌─────────────┐
│             │ ─────────────────────────── │             │
│     DAW     │      MIDI Start/Stop        │  musa-dsl   │
│   (Master)  │ ═══════════════════════════ │   (Slave)   │
│             │        puerto: Clock        │             │
│             │                             │             │
│             │      MIDI Notes             │             │
│             │ ←────────────────────────── │             │
│             │        puerto: Main         │             │
└─────────────┘                             └─────────────┘
```

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
3. Crear 4 pistas MIDI recibiendo en canales 1-4
4. Presionar PLAY

## Próximos pasos

- **Demo 01:** Hello Musa - Primera composición simple
- **Demo 04:** Neumas - Notación musical avanzada
- **Demo 12:** DAW Sync - Más sobre sincronización
