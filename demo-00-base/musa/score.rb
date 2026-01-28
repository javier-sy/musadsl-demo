module TheScore
  using Musa::Extension::Neumas

  def score
    melody = '(0 1 mf) (+2 1) (+2 1) (+1 1)'.to_neumas

    at 1 do
      neuma melody, voice: v(0)
    end
  end
end
