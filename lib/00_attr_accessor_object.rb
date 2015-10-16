class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method("#{name}=") do |value|
        iv = instance_variable_set("@#{name}".to_sym, value)
      end

      define_method(name) do
        instance_variable_get("@#{name}".to_sym)
      end
    end
  end
end

class Cat < AttrAccessorObject
  my_attr_accessor :name

  def initialize(name)
    @name = name
  end
end

c = Cat.new("lucky")

p c.name

c.name = "stripe"

p c.name
