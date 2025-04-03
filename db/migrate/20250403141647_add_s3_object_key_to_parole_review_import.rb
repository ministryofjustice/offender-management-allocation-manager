class AddS3ObjectKeyToParoleReviewImport < ActiveRecord::Migration[7.1]
  def change
    add_column :parole_review_imports, :s3_object_key, :string
  end
end
