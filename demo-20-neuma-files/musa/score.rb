# Demo 20: Neuma Files & Transcriptor - Composición
#
# Demuestra:
# - Cargar archivo .neu externo
# - Usar neumas inline
# - Ornamentos expandidos por Transcriptor
# - Conversión GDV → PDV → MIDI
# - Encadenamiento de secciones con .after

module TheScore
  def play_neuma(neuma_string)
    serie = Neumalang.parse(neuma_string, decode_with: decoder)
    play serie, mode: :neumalang, decoder: decoder do |gdv|
      if gdv.is_a?(Musa::Datasets::GDV)
        pdv = gdv.to_pdv(scale)
        voice.note(**pdv)
      end
    end
  end

  def play_neuma_file(file_path)
    serie = Neumalang.parse_file(file_path)
    play serie, mode: :neumalang, decoder: decoder do |gdv|
      if gdv.is_a?(Musa::Datasets::GDV)
        pdv = gdv.to_pdv(scale)
        voice.note(**pdv)
      end
    end
  end

  def score
    at 1 do
      play_section_1
    end
  end

  # ==========================================================================
  # Sección 1: Neumas inline básicos
  # ==========================================================================

  def play_section_1
    puts "\n[Sección 1] Neumas inline básicos"
    puts "  Neuma: (0 1/4 mf) (2 1/4) (4 1/8) (5 1/8) (7 1/2)"

    control = play_neuma('(0 1/4 mf) (2 1/4) (4 1/8) (5 1/8) (7 1/2)')
    control.after { wait 1/4r do play_section_2 end }
  end

  # ==========================================================================
  # Sección 2: Neumas con cambios relativos
  # ==========================================================================

  def play_section_2
    puts "\n[Sección 2] Cambios relativos"
    puts "  Neuma con deltas: (0 1/4 mf) (+2 1/4) (+2 1/4) (-1 1/4) (-3 1/2)"

    control = play_neuma('(0 1/4 mf) (+2 1/4) (+2 1/4) (-1 1/4) (-3 1/2)')
    control.after { wait 1/4r do play_section_3 end }
  end

  # ==========================================================================
  # Sección 3: Neumas con ornamentos
  # ==========================================================================

  def play_section_3
    puts "\n[Sección 3] Ornamentos (Transcriptor)"
    puts "  Neuma con ornamentos: (0 1/2 mf tr) (2 1/4) (4 1/4 mor) (5 1/2)"
    puts "  El Transcriptor expande tr y mor a múltiples notas"

    control = play_neuma('(0 1/2 mf tr) (2 1/4) (4 1/4 mor) (5 1/2)')
    control.after { wait 1/4r do play_section_4 end }
  end

  # ==========================================================================
  # Sección 4: Cargar archivo .neu externo
  # ==========================================================================

  def play_section_4
    puts "\n[Sección 4] Archivo .neu externo"

    neu_file = File.join(File.dirname(__FILE__), 'melody.neu')
    puts "  Cargando: #{neu_file}"
    puts "  Variables: @motif, @motif_tr, @motif_up, @var1, @phrase"

    control = play_neuma_file(neu_file)
    control.after { wait 1/4r do play_section_5 end }
  end

  # ==========================================================================
  # Sección 5: Dinámicas y octavas
  # ==========================================================================

  def play_section_5
    puts "\n[Sección 5] Dinámicas y cambios de octava"
    puts "  Dinámicas: pp → p → mp → mf → f → ff"

    control = play_neuma('(0 1/4 pp) (0 1/4 p) (0 1/4 mp) (0 1/4 mf) (0 1/4 f) (0 1/4 ff)')

    control.after do
      puts "\n  Octavas: base → +o1 → +o2 → base"

      control2 = play_neuma('(0 1/4 mf) (0 +o1 1/4) (0 +o2 1/4) (0 -o1 1/4) (0 1/2)')
      control2.after { wait 1/4r do play_section_6 end }
    end
  end

  # ==========================================================================
  # Sección 6: Silencios
  # ==========================================================================

  def play_section_6
    puts "\n[Sección 6] Silencios"
    puts "  Con silencios intercalados"

    control = play_neuma('(0 1/4 mf) (silence 1/4) (2 1/4) (silence 1/2) (4 1/4) (5 1/4) (7 1)')

    control.after do
      wait 1/4r do
        puts "\n¡Demo de Neuma Files terminada!"
        transport.stop
      end
    end
  end
end
