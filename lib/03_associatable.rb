require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'
# Phase IIIa
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

    # byebug
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
  # Phase IIIb
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
end

class SQLObject
  extend Associatable
end
