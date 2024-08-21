module ConsoleDisplayHelpers
  def display_title(text)
    "#{text}\n#{'=' * text.length}"
  end

  def display_table(headings: [], rows: [], key: nil)
    col_max_widths = ([headings] + rows).each_with_object(Array.new(headings.length, 0)) do |row, results|
      row.each_with_index do |col, col_i|
        results[col_i] = [results[col_i], col.to_s.length].max
      end
    end

    output = []

    output << headings.map
      .with_index { |heading, col_i| heading.ljust(col_max_widths[col_i]) }

    rows.each do |row|
      output << row.map
        .with_index { |col, col_i| col.to_s.ljust(col_max_widths[col_i]) }
    end

    output.map.with_index { |row, i|
      to_output = row.join(' | ')
      to_output += "\n#{'-' * to_output.length}" if i == 0

      to_output
    }
      .join("\n")
      .then { |table| table + (key ? "\nKey: #{key}" : '').to_s }
  end

  def display_date(date)
    if date.is_a?(String)
      Date.parse(date).strftime('%d/%m/%Y')
    else
      date&.strftime('%d/%m/%Y')
    end
  end

  def display_date_time(date_time)
    date_time&.strftime('%d/%m/%Y %H:%M:%S')
  end

  def display_diff(current_val, new_val)
    current_val == new_val ? current_val : [current_val, new_val].join(' => ')
  end

  def display_tick_cross(value)
    value ? '✔' : '✘'
  end
end
