class Node < ActiveRecord::Base
  validates :discord_user_id, presence: true, length: { maximum: 32 }
  validates :name,            presence: true, length: { maximum: 64 }
  validates :host,            presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: :discord_user_id }
end
