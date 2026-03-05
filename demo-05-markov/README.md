# Demo 05: Markov Melodies

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

## Descripción

Melodías generativas donde tanto las notas como las duraciones se determinan probabilísticamente usando **cadenas de Markov**. Se presentan tres estilos diferentes según las matrices de transición, encadenados mediante el sistema de eventos.

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Estilos demostrados

### 1. Diatónico (Clásico)
- Movimiento por grados conjuntos
- Alta probabilidad de resolución a tónica
- Duraciones fluidas (negras, blancas)

### 2. Jazzy (Cromático)
- Saltos de terceras y quintas
- Arpegios implícitos
- Duraciones swing (larga-corta alternancia)

### 3. Minimalista
- 60% probabilidad de repetir la misma nota
- 70% probabilidad de repetir la misma duración
- Patrón hipnótico con cambios graduales

## Configuración DAW

| Puerto | Dirección |
|--------|-----------|
| Main | musa-dsl → DAW |

| Pista | Canal MIDI | Estilo      |
|-------|------------|-------------|
| Diatónico | 1 | Clásico     |
| Jazzy | 2 | Jazzy       |
| Minimal | 3 | Minimalista |

## Cadenas de Markov

### Concepto
Una cadena de Markov define la probabilidad de transición entre estados. En esta demo, usamos Markov tanto para las notas (grados de escala) como para las duraciones.

### Estructura básica
```ruby
Markov.new(
  start: 0,           # Estado inicial
  finish: nil,        # Estado final (nil = infinito)
  transitions: {
    estado => { siguiente1 => probabilidad1, siguiente2 => probabilidad2, ... }
  }
)
```

### Markov para grados (notas)
```ruby
markov_grades = Markov.new(
  start: 0,
  transitions: {
    0 => { 1 => 0.4, 2 => 0.3, 4 => 0.2, -1 => 0.1 },
    1 => { 0 => 0.3, 2 => 0.5, 3 => 0.2 },
    # ...
  }
)
```

### Markov para duraciones
```ruby
markov_durations = Markov.new(
  start: 1/2r,
  transitions: {
    1/4r => { 1/4r => 0.3, 1/2r => 0.5, 1r => 0.2 },
    1/2r => { 1/4r => 0.3, 1/2r => 0.4, 1r => 0.3 },
    1r   => { 1/4r => 0.4, 1/2r => 0.5, 1r => 0.1 }
  }
)
```

### Transiciones equiprobables
```ruby
# Sintaxis simplificada: array = probabilidades iguales
transitions: {
  0 => [1, 2, 3],      # 33% cada una
  1 => { 0 => 0.5, 2 => 0.5 }  # 50% cada una
}
```

## Código clave

### Crear cadenas y combinar con H()
```ruby
# Cadenas de Markov (sin .i)
grades = markov_grades.max_size(24)
durations = markov_durations.max_size(24)
velocities = S(75).repeat(24)

# Combinar en serie de hashes
melody = H(grade: grades, duration: durations, velocity: velocities)

# Reproducir con keyword destructuring
play melody do |grade:, duration:, velocity:|
  pitch = scale[grade].pitch
  voice.note(pitch, velocity: velocity, duration: duration)
end
```

### Sistema de eventos para encadenar secciones
```ruby
on :diatonic do
  # ... crear y reproducir melodía ...
  control = play melody do |grade:, duration:, velocity:|
    pitch = scale[grade].pitch
    voice.note(pitch, velocity: velocity, duration: duration)
  end

  # Encadenar a la siguiente sección
  control.after(1) { launch :jazzy }
end

on :jazzy do
  # ...
  control.after(1) { launch :minimal }
end

on :minimal do
  # ...
  control.after(1) { launch :finale }
end

on :finale do
  # Acorde final y detener
  wait 4 do
    transport.stop
  end
end

# Iniciar la cadena
at 1 do
  launch :diatonic
end
```

## Notas importantes

- **No usar `.i` antes de `.max_size()`**: Las series Markov son prototipos. Usar `markov.max_size(24)`, no `markov.i.max_size(24)`.
- **H() espera prototipos**: Todas las series pasadas a `H()` deben ser prototipos, no instancias.
- **Sistema de eventos**: Usar `on :event` / `launch :event` permite encadenar secciones sin tiempos absolutos.

## Buenas prácticas

- **Markov sin `.i` antes de `.max_size()`**: Las cadenas de Markov son prototipos de serie. Aplica `.max_size()` directamente sobre el prototipo, no sobre una instancia. `markov.i.max_size(24)` falla porque `.i` devuelve una instancia que no responde a `.max_size`.
- **`H()` espera prototipos, no instancias**: Todas las series que pases a `H(grade: ..., duration: ..., velocity: ...)` deben ser prototipos. `H()` se encarga de instanciarlas internamente.
- **Keyword destructuring en `play`**: Usa `play melody do |grade:, duration:, velocity:| ... end` para extraer campos directamente del hash producido por `H()`.
