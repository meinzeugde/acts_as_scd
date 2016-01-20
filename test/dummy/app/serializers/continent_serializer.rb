class ContinentSerializer < ActiveModel::Serializer
  attributes :name

  has_many :countries_at_present, key: :countries_at_present
  has_many :countries_past, key: :countries_past
  has_many :countries_upcoming, key: :countries_upcoming
end
