# MusaDSL - Suite de Demostraciones

Esta carpeta contiene 23 demostraciones progresivas del framework **musa-dsl** para composición algorítmica en Ruby. Incluye demos con MIDI y OSC, basadas en técnicas reales usadas en obras de composición.

> **Nota:** Las demos 00-10 han sido revisadas y están disponibles en el repositorio. Las demos 11-22 están pendientes de revisión.

> **Nota:** Son demostraciones orientadas a mostrar las características y posibilidades de musa-dsl. NO PRETENDEN TENER NINGÚN VALOR ARTÍSTICO NI CREATIVO.


---

## Modos de Sincronización

MusaDSL soporta dos modos de sincronización con DAWs:

### Master Clock (TimerClock)
```ruby
clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24)

# IMPORTANTE: TimerClock inicia pausado - requiere inicio explícito
transport.before_begin do
  Thread.new do
    sleep 0.1
    clock.start
  end
end

transport.start
```
- **musa-dsl controla el tempo**
- El DAW puede recibir MIDI Clock desde musa-dsl (opcional)
- Útil para: composiciones autónomas, instalaciones, performances sin DAW
- **Nota técnica:** `TimerClock` inicia en estado pausado. Se debe llamar `clock.start` desde un Thread separado después de `transport.start` (que es bloqueante)

### Slave Clock (InputMidiClock)
```ruby
clock_input = MIDICommunications::Input.find_by_name('DAW Clock')
clock = InputMidiClock.new(clock_input)
```
- **El DAW controla el tempo**
- musa-dsl recibe MIDI Clock del DAW y sincroniza sus eventos
- Útil para: integración con proyectos DAW existentes, colaboración, live coding

---

## Índice de Demos

| # | Demo | Nivel | Clock | Descripción |
|---|------|-------|-------|-------------|
| 00 | [Template](#demo-00-template) | Plantilla | Slave | Plantilla base para proyectos |
| 01 | [Hello Musa](#demo-01-hello-musa) | Básico | Master | Primera secuencia musical |
| 02 | [Series Explorer](#demo-02-series-explorer) | Básico | Master | Constructores de series |
| 03 | [Canon](#demo-03-canon) | Intermedio | Master | Series buffered para canon |
| 04 | [Neumas](#demo-04-neumas) | Intermedio | Master | Notación textual musical |
| 05 | [Markov](#demo-05-markov) | Intermedio | Master | Melodías probabilísticas |
| 06 | [Variatio](#demo-06-variatio) | Intermedio | Master | Variaciones combinatorias |
| 07 | [Scale Navigator](#demo-07-scale-navigator) | Intermedio | Master | Navegación armónica |
| 08 | [Voice Leading](#demo-08-voice-leading) | Avanzado | Master | Reglas de contrapunto |
| 09 | [Darwin](#demo-09-darwin) | Avanzado | Master | Selección evolutiva |
| 10 | [Grammar](#demo-10-grammar) | Avanzado | Master | Gramáticas generativas |
| 11 | [Matrix](#demo-11-matrix) | Avanzado | Master | Gestos multidimensionales |
| 12 | [DAW Sync](#demo-12-daw-sync) | Intermedio | Slave | Sincronización con DAW |
| 13 | [Live Coding](#demo-13-live-coding) | Avanzado | Slave | Performance interactiva |
| 14 | [Clock Modes](#demo-14-clock-modes) | Intermedio | Ambos | Comparativa de modos |
| **OSC** |||||
| 15 | [OSC SuperCollider](#demo-15-osc-supercollider) | Avanzado | OSC | Control de síntesis granular |
| 16 | [OSC Max/MSP](#demo-16-osc-maxmsp) | Avanzado | OSC | Audio espacial y módulos |
| **Patrones Avanzados** |||||
| 17 | [Event Architecture](#demo-17-event-architecture) | Intermedio | Master | Sistema launch/on |
| 18 | [Parameter Automation](#demo-18-parameter-automation) | Intermedio | Master | SIN(), move, envelopes |
| 19 | [Advanced Series](#demo-19-advanced-series) | Avanzado | Master | H(), eval, SS, Fibonacci |
| 20 | [Neuma Files](#demo-20-neuma-files) | Intermedio | Master | .neu externos, Transcriptor |
| 21 | [Fibonacci Episodes](#demo-21-fibonacci-episodes) | Avanzado | Master | Episodios, multi-threading |
| 22 | [Multi-Phase](#demo-22-multiphase) | Avanzado | Master | Composición multi-fase |

---

## Demo 00: Template

**Nivel:** Plantilla | **Clock:** Slave (InputMidiClock)

### Descripción

Plantilla base para empezar proyectos de composición algorítmica con MusaDSL. Incluye configuración completa lista para usar con Bitwig Studio.

### Recursos musa-dsl

- `include Musa::All` - Incluye todos los módulos
- `using Musa::Extension::Neumas` - Extensión para notación neuma
- `InputMidiClock.new(input)` - Clock esclavo (DAW controla tempo)
- `MIDIVoices` con 4 canales preconfigurados
- `Transcriptor` completo con ornamentos barrocos
- Helper `neuma(serie, voice:)` para reproducir neumas
- Helper `reload` para hot-reload de score.rb

### Estructura

```
demo-00/
├── musa/
│   ├── main.rb      # Setup completo
│   ├── score.rb     # Tu composición (hot-reloadable)
│   └── Gemfile
└── bw/
    └── demo/        # Proyecto Bitwig preconfigurado
```

### Configuración DAW

- **Puertos MIDI:** Crear puertos virtuales `Clock` (entrada) y `Main` (salida)
- **Pistas:** 1 pista MIDI recibiendo en canal 1 (4 canales disponibles para expandir)
- **Clock:** Habilitar MIDI Clock Output hacia puerto `Clock`
- **Sincronización:** El DAW controla el tempo (Slave mode)

### Uso

```bash
cd musa
bundle install
ruby main.rb
# Presiona PLAY en el DAW
```

---

## Demo 01: Hello Musa

**Nivel:** Básico | **Clock:** Master (TimerClock)

### Descripción Musical
Una melodía simple de 8 notas en Do mayor que introduce los conceptos fundamentales: escalas, scheduling y reproducción MIDI.

### Recursos musa-dsl
- `Scales.et12[440.0].major[60]` - Sistema de escalas (12-TET, La=440Hz, Do central)
- `TimerClock.new(bpm: 120)` - Clock interno independiente
- `Transport.new(clock, 4, 24)` - Transporte (4 beats/compás, 24 ticks/beat)
- `sequencer.at(position) { }` - Scheduling de eventos en posición absoluta
- `MIDIVoices` - Gestión de voces MIDI

### Configuración DAW
- **Pistas:** 1 pista MIDI con instrumento de piano
- **MIDI:** Conexión virtual (IAC Driver en macOS, loopMIDI en Windows)
- **Clock:** No necesario (musa-dsl es master)

---

## Demo 02: Series Explorer

**Nivel:** Básico | **Clock:** Master (TimerClock)

### Descripción Musical
Exploración auditiva de los diferentes constructores de series: melodías fijas con `S()`, escalas con `FOR()`, melodías aleatorias con `RND()`, y ritmos Fibonacci con `FIBO()`.

### Recursos musa-dsl
- `S(60, 64, 67, 72)` - Serie de valores literales
- `FOR(from: 60, to: 72, step: 2)` - Secuencia numérica
- `RND(60, 62, 64, 65, 67)` - Valores aleatorios
- `FIBO(start: 1, steps: 8)` - Serie Fibonacci
- `HARMO(base: 60)` - Serie armónica (overtones)
- `H(pitch: serie1, velocity: serie2)` - Series combinadas en hash
- `.map { }`, `.repeat(n)`, `.max_size(n)` - Operaciones de transformación
- `sequencer.play(serie) { |element| }` - Reproducción de series

### Configuración DAW
- **Pistas:** 4 pistas MIDI (una por tipo de serie)
- **Instrumentos:** Piano, Marimba, Bells, Bass Synth
- **MIDI:** 4 canales MIDI virtuales

---

## Demo 03: Canon

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

### Descripción Musical
Un canon clásico a dos voces donde la segunda voz entra 2 compases después de la primera, ejecutando exactamente la misma melodía. Demuestra el sistema buffered para lecturas independientes de una misma serie.

### Recursos musa-dsl
- `.buffered` - Crea serie con buffer compartido
- `.buffer` - Obtiene reader independiente del buffer
- `sequencer.wait(duration) { }` - Scheduling relativo (offset temporal)
- `sequencer.play(serie) { }` - Reproducción continua
- Múltiples instancias de `MIDIVoice`

### Configuración DAW
- **Pistas:** 2 pistas MIDI (Voz 1 y Voz 2)
- **Instrumentos:** Mismo instrumento o variaciones tímbricas (ej: dos flautas)
- **MIDI:** 2 canales MIDI virtuales

---

## Demo 04: Neumas

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

### Descripción Musical
Una pieza compuesta enteramente usando notación Neuma: grados de escala relativos, duraciones, dinámicas y ornamentos barrocos (trinos, mordentes). Utiliza el sistema de eventos (on/launch) para encadenar secciones.

### Recursos musa-dsl
- `using Musa::Extension::Neumas` - Refinement para `.to_neumas`
- Sintaxis: `'(0 1 mf) (+2 1) (-1 1/2) (+3 1 tr)'.to_neumas`
- Ornamentos: `tr` (trino), `mor` (mordente), `turn`, `st` (staccato)
- `NeumaDecoder.new(scale)` - Decodificador GDV
- `Transcriptor` - Pipeline de expansión de ornamentos a MIDI
- `on :event do ... end` / `launch :event` - Sistema de eventos

### Sintaxis Neuma
```
(grado duración dinámica ornamento)
  grado: 0, +2, -1 (absoluto o relativo)
  duración: 2 (blanca), 1 (negra), 1/2 (corchea), 1/4 (semicorchea)
  dinámica: ppp, pp, p, mp, mf, f, ff, fff
  ornamento: tr, mor, turn, st
```

### Configuración DAW
- **Pistas:** 1 pista MIDI
- **Instrumento:** Clavecín, violín u otro instrumento expresivo

---

## Demo 05: Markov

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

### Descripción Musical
Melodías generativas donde cada nota y duración se determinan probabilísticamente usando cadenas de Markov. Se presentan tres estilos: diatónico (clásico), jazz (cromático), minimalista (repetitivo). Usa el sistema de eventos (on/launch) para encadenar secciones.

### Recursos musa-dsl
- `Markov.new(transitions:, start:, finish:)` - Constructor de cadena
- Transiciones equiprobables: `{ 0 => [2, 4, 7] }`
- Transiciones ponderadas: `{ 0 => { 2 => 0.4, 4 => 0.4, 7 => 0.2 } }`
- Transiciones dinámicas: `{ state => proc { |history| ... } }`
- `.max_size(n)` - Limitar longitud
- `H(grade:, duration:, velocity:)` - Combinar series en hash
- `on :event do ... end` / `launch :event` - Sistema de eventos
- `control.after(delay) { }` - Encadenar tras completar play

### Configuración DAW
- **Pistas:** 3 pistas MIDI (una por estilo)
- **Instrumentos:** Diferenciados por estilo

---

## Demo 06: Variatio

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

### Descripción Musical
Un motivo de 4 notas con todas sus variaciones posibles de transposición, ritmo y dirección (normal/invertido), generando 32 versiones únicas automáticamente mediante producto cartesiano. Usa el sistema de eventos para encadenar la reproducción.

### Recursos musa-dsl
- `Variatio.new(:name) { field; constructor }` - Definición de variatio
- `field :transpose, [0, 2, 4, 7]` - Campo con opciones
- `field :direction, [:normal, :reverse]` - Motivo normal o al revés
- `constructor { |transpose:, articulation:| }` - Bloque constructor
- `.run` - Genera todas las combinaciones (Array)
- `H(grade:, duration:, velocity:)` - Convertir variación a serie
- `on :event` / `launch :event` - Sistema de eventos

### Configuración DAW
- **Pistas:** 1 pista MIDI
- **Instrumento:** Piano, cuerdas

---

## Demo 07: Scale Navigator

**Nivel:** Intermedio | **Clock:** Master (TimerClock)

### Descripción Musical
Exploración de las 40+ escalas del sistema con modulaciones dinámicas entre modos griegos, escalas simétricas y escalas étnicas, manteniendo coherencia melódica.

### Recursos musa-dsl
- Escalas: `.major`, `.minor`, `.dorian`, `.phrygian`, `.lydian`, `.mixolydian`, `.locrian`
- Escalas simétricas: `.whole_tone`, `.diminished_hw`, `.diminished_wh`
- Escalas étnicas: `.double_harmonic`, `.hungarian_minor`, `.phrygian_dominant`
- Funciones: `.tonic`, `.dominant`, `.mediant`, `.subdominant`
- Intervalos: `note.up(:P5)`, `note.down(:M3)`
- Acordes: `note.chord(:seventh)`
- Metadatos: `scale.metadata[:brightness]`, `[:family]`

### Configuración DAW
- **Pistas:** 2 pistas MIDI (melodía y pads armónicos)

---

## Demo 08: Voice Leading

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

### Descripción Musical
Progresión armónica a 4 voces con conducción de voces generada automáticamente usando reglas de contrapunto clásico: evitar quintas paralelas, movimiento gradual, resolución de sensibles.

### Recursos musa-dsl
- `Rules.new { grow; cut; ended_when }` - Sistema de reglas
- `grow 'name' { |state, history| branch(option) }` - Regla de expansión
- `cut 'name' { |state, history| prune if condition }` - Regla de poda
- `ended_when { |state, history| condition }` - Condición de fin
- `.apply([seeds])` - Generar árbol de posibilidades
- `.combinations` - Obtener resultados válidos

### Configuración DAW
- **Pistas:** 4 pistas MIDI (Soprano, Alto, Tenor, Bass)
- **Instrumentos:** Cuerdas o viento

---

## Demo 09: Darwin

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

### Descripción Musical
Genera 100 melodías aleatorias, las evalúa por criterios estéticos (contorno melódico, variedad de intervalos, resolución tonal) y selecciona las 5 mejores para reproducir.

### Recursos musa-dsl
- `Darwin.new { measures { |obj| feature; dimension; die } }` - Evaluador
- `feature :name if condition` - Característica binaria
- `dimension :name, value` - Dimensión continua (normalizada)
- `die if condition` - Eliminar candidato no viable
- `weight feature: 2.0, dimension: -0.5` - Pesos de evaluación
- `.select(population)` - Ordenar por fitness

### Configuración DAW
- **Pistas:** 5 pistas MIDI (mejores melodías)
- **Reproducción:** Secuencial o simultánea

---

## Demo 10: Grammar

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

### Descripción Musical
Patrones rítmicos y melódicos generados por gramática formal: estructura A-B-A donde cada sección se expande según reglas gramaticales, creando variaciones coherentes.

### Recursos musa-dsl
- `include Musa::GenerativeGrammar` - Módulo de gramáticas
- `N('note', size: 1)` - Nodo terminal
- `(a | b)` - Alternativa (OR)
- `a + b` - Concatenación
- `.repeat(min:, max:)` - Repetición
- `.limit { |options| condition }` - Restricción
- `.options(content: :join)` - Generar combinaciones
- `PN()` - Proxy node para recursión

### Configuración DAW
- **Pistas:** 2 pistas MIDI (melodía y acompañamiento rítmico)

---

## Demo 11: Matrix

**Nivel:** Avanzado | **Clock:** Master (TimerClock)

### Descripción Musical
Gestos sonoros definidos como matrices de puntos en espacio multidimensional (tiempo, pitch, velocity), convertidos a secuencias reproducibles.

### Recursos musa-dsl
- `using Musa::Extension::Matrix` - Refinement para matrices
- `Matrix[[0, 60, 100], [0.5, 72, 80], [1, 65, 90]]` - Definición de gesto
- `.to_p(time_dimension: 0)` - Conversión a P sequences
- `.condensed_matrices` - Unión de gestos conectados
- `sequencer.play_timed(p_sequence)` - Reproducción temporizada

### Configuración DAW
- **Pistas:** 1 pista MIDI con instrumento expresivo
- **Opcional:** Automatización de parámetros (pan, filtro)

---

## Demo 12: DAW Sync

**Nivel:** Intermedio | **Clock:** Slave (InputMidiClock)

### Descripción Musical
El DAW (Bitwig o Ableton) es el master clock. musa-dsl espera MIDI Start y sincroniza sus eventos al tempo del proyecto DAW. Al cambiar el tempo en el DAW, musa-dsl sigue automáticamente.

### Recursos musa-dsl
- `InputMidiClock.new(midi_input)` - Recibe clock del DAW
- `transport.on_start { }` - Callback al recibir MIDI Start
- `transport.after_stop { }` - Callback al recibir MIDI Stop
- `transport.on_position_change { }` - Callback al cambiar posición

### Configuración DAW
- **MIDI Clock:** Habilitar salida de MIDI Clock hacia musa-dsl
- **Transport:** Enviar mensajes Start/Stop/Continue
- **Pistas:** Las necesarias para los instrumentos
- **Nota:** El tempo se controla desde el DAW

---

## Demo 13: Live Coding

**Nivel:** Avanzado | **Clock:** Slave (InputMidiClock)

### Descripción Musical
Performance de live coding donde el DAW controla el tempo y musa-dsl genera contenido musical en tiempo real. El código se puede modificar mientras la música suena.

### Recursos musa-dsl
- `InputMidiClock` - Sincronización con DAW
- `sequencer.every(interval, duration:) { }` - Loops modificables
- `def reload; load 'score.rb'; end` - Hot-reload de código
- `REPL` / MusaLCE server - Evaluación remota de código
- VSCode + MusaLCE extension

### Configuración DAW
- **DAW:** Bitwig o Ableton como master clock
- **MusaLCE:** Instalar extensión de VSCode
- **Pistas:** Múltiples pistas MIDI para diferentes voces

---

## Demo 14: Clock Modes

**Nivel:** Intermedio | **Clock:** Ambos

### Descripción Musical
Misma composición ejecutada en ambos modos para mostrar la diferencia práctica entre master y slave clock.

### Estructura
```
demo-14-clock-modes/
├── musa/
│   ├── main_master.rb    # Versión con TimerClock (musa-dsl como master)
│   ├── main_slave.rb     # Versión con InputMidiClock (DAW como master)
│   ├── score.rb          # Composición compartida
│   └── Gemfile
└── README.md             # Guía de cuándo usar cada modo
```

### Cuándo usar cada modo

| Escenario | Modo recomendado |
|-----------|------------------|
| Composición autónoma sin DAW | Master (TimerClock) |
| Instalación sonora | Master (TimerClock) |
| Integración con proyecto DAW existente | Slave (InputMidiClock) |
| Live coding con sincronización | Slave (InputMidiClock) |
| Colaboración con otros músicos en DAW | Slave (InputMidiClock) |
| Grabación en DAW con tempo variable | Slave (InputMidiClock) |

---

## Demo 15: OSC SuperCollider

**Nivel:** Avanzado | **Protocolo:** OSC | **Inspirado en:** The Washing Machine (2016)

### Descripción Musical
Control de síntesis granular en SuperCollider via OSC. Múltiples voces de granulador controladas desde musa-dsl con parámetros: volumen, pitch, tamaño de ventana.

### Recursos musa-dsl + OSC
- `gem 'osc-ruby'` - Cliente/servidor OSC
- `OSC::Client.new('localhost', 57120)` - Puerto default SuperCollider
- `client.send OSC::Message.new('/vol', voice_index, value)`
- Mensajes: `/vol`, `/rate`, `/wsize`, `/input_channel`, `/output_channel`

### Archivos
- `main.rb` - Setup OSC client
- `voices.rb` - Clase Voice con control OSC
- `score.rb` - Composición
- `supercollider/granular.scd` - SynthDef de ejemplo

### Configuración
1. Iniciar SuperCollider con el SynthDef cargado
2. Ejecutar `ruby main.rb`
3. Verificar control de parámetros

---

## Demo 16: OSC Max/MSP

**Nivel:** Avanzado | **Protocolo:** OSC | **Inspirado en:** Elevator Door series (2017)

### Descripción Musical
Control de módulos de audio espacial en Max/MSP. Routing dinámico a múltiples altavoces, control de posición y automatización espacial.

### Recursos musa-dsl + OSC
- `OSC::Client.new('localhost', 8001)` - Puerto hacia Max
- Mensajes: `/start`, `/stop`, `/position`, `/modul`, `/space`
- Clase `Modules` para matriz de módulos
- Clase `Speakers` para asignación dinámica

### Archivos
- `main.rb` - Setup con InputMidiClock + OSC
- `modules.rb` - Control de módulos espaciales
- `speakers.rb` - Allocator de altavoces
- `score.rb` - Composición espacial

### Configuración
1. Abrir patch Max/MSP incluido
2. Configurar routing de audio
3. Ejecutar `ruby main.rb`

---

## Demo 17: Event Architecture

**Nivel:** Intermedio | **Clock:** Master (TimerClock) | **Inspirado en:** Estudio para clave nº1 (2019)

### Descripción Musical
Composición estructurada mediante eventos nombrados. Las fases de la pieza se lanzan mediante `launch :event` y se capturan con `on :event`, permitiendo flujo no-lineal.

### Recursos musa-dsl
- `on :event_name do |params| end` - Suscripción a evento
- `launch :event_name, params` - Disparar evento
- `control.after { }` - Callback post-ejecución
- Contadores de estado para coordinación

### Código ejemplo
```ruby
on :intro_finished do
  launch :development, episode: 1
end

on :development do |episode:|
  ctrl = play(material) { |n| voice.note(**n) }
  ctrl.after { launch :coda if episode >= 4 }
end
```

---

## Demo 18: Parameter Automation

**Nivel:** Intermedio | **Clock:** Master | **Inspirado en:** Estudio para piano nº3 (2019)

### Descripción Musical
Automatización de parámetros musicales (velocity, duración, articulación) usando envolventes sinusoidales y rampas lineales.

### Recursos musa-dsl
- `SIN(steps:, center:, amplitude:, start_value:)` - Generador sinusoidal
- `SIN().repeat(2)` - Envolvente ida y vuelta
- `move from:, to:, duration:, every: do |v| end` - Rampa lineal
- Números primos para períodos no-repetitivos

### Código ejemplo
```ruby
# Velocity sinusoidal
vel_s = SIN(steps: 13, center: 70, amplitude: 40).repeat(2)

# CC automation
move from: 0, to: 127, duration: 8, every: 1/8r do |v|
  voice.control_change(1, v.to_i)
end
```

---

## Demo 19: Advanced Series

**Nivel:** Avanzado | **Clock:** Master | **Inspirado en:** Estudio Fibonacci (2018)

### Descripción Musical
Operaciones avanzadas sobre series: combinación hash, transformaciones funcionales, series anidadas, y estructuras Fibonacci palindrómicas.

### Recursos musa-dsl
- `H(pitch:, duration:, velocity:)` - Series hash sincronizadas
- `.eval { |v| transform(v) }` - Transformación por elemento
- `.duplicate`, `.reverse`, `.shift(n)` - Operaciones de copia
- `SS(series_of_series)` - Series anidadas
- `FIBO().max_size(n)` - Fibonacci truncado

### Código ejemplo
```ruby
p = FIBO().max_size(8) + FIBO().max_size(8).reverse
d = p.duplicate.eval { |v| Rational(v, 16) }
v = p.eval { |v| 30 + (v / 13.0) * 70 }

h = H(pitch: p, duration: d, velocity: v)
play(h) { |note| voice.note(**note) }
```

---

## Demo 20: Neuma Files

**Nivel:** Intermedio | **Clock:** Master (TimerClock) | **Inspirado en:** Pieza pseudo-barroca (2018)

### Descripción Musical
Composición usando archivos `.neu` externos con variables, referencias y operadores. Transcriptor completo con todos los ornamentos barrocos.

### Recursos musa-dsl
- `Musa::Neumalang.parse_file('neumas.neu')` - Carga archivo
- Variables en .neu: `@motif = [ I.1/4.mf II.+1/8.tr ]`
- Referencias: `@phrase = [ @motif @motif.reverse ]`
- Operadores: `||` (alternativa), `+` (concatenación)
- Transcriptor completo con Trill, Mordent, Turn, Appogiatura

### Archivo neumas.neu ejemplo
```
@a = [ I.1/4.mf  II.+1/8.tr  III.-1/8.mor  IV.1/2 ]
@b = [ V.1/4  IV.-1/8  III  II  I.1/2 ]
@phrase = [ @a || @b ]
@coda = [ I.1.ff ]
```

---

## Demo 21: Fibonacci Episodes

**Nivel:** Avanzado | **Clock:** Master (TimerClock) | **Inspirado en:** Estudio Fibonacci para piano nº2 (2018)

### Descripción Musical
Estructura composicional basada en números Fibonacci. Cada episodio lanza fibo(n) threads paralelos, con tracking de finalización y transiciones coordinadas.

### Recursos musa-dsl
- Función `fibo(n)` para números Fibonacci
- `on :next_episode do |episode| end` - Handler de episodio
- `controls_playing[episode]` - Tracking de threads activos
- `.after { launch :thread_finished }` - Sincronización

### Código ejemplo
```ruby
on :next_episode do |episode|
  fibo(episode).times do |t|
    ctrl = play(material_for(t)) { |n| voice.note(**n) }
    controls_playing[episode] << ctrl
    ctrl.after { launch :finished, episode }
  end
end
```

---

## Demo 22: Multi-Phase

**Nivel:** Avanzado | **Clock:** Master (TimerClock) | **Inspirado en:** Estudio para piano nº3 (2019)

### Descripción Musical
Composición en múltiples fases (intro, desarrollo, clímax, coda) con estado complejo, series que se reinician, y transiciones controladas por flags.

### Recursos musa-dsl
- Fases: `on :phase1_start`, `on :phase2_start`, etc.
- `.restart` para reiniciar series
- `.i` para nuevas instancias de iterador
- Flags de estado: `phase1_passed = false`
- Transiciones condicionales entre fases

### Código ejemplo
```ruby
phase1_passed = false

on :phase1_next_episode do
  if duration_s = duration_ss.v
    amplitude_s.restart
    launch :phase1_thread, pitch, add_s.i, duration_s.i
  else
    phase1_passed = true
    launch :phase2_start
  end
end
```

---

## Estructura de Carpetas

Cada demo sigue esta estructura:

```
demo-XX-nombre/
├── musa/
│   ├── main.rb         # Setup: clock, transport, MIDI, escalas
│   ├── score.rb        # Composición modular (se puede recargar)
│   └── Gemfile         # gem 'musa-dsl', gem 'midi-communications'
├── README.md           # Instrucciones específicas de la demo
├── bw/                 # (Crear manualmente) Proyecto Bitwig
└── live/               # (Crear manualmente) Proyecto Ableton Live
```

---

## Requisitos

- Ruby 3.4+
- Gems: `musa-dsl`, `midi-communications`
- DAW: Bitwig Studio o Ableton Live
- MIDI virtual: IAC Driver (macOS) o loopMIDI (Windows)

## Ejecución

```bash
cd demo-XX-nombre/musa
bundle install
ruby main.rb
```

Para demos con **Master Clock**: el script inicia inmediatamente.
Para demos con **Slave Clock**: el script espera MIDI Start del DAW.

---

## License

This work is dedicated to the public domain under [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/).

You are free to copy, modify, and use this code for any purpose, including commercial, without attribution.
