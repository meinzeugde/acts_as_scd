class CountrySerializer < ActiveModel::Serializer
  attributes :code, :name, :area, :identity, :effective_from, :effective_to

  has_many :cities_at_present, key: :cities_at_present
  has_many :cities_upcoming, key: :cities_upcoming
end
