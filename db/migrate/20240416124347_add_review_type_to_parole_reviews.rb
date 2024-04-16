class AddReviewTypeToParoleReviews < ActiveRecord::Migration[6.1]
  def change
    add_column :parole_reviews, :review_type, :string
  end
end
