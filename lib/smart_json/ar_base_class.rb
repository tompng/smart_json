module SmartJSON::ARBaseClass
  def smart_json_style style, *options, &block
    @smart_json_definitions ||= {}
    smart_json_definitions[style] = SmartJSON::Definition.new self, options, block
  end

  def smart_json_includes definitions
    includes = {}
    definitions.each do |definition|
      inc = definition.includes
      SmartJSON::Util.deep_merge includes, inc if inc
    end
    includes
  end

  def as_smart_json *options
    all.as_smart_json *options
  end
end
