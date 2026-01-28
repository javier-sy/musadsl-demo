# Demo 04: Neumas - Notación Musical Textual

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

## Descripción

Pieza compuesta usando el sistema de notación **Neuma** de musa-dsl. Neuma permite escribir música de forma compacta y legible usando texto.

Este demo también introduce el **sistema de eventos** para encadenar secciones musicales.

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Sintaxis Neuma

### Formato básico
```
(grado duración dinámica ornamento)
```

### Grados de escala
```
0       → Tónica (Do en Do Mayor)
+2      → 2 grados arriba (relativo)
-1      → 1 grado abajo (relativo)
4       → Grado 4 absoluto (Sol)
```

### Duraciones

Las duraciones son múltiplos de `base_duration` (por defecto 1/4r = negra):

```
2       → Blanca (2 × base_duration)
1       → Negra (1 × base_duration)
1/2     → Corchea (0.5 × base_duration)
1/4     → Semicorchea (0.25 × base_duration)
```

### Dinámicas

Valores internos que se mapean a MIDI velocity:

```
pp  → -2 → ~33 MIDI
p   → -1 → ~49 MIDI
mp  →  0 → ~64 MIDI
mf  → +1 → ~80 MIDI
f   → +2 → ~96 MIDI
ff  → +3 → ~112 MIDI
```

### Silencios
```
(silence 1)   → Silencio de negra
(silence 2)   → Silencio de blanca
```

## Pipeline de conversión

```
Neuma String → to_neumas → GDVD Serie → NeumaDecoder → GDV → to_pdv(scale) → PDV (MIDI)
     ↓              ↓           ↓              ↓           ↓           ↓
  "(0 1 mf)"    Parser    Diferencial    Absoluto    Conversión   pitch/vel/dur
```

- **GDVD** (Diferencial): Cambios relativos (`+2` = subir 2 grados)
- **GDV** (Absoluto): Valores absolutos (`grade: 2`)
- **PDV** (MIDI): Pitch, Duration, Velocity

## Código clave

### El Transcriptor (para adornos)

Sin transcriptor, los adornos (`tr`, `mor`, `st`) se ignoran. El transcriptor los expande a notas reales:

```ruby
# Crear transcriptor para expandir adornos
transcriptor = Transcription::Transcriptor.new(
  Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/4r),
  base_duration: 1/4r,
  tick_duration: 1/96r
)
```

### El Decoder

```ruby
using Musa::Extension::Neumas

# Crear decoder con escala, duración base y transcriptor
decoder = Decoders::NeumaDecoder.new(
  scale,
  base_duration: 1/4r,
  transcriptor: transcriptor  # Para expandir adornos
)

# Convertir texto a serie GDVD
melody = '(0 1 mf tr) (+2 1) (+2 1/2 st) (+1 1/2)'.to_neumas

# Reproducir con decoder
play melody, decoder: decoder, mode: :neumalang do |gdv|
  pdv = gdv.to_pdv(scale)
  voice.note(pdv[:pitch], velocity: pdv[:velocity], duration: pdv[:duration])
end
```

### Adornos disponibles

| Adorno | Sintaxis | Expansión |
|--------|----------|-----------|
| Trino | `tr` | Alternancia rápida con nota superior |
| Mordente | `mor` | Nota + vecina superior + nota |
| Mordente inferior | `mor(down)` | Nota + vecina inferior + nota |
| Grupeto | `turn` | 4 notas: superior, principal, inferior, principal |
| Staccato | `st` | Acorta la duración (50%) |
| Staccato fuerte | `st(2)` | Acorta más (25%) |

### Reset del decoder entre secciones

```ruby
# El decoder mantiene estado (último grado, octava, etc.)
# Para empezar desde cero, reseteamos su estado base:
decoder.base = { grade: 0, octave: 0, duration: 1/4r, velocity: 1 }
```

## Sistema de Eventos

Este demo utiliza eventos para encadenar secciones musicales sin tiempos absolutos.

### Registrar y disparar eventos

```ruby
# Registrar handler para un evento
on :mi_evento do
  puts "Evento disparado!"
  # ... código de la sección ...
end

# Disparar el evento
launch :mi_evento
```

### Encadenar secciones

```ruby
on :section_1 do
  control = play melody, decoder: decoder, mode: :neumalang do |gdv|
    # ...
  end

  # Cuando termine play, esperar y lanzar siguiente sección
  control.after do
    wait 1/2r do
      launch :section_2
    end
  end
end

on :section_2 do
  # ...
end

# Iniciar la cadena
at 1 do
  launch :section_1
end
```

### Ventajas del sistema de eventos

1. **Sin tiempos hardcodeados**: Las secciones se encadenan automáticamente
2. **Flexible**: Fácil reorganizar o añadir secciones
3. **Reactivo**: Cada sección reacciona al completarse la anterior
4. **Modular**: Cada sección es independiente

## Configuración DAW

### Puertos MIDI requeridos

| Puerto | Nombre | Dirección |
|--------|--------|-----------|
| Output | (seleccionable) | musa-dsl → DAW |

### Pistas necesarias

| Pista | Canal MIDI | Instrumento sugerido |
|-------|------------|---------------------|
| Melodía | 1 | Clavecín, Violín, Flauta |

### Notas

- Tempo moderado (72 BPM)
- Instrumento expresivo recomendado para apreciar las dinámicas

## Próximos pasos

- **Demo 05:** Melodías generativas con Markov
- **Demo 06:** Variaciones combinatorias con Variatio
