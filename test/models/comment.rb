ActiveRecord::Migration.create_table :comments do |t|
  t.references :user
  t.references :post
  t.text :content
  t.timestamps null: false
end

class Comment < ActiveRecord::Base
  belongs_to :blog
  belongs_to :user
  has_many :comments
end
