ActiveRecord::Migration.class_eval do
  create_table :profiles do |t|
    t.references :user
    t.string :image
    t.text :introduction
    t.timestamps
  end
end

class Profile < ActiveRecord::Base
  belongs_to :user
end
