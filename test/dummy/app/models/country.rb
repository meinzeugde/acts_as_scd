class Country < ActiveRecord::Base
  ### VALIDATIONS
  validates :code, :presence => true

  ### ACTS_AS_SCD
  # Attention: be sure to put before associations,
  #   otherwise: `method_missing': undefined method `has_many_iterations_through_identity'
  # Countries will be identified by a 3-character code
  has_identity :string, limit: 3
  # The identity is derived from the country-code. Being a single
  #   column, we could skip it and have only the identity column,
  #   but for test purposes, we'll keep a separate column to be used
  #   for purposes other thant SDE-handling.
  def compute_identity
    self.identity = code
  end

  ### ASSOCIATIONS
  # Countries have cities which also go through iterations
  has_many_iterations_through_identity :cities
  # Countries may belong to associations which are regular models
  belongs_to :commercial_association
  # Countries may be associated with
  has_many_through_identity :commercial_delegates

  ### PUBLIC FUNCTIONS
  def to_s
    name
  end

end
