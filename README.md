Active ORMLite
==============

Summary
-------
Active ORMLite is an Active Record-inspired ORM, which maps SQL tables to Ruby
classes and their rows to instances.

Libraries
---------
* SQLite3 gem
* ActiveSupport::Inflector

Usage
--------
The SQLObject class is comparable to Rails' ActiveRecord::Base class. Simply
create a class using the singular name of the associated database table and
call the `finalize!` method to access the getter methods for all the columns in
the table. For example, if you have a table named "cats":

```
class Cat < SQLObject
  self.finalize!
end
```
Active ORMLite uses the ActiveSupport::Inflector module to "tableize" the name,
but in some cases, you may have to set the table name manually. For instance,
Inflector changes "Human" to "Humen" :(
<br>
To compensate for this, you may call the `::table_name=(table_name)`
method in the class definition to specify the table name:
```
class Human < SQLObject
  self.table_name = 'humans'
  self.finalize!
end
```
From this, you now have getter methods for all of your columns, plus a variety
of class and instance methods, such as:
* ::columns
* ::find(id)
* ::all
* ::where(params_hash)
* ::table_name
* #save
* #update

Additionally, you can create associations between tables with the `has_many`,
`belongs_to`, and `has_one_through` macros.
