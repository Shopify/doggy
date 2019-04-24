class Hash
  def sort_by_key(&block)
    self.keys.sort(&block).reduce({}) do |seed, key|
      seed[key] = self[key]
      if seed[key].is_a?(Hash)
        seed[key] = seed[key].sort_by_key(&block)
      elsif seed[key].is_a?(Array)
        seed[key] = seed[key].map { |i| i.sort_by_key(&block) }
      end
      seed
    end
  end
end
