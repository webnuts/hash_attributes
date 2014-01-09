ActiveRecord::Relation.class_eval do
  def update_all_with_hash_column(attributes)
    update_all_without_hash_column(attributes) unless attributes.is_a?(Hash) && attributes.present?

    attributes = attributes.with_indifferent_access
    hash_column_attributes = attributes.except(*model.column_names)
    if hash_column_attributes.present?
      hash_column_attributes = model.serialize_hash_column_attribute(model.hash_column, hash_column_attributes)
      attributes = attributes.slice(*model.column_names).merge({model.hash_column => hash_column_attributes})
    end

    if attributes.has_key?(model.hash_column)
      attribute_serializer = model.serialized_attributes[model.hash_column]
      if attribute_serializer
        attributes[model.hash_column] = attribute_serializer.dump(attributes[model.hash_column])
      end
    end

    update_all_without_hash_column(attributes)
  end

  alias_method_chain :update_all, :hash_column
end