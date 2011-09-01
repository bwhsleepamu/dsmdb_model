class DataDictionary < ActiveRecord::Base
  # Table Properties
  set_table_name "data_dictionary"
  set_primary_key "record_id"
  set_sequence_name 'id_seq'
  attr_accessible :title, :data_type, :data_subtype, :description, :valid_range, :default_value, :length, :format_string, :unit_id, :allowed_values

  # Associations
  belongs_to :data_unit, :foreign_key => "unit_id"
  has_many :event_dictionary_data_fields, :foreign_key => "data_record_id"
  has_many :event_dictionary, :through => :event_dictionary_data_fields

  # Validations

  # Class Methods
  def self.data_types
    {
        :text_type => {:character => [:default_value, :valid_range, :allowed_values],
                       :boolean => [:default_value],
                       :list => [:length, :allowed_values],
                       :string => [:default_value, :length, :allowed_values],
                       :text => [:default_value, :length]},
        :num_type => {:float => [:default_value, :valid_range, :unit],
                      :integer => [:default_value, :valid_range, :allowed_values, :unit]},
        :time_type => {:date => [:default_value, :valid_range],
                       :time => [:default_value, :valid_range],
                       :datetime => [:default_value, :valid_range]}
    }
  end

  def self.subtypes(type)
    data_types[type.to_sym].keys
  end

    # process attributes from the complex form
  def self.process_attributes(params)
    if params[:default_value].key?(:exclude)
      params.delete[:default_value]
    else
      params[:default_value] = params[:default_value][:value]
    end
  end

  # Instance Methods
  def allowed_values
    self[:allowed_values].nil? ? nil : YAML::load(self[:allowed_values])
  end

  def allowed_values=(val)
    self[:allowed_values] = val.to_yaml unless val.nil?
  end

  def length
    self[:length].nil? ? nil : YAML::load(self[:length])

  end

  def length=(val)
    self[:length] = val.to_yaml unless val.nil?
  end

  def valid_range
    self[:valid_range].nil? ? nil : YAML::load(self[:valid_range])
  end

  def valid_range=(val)
    self[:valid_range] = val.to_yaml unless val.nil?
  end



end
