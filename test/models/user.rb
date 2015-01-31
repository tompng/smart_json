ActiveRecord::Migration.create_table :users do |t|
  t.string :name
  t.timestamps null: false
end

class User < ActiveRecord::Base
  has_one :profile
  has_many :blogs
  has_many :posts
  has_many :comments
end
