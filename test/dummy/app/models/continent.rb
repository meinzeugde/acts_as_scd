class Continent < ActiveRecord::Base
  # this is a static model which does not act as SCD

  def to_s
    name
  end

  has_many_identities :countries

end
