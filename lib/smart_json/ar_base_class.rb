module SmartJSON::ARBaseClass
  def smart_json_style style, *options, &block
    @smart_json_definitions ||= {}
    smart_json_definitions[style] = SmartJSON::Definition.new self, options, block
  end

  def smart_json_includes definitions, default: true
    includes = {}
    if default
      default_definition = self.smart_json_definitions.try :[], :default
      definitions = [default_definition, *definitions] if default_definition
    end
    definitions.each do |definition|
      inc = definition.includes default: false
      SmartJSON::Util.deep_merge includes, inc if inc
    end
    includes
  end

  def as_smart_json *options
    all.as_smart_json *options
  end
end
