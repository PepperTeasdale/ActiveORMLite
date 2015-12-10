require_relative 'db_connection'

require 'active_support/inflector'
require 'byebug'

class SQLObject

  def self.columns
    table = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      LIMIT
        1
    SQL

    table.first.map { |column| column.to_sym }
  end


  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end


  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = ?
      LIMIT 1
    SQL

    result.empty? ? nil : self.new(result.first)
  end

  def initialize(params = {})
    columns = self.class.columns

    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless columns.include?(attr_name)
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert
    col_names = self.class.columns.drop(1).join(", ")
    question_marks = ["?"] * (self.class.columns.drop(1).count)

    query = <<-SQL
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks.join(", ")})
    SQL

    DBConnection.execute(query, *attribute_values.drop(1))
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.drop(1).join("= ?, ")
    col_names << "= ?"

    query = <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL

    DBConnection.execute(query, *attribute_values.rotate(1))
  end

  def save
    self.id.nil? ? insert : update
  end
end
