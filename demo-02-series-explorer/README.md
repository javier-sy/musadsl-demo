# Demo 02: Series Explorer

**Nivel:** Básico | **Clock:** Master (TimerClock)

## Descripción

Exploración auditiva de los diferentes constructores de series de musa-dsl. Cuatro voces entran progresivamente:

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

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | `Main` | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Constructor | Instrumento sugerido |
|-------|------------|-------------|---------------------|
| Melodía S | 1 | S() | Piano |
| Escala FOR | 2 | FOR() | Marimba |
| Random RND | 3 | RND() | Bells/Celesta |
| Fibo H | 4 | H()+FIBO() | Bass Synth |

### Diagrama

```
main.rb (musa-dsl)
    │
    ├── Canal 1 ──► Pista "Melodía S"    (Piano)
    ├── Canal 2 ──► Pista "Escala FOR"   (Marimba)
    ├── Canal 3 ──► Pista "Random RND"   (Bells)
    └── Canal 4 ──► Pista "Fibo H"       (Bass)
```

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

## Próximos pasos

- **Demo 03:** Canon a dos voces usando `.buffered`
- **Demo 05:** Melodías con cadenas de Markov
