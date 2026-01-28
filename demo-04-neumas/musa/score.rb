# Demo 04: Neumas - Composición
#
# Notación textual Neuma y su integración con Series, Decoders y Eventos
#
# Conceptos:
# - Sintaxis Neuma: (grado duración dinámica adorno)
# - to_neumas convierte string → Serie de GDVD (diferencial)
# - NeumaDecoder convierte GDVD → GDV (absoluto)
# - Transcriptor expande adornos (tr, mor, st) a notas reales
# - play() con decoder itera y decodifica automáticamente
# - GDV.to_pdv(scale) convierte grados → pitches MIDI
# - Eventos (on/launch) para encadenar secciones
#
# Ver también: demo-20-neuma-files para cargar neumas desde archivos
# externos (.neumas) y uso avanzado de ornamentos

using Musa::Extension::Neumas

module TheScore
  def score
    voice = v(0)

    # ========================================================================
    # Sistema de Eventos: Encadenamiento de secciones
    # ========================================================================

    on :section_1 do
      puts "\n[Sección 1] play() con decoder - forma idiomática"
      puts "  Neuma: (0 1/2 mf) (+2 1/2) (+2 1/2) (+1 1/2)"
      puts "  Grados relativos: 0=Do, +2=Re, +2=Mi, +1=Fa"

      phrase1 = '(0 1/2 mf) (+2 1/2) (+2 1/2) (+1 1/2)'.to_neumas

      control = play phrase1, decoder: decoder, mode: :neumalang do |gdv|
        pdv = gdv.to_pdv(scale)
        puts "  Grado #{gdv[:grade]} → pitch #{pdv[:pitch]}"
        voice.note(pdv[:pitch], velocity: pdv[:velocity], duration: pdv[:duration])
      end

      control.after { wait(1/4r) { launch :section_2 } }
    end

    on :section_2 do
      puts "\n[Sección 2] Dinámicas explícitas"
      puts "  Crescendo: pp → p → mp → mf → f"

      crescendo = '(0 1/2 pp) (+2 1/2 p) (+2 1/2 mp) (+2 1/2 mf) (+1 1 f)'.to_neumas

      control = play crescendo, decoder: decoder, mode: :neumalang do |gdv|
        pdv = gdv.to_pdv(scale)
        puts "  Grado #{gdv[:grade]}, velocity #{gdv[:velocity]} → MIDI #{pdv[:velocity].round}"
        voice.note(pdv[:pitch], velocity: pdv[:velocity], duration: pdv[:duration])
      end

      control.after { wait(1/4r) { launch :section_3 } }
    end

    on :section_3 do
      puts "\n[Sección 3] Silencios con (silence)"
      puts "  Patrón: nota - silencio - nota - silencio - nota larga"

      con_silencios = '(0 1/2 f) (silence 1/2) (+2 1/2 f) (silence 1/2) (+2 1 ff)'.to_neumas

      control = play con_silencios, decoder: decoder, mode: :neumalang do |gdv|
        if gdv[:silence]
          puts "  [silencio #{gdv[:duration]}]"
        else
          pdv = gdv.to_pdv(scale)
          puts "  Nota: pitch=#{pdv[:pitch]}"
          voice.note(pdv[:pitch], velocity: pdv[:velocity], duration: pdv[:duration])
        end
      end

      control.after { wait(1/4r) { launch :section_4 } }
    end

    on :section_4 do
      puts "\n[Sección 4] Ritmos variados"
      puts "  negra + corcheas + semicorcheas"

      ritmos = '(0 1 mf) (+4 1/2) (-2 1/4) (+1 1/4) (-1 1/4) (+2 1/4) (-4 1/2)'.to_neumas

      control = play ritmos, decoder: decoder, mode: :neumalang do |gdv|
        next if gdv[:silence]
        pdv = gdv.to_pdv(scale)
        dur_name = case pdv[:duration]
                   when 1/4r then "negra"
                   when 1/8r then "corchea"
                   when 1/16r then "semicorchea"
                   else pdv[:duration].to_s
                   end
        puts "  #{dur_name}: pitch #{pdv[:pitch]}"
        voice.note(pdv[:pitch], velocity: pdv[:velocity], duration: pdv[:duration])
      end

      control.after { wait(1/4r) { launch :section_5 } }
    end

    on :section_5 do
      puts "\n[Sección 5] Melodía con adornos"
      puts "  Trinos (tr), mordentes (mor) y staccato (st)"

      # Sintaxis: (grado duración dinámica adorno)
      melodia = '
        (0 1/2 mf) (+2 1/4) (+1 1/4) (+2 1/2 tr) (+2 1/2)
        (+1 1/4 f st) (-1 1/4 st) (-2 1/2) (+1 1 mf tr)
        (-1 1/2 mor) (-2 1/4) (-1 1/4) (-2 1/2 p) (-2 1/2)
        (+1 1/4 mp) (+1 1/4) (+2 1 f tr)
      '.to_neumas

      control = play melodia, decoder: decoder, mode: :neumalang do |gdv|
        next if gdv[:silence]
        pdv = gdv.to_pdv(scale)
        voice.note(pdv[:pitch], velocity: pdv[:velocity], duration: pdv[:duration])
      end

      control.after(1/4r) do
        puts "\n¡Demo de Neumas terminada!"
        transport.stop
      end
    end

    # Inicio
    at 1 do
      launch :section_1
    end
  end
end
