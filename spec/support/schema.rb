ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:'
)

class Item < ActiveRecord::Base
  def awesome?
    respond_to?(:is_awesome) && is_awesome
  end
end

module Schema
  def self.create
    ActiveRecord::Base.silence do
      ActiveRecord::Migration.verbose = false

      ActiveRecord::Schema.define do
        create_table :items, :force => true do |t|
          t.string   :name
          t.string   :type
          t.text     :bucket
          t.text     :other_bucket
        end
      end
    end
  end
end