module SmartJSON::ARBase
  def as_styled_smart_json param, definitions, loaded: true, default: true
    json = {}
    if default
      default_definition = self.class.smart_json_definitions.try :[], :default
      definitions.unshift default_definition if default_definition
      json = as_json unless definitions.any? &:have_block?
    end
    definitions.each do |definition|
      SmartJSON::Util.deep_merge json, definition.serialize(self, param, loaded: loaded, default: false)
    end
    json
  end
  def as_smart_json *options
    as_smart_json_with_param nil, *options
  end
  def as_smart_json_with_param param, *options
    as_styled_smart_json param, [SmartJSON::Definition.new(self.class, options)], loaded: false
  end
end
