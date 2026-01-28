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

### 2. Jazz (Cromático)
- Saltos de terceras y quintas
- Arpegios implícitos
- Duraciones swing (larga-corta alternancia)

### 3. Minimalista
- 60% probabilidad de repetir la misma nota
- 70% probabilidad de repetir la misma duración
- Patrón hipnótico con cambios graduales

## Configuración DAW

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | (seleccionable) | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Estilo | Instrumento sugerido |
|-------|------------|--------|---------------------|
| Diatónico | 1 | Clásico | Piano, Cuerdas |
| Jazzy | 2 | Jazz | Piano eléctrico, Saxo |
| Minimal | 3 | Minimalista | Marimba, Synth pad |

**Sincronización:** Master (musa-dsl controla el tempo a 110 BPM).

## Cadenas de Markov

### Concepto
Una cadena de Markov define la probabilidad de transición entre estados. En esta demo, usamos Markov tanto para las notas (grados de escala) como para las duraciones.

### Estructura básica
```ruby
Markov.new(
  start: 0,           # Estado inicial
  finish: nil,        # Estado final (nil = infinito)
  transitions: {
    estado => { siguiente1 => prob1, siguiente2 => prob2, ... }
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

# Reproducir
play melody do |note|
  pitch = scale[note[:grade]].pitch
  voice.note(pitch: pitch, velocity: note[:velocity], duration: note[:duration])
end
```

### Sistema de eventos para encadenar secciones
```ruby
on :diatonic do
  # ... crear y reproducir melodía ...
  control = play melody do |note|
    # ...
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

## Próximos pasos

- **Demo 06:** Variaciones combinatorias con Variatio
- **Demo 09:** Selección evolutiva con Darwin
