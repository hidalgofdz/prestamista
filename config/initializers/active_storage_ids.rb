Rails.application.config.to_prepare do
  ActiveStorage::Record.include(Module.new {
    extend ActiveSupport::Concern

    included do
      before_create { self.id ||= ApplicationRecord.generate_id }
    end
  })
end
