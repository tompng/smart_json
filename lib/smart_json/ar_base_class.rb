require_relative 'util'

module SmartJSON::ARBaseClass
  class Dependencies < Hash
    def styles
      @styles ||= []
    end
    def styles= styles
      @styles = styles
    end
  end
  class Definition
    attr_reader :dependency
    def initialize klass, block, options
      @klass = klass
      @block = block
      @options = options
    end
    def require *options
      @dependency = SmartJSON::Util.options_to_hash options
    end
    def serialize model, loaded
      if @options.present?
        dependencies, includes = @klass.smart_json_dependencies(@options)
        if loaded
          base = model.as_loaded_smart_json dependencies
        else
          base = model.as_smart_json_from_dependencies dependencies, includes
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
    def dependency
      return @dependency unless @options.present?
      dependencies, includes = @klass.smart_json_dependencies @options
      if @dependency
        SmartJSON::Util.deep_merge @dependency.dup, includes
      else
        includes
      end
    end
  end
  def smart_json style, *options, &block
    @smart_json_definitions ||= {}
    smart_json_definitions[style] = Definition.new self, block, options
  end
  def smart_json_dependencies arguments
    options = Array.wrap arguments
    dependencies = Dependencies.new
    includes = {}
    options.select{|t|Symbol === t}.each do |style|
      next if reflections[style.to_s] || reflections[style]
      definition = smart_json_definitions.try :[], style
      next if definition.nil?
      dependencies.styles << style
      dependency = definition.dependency
      SmartJSON::Util.deep_merge includes, dependency if dependency
    end
    options -= dependencies.styles
    options.reject{|o|Hash===o}.each do |name|
      dependencies[name] ||= Dependencies.new
      includes[name] ||= {}
    end
    options.select{|o|Hash===o}.each do |hash|
      hash.each do |key, value|
        reflection = reflections[key.to_s] || reflections[key]
        dep, inc = reflection.klass.smart_json_dependencies value
        depkey = dependencies[key] ||= Dependencies.new
        SmartJSON::Util.deep_merge depkey, dep
        depkey.styles |= dep.styles
        SmartJSON::Util.deep_merge (includes[key] ||= {}), inc
      end
    end
    [dependencies, includes]
  end
  def as_smart_json *options
    all.as_smart_json *options
  end
end
