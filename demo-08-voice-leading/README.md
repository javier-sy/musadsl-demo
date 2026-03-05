# Demo 08: Voice Leading - Sistema de Reglas

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

## Descripción

Genera voicings SATB para una progresión armónica usando **dos niveles de Rules**. El nivel 1 genera voicings acústicamente válidos para cada acorde. El nivel 2 construye el árbol completo de la progresión y poda las secuencias que violan reglas de conducción de voces. Solo las progresiones completas que cumplen todas las restricciones sobreviven.

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Arquitectura de dos niveles

### Nivel 1: Voicings locales (por acorde)

Genera voicings SATB a partir de tríadas usando constraints que no dependen del contexto.

| Grow | Dimensión | Ramas |
|------|-----------|-------|
| `'inversión'` | Qué nota va en el bajo | Fundamental, 1ª inv, 2ª inv |
| `'duplicación'` | Qué nota se dobla para 4 voces | Root↑, root↓, fifth↑ |

| Cut | Restricción |
|-----|-------------|
| `'rango SATB'` | Bajo 40–60, tenor 48–67, alto 55–74, soprano 60–81 |
| `'separación voces'` | Máximo 1 octava entre voces adyacentes |

**Resultado:** Lista de voicings válidos por acorde (subconjunto de 9 candidatos).

### Nivel 2: Conducción de voces (progresión completa)

Construye el árbol de todas las secuencias posibles y poda las que violan reglas entre acordes consecutivos. Cada grow ramifica con los voicings del nivel 1.

| Grow | Paso | Ramas |
|------|------|-------|
| `'voicing del I'` | 1º acorde | N voicings válidos del I |
| `'voicing del IV'` | 2º acorde | M voicings válidos del IV |
| `'voicing del V'` | 3º acorde | P voicings válidos del V |
| `'voicing del I'` | 4º acorde | Q voicings válidos del I |

| Cut | Restricción |
|-----|-------------|
| `'movimiento máximo'` | Total ≤ 24 semitonos entre voicings consecutivos |
| `'quintas paralelas'` | Prohíbe 5ªs justas paralelas entre pares de voces |
| `'octavas paralelas'` | Prohíbe 8ªs paralelas entre pares de voces |

**Objeto acumulativo:** Cada grow añade un voicing al array de la secuencia. Los cuts comparan los dos últimos elementos (`sequence[-1]` vs `sequence[-2]`).

**Resultado:** Todas las progresiones completas con conducción de voces válida.

### Flujo

```
Nivel 1 (por acorde):
  tríada → inversión × duplicación → filtros locales → N voicings

Nivel 2 (progresión):
  [] → +I(N) → +IV(M) → +V(P) → +I(Q) → progresiones válidas
       cuts ────────────────────────────→ poda por conducción
```

## Configuración DAW

| Puerto | Dirección |
|--------|-----------|
| Main | musa-dsl → DAW |

| Pista | Canal MIDI |
|-------|------------|
| Soprano | 1 |
| Alto | 2 |
| Tenor | 3 |
| Bajo | 4 |

## API de Rules

### Nivel 1: Grows semánticos con Chord API
```ruby
voicing_rules = Rules.new do
  grow 'inversión' do |chord|
    branch chord                                # Posición fundamental
    branch chord.with_move(root: 1)             # 1ª inversión
    branch chord.with_move(root: 1, third: 1)   # 2ª inversión
  end

  grow 'duplicación' do |chord|
    branch chord.with_duplicate(root: 1)        # Doblar fundamental
    branch chord.with_duplicate(fifth: 1)       # Doblar quinta
  end

  cut 'rango SATB' do |chord|
    pitches = chord.pitches
    prune if pitches[0] < 40 || pitches[0] > 60 if pitches.size >= 4
  end
end

# Aplicar por acorde
tree = voicing_rules.apply([scale.tonic.chord])
voicings = tree.combinations.map(&:last)
```

### Nivel 2: Objeto acumulativo con cuts entre pasos
```ruby
progression_rules = Rules.new do
  # Cada grow ramifica con los voicings pre-generados
  grow "voicing del I" do |sequence|
    i_voicings.each { |chord| branch sequence + [chord.pitches] }
  end

  grow "voicing del IV" do |sequence|
    iv_voicings.each { |chord| branch sequence + [chord.pitches] }
  end

  # Cuts comparan los dos últimos elementos de la secuencia
  cut 'quintas paralelas' do |sequence|
    if sequence.size >= 2
      curr, prev = sequence[-1], sequence[-2]
      # ... detectar quintas paralelas entre curr y prev
    end
  end
end

# Seed = array vacío; el objeto crece con cada grow
tree = progression_rules.apply([[]])
progressions = tree.combinations.map(&:last)
```

### API de Chord para voicings
```ruby
chord = scale.tonic.chord                   # Tríada: [60, 64, 67]

# Inversiones (with_move mueve posiciones por octavas)
chord.with_move(root: 1)                    # 1ª inversión: [64, 67, 72]
chord.with_move(root: 1, third: 1)          # 2ª inversión: [67, 72, 76]

# Duplicaciones (with_duplicate añade notas)
chord.with_duplicate(root: -1)              # [48, 60, 64, 67]
chord.with_duplicate(root: 1)               # [60, 64, 67, 72]

# Pitches siempre ordenados de grave a agudo
chord.pitches                               # => [60, 64, 67]
```

## Buenas prácticas

- **Dos niveles de Rules para separar concerns**: El nivel 1 filtra lo acústicamente imposible (rangos, separación). El nivel 2 filtra lo musicalmente incorrecto (conducción de voces). Cada nivel tiene sus propios grows y cuts, sin mezclar restricciones locales con contextuales.
- **Objeto acumulativo para llevar la historia**: En el nivel 2, el objeto es un array que crece con cada grow (`sequence + [pitches]`). Los cuts comparan `sequence[-1]` con `sequence[-2]`. Esto sigue el patrón estándar de Rules — el objeto lleva su propio contexto.
- **Árbol completo para explorar todas las combinaciones**: A diferencia de seleccionar voicings paso a paso (greedy), el árbol completo explora TODAS las secuencias posibles. Un voicing del I que parece "malo" para el IV puede ser "perfecto" para la progresión completa I→IV→V→I.
- **`with_move` para inversiones, `with_duplicate` para doblar voces**: `with_move(root: 1)` mueve la fundamental una octava arriba (inversión). `with_duplicate(root: -1)` añade una copia una octava abajo (duplicación para SATB). Ambos retornan un Chord nuevo.
