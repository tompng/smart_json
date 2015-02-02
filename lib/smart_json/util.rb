module SmartJSON::Util
  class << self
    def deep_merge hash, hash2
      hash2.each do |key, value|
        if hash[key] && Hash === value
          deep_merge hash[key], value
        else
          hash[key] = value
        end
      end
      hash
    end
    def options_to_hash options
      out = {}
      options.grep Symbol do |name|
        out[name] = {}
      end
      options.grep Hash do |hash|
        hash.each do |name, value|
          out[name] = options_to_hash [*value]
        end
      end
      out
    end
    def hash_to_includes_options hash
      hash.map do |key, value|
        if value.empty?
          key
        else
          {key => hash_to_includes_options(value)}
        end
      end
    end
  end
end
