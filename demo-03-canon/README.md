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

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | `Main` | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Rol | Instrumento sugerido |
|-------|------------|-----|---------------------|
| Dux | 1 | Voz líder | Flauta / Violín |
| Comes | 2 | Voz seguidora | Oboe / Viola |

### Notas

- La voz Comes está transportada una quinta abajo para mejor armonía
- El tempo es lento (80 BPM) para apreciar el contrapunto

## Series Buffered

### Problema que resuelve

Normalmente, una serie solo puede leerse una vez:

```ruby
s = S(1, 2, 3).i
s.next_value  # => 1
s.next_value  # => 2
# No hay forma de que otra voz lea los mismos valores
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
- **Procesos paralelos**: Múltiples consumidores de mismos datos

## Código clave

```ruby
# Crear melodía buffered
melody = S(0, 2, 4, 5, 7).buffered

# Readers para cada voz
melody_dux = melody.buffer
melody_comes = melody.buffer

# Dux empieza en beat 1
at 1 do
  play melody_dux do |note|
    pitch = scale[note[:grade]].pitch
    voice1.note(pitch, velocity: note[:velocity], duration: note[:duration])
  end
end

# Comes empieza en beat 2 (1 compás después)
at 2 do
  play melody_comes do |note|
    # Transposición: -4 grados = quinta inferior
    pitch = scale[note[:grade] - 4].pitch
    voice2.note(pitch, velocity: note[:velocity] - 10, duration: note[:duration])
  end
end
```

## Próximos pasos

- **Demo 04:** Notación textual con Neumas
- **Demo 07:** Conducción de voces con reglas de contrapunto
