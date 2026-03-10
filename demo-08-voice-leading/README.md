# Demo 08: Voice Leading - Sistema de Reglas

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

## Descripción

Genera voicings SATB para una progresión con **modulación** usando Rules con **control externo**. Un único Rules define grows (inversión, duplicación) y cuts (locales + conducción de voces). Un bucle externo recorre la progresión acorde por acorde, pasando los voicings anteriores como parámetros para que los cuts de conducción puedan filtrar.

### Progresión

```
C: I → IV → V  →  G: IV → V  →  C: IV → V → I
                ↑                ↑
            pivote C:V=G:I    vuelta a C
```

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Arquitectura: Rules + control externo

### Un solo Rules con todos los constraints

```
apply([chord], prev_pitches: ..., prev2_pitches: ...)
  │
  ├── grow 'inversión'      → 3 ramas (fundamental, 1ª, 2ª)
  ├── grow 'duplicación'    → 3 ramas (root↑, root↓, fifth↑)
  │                           = 9 candidatos
  ├── cut 'rango SATB'         ← local
  ├── cut 'separación voces'   ← local
  ├── cut 'movimiento máximo'  ← usa prev_pitches
  ├── cut 'quintas paralelas'  ← usa prev_pitches
  ├── cut 'movimiento contrario' ← usa prev_pitches + prev2_pitches
  └── cut 'octavas paralelas'  ← usa prev_pitches
```

Los cuts locales no usan parámetros — filtran independientemente del contexto. Los cuts de conducción reciben `prev_pitches:` (voicing anterior) y `prev2_pitches:` (dos pasos atrás) para verificar reglas entre acordes.

### Control externo

```ruby
sequences = [[]]  # Secuencias válidas acumuladas

progression_steps.each do |step|
  chord = step[:scale].send(step[:func]).chord
  new_sequences = []

  sequences.each do |seq|
    tree = voicing_rules.apply([chord],
      prev_pitches:  seq[-1],
      prev2_pitches: seq[-2])
    voicings = tree.combinations.map(&:last)

    voicings.each { |v| new_sequences << seq + [v.pitches] }
  end

  sequences = new_sequences
end
```

En cada paso de la progresión, para cada secuencia acumulada:
1. Llama a Rules con el acorde nuevo + los 2 voicings anteriores
2. Rules genera 9 variantes y las filtra con todos los cuts
3. Los voicings supervivientes extienden la secuencia

Las secuencias que no producen voicings válidos desaparecen. Al final, solo sobreviven las progresiones completas con conducción correcta.

### Cuts

| Cut | Contexto | Restricción |
|-----|----------|-------------|
| `'rango SATB'` | local | Bajo 40–60, tenor 48–67, alto 55–74, soprano 60–81 |
| `'separación voces'` | local | Máximo 1 octava entre voces adyacentes |
| `'movimiento máximo'` | `prev_pitches` | Total ≤ 24 semitonos entre voicings consecutivos |
| `'quintas paralelas'` | `prev_pitches` | Prohíbe 5ªs justas paralelas entre pares de voces |
| `'movimiento contrario'` | `prev_pitches` + `prev2_pitches` | Si una voz bajó, debe subir o mantenerse (y viceversa) |
| `'octavas paralelas'` | `prev_pitches` | Prohíbe 8ªs paralelas entre pares de voces |

### Escalas de voicing

| Escala | Root MIDI | Uso |
|--------|-----------|-----|
| C mayor | 48 (C3) | Acordes en C: I, IV, V |
| G mayor | 43 (G2) | Acordes en G: IV (C3), V (D3) |

## Configuración DAW

Usa el proyecto DAW compartido (`daw-bitwig/` o `daw-live/`). Ver [README principal](../README.md#proyecto-daw-compartido).

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Soprano | 1 | Voz superior |
| Alto | 2 | Voz media-alta |
| Tenor | 3 | Voz media-baja |
| Bajo | 4 | Voz inferior |

## API de Chord para voicings

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

- **Rules + control externo para contexto progresivo**: Los grows generan variantes del acorde, los cuts filtran con constraints locales Y de conducción. El bucle externo pasa `prev_pitches:` y `prev2_pitches:` como parámetros de `apply()`, manteniendo Rules sin estado y el control explícito.
- **Parámetros con `nil` por defecto para cuts graduales**: Los cuts de conducción declaran `prev_pitches: nil, prev2_pitches: nil`. En el primer paso (sin historia), los parámetros son `nil` y los cuts se saltan. En pasos posteriores, se activan progresivamente. Esto permite un solo Rules para todos los pasos.
- **Modulación con acorde pivote**: El V de C (Sol mayor) es simultáneamente I de G. Se define como `c_major.dominant` y el siguiente paso usa `g_major.subdominant`. Dos escalas en registros bajos (C3, G2) mantienen las tríadas en rango SATB.
- **`with_move` para inversiones, `with_duplicate` para doblar voces**: `with_move(root: 1)` mueve la fundamental una octava arriba (inversión). `with_duplicate(root: -1)` añade una copia una octava abajo (duplicación para SATB). Ambos retornan un Chord nuevo.
