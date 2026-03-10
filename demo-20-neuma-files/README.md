# Demo 20: Neuma Files & Transcriptor

**Nivel:** Intermedio | **Clock:** Master

## Descripción

Archivos `.neu` externos con notación neuma y Transcriptor completo con ornamentos (Trill, Mordent, Turn, Appogiatura). Demuestra el pipeline completo: Neuma → GDV → PDV → MIDI.

## Configuración DAW

Usa el proyecto DAW compartido (`daw-bitwig/` o `daw-live/`). Ver [README principal](../README.md#proyecto-daw-compartido).

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Melodía ornamentada | 1 | Neumas con ornamentos |

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

### Sintaxis Neuma

```neuma
(grado duración dinámica ornamento)

# Ejemplos:
(0 1/4 mf)       # Grado 0, negra, mezzoforte
(2 1/8 f tr)     # Grado 2, corchea, forte, con trino
(+3 1/4)         # Subir 3 grados, negra
(-2 +o1 1/2 p)   # Bajar 2 grados, octava arriba, blanca, piano
```

### Variables en .neu

```neuma
@motif = [ (I 1/4 mf) (II +1/8) (III -1/8) (IV 1/2) ]
@motif
@motif.reverse
@phrase = [ @motif (silence 1/4) @motif.reverse ]
```

### Transcriptor con Ornamentos

```ruby
# Shorthand: incluye todos los ornamentos estándar
processor = Transcriptor.new(
  Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/8r),
  base_duration: 1/4r,
  tick_duration: 1/96r
)
```

### Pipeline GDV → PDV → MIDI

```ruby
# Crear decoder con transcriptor
decoder = Neumas::Decoders::NeumaDecoder.new(
  scale,
  transcriptor: processor,
  base_duration: 1/4r
)

# Parsear neumas
serie = Neumalang.parse(neuma_string, decode_with: decoder)

# Reproducir
play serie, mode: :neumalang, decoder: decoder do |gdv|
  pdv = gdv.to_pdv(scale)  # GDV → PDV
  voice.note(**pdv)         # PDV → MIDI
end
```

## Archivo melody.neu

```neuma
@motif = [ (I 1/4 mf) (II +1/8) (III -1/8) (IV 1/2) ]
@motif_tr = [ (I 1/4 mf tr) (II +1/8) (III -1/8 mor) (IV 1/2) ]
@motif_up = [ (I +o1 1/4 mf) (II +1/8) (III -1/8) (IV 1/2) ]
@var1 = [ @motif.reverse ]
@phrase = [ @motif (silence 1/4) @var1 ]
@parallel_demo = [ @motif || @motif_up ]

@motif
@motif_tr
(silence 1/2)
@phrase

::end
```

**Nota:** Los archivos `.neu` no soportan comentarios `#`.

## Secciones de la Demo

| Sección | Descripción | Encadena con |
|---------|-------------|--------------|
| 1 | Neumas inline básicos | → 2 |
| 2 | Cambios relativos (+2, -1) | → 3 |
| 3 | Ornamentos (tr, mor) | → 4 |
| 4 | Archivo .neu externo | → 5 |
| 5 | Dinámicas y octavas | → 6 |
| 6 | Silencios | → fin |

Las secciones se encadenan con `control.after { }` — sin posiciones fijas.

## Ornamentos Disponibles

| Ornamento | Notación | Descripción |
|-----------|----------|-------------|
| Trill | `tr` | Alternancia rápida con nota superior |
| Mordent | `mor` | Nota + inferior + nota |
| Mordent bajo | `mor(low)` | Nota + superior + nota |
| Turn | `turn` | Figura ornamental |
| Appogiatura | `app` | Nota de gracia |

### Ejemplo de Expansión

```neuma
(2 1/2 tr)  # Entrada: Sol con trino

# Transcriptor expande a:
# (3 1/8) (2 1/8) (3 1/8) (2 1/8)  # La-Sol-La-Sol
```

## Dinámicas

| Símbolo | Velocity |
|---------|----------|
| ppp | ~16 |
| pp | ~32 |
| p | ~48 |
| mp | ~64 |
| mf | ~80 |
| f | ~96 |
| ff | ~112 |
| fff | ~127 |

## Cambios de Octava

```neuma
(0 +o1)   # Una octava arriba
(0 +o2)   # Dos octavas arriba
(0 -o1)   # Una octava abajo
```

## Cargar Archivo .neu

```ruby
# Cargar archivo
serie = Neumalang.parse_file('melody.neu', decode_with: decoder)

# O desde ruta absoluta
neu_file = File.join(File.dirname(__FILE__), 'melody.neu')
serie = Neumalang.parse_file(neu_file, decode_with: decoder)
```

## Estructuras Paralelas

```neuma
# Dos voces en paralelo
[ @voz1 || @voz2 ]

# Tres voces
[ @soprano || @alto || @bajo ]
```

## Conversión de Tipos

| Tipo | Descripción |
|------|-------------|
| Neuma | Texto notación |
| GDV | Grade-Duration-Velocity (datos abstractos) |
| PDV | Pitch-Duration-Velocity (MIDI-ready) |

```ruby
# Neuma → GDV (via decoder)
gdv = decoder.decode(neuma)

# GDV → PDV (via scale)
pdv = gdv.to_pdv(scale)

# PDV → MIDI (via voice)
voice.note(**pdv)
```

## Buenas prácticas

- **`Neumalang.parse_file` para archivos `.neu` externos**: Separa la notación musical del código Ruby. Los archivos `.neu` permiten variables, operaciones (`.reverse`) y estructuras paralelas (`||`), haciendo la composición más legible.
- **Transcriptor con procesadores individuales**: Crea el `Transcriptor` con una lista explícita de procesadores (`Trill.new`, `Mordent.new`, etc.) para controlar qué ornamentos se expanden y con qué parámetros.
- **`decoder.base` reset entre secciones**: El `NeumaDecoder` mantiene estado (último grado, octava, dinámica). Resetea con `decoder.base = { grade: 0, octave: 0, duration: 1/4r, velocity: 1 }` al empezar una nueva sección desde cero.
- **`using Musa::Extension::Neumas` en cada archivo**: Los refinements de Ruby son de ámbito de archivo. Cada `.rb` que use `.to_neumas` necesita su propio `using`.
- **`control.after { }` para encadenar secciones**: En vez de fijar posiciones `at` con gaps arbitrarios, usa `.after` del control devuelto por `play`. Cada sección arranca automáticamente al terminar la anterior, sin tiempos muertos.
