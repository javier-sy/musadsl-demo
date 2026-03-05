# Demo 02: Series Explorer

**Nivel:** Básico | **Clock:** Master (TimerClock)

## Descripción

Exploración los diferentes constructores de series de musa-dsl. Cuatro voces entran progresivamente:

- **S()** - Serie de valores literales (melodía fija) - Beat 1
- **FOR()** - Secuencia numérica (escalas) - Beat 3
- **RND()** - Valores aleatorios (melodía generativa) - Beat 5
- **FIBO() + H()** - Fibonacci combinado con hash de series - Beat 10
- **Operaciones combinadas** - Todas las voces juntas - Beat 15

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Configuración DAW

| Puerto | Dirección |
|--------|-----------|
| Main | musa-dsl → DAW |

| Pista | Canal MIDI | Constructor |
|-------|------------|-------------|
| Melodía S | 1 | S() |
| Escala FOR | 2 | FOR() |
| Random RND | 3 | RND() |
| Fibo H | 4 | H()+FIBO() |

## Constructores demostrados

### S() - Serie literal
```ruby
S(60, 64, 67, 72)           # Valores explícitos
S(1..10)                     # Desde rango
```

### FOR() - Secuencia numérica
```ruby
FOR(from: 0, to: 7)          # 0, 1, 2, 3, 4, 5, 6, 7
FOR(from: 10, to: 0, step: -2)  # 10, 8, 6, 4, 2, 0
```

### RND() - Aleatorio
```ruby
RND(60, 62, 64, 65, 67)      # Selección aleatoria uniforme
```

### FIBO() - Fibonacci
```ruby
FIBO()                        # 1, 1, 2, 3, 5, 8, 13, 21...
FIBO(start: 2, steps: 10)    # Configurar inicio y longitud
```

### H() - Hash de series
```ruby
H(pitch: S(60, 64, 67), velocity: S(80, 100, 90))
# Produce: {pitch: 60, velocity: 80}, {pitch: 64, velocity: 100}, ...
```

### MERGE() - Concatenar
```ruby
MERGE(S(1, 2), S(3, 4))      # 1, 2, 3, 4
```

## Operaciones demostradas

```ruby
serie.map { |v| v * 2 }       # Transformar
serie.repeat(4)               # Repetir 4 veces
serie.max_size(16)            # Limitar a 16 elementos
serie.i                       # Instanciar para consumo
```

## Buenas prácticas

- **Keyword destructuring en `play`**: Usa `play melody do |grade:, duration:, velocity:| ... end` para extraer campos directamente del hash, en vez de `|note|` con `note[:grade]`.
- **`H()` + `S().repeat` para datasets**: Combina `H(grade: ..., duration: ..., velocity: ...)` para crear series de hashes que `play` consume automáticamente. Usa `S(valor).repeat(n)` para campos constantes.
- **`control.after` para encadenamiento**: El objeto devuelto por `play` tiene `.after { ... }` para ejecutar código cuando la serie termina. Úsalo para encadenar secciones sin calcular tiempos absolutos.
