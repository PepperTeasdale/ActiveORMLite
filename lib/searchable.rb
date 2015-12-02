require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map { |k| "#{k} = ?"}.join(" AND ")
    query = <<-SQL
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL

    results = DBConnection.execute(query, *params.values)
    results.map { |result| self.new(result) }
  end
end

class SQLObject
  extend Searchable
end
