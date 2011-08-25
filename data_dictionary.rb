class DataDictionary < ActiveRecord::Base
  # Table Properties
  set_table_name "data_dictionary"
  set_primary_key "record_id"
  set_sequence_name 'id_seq'

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


end
