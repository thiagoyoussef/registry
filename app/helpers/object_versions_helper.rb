module ObjectVersionsHelper
  def attach_existing_fields(version, new_object)
    version.object_changes.to_h.each do |key, value|
      method_name = "#{key}=".to_sym
      new_object.public_send(method_name, event_value(version, value)) if new_object.respond_to?(method_name)
    end
  end

  def only_present_fields(version, model)
    field_names = model.column_names
    version.object.to_h.select { |key, _value| field_names.include?(key) }
  end

  private

  def event_value(version, val)
    version.event == 'destroy' ? val.first : val.last
  end
end
