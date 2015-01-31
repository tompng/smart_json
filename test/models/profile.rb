ActiveRecord::Migration.create_table :profiles do |t|
  t.references :user
  t.string :image
  t.text :introduction
  t.timestamps null: false
end

class Profile < ActiveRecord::Base
  belongs_to :user
end
