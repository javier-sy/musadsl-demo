# Demo 07: Scale Navigator - Navegación Armónica

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

## Descripción

Exploración completa del sistema de escalas de musa-dsl: tipos de escalas, modos griegos, escalas exóticas, construcción de acordes y modulación entre tonalidades.

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Secciones

La demo usa el sistema de eventos (`on`/`launch`) para encadenar 4 secciones:

### 1. Modos griegos (`:greek_modes`)
Los 7 modos construidos sobre Do, destacando Mayor (Jónico) y Menor (Eólico):
- Jónico (Mayor) ★
- Dórico
- Frigio
- Lidio
- Mixolidio
- Eólico (Menor) ★
- Locrio

Cada modo muestra la escala completa (8 notas) seguida de su acorde tónica.

### 2. Escalas exóticas (`:exotic_scales`)
- Húngara menor
- Tonos enteros (Whole tone)
- Disminuida (half-whole)

Patrón melódico ascendente-descendente con bajo pedal.

### 3. Progresión armónica (`:harmonic_progression`)
Progresión I - IV - V7 - I (cadencia perfecta) usando:
- `scale.tonic.chord` - Tríada de tónica
- `scale.subdominant.chord` - Tríada de subdominante
- `scale.dominant.chord(:seventh)` - Acorde de séptima de dominante

### 4. Índices extendidos (`:extended_navigation`)
Demuestra que `scale[n]` acepta cualquier entero:
- Índices negativos (-2, -1) → octavas inferiores
- Índices > 6 (7, 8, 9) → octavas superiores

## Configuración DAW

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | `Main` | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Instrumento sugerido |
|-------|------------|---------------------|
| Melodía | 1 | Piano, Flauta |
| Acordes | 2 | Strings, Pad |
| Bajo | 3 | Contrabajo, Synth Bass |

**Pistas a crear:** 3 pistas MIDI (melodía + armonía + bajo).

**Sincronización:** Master (musa-dsl controla el tempo a 80 BPM).

## API de Escalas

### Crear una escala
```ruby
# Escala mayor desde C4 (MIDI 60)
scale = Scales.et12[440.0].major[60]

# Escala menor desde A3 (MIDI 57)
scale = Scales.et12[440.0].minor[57]

# Modo dórico desde D4 (MIDI 62)
scale = Scales.et12[440.0].dorian[62]
```

### Acceder a grados
```ruby
scale = Scales.et12[440.0].major[60]

# Por índice numérico
scale[0].pitch   # => 60 (Do)
scale[1].pitch   # => 62 (Re)
scale[4].pitch   # => 67 (Sol)
scale[7].pitch   # => 72 (Do octava superior)

# Por función armónica
scale.tonic.pitch       # => 60 (I)
scale.supertonic.pitch  # => 62 (II)
scale.dominant.pitch    # => 67 (V)
scale[:I].pitch         # => 60 (alternativa por símbolo)
scale[:V].pitch         # => 67

# Número de grados de la escala
scale.kind.class.grades # => 7 (escalas diatónicas)

# Índices negativos y extendidos
scale[-1].pitch  # => 59 (Si, debajo de la tónica)
scale[8].pitch   # => 74 (Re, segunda octava)
```

### Tipos de escalas disponibles
```ruby
# Escalas básicas
.major          # Mayor (Jónico)
.minor          # Menor natural (Eólico)
.harmonic_minor # Menor armónica
.melodic_minor  # Menor melódica

# Modos griegos
.dorian         # Dórico
.phrygian       # Frigio
.lydian         # Lidio
.mixolydian     # Mixolidio
.locrian        # Locrio

# Pentatónicas
.pentatonic_major
.pentatonic_minor

# Jazz/Blues
.blues
.bebop

# Simétricas
.whole_tone     # Tonos enteros
.diminished     # Disminuida (tono-semitono)
.chromatic      # Cromática

# Exóticas
.hungarian_minor
.byzantine
.japanese
# ... y más
```

### Construcción de acordes (API de acordes)
```ruby
scale = Scales.et12[440.0].major[60]

# Tríada de tónica (I)
chord_I = scale.tonic.chord
chord_I.pitches  # => [60, 64, 67] (Do-Mi-Sol)

# Tríada de dominante (V)
chord_V = scale.dominant.chord
chord_V.pitches  # => [67, 71, 74] (Sol-Si-Re)

# Séptima de dominante (V7)
v7 = scale.dominant.chord(:seventh, allow_chromatic: false)
v7.pitches  # => [67, 71, 74, 77] (Sol-Si-Re-Fa)

# Acceso a notas individuales del acorde
chord_I.root.pitch   # => 60
chord_I.third.pitch  # => 64
chord_I.fifth.pitch  # => 67

# Duplicar notas (para voicing)
chord_with_octave = chord_I.duplicate(root: 1)
chord_with_octave.pitches  # Incluye raíz duplicada octava arriba

# Progresión usando funciones armónicas
[:tonic, :subdominant, :dominant, :tonic].each do |func|
  root_note = scale.send(func)
  chord = root_note.chord
  bass = root_note.pitch - 12
  puts "#{func}: #{chord.pitches}"
end
```

### Modulación (usando funciones armónicas)
```ruby
# Escala base para definir relaciones
base_scale = Scales.et12[440.0].major[60]  # Do Mayor

# Ciclo de quintas: I -> V -> II -> I
modulations = [:tonic, :dominant, :supertonic, :tonic]

modulations.each do |func|
  # Obtener centro tonal desde función armónica
  tonal_center = base_scale.send(func)
  new_scale = Scales.et12[440.0].major[tonal_center.pitch]
  puts "#{func}: pitch #{tonal_center.pitch}"
  # tonic: 60 (Do), dominant: 67 (Sol), supertonic: 62 (Re)
end
```

## Conceptos musicales

### Modos griegos
Los 7 modos se construyen empezando la escala mayor desde cada grado:
- **Jónico** (I): Mayor natural
- **Dórico** (II): Menor con 6ª mayor
- **Frigio** (III): Menor con 2ª menor (sonido español)
- **Lidio** (IV): Mayor con 4ª aumentada (sonido brillante)
- **Mixolidio** (V): Mayor con 7ª menor (sonido blues/rock)
- **Eólico** (VI): Menor natural
- **Locrio** (VII): Disminuido (inestable)

### Funciones armónicas
- **Tónica (I)** `scale.tonic`: Reposo, resolución
- **Supertónica (II)** `scale.supertonic`: Movimiento hacia subdominante
- **Mediante (III)** `scale.mediant`: Función tónica secundaria
- **Subdominante (IV)** `scale.subdominant`: Movimiento, preparación
- **Dominante (V)** `scale.dominant`: Tensión, necesidad de resolver
- **Submediante (VI)** `scale.submediant`: Función tónica sustituta
- **Sensible (VII)** `scale.leading_tone`: Tensión hacia tónica

## Próximos pasos

- **Demo 08:** Voice Leading - Conducción de voces con reglas
- **Demo 09:** Darwin - Selección evolutiva de motivos
