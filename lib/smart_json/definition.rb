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
      definitions, symbols, hash = extract_smart_json_definitions @options
      base = model.as_styled_smart_json definitions, loaded: loaded, default: default
      symbols.each do |name|
        base[name] = model.send(name).try :as_styled_smart_json, [], loaded: loaded
      end
      hash.try :each do |key, value|
        reflection = @klass.reflections[key.to_s] || @klass.reflections[key]
        definition = SmartJSON::Definition.new(reflection.klass, value)
        base[key] = model.send(key).try :as_styled_smart_json, [definition], loaded: loaded
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
    definitions, symbols, hash = extract_smart_json_definitions @options
    includes = @klass.smart_json_includes definitions
    symbols.each do |child|
      includes[child] ||= {}
    end
    hash.try :each do |key, value|
      definition = @klass.smart_json_definitions[key]
      includes[key] = {}
      if definition
        incs = definition.includes
      else
        reflection = @klass.reflections[key.to_s] || @klass.reflections[key]
        incs = SmartJSON::Definition.new(reflection.klass, value).includes
      end
      SmartJSON::Util.deep_merge includes[key], incs
    end
    if @dependency
      SmartJSON::Util.deep_merge @dependency.dup, includes
    else
      includes
    end
  end

  def extract_smart_json_definitions options
    options = Array.wrap options
    styles = options.select do |style|
      @klass.smart_json_definitions.try :[], style
    end
    others = options - styles
    definitions = styles.map{|style|@klass.smart_json_definitions[style]}
    [definitions, others.grep(Symbol), others.grep(Hash).inject(&:merge)]
  end
end
