# Demo 08: Voice Leading - Sistema de Reglas

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

## Descripción

Demostración del sistema de **Rules** para generar progresiones de acordes y melodías con conducción de voces controlada. El sistema funciona como un L-system o gramática formal, con reglas de crecimiento (grow) y poda (cut/prune).

Usa el sistema de eventos (`on`/`launch`) para encadenar secciones dinámicamente.

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Secciones

### 1. Melodía con reglas `:melody_rules`
Genera melodías de 8 notas aplicando:
- Rango: C4-G5
- Sin repetición inmediata
- Sin saltos grandes consecutivos
- Pitch inicial: `scale.tonic.pitch`

### 2. Progresión armónica `:chord_progression`
Genera progresiones de acordes usando funciones armónicas:
- I puede ir a ii, IV, V, vi
- V resuelve a I o vi
- Termina en tónica
- Usa `scale.send(func_name).chord.pitches` para construir acordes

### 3. Conducción de voces `:voice_leading`
Genera voicings con movimiento mínimo entre acordes.
- Progresión: I - ii - IV - V - I definida con funciones armónicas
- Acordes construidos con `scale.tonic.chord`, `scale.supertonic.chord`, etc.

### 4. Contrapunto a dos voces `:counterpoint`
Genera una línea de contrapunto sobre un cantus firmus:
- Cantus definido con grados de escala: `[0, 1, 2, 3, 4, 3, 2, 1, 0]`
- Solo intervalos consonantes
- Sin quintas paralelas
- Sin saltos grandes

## Flujo de eventos

```
:melody_rules → :chord_progression → :play_progression_chord (loop)
                                          ↓
:voice_leading → :play_voicing (loop) → :counterpoint → :play_counterpoint (loop)
                                                              ↓
                                                          :finale
```

## Configuración DAW

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | `Main` | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Voz | Rango sugerido | Instrumento sugerido |
|-------|------------|-----|----------------|---------------------|
| Soprano | 1 | Aguda | C4-C6 | Flauta, Violín |
| Alto | 2 | Media-alta | G3-G5 | Oboe, Viola |
| Tenor | 3 | Media | C3-C5 | Clarinete, Cello |
| Bajo | 4 | Grave | E2-E4 | Fagot, Contrabajo |

**Pistas a crear:** 4 pistas MIDI para coral a 4 voces.

**Instrumento alternativo:** Choir, Strings, u Organ para las 4 voces.

**Sincronización:** Master (musa-dsl controla el tempo a 72 BPM).

## API de Rules

### Estructura básica
```ruby
rules = Rules.new do
  # Reglas de crecimiento: generan ramas
  grow 'nombre regla' do |objeto, history|
    branch(nuevo_objeto)  # Crear nueva rama
  end

  # Reglas de poda: eliminan ramas inválidas
  cut 'nombre regla' do |objeto, history|
    prune if condicion_invalida  # Podar rama
  end

  # Condición de fin
  ended_when do |objeto, history|
    history.size >= longitud_deseada
  end
end

# Ejecutar
tree = rules.apply(objeto_inicial)
resultados = tree.combinations  # Todas las secuencias válidas
```

### Reglas de crecimiento (grow)
```ruby
grow 'next note' do |pitch, history|
  # pitch: objeto actual
  # history: array de objetos anteriores

  # Crear múltiples ramas posibles
  [-2, -1, 1, 2].each do |interval|
    branch(pitch + interval)
  end
end
```

### Reglas de poda (cut)
```ruby
cut 'range limit' do |pitch, history|
  # Eliminar ramas fuera de rango
  prune if pitch < 60 || pitch > 84
end

cut 'no parallel fifths' do |chord, history|
  if history.any?
    # Analizar relación con acorde anterior
    prune if has_parallel_fifths?(history.last, chord)
  end
end
```

### Condición de fin
```ruby
ended_when do |objeto, history|
  # Terminar cuando se alcance la longitud deseada
  history.size >= 8
end
```

### Extraer resultados
```ruby
tree = rules.apply(semilla)

# Todas las secuencias válidas completas (paths con estados intermedios)
sequences = tree.combinations
# => [[obj1, obj2, obj3], [obj1, obj4, obj5], ...]

# IMPORTANTE: .map(&:last) extrae el estado final de cada path
# Cada path es acumulativo, conteniendo todos los estados intermedios
# El último elemento (.last) es el resultado completo
final_states = tree.combinations.map(&:last)

# Objetos finales válidos
endpoints = tree.fish
# => [obj3, obj5, ...]

# Seleccionar aleatoriamente
selected = final_states.sample
```

**Nota:** Esta demo usa el modelo acumulativo donde cada `grow` añade al array de estados. Por eso `tree.combinations.map(&:last)` extrae el resultado final completo de cada path.

## Ejemplo: Progresión de acordes

```ruby
chord_rules = Rules.new do
  grow 'chord progression' do |chord, history|
    case chord
    when :I   then branch(:ii); branch(:IV); branch(:V)
    when :ii  then branch(:V)
    when :IV  then branch(:I); branch(:V)
    when :V   then branch(:I); branch(:vi)
    when :vi  then branch(:ii); branch(:IV)
    end
  end

  cut 'no immediate repeat' do |chord, history|
    prune if history.last == chord
  end

  ended_when do |chord, history|
    history.size >= 3 && chord == :I
  end
end

tree = chord_rules.apply(:I)
progressions = tree.combinations
# => [[:I, :IV, :V, :I], [:I, :ii, :V, :I], ...]

# Convertir símbolos a acordes usando API de funciones armónicas
scale = Scales.et12[440.0].major[60]
symbol_to_function = {
  I: :tonic, ii: :supertonic, IV: :subdominant,
  V: :dominant, vi: :submediant, vii: :leading_tone
}

progressions.first.each do |chord_symbol|
  func_name = symbol_to_function[chord_symbol]
  root_note = scale.send(func_name)
  chord = root_note.chord
  puts "#{chord_symbol}: #{chord.pitches}"
end
```

## Ejemplo: Conducción de voces

```ruby
# Definir progresión con funciones armónicas
scale = Scales.et12[440.0].major[60]
chord_sequence = [:tonic, :supertonic, :subdominant, :dominant, :tonic]

# Pre-calcular acordes
progression_chords = chord_sequence.map { |func|
  scale.send(func).chord.pitches
}

voice_leading_rules = Rules.new do
  grow 'next voicing' do |state, history|
    current_pitches, chord_index = state
    if chord_index < progression_chords.size
      next_chord = progression_chords[chord_index]
      # Generar variaciones de octava
      branch([next_chord, chord_index + 1])
      branch([next_chord.map { |p| p + 12 }, chord_index + 1])
    end
  end

  cut 'max movement' do |state, history|
    if history.any?
      current_pitches = state[0]
      prev_pitches = history.last[0]
      total_movement = current_pitches.zip(prev_pitches).sum { |c, p| (c - p).abs }
      prune if total_movement > 12
    end
  end

  ended_when do |state, history|
    history.size >= chord_sequence.size - 1
  end
end
```

## Conceptos de contrapunto

### Intervalos consonantes
- **Perfectas**: Unísono, 5ª justa, 8ª
- **Imperfectas**: 3ª mayor/menor, 6ª mayor/menor

### Reglas clásicas
1. **No quintas paralelas**: Dos quintas justas consecutivas
2. **No octavas paralelas**: Dos octavas consecutivas
3. **Movimiento contrario**: Preferir que las voces se muevan en direcciones opuestas
4. **Resolver sensible**: La 7ª escala sube a la tónica

## Aplicaciones musicales

- **Armonización coral**: Generar voicings de 4 partes
- **Contrapunto**: Generar líneas melódicas compatibles
- **Progresiones**: Explorar todas las progresiones válidas
- **Voicings de jazz**: Aplicar reglas de spacing y voice leading

## Próximos pasos

- **Demo 09:** Darwin - Selección evolutiva de motivos
- **Demo 10:** Grammar - Gramáticas generativas
