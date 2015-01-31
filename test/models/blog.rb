ActiveRecord::Migration.create_table :blogs do |t|
  t.references :owner
  t.string :title
  t.string :slug
  t.timestamps null: false
end

class Blog < ActiveRecord::Base
  belongs_to :owner, class_name: 'User'
  has_many :posts
end
