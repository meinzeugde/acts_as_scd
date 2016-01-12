module ActsAsScd


  module ClassMethods

    # Return objects representing identities; (with a single attribute, :identity)
    # Warning: do not chain this method after other queries;
    # any query should be applied after this method.
    # If identities are required for an association, either latest, earliest or initial can be used
    # (which one is appropriate depends on desired result, data contents, etc.; initial/current are faster)
    def distinct_identities
      # Note that since Rails 2.3.13, when pluck(col) is applied to distinct_identities
      # the "DISTINCT" is lost from the SELECT if added explicitly  as in .select('DISTINCT #{col}'),
      # so we have avoid explicit use of DISTINCT in distinct_identities.
      # This can be used on association queries
      if ActiveRecord::VERSION::MAJOR > 3
        unscope(:select).reorder(identity_column_sql).select(identity_column_sql).uniq
      else
        query = scoped.with_default_scope
        query.select_values.clear
        query.reorder(identity_column_sql).select(identity_column_sql).uniq
      end
    end

    def ordered_identities
      distinct_identities.pluck(identity_column_sql)
    end

    # This can be applied to an ordered query (but returns an Array, not a query)
    def identities
      # pluck(identity_column_sql).uniq # does not work if select has been applied
      scoped.map(&IDENTITY_COLUMN).uniq
    end

    def identities_at(date=nil)
      at_date(date).identities
    end

    def present_identities
      at_present.identities
    end

    def current_identities
      current.identities
    end

    def at_present
      at_date(Date.today)
    end

    def at_present!
      begin
        result = at_present
        raise ActiveRecord::RecordNotFound if result.to_a.empty?
        result
      end
    end

    def at_present_or(date=nil)
      if date.nil?
        at_present
      else
        at_date(date)
      end
    end

    # returns exception (ActiveRecord::RecordNotFound) if nothing is found
    def at_present_or!(date=nil)
      begin
        result = at_present_or(date)
        raise ActiveRecord::RecordNotFound if result.to_a.empty?
        result
      end
    end

    def identity_column_sql(table_alias=nil)
      # %{#{ActiveRecord::Base.connection.quote_table_name(table_alias || table_name)}.#{ActiveRecord::Base.connection.quote_column_name(IDENTITY_COLUMN)}}
      %{#{connection.quote_table_name(table_alias || table_name)}.#{connection.quote_column_name(IDENTITY_COLUMN)}}
    end

    def effective_from_column_sql(table_alias=nil)
      # %{#{ActiveRecord::Base.connection.quote_table_name(table_alias || table_name)}.#{ActiveRecord::Base.connection.quote_column_name(START_COLUMN)}}
      %{#{connection.quote_table_name(table_alias || table_name)}.#{connection.quote_column_name(START_COLUMN)}}
    end

    def effective_to_column_sql(table_alias=nil)
      # %{#{ActiveRecord::Base.connection.quote_table_name(table_alias || table_name)}.#{ActiveRecord::Base.connection.quote_column_name(END_COLUMN)}}
      %{#{connection.quote_table_name(table_alias || table_name)}.#{connection.quote_column_name(END_COLUMN)}}
    end

    def effective_date(d)
      Period.date(d)
    end

    #returns Array (may be emtpy)
    def find_all_by_identity(identity)
      all_of(identity).to_a
    end

    # returns exception (ActiveRecord::RecordNotFound) if nothing is found
    def find_all_by_identity!(identity)
      begin
        result = find_all_by_identity(identity)
        raise ActiveRecord::RecordNotFound if result.empty?
        result
      end
    end

    #returns nil if nothing is found
    def find_by_identity_at(identity, date)
      at_date(date).where(IDENTITY_COLUMN=>identity).first
    end

    # returns exception (ActiveRecord::RecordNotFound) if nothing is found
    def find_by_identity_at!(identity, date)
      begin
        result = find_by_identity_at(identity, date)
        raise ActiveRecord::RecordNotFound if result.nil?
        result
      end
    end

    #returns nil if nothing is found
    def find_by_identity_at_present(identity)
      at_date(Date.today).where(IDENTITY_COLUMN=>identity).first
    end

    # returns exception (ActiveRecord::RecordNotFound) if nothing is found
    def find_by_identity_at_present!(identity)
      begin
        result = find_by_identity_at_present(identity)
        raise ActiveRecord::RecordNotFound if result.nil?
        result
      end
    end

    #returns nil if nothing is found
    def find_by_identity_at_present_or(identity,date=nil)
      if date.nil?
        at_date(Date.today).where(IDENTITY_COLUMN=>identity).first
      else
        at_date(date).where(IDENTITY_COLUMN=>identity).first
      end
    end

    # returns exception (ActiveRecord::RecordNotFound) if nothing is found
    def find_by_identity_at_present_or!(identity,date=nil)
      begin
        result = find_by_identity_at_present_or(identity,date)
        raise ActiveRecord::RecordNotFound if result.nil?
        result
      end
    end

    # The first iteration can be defined with a specific start date, but
    # that is in general a bad idea, since it complicates obtaining
    # the first iteration
    def create_identity(attributes, start_date=nil, end_date=nil)
      start_date = (start_date.nil?) ? START_OF_TIME : start_date.to_date.strftime("%Y%m%d")
      end_date = (end_date.nil?) ? END_OF_TIME : end_date.to_date.strftime("%Y%m%d")
      create(attributes.merge({START_COLUMN=>start_date,END_COLUMN=>end_date}))
    end

    # returns exception (ActiveRecord::RecordInvalid) if validation of model fails
    def create_identity!(attributes, start_date=nil, end_date=nil)
      begin
        record = create_identity(attributes, start_date, end_date)
        raise ActiveRecord::RecordInvalid.new(record) if record.errors.any?
        record
      end
    end

    # Splits an existing period at the given date
    # It is not possible to split a period at the start- or end-date
    # (This behaviour is implemented via validation method "before_create" in initialize.rb)
    def create_iteration(identity, attribute_changes, date=nil)
      date = effective_date(date || Date.today)
      transaction do
        current_record = find_by_identity_at(identity,date)
        attributes = {IDENTITY_COLUMN=>identity}.with_indifferent_access
        if current_record
          # todo-matteo: replace clear names with constants
          non_replicated_attrs = %w[id effective_from updated_at created_at]
          attributes = attributes.merge current_record.attributes.with_indifferent_access.except(*non_replicated_attrs)
        end
        attributes = attributes.merge(START_COLUMN=>date).merge(attribute_changes.with_indifferent_access.except(START_COLUMN, END_COLUMN))
        new_record = create(attributes.merge(:acts_as_scd_create_iteration => true))
        if new_record.errors.blank? && current_record
          current_record.send :"#{END_COLUMN}=", date
          current_record.save validate: false
        end
        new_record
      end
    end

    # returns exception (ActiveRecord::RecordInvalid) if validation of model fails
    def create_iteration!(identity, attribute_changes, date=nil)
      begin
        record = create_iteration(identity, attribute_changes, date)
        raise ActiveRecord::RecordInvalid.new(record) if record.errors.any?
        record
      end
    end

    # returns updated record or false
    def update_iteration(identity, attribute_changes, date=nil)
      date = effective_date(date || Date.today)
      transaction do
        current_record = find_by_identity_at(identity,date)
        if current_record
          current_record.send :update_attributes, attribute_changes
        end
        return (current_record.nil? ? false : current_record)
      end
    end

    # returns exception if model could not be updated
    # returns exception (ActiveRecord::RecordInvalid) if validation of model fails
    def update_iteration!(identity, attribute_changes, date=nil)
      begin
        record = update_iteration(identity, attribute_changes, date)
        raise I18n.t('scd.errors.cannot_update_iteration_that_does_not_exist') unless record
        raise ActiveRecord::RecordInvalid.new(record) if record.errors.any?
        record
      end
    end

    # returns terminated record or false
    def terminate_iteration(identity, date=nil)
      date = effective_date(date || Date.today)
      transaction do
        current_record = find_by_identity_at(identity,date)
        if current_record
          if(current_record.past_limited? && date == current_record.effective_from)
            current_record.errors.add(:base, I18n.t('scd.errors.cannot_terminate_iteration_at_start_date'))
            return current_record
          end
          if(current_record.future_limited? && date == (current_record.effective_to - 1))
            current_record.errors.add(:base, I18n.t('scd.errors.cannot_terminate_iteration_at_end_date'))
            return current_record
          end
          current_record.send :update_attributes, END_COLUMN=>date
        end
        return (current_record.nil? ? false : current_record)
      end
    end

    # returns exception if model could not be terminated
    # returns exception (ActiveRecord::RecordInvalid) if validation of model fails
    def terminate_iteration!(identity, date=nil)
      begin
        record = terminate_iteration(identity, date)
        raise I18n.t('scd.errors.cannot_terminate_iteration_that_does_not_exist') unless record
        raise ActiveRecord::RecordInvalid.new(record) if record.errors.any?
        record
      end
    end

    # returns destroyed record or false
    def destroy_iteration(identity, date=nil)
      date = effective_date(date || Date.today)
      transaction do
        current_record = find_by_identity_at(identity,date)
        if current_record
          current_record.send :destroy
        end
        return (current_record.nil? ? false : current_record)
      end
    end

    # returns exception if model could not be destroyed
    # returns exception (ActiveRecord::RecordInvalid) if validation of model fails
    def destroy_iteration!(identity, date=nil)
      begin
        record = destroy_iteration(identity, date)
        raise I18n.t('scd.errors.cannot_destroy_iteration_that_does_not_exist') unless record
        raise ActiveRecord::RecordInvalid.new(record) if record.errors.any?
        record
      end
    end

    # returns an array of all destroyed records or false
    def destroy_identity(identity)
      destroyed_periods = []
      transaction do
        find_all_by_identity(identity).each do |current_record|
          destroyed_periods.push(current_record.send(:destroy))
        end

        return (destroyed_periods.empty? ? false : destroyed_periods)
      end
    end

    # returns exception if model could not be destroyed
    # returns exception (ActiveRecord::RecordInvalid) if validation of model fails
    def destroy_identity!(identity)
      begin
        records = destroy_identity(identity)
        raise I18n.t('scd.errors.cannot_destroy_identity_that_does_not_exist') unless records
        records.each do |record|
          raise ActiveRecord::RecordInvalid.new(record) if record.errors.any?
        end

        records
      end
    end

    # Association yo be used in a parent class which has identity and has children
    # which have identities too;
    # the association is implemented through the identity, not the PK.
    # The inverse association should be belongs_to_identity
    def has_many_iterations_through_identity(assoc, options={})
      fk =  options[:foreign_key] || :"#{model_name.to_s.underscore}_identity"
      assoc_singular = assoc.to_s.singularize
      other_model_name = options[:class_name] || assoc_singular.camelize
      other_model = other_model_name.constantize
      pk = IDENTITY_COLUMN

      # all children iterations
      has_many :"#{assoc_singular}_iterations", class_name: other_model_name, foreign_key: fk, primary_key: pk

      # current_children
      if ActiveRecord::VERSION::MAJOR > 3
        has_many assoc, ->{ where "#{other_model.effective_to_column_sql}=#{END_OF_TIME}" },
                 options.reverse_merge(foreign_key: fk, primary_key: pk)
      else
        has_many assoc, options.reverse_merge(
            foreign_key: fk, primary_key: pk,
            conditions: "#{other_model.effective_to_column_sql}=#{END_OF_TIME}"
        )
      end

      # children at some date
      define_method :"#{assoc}_at" do |date|
        send(:"#{assoc_singular}_iterations").at_date(date)
      end

      # children at today
      define_method :"#{assoc}_at_present" do
        send(:"#{assoc_singular}_iterations").at_date(Date.today)
      end

      # children at today or some date
      define_method :"#{assoc}_at_present_or" do |date=nil|
        if date.nil?
          send(:"#{assoc_singular}_iterations").at_date(Date.today)
        else
          send(:"#{assoc_singular}_iterations").at_date(date)
        end
      end

      # all children identities
      define_method :"#{assoc_singular}_identities" do
        # send(:"#{assoc}_iterations").select("DISTINCT #{other_model.identity_column_sql}").reorder(other_model.identity_column_sql).pluck(:identity)
        # other_model.unscoped.where(fk=>send(pk)).identities
        send(:"#{assoc_singular}_iterations").identities
      end

      # children identities at a date
      define_method :"#{assoc_singular}_identities_at" do |date=nil|
        # send(:"#{assoc}_iterations_at", date).select("DISTINCT #{other_model.identity_column_sql}").reorder(other_model.identity_column_sql).pluck(:identity)
        # other_model.unscoped.where(fk=>send(pk)).identities_at(date)
        send(:"#{assoc_singular}_iterations").identities_at(date)
      end

      # current children identities
      define_method :"#{assoc_singular}_current_identities" do
        # send(assoc).select("DISTINCT #{other_model.identity_column_sql}").reorder(other_model.identity_column_sql).pluck(:identity)
        # other_mode.unscoped.where(fk=>send(pk)).current_identities
        send(:"#{assoc_singular}_iterations").current_identities
      end

      # present children identities
      define_method :"#{assoc}_present_identities" do
        send(:"#{assoc}_iterations").present_identities
      end

    end

    # Association to be used in a parent class which has identity and has children
    # which don't have identities;
    # the association is implemented through the identity, not the PK.
    # The inverse association should be belongs_to_identity
    def has_many_through_identity(assoc, options={})
      fk = :"#{model_name.to_s.underscore}_identity"
      pk = IDENTITY_COLUMN

      has_many assoc, {:foreign_key=>fk, :primary_key=>pk}.merge(options)
    end

    def identity_column_definition
      @slowly_changing_columns.first
    end

    def slow_changing_migration
      migration = ""

      migration << "def up\n"
      @slowly_changing_columns.each do |col, args|
        migration << "  add_column :#{table_name}, :#{col}, #{args.inspect.unwrap('[]')}\n"
      end
      @slowly_changing_indices.each do |index|
        migration << "  add_index :#{table_name}, #{index.inspect}\n"
      end
      migration << "end\n"

      migration << "def down\n"
      @slowly_changing_columns.each do |col, args|
        migration << "  remove_column :#{table_name}, :#{col}\n"
      end
      migration << "end\n"

    end

    def effective_periods(*args)
      # periods = unscoped.select("DISTINCT effective_from, effective_to").order('effective_from, effective_to')
      if ActiveRecord::VERSION::MAJOR > 3
        # periods = unscope(where: [:effective_from, :effective_to]).select("DISTINCT effective_from, effective_to").reorder('effective_from, effective_to')
        periods = unscope(where: [:effective_from, :effective_to]).select([:effective_from, :effective_to]).uniq.reorder('effective_from, effective_to')
      else
        query = scoped.with_default_scope
        query.select_values.clear
        periods = query.reorder('effective_from, effective_to').select([:effective_from, :effective_to]).uniq
      end

      # formerly unscoped was used, so any desired condition had to be defined here
      periods = periods.where(*args) if args.present?

      periods.map{|p| Period[p.effective_from, p.effective_to]}
    end

    def effective_periods_formatted(strftime_format='%Y-%m-%d',*args)
      scoped.effective_periods(*args).map{|p| p.formatted(strftime_format)}
    end

    # while effective periods are just a sorted bunch of all periods with redundant dates,
    #   combined periods have no redundant dates and combine overlapping periods if existent
    def combined_periods(*args)
      effective_periods = effective_periods(*args)
      start_dates = effective_periods.map(&:start).uniq.sort
      end_dates = effective_periods.map(&:end).uniq.sort
      combined_dates = (start_dates + end_dates).uniq.sort
      combined_periods = []

      combined_dates.size.times.each do |idx|
        break if combined_dates[idx+1].nil?
        combined_periods.push(Period[combined_dates[idx],combined_dates[idx+1]])
      end

      combined_periods
    end

    def combined_periods_formatted(strftime_format='%Y-%m-%d',*args)
      combined_periods(*args).map{|p| p.formatted(strftime_format) }.uniq
    end

    def reference_dates(*args)
      effective_periods(*args).map{|p| p.reference_date }.uniq
    end

    def reference_dates_formatted(strftime_format='%Y-%m-%d',*args)
      effective_periods(*args).map{|p| p.reference_date_formatted(strftime_format) }.uniq
    end

    # Most recent iteration (terminated or not)
    def latest_of(identity)
      where(IDENTITY_COLUMN=>identity).reorder('effective_to desc').limit(1).first
    end

    def earliest_of(identity)
      where(IDENTITY_COLUMN=>identity).reorder('effective_to asc').limit(1).first
    end

    def all_of(identity)
      where(IDENTITY_COLUMN=>identity).reorder('effective_from asc')
    end

    def has_identity?(identity)
      where(IDENTITY_COLUMN=>identity).exists?
    end

    def has_identity_at?(identity, date)
      at_date(date).where(IDENTITY_COLUMN=>identity).exists?
    end

    def has_identity_at_present?(identity)
      at_date(Date.today).where(IDENTITY_COLUMN=>identity).exists?
    end

    def has_unlimited_identity?(identity)
      where(IDENTITY_COLUMN=>identity,START_COLUMN=>START_OF_TIME,END_COLUMN=>END_OF_TIME).exists?
    end
  end

end
