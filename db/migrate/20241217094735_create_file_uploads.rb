class CreateFileUploads < ActiveRecord::Migration[5.2]
  def change
    create_table :file_uploads do |t|
      t.references :user, foreign_key: true
      t.string :title
      t.text :description
      t.string :file_url
      t.string :file_type
      t.integer :size

      t.timestamps
    end
  end
end
