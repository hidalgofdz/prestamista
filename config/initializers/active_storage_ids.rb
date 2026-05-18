module ActiveStorageUUIDv7
  def self.included(base)
    base.before_create { self.id ||= ApplicationRecord.generate_id }
  end
end

Rails.application.config.to_prepare do
  ActiveStorage::Record.include(ActiveStorageUUIDv7) unless ActiveStorage::Record < ActiveStorageUUIDv7
end
