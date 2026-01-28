# Demo 10: Grammar - Gramáticas Generativas

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

## Descripción

Demostración del sistema **GenerativeGrammar** para crear patrones musicales usando gramáticas formales. Permite definir reglas de producción con terminales, operadores de alternación y secuencia, y generar todas las combinaciones posibles.

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Secciones

### 1. Alternación (compases 1-11)
Gramática simple `(a | b).repeat(4)` que genera todas las combinaciones de Do/Mi en 4 posiciones (16 opciones).

### 2. Secuencia (compases 12-24)
Motivos de 2 notas combinados: `(up | down | leap).repeat(3)` genera 27 secuencias posibles.

### 3. Atributos (compases 25-37)
Patrones rítmicos con restricción: solo combinaciones que suman exactamente 1 compás.

### 4. Progresiones armónicas (compases 38-54)
Gramática de acordes que genera progresiones válidas terminando en cadencia auténtica.

### 5. Contenido dinámico (compases 55-62)
Nodos con bloques que generan contenido aleatorio dentro de rangos definidos.

## Configuración DAW

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | `Main` | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Instrumento sugerido |
|-------|------------|---------------------|
| Melodía | 1 | Piano, Vibraphone |
| Acordes | 2 | Pad, Strings |

**Pistas a crear:** 2 pistas MIDI.

**Sincronización:** Master (musa-dsl controla el tempo a 110 BPM).

## API de GenerativeGrammar

### Incluir el módulo
```ruby
include Musa::GenerativeGrammar
```

### Crear nodos terminales con N()
```ruby
# Nodo simple con contenido
a = N('a')
b = N(60)  # Número

# Nodo con atributos
note = N(0, dur: 1/4r, vel: 80)

# Nodo con bloque dinámico
random_note = N(range: :mid) { |parent| rand(3..5) }
```

### Operadores

#### Alternación `|` (or)
```ruby
# Una opción u otra
choice = a | b
# Genera: ['a'], ['b']

# Múltiples opciones
multi = a | b | c
```

#### Secuencia `+` (concatenación)
```ruby
# Una seguida de otra
sequence = a + b
# Genera: ['a', 'b']

# Cadena de secuencias
motif = a + b + c + a
```

#### Combinando operadores
```ruby
# Paréntesis para agrupar
grammar = (a | b) + (c | d)
# Genera: ['a','c'], ['a','d'], ['b','c'], ['b','d']
```

### Modificadores

#### repeat (repetición)
```ruby
# Exactamente N veces
a.repeat(3)     # ['a', 'a', 'a']

# Rango de repeticiones
a.repeat(min: 2, max: 4)  # 2, 3, o 4 veces

# Infinito (usar con limit)
a.repeat  # Requiere .limit() para acotar
```

#### limit (restricción)
```ruby
# Con bloque de condición
(a | b).repeat.limit { |o|
  o.collect { |e| e.attributes[:size] }.sum == 4
}

# Forma simplificada
(a | b).repeat.limit(:size, :sum, :==, 4)
```

### Generar resultados con options()
```ruby
grammar = (a | b).repeat(2)

# Arrays de contenido
grammar.options
# => [['a','a'], ['a','b'], ['b','a'], ['b','b']]

# Contenido unido
grammar.options(content: :join)
# => ['aa', 'ab', 'ba', 'bb']

# Con filtro
grammar.options { |o| o.size == 2 }

# Objetos raw con atributos
grammar.options(raw: true)
```

## Ejemplos musicales

### Melodías con alternación
```ruby
do_note = N(0)
mi_note = N(2)
sol_note = N(4)

# Todas las melodías de 4 notas usando Do, Mi, Sol
grammar = (do_note | mi_note | sol_note).repeat(4)
melodies = grammar.options  # 81 melodías

# Reproducir
melodies.sample.each do |grade|
  pitch = scale[grade].pitch
  voice.note(pitch, duration: 1/4r)
  wait 1/4r
end
```

### Patrones rítmicos con restricción
```ruby
q = N(:q, size: 1/4r)
e = N(:e, size: 1/8r)
h = N(:h, size: 1/2r)

# Solo patrones que suman 1 compás
grammar = (q | e | h).repeat.limit { |o|
  o.collect { |e| e.attributes[:size] }.sum == 1r
}

rhythms = grammar.options(raw: true)
rhythms.each do |pattern|
  durations = pattern.map { |e| e.attributes[:size] }
  # => [1/4r, 1/4r, 1/2r] o [1/8r, 1/8r, 1/4r, 1/2r], etc.
end
```

### Progresiones de acordes
```ruby
I = N(:I)
IV = N(:IV)
V = N(:V)
vi = N(:vi)

# Frase: inicio + desarrollo + cadencia
grammar = (I | IV) + (IV | vi) + (V + I)

progressions = grammar.options
# => [[:I, :IV, :V, :I], [:I, :vi, :V, :I], [:IV, :IV, :V, :I], [:IV, :vi, :V, :I]]
```

### PN() - Proxy Nodes para recursión

`PN()` crea un nodo proxy que permite definir gramáticas recursivas:

```ruby
phrase = PN()  # Crear proxy vacío

# Definir nodos terminales
tonic = N(:tonic)
dominant = N(:dominant)

# Definir expansión recursiva: dominante puede modular y repetir la frase
dominant_phrase = N(:modulate) + dominant + phrase + N(:demodulate)

# Asignar la gramática al proxy
phrase.node = tonic + (dominant | dominant_phrase) + tonic
```

### scale_stack para modulaciones

Cuando una gramática genera modulaciones, usa un stack para rastrear la escala actual:

```ruby
scale_stack = [scale]  # Escala inicial

option_elements.filter_map do |element|
  case element.content
  when :modulate
    # Modular a la dominante de la escala actual
    scale_stack.push(scale_stack.last.dominant.major)
    nil  # No genera nota
  when :demodulate
    scale_stack.pop if scale_stack.size > 1
    nil  # No genera nota
  else
    # Usar la escala actual del stack
    current_scale = scale_stack.last
    chord = current_scale.send(element.content).chord
    { pitches: chord.pitches, ... }
  end
end
```

### Contorno melódico
```ruby
low = N(range: :low) { rand(0..2) }
mid = N(range: :mid) { rand(3..4) }
high = N(range: :high) { rand(5..7) }

# Arco: bajo -> medio -> alto -> medio -> bajo
contour = low + mid + high + mid + low

# Cada llamada genera valores diferentes
melody1 = contour.options.first  # [1, 3, 6, 4, 0]
melody2 = contour.options.first  # [2, 4, 5, 3, 1]
```

## Conceptos de gramáticas formales

### Símbolos terminales
Elementos finales que aparecen en el resultado (notas, acordes, duraciones).

### Reglas de producción
Definen cómo se expanden los símbolos:
- `A → a | b` (alternación)
- `A → a b` (secuencia)
- `A → a*` (repetición)

### Derivaciones
Proceso de aplicar reglas para generar todas las cadenas posibles.

## Aplicaciones musicales

- **Melodías**: Generar todas las combinaciones de un set de notas
- **Ritmos**: Crear patrones que cumplan restricciones métricas
- **Armonía**: Definir progresiones válidas con cadencias obligatorias
- **Forma**: Estructurar secciones con reglas de repetición/contraste
- **Contrapunto**: Generar líneas que sigan reglas de conducción

## Próximos pasos

- **Demo 11:** Matrix - Gestos multidimensionales
- **Demo 12:** DAW Sync - Sincronización como slave
