# Max/MSP Patches para Demo 16: Secuenciador Reactivo

## Arquitectura

```
┌─────────────────────┐         ┌──────────────────────┐
│  Patch: Controller  │         │      musa-dsl        │
│                     │         │                      │
│  [sliders]──────────┼── OSC ──▶  InputHandler (:8000)│
│   root, mode,       │  :8000  │     ↓ launch()       │
│   density, register │         │  on :param_changed   │
└─────────────────────┘         │     ↓                │
                                │  every 1/8r          │
┌─────────────────────┐         │     ↓                │
│  Patch: Synth       │         │                      │
│                     │         │                      │
│  [synth]◀───────────┼── OSC ──┤  OscOutput (:8001)   │
│   cycle~/saw~       │  :8001  │                      │
└─────────────────────┘         └──────────────────────┘
```

## Puertos OSC

| Puerto | Dirección | Contenido |
|--------|-----------|-----------|
| 8000 | Max → musa-dsl | Parámetros de control |
| 8001 | musa-dsl → Max | Notas generadas |

## Mensajes que Max ENVÍA (puerto 8000)

| Mensaje | Argumento | Rango | Descripción |
|---------|-----------|-------|-------------|
| `/root` | int | 0-11 | Nota raíz (0=C, 1=C#, ..., 11=B) |
| `/mode` | int | 0-3 | Modo: 0=Mayor, 1=Menor, 2=Dórico, 3=Mixolidio |
| `/density` | int | 1-8 | Notas por compás |
| `/register` | int | -2..2 | Desplazamiento de octava |

## Mensajes que Max RECIBE (puerto 8001)

| Mensaje | Argumentos | Descripción |
|---------|------------|-------------|
| `/note` | int, int, int | pitch (MIDI), velocity (0-127), duration (ms) |

## Patch 1: Controller (sliders → musa-dsl)

Patch de control con 4 sliders que envían parámetros via OSC.

```max
── Root (nota raíz) ──
[slider]  rango 0-11
    │
[prepend /root]
    │
[udpsend localhost 8000]


── Mode (modo de escala) ──
[umenu]  items: Mayor, Menor, Dórico, Mixolidio
    │
[prepend /mode]
    │
[udpsend localhost 8000]


── Density (notas por compás) ──
[slider]  rango 1-8
    │
[prepend /density]
    │
[udpsend localhost 8000]


── Register (octava) ──
[slider]  rango -2..2
    │
[prepend /register]
    │
[udpsend localhost 8000]
```

Cada slider usa `[prepend /address]` para construir el mensaje OSC
y lo envía al puerto 8000 donde musa-dsl escucha.

## Patch 2: Synth (musa-dsl → sonido)

Patch receptor que convierte mensajes `/note` en audio.

### Recepción de notas

```max
[udpreceive 8001]
    │
[route /note]
    │
[unpack i i i]     ── pitch, velocity, duration_ms
```

### Synth mínimo

```max
[unpack i i i]
  │      │        │
  │      │      [/ 1000.]              ── duration en segundos
  │      │        │
  │      │      [pack 0. $1 0. 20]     ── envelope: attack, sustain, release
  │      │        │
  │      │      [line~]                ── envelope
  │      │        │
  │    [/ 127.]   │                    ── velocity normalizada
  │      │        │
  │    [*~]───────┘                    ── velocity × envelope
  │      │
[mtof]   │                             ── MIDI → frecuencia
  │      │
[cycle~] │                             ── oscilador
  │      │
  └──[*~]┘                             ── oscilador × (velocity × envelope)
      │
    [dac~]
```

## Notas

- Los sliders de Max envían valores al moverlos — no hay polling
- musa-dsl genera notas continuamente; los cambios de slider afectan inmediatamente la próxima nota
- El pitch es MIDI estándar (60 = C4), usar `[mtof]` para convertir a frecuencia
- La duration en ms es orientativa para el envelope del synth
- Los dos patches pueden estar en el mismo archivo .maxpat o separados
