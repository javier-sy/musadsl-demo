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

## Configuración DAW

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | `Main` | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Instrumento sugerido |
|-------|------------|---------------------|
| Gestos melódicos | 1 | Synth Lead, Piano |
| Acordes/texturas | 2 | Pad, Strings |

**Pistas a crear:** 2 pistas MIDI.

**Sincronización:** Master (musa-dsl controla el tempo a 90 BPM).

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
```ruby
# Transponer (añadir a columna de pitch)
transposed = gesture.map.with_index do |val, row, col|
  col == 1 ? val + 4 : val  # +4 semitonos (tercera mayor)
end

# Escalar tiempo (multiplicar columna de tiempo)
augmented = gesture.map.with_index do |val, row, col|
  col == 0 ? val * 2 : val  # x2 tiempo
end

# Inversión melódica (reflejar pitch)
axis = 60
inverted = gesture.map.with_index do |val, row, col|
  col == 1 ? axis - (val - axis) : val
end
```

## Operaciones de transformación

### Transposición
```ruby
# Añadir intervalo a todos los pitches
interval = 4  # tercera mayor
transposed = matrix.map.with_index do |v, r, c|
  c == pitch_column ? v + interval : v
end
```

### Escalado temporal
```ruby
# Augmentación: valores de tiempo x factor
augmented = matrix.map.with_index do |v, r, c|
  c == time_column ? v * 2 : v
end

# Disminución
diminished = matrix.map.with_index do |v, r, c|
  c == time_column ? v / 2 : v
end
```

### Inversión melódica
```ruby
# Espejo alrededor de un eje
axis_pitch = 60
inverted = matrix.map.with_index do |v, r, c|
  c == pitch_column ? axis_pitch - (v - axis_pitch) : v
end
```

### Retrogradación
```ruby
# Invertir orden de filas (tiempo al revés)
rows = matrix.row_vectors.reverse
retrograde = Matrix[*rows.map(&:to_a)]
```

## Generación procedural

### Espiral
```ruby
# Generar puntos en espiral
points = n.times.map do |i|
  time = i * step
  pitch = base_pitch + i
  velocity = 70 + (Math.sin(i * freq) * amplitude).to_i
  [time, pitch, velocity]
end

spiral = Matrix[*points]
```

### Curva Bézier
```ruby
# Interpolar entre puntos de control
def bezier(t, p0, p1, p2, p3)
  (1-t)**3 * p0 + 3*(1-t)**2*t * p1 + 3*(1-t)*t**2 * p2 + t**3 * p3
end

points = resolution.times.map do |i|
  t = i.to_f / resolution
  [t * duration, bezier(t, 60, 72, 55, 67)]
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
