# Demo 07: Scale Navigator - Navegación Armónica

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

## Descripción

Exploración del sistema de escalas de musa-dsl: modos griegos, escalas exóticas, construcción de acordes con funciones armónicas e índices extendidos.

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Secciones

La demo usa el sistema de eventos (`on`/`launch`) para encadenar 3 secciones:

### 1. Escalas y modos (`:scales`)
9 escalas construidas sobre Do, incluyendo modos griegos y escalas exóticas:
- Mayor (Jónico) ★
- Dórico
- Frigio
- Lidio
- Mixolidio
- Menor (Eólico) ★
- Locrio
- Húngara menor
- Tonos enteros

Cada escala muestra sus grados completos seguidos de su acorde tónica. El número de grados se adapta automáticamente (7 para diatónicas, 6 para tonos enteros).

### 2. Progresión armónica (`:harmonic_progression`)
Progresión I - IV - V7 - I (cadencia perfecta) usando:
- `scale.tonic.chord` — Tríada de tónica
- `scale.subdominant.chord` — Tríada de subdominante
- `scale.dominant.chord(:seventh)` — Acorde de séptima de dominante

### 3. Índices extendidos (`:extended_navigation`)
Demuestra que `scale[n]` acepta cualquier entero:
- Índices negativos (-2, -1) → octavas inferiores
- Índices > 6 (7, 8, 9) → octavas superiores

## Configuración DAW

| Puerto | Dirección |
|--------|-----------|
| Main | musa-dsl → DAW |

| Pista | Canal MIDI |
|-------|------------|
| Melodía | 1 |
| Acordes | 2 |
| Bajo | 3 |

## API de Escalas

### Crear una escala
```ruby
scale = Scales.et12[440.0].major[60]      # Do Mayor (MIDI 60)
scale = Scales.et12[440.0].minor[57]      # La menor (MIDI 57)
scale = Scales.et12[440.0].dorian[62]     # Re Dórico (MIDI 62)
scale = Scales.et12[440.0].send(:lydian)  # Acceso dinámico por símbolo
```

### Acceder a grados
```ruby
scale = Scales.et12[440.0].major[60]

# Por índice numérico
scale[0].pitch   # => 60 (Do)
scale[4].pitch   # => 67 (Sol)
scale[7].pitch   # => 72 (Do octava superior)

# Por función armónica
scale.tonic.pitch       # => 60 (I)
scale.dominant.pitch    # => 67 (V)

# Número de grados
scale.kind.class.grades # => 7

# Índices negativos y extendidos
scale[-1].pitch  # => 59 (Si, debajo de la tónica)
scale[8].pitch   # => 74 (Re, segunda octava)
```

### Tipos de escalas disponibles
```ruby
# Básicas
.major, .minor, .minor_harmonic, .major_harmonic

# Modos griegos
.dorian, .phrygian, .lydian, .mixolydian, .locrian

# Pentatónicas y blues
.pentatonic_major, .pentatonic_minor, .blues, .blues_major

# Simétricas
.whole_tone, .diminished, .chromatic

# Exóticas
.hungarian_minor, .byzantine, .japanese  # y más
```

### Construcción de acordes
```ruby
scale = Scales.et12[440.0].major[60]

# Tríada de tónica (I)
scale.tonic.chord.pitches        # => [60, 64, 67]

# Séptima de dominante (V7)
scale.dominant.chord(:seventh, allow_chromatic: false).pitches
# => [67, 71, 74, 77]

# Progresión dinámica con funciones armónicas
[:tonic, :subdominant, :dominant, :tonic].each do |func|
  chord = scale.send(func).chord
  puts "#{func}: #{chord.pitches}"
end
```

## Funciones armónicas

| Función | Método | Grado |
|---------|--------|-------|
| Tónica | `scale.tonic` | I |
| Supertónica | `scale.supertonic` | II |
| Mediante | `scale.mediant` | III |
| Subdominante | `scale.subdominant` | IV |
| Dominante | `scale.dominant` | V |
| Submediante | `scale.submediant` | VI |
| Sensible | `scale.leading_tone` | VII |

## Buenas prácticas

- **`scale.send(func).chord` para progresiones dinámicas**: Usa `scale.send(:tonic)`, `scale.send(:dominant)`, etc. para construir progresiones a partir de arrays de símbolos. Esto permite parametrizar la armonía sin hardcodear acordes.
- **`.chord(:seventh)` para extensiones**: Llama `.chord(:seventh)` sobre cualquier grado para obtener un acorde de séptima. La calidad (mayor, menor, dominante) se deduce automáticamente del grado en la escala.
- **Índices negativos/extendidos en `scale[n]`**: `scale[-1]` accede al grado inferior a la tónica, `scale[7]` al primer grado de la octava superior. No hay límite — musa-dsl extrapola automáticamente a cualquier octava.
- **`scale.kind.class.grades` para escalas de tamaño variable**: No asumas 7 grados — las pentatónicas tienen 5, tonos enteros 6, cromática 12. Usa `.grades` para iterar correctamente cualquier escala.
