# Demo 03: Canon a Dos Voces

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

## Descripción

Un canon clásico donde la segunda voz (Comes) entra 1 compás después de la primera (Dux), ejecutando la misma melodía transportada una quinta inferior. Demuestra el sistema **buffered** de series para crear lecturas independientes.

## Concepto Musical

```
Beat:   1       2       3       4       5    ...
Dux:    [===========melodía============]
Comes:          [===========melodía============]
                ↑
                Entrada 1 compás después
```

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

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Dux | 1 | Voz líder |
| Comes | 2 | Voz seguidora |

## Series Buffered

### Problema que resuelve

Normalmente, una serie solo puede leerse una vez sin reiniciarla:

```ruby
s = S(1, 2, 3).i
s.next_value  # => 1
s.next_value  # => 2
# No hay forma de que otra voz lea los mismos valores sin llamar a .reset
```

### Solución: .buffered

```ruby
# Crear serie con buffer compartido
buffered = S(1, 2, 3).buffered

# Crear readers independientes
reader1 = buffered.buffer
reader2 = buffered.buffer

# Cada reader puede consumir independientemente
reader1.i.next_value  # => 1
reader2.i.next_value  # => 1 (mismo valor!)
reader1.i.next_value  # => 2
reader2.i.next_value  # => 2
```

### Aplicaciones

- **Canones**: Misma melodía, entradas escalonadas
- **Fugas**: Sujeto repetido en diferentes voces
- **Procesos paralelos**: Múltiples consumidores de los mismos datos

## Código clave

```ruby
# Crear melodía buffered
melody = S(0, 2, 4, 5, 7).buffered

# Readers para cada voz
melody_dux = melody.buffer
melody_comes = melody.buffer

# Dux empieza en beat 1
at 1 do
  play melody_dux do |grade:, duration:, velocity:|
    pitch = scale[grade].pitch
    voice1.note(pitch, velocity: velocity, duration: duration)
  end
end

# Comes empieza en beat 2 (1 compás después)
at 2 do
  play melody_comes do |grade:, duration:, velocity:|
    # Transposición: -4 grados = quinta inferior
    pitch = scale[grade - 4].pitch
    voice2.note(pitch, velocity: velocity - 10, duration: duration)
  end
end
```

## Buenas prácticas

- **`.buffered` + `.buffer` para lecturas paralelas**: Llama `.buffered` sobre el prototipo para crear un buffer compartido, luego `.buffer` para obtener cada reader independiente. Cada reader mantiene su propia posición de lectura.
- **Keyword destructuring en `play`**: Usa `play serie do |grade:, duration:, velocity:| ... end` para extraer campos directamente, en vez de acceder con `note[:grade]`.
