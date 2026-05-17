module ApplicationHelper
  def currency(amount)
    number_to_currency(amount, unit: "$", separator: ".", delimiter: ",")
  end
end
