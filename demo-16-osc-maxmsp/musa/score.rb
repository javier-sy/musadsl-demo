# Demo 16: OSC Max/MSP - Secuenciador Reactivo
#
# Arquitectura push: InputHandler lanza eventos cuando Max cambia params.
# Los handlers actualizan variables locales que el generador lee.
# El every solo se encarga del ritmo, no de samplear inputs.

module TheScore
  def score
    note_names = %w[C C# D D# E F F# G G# A A# B].freeze

    # Patrones rítmicos por densidad (8 slots = corcheas por compás)
    patterns = {
      1 => [1, 0, 0, 0, 0, 0, 0, 0],
      2 => [1, 0, 0, 0, 1, 0, 0, 0],
      3 => [1, 0, 0, 1, 0, 0, 1, 0],
      4 => [1, 0, 1, 0, 1, 0, 1, 0],
      5 => [1, 1, 0, 1, 0, 1, 0, 1],
      6 => [1, 1, 0, 1, 1, 0, 1, 1],
      7 => [1, 1, 1, 1, 1, 1, 1, 0],
      8 => [1, 1, 1, 1, 1, 1, 1, 1]
    }.freeze

    beat_ms = 60_000.0 / bpm
    dur_ms = (beat_ms / 2 * 0.8).round  # 80% gate de corchea

    rng = Random.new(42)
    grade = 0
    direction = 1

    # ========================================================================
    # Estado reactivo — actualizado por los handlers de eventos
    # ========================================================================

    initial = input.params
    current_scale = Scales.et12[440.0].send(initial[:mode])[60 + initial[:root]]
    current_pattern = patterns[initial[:density]]
    octave_offset = initial[:register] * 12

    # ========================================================================
    # Handlers: reaccionan a cambios de parámetros desde Max
    # ========================================================================

    rebuild_scale = proc do |params|
      root_midi = 60 + params[:root]
      current_scale = Scales.et12[440.0].send(params[:mode])[root_midi]
      root_name = note_names[params[:root]]
      mode_name = InputHandler::MODE_NAMES[params[:mode]]
      puts "  Escala: #{root_name} #{mode_name}"
    end

    on :root_changed do |params|
      rebuild_scale.call(params)
    end

    on :mode_changed do |params|
      rebuild_scale.call(params)
    end

    on :density_changed do |params|
      current_pattern = patterns[params[:density]]
      puts "  Densidad: #{params[:density]}"
    end

    on :register_changed do |params|
      octave_offset = params[:register] * 12
      puts "  Registro: #{params[:register]}"
    end

    # ========================================================================
    # Generador de notas — solo ritmo, lee estado reactivo
    # ========================================================================

    puts "\n=== Secuenciador reactivo ==="
    puts "Mueve los sliders en Max para controlar la música."
    puts

    at 1 do
      every 1/8r do
        bar_pos = ((position * 8).to_i) % 8

        next unless current_pattern[bar_pos] == 1

        # Movimiento pendular por grados (0-6)
        if grade >= 6
          direction = -1
        elsif grade <= 0
          direction = 1
        end
        grade += direction

        # Nota
        pitch = current_scale[grade].pitch.to_i + octave_offset
        velocity = 60 + rng.rand(30)

        osc_out.send_note(pitch, velocity, dur_ms)

        note_name = note_names[pitch % 12]
        octave = pitch / 12 - 1
        puts "    #{note_name}#{octave} (grado #{grade}, vel #{velocity})"
      end
    end
  end
end
