ActiveRecord::Migration.class_eval do
  create_table :comments do |t|
    t.references :user
    t.references :post
    t.text :content
    t.timestamps
  end
end

class Comment < ActiveRecord::Base
  belongs_to :blog
  belongs_to :user, class: User
  has_many :comments
end
