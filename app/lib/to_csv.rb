module ToCsv
  def to_csv
    CSV.generate do |csv|
      csv << column_names
      all.find_each do |item|
        csv << item.attributes.values_at(*column_names)
      end
    end
  end
end
