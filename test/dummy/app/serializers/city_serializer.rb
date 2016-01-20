class CitySerializer < ActiveModel::Serializer
  attributes :code, :name, :area, :identity, :effective_from, :effective_to
end
