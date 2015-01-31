ActiveRecord::Migration.create_table :posts do |t|
  t.references :blog
  t.references :author
  t.string :title
  t.text :content
  t.timestamps null: false
end

class Post < ActiveRecord::Base
  belongs_to :blog
  belongs_to :author, class: User
  has_many :comments
end
