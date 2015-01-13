ActiveRecord::Migration.class_eval do
  create_table :posts do |t|
    t.references :blog
    t.references :author
    t.string :title
    t.text :content
    t.timestamps
  end
end

class Post < ActiveRecord::Base
  belongs_to :blog
  belongs_to :author, class: User
  has_many :comments
end
