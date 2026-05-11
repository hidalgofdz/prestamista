class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  self.implicit_order_column = "created_at"

  before_create { self.id ||= self.class.generate_id }

  def self.generate_id
    SecureRandom.uuid_v7.delete("-").to_i(16).to_s(36).rjust(25, "0")
  end
end
