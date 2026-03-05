module TheScore
  using Musa::Extension::Neumas

  def score
    melody = '(0 1 mf) (+2 1) (+2 1) (+1 1)'.to_neumas

    at 1 do
      neuma melody, voice: v(0)
    end

    at 2r do
      neuma melody, voice: v(1)
    end

    at 3r do
      neuma melody, voice: v(2)
    end

    at 4r do
      neuma melody, voice: v(3)
    end
  end
end
