# Demo 03: Canon - Composición
#
# Canon clásico usando series buffered para lecturas independientes
# NOTA: play() requiere series de hashes creadas con H()

module TheScore
  def score
    dux = v(0)    # Voz líder (Dux)
    comes = v(1)  # Voz seguidora (Comes)

    # ========================================================================
    # Melodía del Canon
    # ========================================================================
    # Una melodía de 16 notas que funciona bien en canon

    melody_grades = S(
      0, 2, 4, 2,    # Compás 1-2: Do Re Mi Re
      5, 4, 2, 0,    # Compás 3-4: Fa Mi Re Do
      7, 5, 4, 2,    # Compás 5-6: Sol Fa Mi Re
      4, 2, 0, -1    # Compás 7-8: Mi Re Do Si
    )

    melody_dur = S(1/4r).repeat(16)  # Todas negras (4 compases total)
    melody_vel = S(85).repeat(16)

    # ========================================================================
    # Serie Buffered con H()
    # ========================================================================
    #
    # SERIES BUFFERED
    # ================
    # Las series normales son iteradores lazy de un solo uso.
    # .buffered() crea un buffer compartido que permite múltiples
    # lecturas independientes en paralelo mediante .buffer
    #
    # Sin buffered: cada reader avanzaría la MISMA serie
    # Con buffered: cada reader tiene su propio cursor
    #
    # Combinamos las series en un H() y luego aplicamos .buffered
    # Cada .buffer crea un reader independiente

    melody = H(grade: melody_grades, duration: melody_dur, velocity: melody_vel)
    buffered_melody = melody.buffered

    # Dos readers independientes de la misma melodía
    melody_dux = buffered_melody.buffer
    melody_comes = buffered_melody.buffer

    # ========================================================================
    # Voz 1: Dux (líder) - Compases 1-8
    # ========================================================================

    at 1 do
      puts "[Dux] Melodía principal comienza"

      play melody_dux do |note|
        pitch = scale[note[:grade]].pitch
        dux.note(pitch: pitch, velocity: note[:velocity], duration: note[:duration])
      end
    end

    # ========================================================================
    # Voz 2: Comes (seguidora) - 1 compás después del Dux
    # ========================================================================

    at 2 do
      puts "[Comes] Imitación comienza (1 compás después)"

      comes_control = play melody_comes do |note|
        # Transposición: -4 grados = quinta inferior
        pitch = scale[note[:grade] - 4].pitch
        comes.note(pitch: pitch, velocity: note[:velocity] - 10, duration: note[:duration])
      end

      # ======================================================================
      # Coda: Cadencia final V-I
      # ======================================================================

      comes_control.after do
        puts "[Ambas voces] Cadencia final"

        # Acorde de dominante
        dux.note(pitch: scale[4].pitch, velocity: 80, duration: 1/2r)
        comes.note(pitch: scale[7].pitch - 12, velocity: 80, duration: 1/2r)

        wait 1/2r do |_|
          # Acorde de tónica
          dux.note(pitch: scale[0].pitch, velocity: 90, duration: 1/2r)
          comes.note(pitch: scale[0].pitch - 12, velocity: 90, duration: 1/2r)

          wait 1/2r do |_|
            puts "\n¡Canon terminado!"
            transport.stop
          end
        end
      end
    end
  end
end
