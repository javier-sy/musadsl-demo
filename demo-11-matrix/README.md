# Demo 11: Matrix - Gestos Multidimensionales

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

## Descripción

Demostración del sistema **Matrix** para crear y manipular gestos musicales multidimensionales. Las matrices permiten representar trayectorias en espacios de parámetros (tiempo, pitch, velocity, etc.) y aplicar transformaciones geométricas.

**Flujo de trabajo:**
1. `Matrix[[time, pitch, ...], ...]` - crear matriz de puntos
2. `matrix.to_p(time_dimension: 0)` - convertir a P sequences
3. `p.to_timed_serie()` - convertir P a serie temporizada
4. `play_timed(serie)` - reproducir con timing absoluto

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
| Gestos melódicos | 1 | Secuencias de la matriz |
| Acordes/texturas | 2 | Texturas armónicas |

## Secciones

La demo usa eventos (`on`/`launch`) para encadenar 7 secciones:

### 1. Matriz 2D (`:section_1`)
Matriz básica con tiempo y pitch. Demuestra el flujo completo: Matrix → to_p → to_timed_serie → play_timed.

### 2. Matriz 3D (`:section_2`)
Añade velocity como tercera dimensión: crescendo al clímax y decrescendo.

### 3. Transposición (`:section_3`)
Transformación matricial con suma de matrices para transponer el gesto una tercera mayor (+4 semitonos).

### 4. Escalado temporal (`:section_4`)
Augmentación (x2) y disminución (x0.5) del ritmo usando producto Hadamard sobre la columna de tiempo.

### 5. Inversión melódica (`:section_5`)
Reflejo del contorno melódico alrededor de un eje usando suma y producto Hadamard.

### 6. Espiral 2D → polifonía emergente (`:section_6`)
Genera una espiral de Arquímedes en 2D (x, y). Al usar `to_p(time_dimension: 0)`, los fragmentos donde la espiral "retrocede" en X se convierten en líneas P separadas. La polifonía emerge naturalmente de la geometría: cada vuelta de la espiral genera nuevas voces superpuestas.

### 7. Condensación de matrices (`:section_7`)
Fusión automática de matrices que comparten puntos extremos.

## API de Matrix

### Activar el refinamiento
```ruby
using Musa::Extension::Matrix
```

### Crear matrices
```ruby
# Es preferible usar Rational para tiempos
# Matriz 2D: [tiempo, pitch]
melody = Matrix[
  [0r, 60],
  [1/2r, 62],
  [1r, 64]
]

# Matriz 3D: [tiempo, pitch, velocity]
gesture = Matrix[
  [0r, 60, 100],
  [1/2r, 62, 110],
  [1r, 64, 120]
]
```

### Convertir a P sequence y reproducir
```ruby
# 1. Convertir matriz a P sequences
#    time_dimension indica qué columna es el tiempo
p_sequences = gesture.to_p(time_dimension: 0)
# => Array de P sequences (normalmente 1)

# 2. Formato P: [value, duration, value, duration, ..., value]
#    Cada value es un array extendido con V module
#    P = [[60, 100], 1/2r, [62, 110], 1/2r, [64, 120]].extend(P)

# 3. Convertir P a timed serie
p_seq = p_sequences.first
timed_serie = p_seq.to_timed_serie(base_duration: 1r)
# => Serie de {time: X, value: [pitch, velocity]}

# 4. Reproducir con play_timed
#    Es preferible usar duraciones Rational alineadas al tick
play_timed timed_serie do |value, time:, started_ago:, control:|
  pitch, velocity = value[0].to_i, value[1].to_i
  voice.note(pitch, velocity: velocity, duration: 1/2r)
end
```

### Mantener tiempo en valores
```ruby
# Con keep_time: true, el tiempo permanece en cada valor
p_with_time = gesture.to_p(time_dimension: 0, keep_time: true)
# P = [[0r, 60, 100], 1/2r, [1/2r, 62, 110], 1/2r, [1r, 64, 120]]
```

### Transformaciones matriciales

Las transformaciones usan operaciones estándar de `Matrix` de Ruby:

```ruby
original = Matrix[[0r, 60], [1/4r, 64], [1/2r, 67], [3/4r, 64], [1r, 60]]

# Transposición: suma de matrices (añadir +4 semitonos a pitch)
transposed = original + Matrix[*[[0, 4]] * original.row_count]

# Escalado temporal: producto Hadamard (tiempo x2, pitch x1)
augmented = original.hadamard_product(Matrix[*[[2, 1]] * original.row_count])

# Disminución: producto Hadamard (tiempo x0.5, pitch x1)
diminished = original.hadamard_product(Matrix[*[[1/2r, 1]] * original.row_count])

# Inversión melódica: espejo alrededor de un eje
axis = 60
inverted = Matrix[*[[0, 2 * axis]] * original.row_count] +
           original.hadamard_product(Matrix[*[[1, -1]] * original.row_count])
```

## Polifonía emergente con espiral

Cuando una matriz "retrocede" en la dimensión de tiempo, `to_p` genera múltiples P sequences — una por cada fragmento que avanza. Esto convierte trayectorias geométricas en polifonía:

```ruby
# Espiral de Arquímedes: x=r*cos(θ), y=r*sin(θ)
points = num_points.times.map do |i|
  theta = i * (num_turns * 2 * Math::PI) / num_points
  r = 1 + theta / (2 * Math::PI)
  x = r * Math.cos(theta)  # → tiempo (normalizar a Rational)
  y = r * Math.sin(theta)  # → pitch (normalizar a rango MIDI)
  [Rational(x_normalized.round(4)), pitch_normalized.round]
end

spiral = Matrix[*points]
p_sequences = spiral.to_p(time_dimension: 0)
# => Múltiples P sequences (una por fragmento que avanza en X)

# Reproducir todas en paralelo → polifonía emergente
controls = p_sequences.map do |p_seq|
  play_timed p_seq.to_timed_serie(base_duration: 1r) do |pitches, **|
    voice.note(pitches, velocity: 75, duration: 1/16r)
  end
end
```

## Condensación de matrices

Matrices que comparten puntos extremos se fusionan automáticamente:

```ruby
phrase1 = Matrix[[0r, 60], [1r, 62]]
phrase2 = Matrix[[1r, 62], [2r, 64]]  # Comparte punto final de phrase1

# Se fusionan al convertir
# IMPORTANTE: [array_of_matrices].to_p() retorna [[P_sequence]]
# Necesita .first.first para obtener la P sequence
condensed_ps = [phrase1, phrase2].to_p(time_dimension: 0)
p_seq = condensed_ps.first.first  # Doble .first por estructura anidada
timed_serie = p_seq.to_timed_serie(base_duration: 1r)
```

## Aplicaciones musicales

- **Gestos expresivos**: Curvas de pitch bend, crescendos, vibratos
- **Trayectorias espaciales**: Movimiento de sonido en cuadrafonía/surround
- **Síntesis paramétrica**: Control de filtros, envolventes, moduladores
- **Visualización**: Representación gráfica de estructuras musicales
- **Transformaciones seriales**: Operaciones sobre filas de doce tonos

## Dimensiones típicas

| Columna | Parámetro | Rango típico |
|---------|-----------|--------------|
| 0 | Tiempo | 0r - nr (beats) |
| 1 | Pitch | 0-127 (MIDI) |
| 2 | Velocity | 0-127 |
| 3 | Duration | 0r - nr |
| 4 | Pan | 0r-1r |
| 5 | CC values | 0-127 |

**Nota:** Es preferible usar Rational (0r, 1/2r, 1r) para tiempos y duraciones.
El Sequencer codifica internamente el tiempo como Rational, por lo que usar Float
puede causar problemas de precisión en la conversión.

## Buenas prácticas

- **Rational para tiempos en Matrix**: Usa siempre `Rational` (`0r`, `1/2r`, `1r`) para la columna de tiempo. El Sequencer trabaja internamente con Rational — usar Float causa errores de precisión en la conversión a timed series.
- **`using Musa::Extension::Matrix` en cada archivo**: Al igual que con Neumas, el refinement `Matrix` es de ámbito de archivo. Cada archivo `.rb` que use `.to_p()` necesita su propio `using Musa::Extension::Matrix`.
- **Condensación automática de matrices con puntos compartidos**: Cuando dos matrices comparten un punto extremo (el último punto de una coincide con el primero de la siguiente), `[m1, m2].to_p()` las fusiona automáticamente en una sola P sequence continua.
