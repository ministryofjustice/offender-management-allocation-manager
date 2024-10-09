class MigrateParoleReviewThDs < ActiveRecord::Migration[7.1]
  def up
   execute <<-SQL
      UPDATE parole_reviews AS pr
      SET target_hearing_date = to_date(pri.review_date, 'DD-MM-YYYY')
      FROM parole_review_imports AS pri
      WHERE pri.review_id::integer = pr.review_id
    SQL
  end

  def down
    execute <<-SQL
      UPDATE parole_reviews AS pr
      SET target_hearing_date = to_date(pri.curr_target_date, 'DD-MM-YYYY')
      FROM parole_review_imports AS pri
      WHERE pri.review_id::integer = pr.review_id
    SQL
  end
end
