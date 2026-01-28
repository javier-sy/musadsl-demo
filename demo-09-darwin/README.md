# Demo 09: Darwin - Selección Evolutiva

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

## Descripción

Demostración del sistema **Darwin** para selección evolutiva de material musical. Darwin evalúa una población de candidatos usando criterios de fitness definidos por el usuario y devuelve los mejores ordenados por puntuación.

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Secciones

La demo genera todo el material antes de iniciar la reproducción, luego usa eventos para encadenar secciones.

### 1. Selección de melodías (`:play_melodies`)
- **Población**: 50 melodías aleatorias de 8 notas
- **Criterios**: Pocos saltos (smoothness), direccionalidad, empieza/termina en tónica
- **Filtro**: Descarta melodías con saltos > 4 grados
- **Salida**: Las 3 mejores melodías

### 2. Selección de ritmos (`:play_rhythms`)
- **Población**: 40 patrones rítmicos que suman exactamente 1 beat
- **Criterios**: Variedad de figuras, inicio fuerte
- **Filtro**: Máximo 4 fusas (1/32r)
- **Salida**: Los 2 mejores ritmos

### 3. Selección de progresiones (`:play_progression`)
- **Población**: 30 progresiones de acordes (I + 3 aleatorios + I)
- **Criterios**: Variedad, uso de V, cadencia auténtica (V-I)
- **Filtro**: Sin repeticiones consecutivas
- **Salida**: La mejor progresión

### 4. Darwin + Variatio (`:play_variations`)
Combina Variatio para generar 24 variaciones (4 × 3 × 2) y Darwin para seleccionar las mejores según equilibrio de transposición y articulación legato.

## Configuración DAW

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | `Main` | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Instrumento sugerido |
|-------|------------|---------------------|
| Melodía | 1 | Piano, Marimba |
| Acordes | 2 | Strings, Pad |

**Pistas a crear:** 2 pistas MIDI.

**Sincronización:** Master (musa-dsl controla el tempo a 100 BPM).

## API de Darwin

### Estructura básica
```ruby
darwin = Darwin.new do
  measures do |object|
    # Evaluar cada objeto
    dimension :nombre, valor_numerico
    feature :nombre if condicion
    die if condicion_invalida
  end

  weight dimension1: peso1, feature1: peso2
end

# Seleccionar
selected = darwin.select(population)
```

### Bloque measures

Dentro de `measures`, tienes acceso a tres métodos de evaluación:

#### dimension (medición numérica)
```ruby
dimension :smoothness, -total_jumps.to_f
dimension :variety, unique_count.to_f
```
- Los valores se normalizan automáticamente (0-1) en la población
- Usa valores negativos para preferir valores menores

#### feature (característica booleana)
```ruby
feature :starts_on_tonic if melody.first == 0
feature :has_cadence if ends_with_V_I?(progression)
```
- Añade el peso completo si la condición es verdadera
- No añade nada si es falsa

#### die (descartar)
```ruby
die if has_parallel_fifths?(progression)
die if total_jumps > 20
```
- Excluye el objeto de los resultados
- Útil para filtros absolutos

### Pesos (weight)
```ruby
weight smoothness: 3.0,      # Positivo: favorece
       complexity: -1.0,     # Negativo: penaliza
       has_cadence: 2.0
```

### Ejemplo completo
```ruby
melody_darwin = Darwin.new do
  measures do |melody|
    notes = melody[:notes]

    # Calcular métricas
    jumps = notes.each_cons(2).sum { |a, b| (a - b).abs }
    range = notes.max - notes.min

    # Dimensiones
    dimension :smoothness, -jumps.to_f  # Preferir menos saltos
    dimension :range, range.to_f        # Preferir mayor rango

    # Características
    feature :starts_tonic if notes.first == 0
    feature :ends_tonic if notes.last == 0
    feature :has_climax if notes.max >= 7

    # Filtros absolutos
    die if jumps > 15
    die if range < 3
  end

  weight smoothness: 3.0,
         range: 1.0,
         starts_tonic: 2.0,
         ends_tonic: 2.5,
         has_climax: 1.5
end

# Generar población
population = 100.times.map do
  { notes: 8.times.map { rand(0..7) } }
end

# Seleccionar mejores
best = melody_darwin.select(population)
top_10 = best.first(10)
```

## Combinando Darwin con Variatio

Variatio genera todas las combinaciones posibles; Darwin selecciona las mejores:

```ruby
# 1. Generar variaciones con Variatio
variatio = Variatio.new :motif do
  field :transpose, [0, 2, 4, 7]
  field :rhythm, [:fast, :slow, :mixed]
  field :articulation, [:legato, :staccato]

  constructor do |transpose:, rhythm:, articulation:|
    { transpose: transpose, rhythm: rhythm, articulation: articulation }
  end
end

all_variations = variatio.run  # 4 × 3 × 2 = 24 variaciones

# 2. Seleccionar con Darwin
darwin = Darwin.new do
  measures do |var|
    dimension :transpose_balance, -(var[:transpose] - 4).abs.to_f
    feature :is_legato if var[:articulation] == :legato
  end

  weight transpose_balance: 1.0, is_legato: 2.0
end

best_variations = darwin.select(all_variations).first(5)
```

## Proceso de evaluación

1. **Measure**: Cada objeto se evalúa con el bloque measures
2. **Normalize**: Las dimensiones se normalizan a 0-1 en toda la población
3. **Weight**: Se aplican los pesos a dimensiones y features
4. **Score**: Fitness = Σ(dimension × peso) + Σ(feature × peso)
5. **Sort**: La población se ordena por fitness descendente
6. **Filter**: Los objetos marcados con `die` se excluyen

## Aplicaciones musicales

- **Melodías**: Seleccionar las más suaves, direccionales, con buen contorno
- **Ritmos**: Encontrar patrones equilibrados, con variedad apropiada
- **Armonía**: Elegir progresiones con buena conducción de voces
- **Orquestación**: Seleccionar combinaciones tímbricas óptimas
- **Formas**: Encontrar estructuras con balance de repetición/variación

## Próximos pasos

- **Demo 10:** Grammar - Gramáticas generativas
- **Demo 11:** Matrix - Gestos multidimensionales
