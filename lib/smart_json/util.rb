module SmartJSON::Util
  class << self
    def deep_merge hash, hash2
      return hash unless hash2
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
          out[name] = options_to_hash Array.wrap(value)
        end
      end
      out
    end
    def hash_to_includes_options hash
      array_options = []
      hash_options = {}
      hash.each do |key, value|
        if value.empty?
          array_options << key
        else
          hash_options[key] = hash_to_includes_options value
        end
      end
      array_options << hash_options if hash_options.present?
      array_options
    end
  end
end
