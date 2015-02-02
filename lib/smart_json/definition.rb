class SmartJSON::Definition
  attr_reader :dependency
  def initialize klass, options, block=nil
    @klass = klass
    @block = block
    @options = Array.wrap options
  end

  def have_block?
    @block.present? || @options.any?{|style|
      definition = @klass.smart_json_definitions.try :[], style
      definition && definition.have_block?
    }
  end

  def require *options
    @dependency = SmartJSON::Util.options_to_hash options
  end

  def serialize model, loaded: loaded, default: default
    if @options.present?
      definitions, others = extract_smart_json_definitions_and_others @options
      base = model.as_styled_smart_json definitions, loaded: loaded, default: default
      symbols = others.select{|a|Symbol === a}
      hashes = others.select{|a|Hash === a}
      symbols.each do |name|
        base[name] = model.send(name).try :as_styled_smart_json, [], loaded: loaded
      end
      hashes.each do |hash|
        hash.each do |key, value|
          reflection = @klass.reflections[key.to_s] || @klass.reflections[key]
          definition = SmartJSON::Definition.new(reflection.klass, value)
          base[key] = model.send(key).try :as_styled_smart_json, [definition], loaded: loaded
        end
      end
    end
    if @block
      overrides = model.instance_exec &@block
    else
      overrides = {}
    end
    if base
      SmartJSON::Util.deep_merge base, overrides
    else
      overrides
    end
  end

  def includes
    return @dependency unless @options.present?
    definitions, others = extract_smart_json_definitions_and_others @options
    includes = @klass.smart_json_includes definitions
    symbols = others.select{|a|Symbol === a}
    hashes = others.select{|a|Hash === a}
    symbols.each do |child|
      includes[child] ||= {}
    end
    hashes.each do |hash|
      hash.each do |key, value|
        definition = @klass.smart_json_definitions[key]
        if definition
          includes[key] = definition.includes
        else
          reflection = @klass.reflections[key.to_s] || @klass.reflections[key]
          includes[key] = SmartJSON::Definition.new(reflection.klass, value).includes
        end
      end
    end
    if @dependency
      SmartJSON::Util.deep_merge @dependency.dup, includes
    else
      includes
    end
  end

  def extract_smart_json_definitions_and_others options
    options = Array.wrap options
    styles = options.select{|t|Symbol === t}.select do |style|
      reflection = @klass.reflections[style.to_s] || @klass.reflections[style]
      definition = @klass.smart_json_definitions.try :[], style
      raise "both reflection and style '#{style}' defined for '#{name}'" if reflection && definition
      raise "no reflection or style '#{style}' defined for '#{name}'" if reflection.nil? && definition.nil?
      definition.present?
    end
    others = options - styles
    definitions = styles.map{|style|@klass.smart_json_definitions[style]}
    [definitions, others]
  end

end
