# Demo 06: Variatio - Variaciones Combinatorias

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

## Descripción

Un motivo de 4 notas con todas sus variaciones posibles de transposición, ritmo y dirección (normal/invertido), generadas automáticamente mediante **producto cartesiano**. Usa el sistema de eventos para encadenar la reproducción de variaciones.

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Concepto

Variatio genera todas las combinaciones posibles de los campos definidos:

```
4 transposiciones × 4 ritmos × 2 articulaciones = 32 variaciones
```

## Configuración DAW

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | (seleccionable) | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Instrumento sugerido |
|-------|------------|---------------------|
| Motivo | 1 | Piano, Cuerdas |

**Sincronización:** Master (musa-dsl controla el tempo a 100 BPM).

## Variatio API

### Estructura básica
```ruby
variatio = Variatio.new :nombre do
  field :campo1, [opción1, opción2, ...]
  field :campo2, [opción1, opción2, ...]

  constructor do |campo1:, campo2:|
    # Crear objeto resultado
    { campo1: campo1, campo2: campo2 }
  end
end

# Generar todas las variaciones
all = variatio.run  # Array de resultados
```

### Campos (fields)
```ruby
field :transpose, [0, 2, 4, 7]           # 4 opciones
field :rhythm, [[1/4r]*4, [1/2r, 1/4r, 1/4r]]  # 2 opciones
field :direction, [:normal, :reverse]    # 2 opciones (motivo normal o al revés)
```

### Fieldsets (grupos de campos)
```ruby
fieldset :dynamics do
  field :velocity, [60, 80, 100]
  field :crescendo, [true, false]
end
```

### Constructor
```ruby
constructor do |transpose:, rhythm:, direction:|
  {
    transpose: transpose,
    rhythm: rhythm,
    direction: direction
  }
end
```

## Parámetros de la demo

Esta demo usa dos parámetros de ajuste:

- **`speed_factor = 1/2r`**: Multiplica todas las duraciones por 0.5, acelerando la reproducción al doble
- **`duration * 0.9`**: Las notas suenan el 90% de su duración, creando una ligera separación entre ellas (articulación legato pero no ligado)

## Código clave

### Definir variaciones y convertir a series
```ruby
# Definir variatio
motif_variatio = Variatio.new :motif do
  field :transpose, [0, 2, 4, 7]
  field :rhythm, [[1/4r]*4, [1/2r, 1/4r, 1/4r]]
  field :direction, [:normal, :reverse]

  constructor do |transpose:, rhythm:, direction:|
    {
      transpose: transpose,
      rhythm: rhythm,
      direction: direction
    }
  end
end

# Generar todas las variaciones
all_variations = motif_variatio.run

# Convertir una variación a serie para play
def variation_to_series(base_motif, variation)
  transposed = base_motif.map { |g| g + variation[:transpose] }

  # Aplicar dirección
  transposed = transposed.reverse if variation[:direction] == :reverse
  rhythm = variation[:rhythm]
  rhythm = rhythm.reverse if variation[:direction] == :reverse

  grades = S(*transposed)
  durations = S(*rhythm)
  velocities = S(80).repeat(transposed.size)

  H(grade: grades, duration: durations, velocity: velocities)
end
```

### Reproducir variaciones con eventos
```ruby
variation_index = 0

on :play_variation do
  if variation_index < selected.size
    variation = selected[variation_index]
    melody = variation_to_series(base_motif, variation)

    control = play melody do |note|
      pitch = scale[note[:grade]].pitch
      voice.note(pitch, velocity: note[:velocity], duration: note[:duration] * 0.9)
    end

    variation_index += 1
    control.after(1) { launch :play_variation }
  else
    launch :finale
  end
end

at 1 do
  launch :play_variation
end
```

## Aplicaciones musicales

- **Variaciones temáticas**: Explorar todas las versiones de un motivo
- **Voicings de acordes**: Generar todas las inversiones y disposiciones
- **Patrones rítmicos**: Combinar diferentes subdivisiones
- **Orquestación**: Combinar instrumentos y registros

## Próximos pasos

- **Demo 07:** Navegación de escalas y armonía
- **Demo 09:** Selección evolutiva con Darwin
