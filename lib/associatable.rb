require_relative 'searchable'
require 'active_support/inflector'
require 'byebug'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions

  def initialize(name, options = {})
    default_options = {
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id,
      class_name: name.camelcase
    }
    default_options.merge!(options)

    default_options.each do |k, v|
      self.send("#{k}=", v)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default_fk = self_class_name.underscore

    default_options = {
      foreign_key: "#{default_fk}_id".to_sym,
      primary_key: :id,
      class_name: name.camelcase.singularize
    }

    default_options.merge!(options)

    default_options.each { |k, v| self.send("#{k}=", v) }
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name.to_s, options)

    assoc_options[name] = options

    define_method(name) do
      fk = self.send(options.foreign_key)
      target_model = options.model_class
      target_model.where(options.primary_key => fk).first
    end
  end


  def has_many(name, options = {})
    hm_options = HasManyOptions.new(name.to_s, self.to_s, options)

    define_method(name) do
      pk = self.send(hm_options.primary_key)
      target_model = hm_options.model_class
      target_model.where(hm_options.foreign_key => pk)
    end
  end


  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]
    define_method(name) do
      source_options = through_options
                       .model_class
                       .assoc_options[source_name]

      owner_id = self.send("#{through_name}").send("#{through_options.primary_key}")
      query = <<-SQL
        SELECT
          #{source_options.table_name}.*
        FROM
          #{through_options.table_name}
        JOIN
          #{source_options.table_name}
        ON #{through_options.table_name}.#{source_options.foreign_key} = #{source_options.table_name}.#{through_options.primary_key}
        WHERE
          #{through_options.table_name}.#{through_options.primary_key} = ?
      SQL

      results = DBConnection.execute(query, owner_id)
      source_options.model_class.parse_all(results).first
    end
  end
end

class SQLObject
  extend Associatable
end
