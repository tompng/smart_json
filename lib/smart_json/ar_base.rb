require_relative 'util'

module SmartJSON::ARBase
  def as_styled_smart_json styles, loaded=true
    definitions = styles.map{|style|self.class.smart_json_definitions[style]}
    default = self.class.smart_json_definitions.try :[], :default
    definitions.unshift default if default
    return as_json if definitions.blank?
    json = {}
    definitions.each do |definition|
      SmartJSON::Util.deep_merge json, definition.serialize(self, loaded)
    end
    json
  end
  def as_loaded_smart_json dependencies
    json = as_styled_smart_json dependencies.styles
    dependencies.each do |key, value|
      child = self.send(key)
      if ActiveRecord::Relation === child
        json[key] = child.try(:map){|c|c.as_loaded_smart_json value}
      else
        json[key] = child.try :as_loaded_smart_json, value
      end
    end
    json
  end
  def as_smart_json_from_dependencies dependencies, includes
    json = as_styled_smart_json dependencies.styles, false
    dependencies.each do |key, value|
      json[key] = send(key).try :as_smart_json_from_dependencies, value, includes[key]
    end
    json
  end
  def as_smart_json *options
    as_smart_json_from_dependencies *self.class.smart_json_dependencies(options)
  end
end
