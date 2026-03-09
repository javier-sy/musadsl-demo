# Demo 19: Advanced Series Operations

**Nivel:** Avanzado | **Clock:** Master | **Inspirado en:** Estudio Fibonacci para piano (2018)

## Descripción

Operaciones avanzadas con series: `H()` para combinar pitch/duration/velocity, `.eval()` para transformaciones, `.duplicate()/.reverse()/.shift()` para manipulación, y `FIBO().max_size()` para patrones Fibonacci.

## Configuración DAW

| Puerto | Dirección |
|--------|-----------|
| Main | musa-dsl → DAW |

| Pista | Canal MIDI |
|-------|------------|
| Voz principal | 1 |
| Voz canon/secundaria | 2 |

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

### H() - Hash Series

Combina múltiples series en una serie de hashes. Para cuando termina la serie más corta.

```ruby
pitches = S(60, 64, 67)
durations = S(1r, 1/2r, 1/4r)
velocities = S(96, 80, 64)

# H() combina en hash
notes = H(pitch: pitches, duration: durations, velocity: velocities).instance

notes.next_value  # => {pitch: 60, duration: 1r, velocity: 96}
notes.next_value  # => {pitch: 64, duration: 1/2r, velocity: 80}
notes.next_value  # => {pitch: 67, duration: 1/4r, velocity: 64}
notes.next_value  # => nil (terminó)
```

### HC() - Hash Series con Cycling

Como `H()` pero cicla todas las series.

```ruby
hc = HC(a: S(1, 2), b: S(10, 20, 30))
result = hc.max_size(6).instance.to_a
# => [{a:1, b:10}, {a:2, b:20}, {a:1, b:30}, {a:2, b:10}, {a:1, b:20}, {a:2, b:30}]
```

### .eval() - Transformación

Transforma cada valor de la serie.

```ruby
# Fibonacci a duraciones
fib = FIBO().max_size(8)
durations = fib.eval { |n| Rational(n, 8) }
# => [1/8, 1/8, 1/4, 3/8, 5/8, 1, 13/8, 21/8]

# Normalizar a rango MIDI
velocities = fib.eval { |n| 40 + (n / 34.0 * 60).to_i }
```

### .duplicate() - Copia Independiente

Crea una copia que puede transformarse sin afectar el original.

```ruby
original = S(1, 2, 3, 4, 5)
copy = original.duplicate

# Transformar la copia
reversed_copy = copy.reverse
# original sigue intacto
```

### .reverse() - Retrograde

Invierte el orden de la serie.

```ruby
melody = S(60, 64, 67, 72)
retrograde = melody.reverse
# => S(72, 67, 64, 60)

# Ida y vuelta
ida_vuelta = melody + melody.reverse
# => S(60, 64, 67, 72, 72, 67, 64, 60)
```

### .shift() - Rotación

Rota los elementos de la serie.

```ruby
s = S(60, 64, 67)

s.shift(1)   # => S(64, 67, 60)  (rota izquierda 1)
s.shift(2)   # => S(67, 60, 64)  (rota izquierda 2)
s.shift(-1)  # => S(67, 60, 64)  (rota derecha 1)
```

### FIBO().max_size() - Fibonacci Limitado

```ruby
fib = FIBO().max_size(10)
fib.instance.to_a
# => [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]

# Fibonacci como duraciones
rhythm = FIBO().max_size(8).eval { |n| Rational(n, 16) }
```

## Secciones de la Demo

| Sección | Compases | Descripción |
|---------|----------|-------------|
| 1 | 1-2 | H() básico |
| 2 | 2-3 | .eval() transformaciones |
| 3 | 3-5 | FIBO().max_size() |
| 4 | 5-6 | .duplicate() y .reverse() |
| 5 | 6-7 | .shift() rotación |
| 6 | 7-8 | Series anidadas (manual) |
| 7 | 8-10 | Combinación completa |

## Patrones Avanzados

### Patrón 1: Melodía con H()

```ruby
melody = H(
  grade: S(0, 2, 4, 5, 7, 5, 4, 2),
  duration: S(1/4r, 1/4r, 1/8r, 1/8r, 1/2r, 1/4r, 1/4r, 1/2r),
  velocity: S(80, 75, 70, 65, 90, 70, 65, 60)
)

play melody do |grade:, duration:, velocity:|
  pitch = scale[grade].pitch
  voice.note(pitch, duration: duration, velocity: velocity)
end
```

### Patrón 2: Fibonacci completo

```ruby
fib = FIBO().max_size(8)
pattern = fib + fib.reverse  # Ida y vuelta

p_series = pattern.eval { |n| (n - 1) % 8 }
d_series = pattern.eval { |n| Rational(n, 16) }
v_series = pattern.eval { |n| 40 + n * 4 }

melody = H(grade: p_series, duration: d_series, velocity: v_series)
```

### Patrón 3: Canon con shift

```ruby
original = S(0, 2, 4, 5, 7).repeat(4)

# Voz 1: original
# Voz 2: rotado 2 posiciones
# Voz 3: rotado 4 posiciones

v1_melody = original.instance
v2_melody = original.shift(2).instance
v3_melody = original.shift(4).instance
```

## Operaciones Encadenadas

```ruby
result = S(1, 2, 3, 4, 5, 6)
  .select { |n| n.even? }   # Filtrar pares
  .map { |n| n * 10 }        # Multiplicar
  .repeat(2)                  # Repetir
  .instance.to_a
# => [20, 40, 60, 20, 40, 60]
```

## Resumen de Métodos

| Método | Propósito |
|--------|-----------|
| `H()` | Combina series en hashes |
| `HC()` | H() con cycling |
| `.eval { }` | Transforma cada valor (alias de `.with`, aísla valores) |
| `.map { }` | Transforma cada valor (sin aislar valores) |
| `.duplicate` | Copia independiente |
| `.reverse` | Orden inverso |
| `.shift(n)` | Rota n posiciones |
| `.max_size(n)` | Limita a n elementos |
| `.repeat(n)` | Repite n veces |
| `.skip(n)` | Salta n elementos |

## Buenas prácticas

- **`H()` para datasets de `play`**: Combina `H(grade: ..., duration: ..., velocity: ...)` para crear series que `play` consume automáticamente con keyword destructuring: `play melody do |grade:, duration:, velocity:| ... end`.
- **`.eval()` para transformar Fibonacci a valores musicales**: `FIBO()` genera enteros crecientes. Usa `.eval { |n| Rational(n, 16) }` para duraciones o `.eval { |n| (n - 1) % 8 }` para mapear a grados de escala.
- **`.shift()` para canones rotacionales**: Usa `.shift(n)` sobre un prototipo de serie para crear versiones rotadas. Cada voz recibe la misma secuencia pero empezando desde una posición diferente.
- **`.duplicate` antes de transformar**: Si necesitas el original intacto, llama `.duplicate` antes de aplicar `.reverse`, `.shift`, etc. Las operaciones de transformación crean nuevos prototipos pero es buena práctica hacer la copia explícita.
