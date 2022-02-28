class Image < ApplicationRecord
  belongs_to :user

  scope :at, ->(n){ where(step: n) }
  default_scope { order(:step) }

end
