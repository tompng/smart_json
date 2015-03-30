class SmartJSON::Definition
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

  def require *options, &block
    @dependency = ->(param){
      SmartJSON::Util.options_to_hash [*options, *block.try(:call, param)]
    }
  end

  def dependency param
    @dependency.try :call, param
  end

  def serialize model, param, loaded: true, default: true
    if @options.present?
      definitions, symbols, hash = extract_smart_json_definitions @options
      base = model.as_styled_smart_json param, definitions, loaded: loaded, default: default
      symbols.each do |name|
        base[name] = model.send(name).try :as_styled_smart_json, param, [], loaded: loaded
      end
      hash.try :each do |key, value|
        reflection = @klass.reflections[key.to_s] || @klass.reflections[key]
        definition = SmartJSON::Definition.new(reflection.klass, value)
        base[key] = model.send(key).try :as_styled_smart_json, param, [definition], loaded: loaded
      end
    end
    if @block
      overrides = model.instance_exec param, &@block
    else
      overrides = {}
    end
    if base
      SmartJSON::Util.deep_merge base, overrides
    else
      overrides
    end
  end

  def includes_dependencies param, default: true
    dependency = self.dependency param
    return dependency unless @options.present?
    definitions, symbols, hash = extract_smart_json_definitions @options
    includes = @klass.smart_json_includes_dependencies param, definitions, default: default
    symbols.each do |child|
      includes[child] ||= {}
      reflection = @klass.reflections[child.to_s] || @klass.reflections[child]
      child_default_definition = reflection.klass.smart_json_definitions[:default]
      SmartJSON::Util.deep_merge includes[child], child_default_definition.includes_dependencies(param) if child_default_definition
    end
    hash.try :each do |key, value|
      includes[key] ||= {}
      reflection = @klass.reflections[key.to_s] || @klass.reflections[key]
      SmartJSON::Util.deep_merge includes[key], SmartJSON::Definition.new(reflection.klass, value).includes_dependencies(param)
    end
    if dependency
      SmartJSON::Util.deep_merge dependency.dup, includes
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
