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
  validates_presence_of :title, :data_type, :data_subtype, :description
  validates :title, :uniqueness => true,
                    :format =>  { :with => /\A\w+\z/, :message => "Only letters, numbers, or underscores allowed"},
                    :length => { :in => 2..255 }
  validates :description, :length => { :minimum => 5 }

  ##
  # Class Methods
  ##

  # A list of hardcoded datatypes
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

  def self.allowed_field?(type, subtype, data_type)
    self.data_types[type][subtype].find(data_type)
  end

  ##
  # Instance Methods
  ##

  ##
  # Getters and setters for complex fields

  # allowed values: saved as yaml list
  def allowed_values
    # loads list if not nil
    self[:allowed_values].nil? ? nil : YAML::load(self[:allowed_values])
  end

  def allowed_values=(val)
    # nil if not set
    #ASSUMES val is a hash {:values => [-value array-], :exclude => 1or0}
    if val[:exclude] || val[:values].nil?
      self[:allowed_values] = nil
    else
      self[:allowed_values] = val[:values].to_yaml
    end
  end

  def length
    return {:min => nil, :max => nil} if self[:length].nil?

    # return hash with min, max keys
    vals = self[:length].scan(/[\s\d\\\/:\.]+/)
    { :min => vals[0].to_i, :max => vals[1].to_i }
  end

  def length=(val)
    # make sure val is a hash with min, max keys
    # also allows an "exclude" key
    self[:length] = val[:exclude] ? nil : "[#{val[:min]}, #{val[:max]}]"
  end

  def valid_range
    # return hash with lower, upper keys
    return {:lower => nil, :upper => nil} if self[:valid_range].nil?

    vals = self[:valid_range].scan(/[\s\d\\\/:\.]+/)
    vals.map! { |x| x.strip }
    {:lower => time_read_filter(vals[0]), :upper => time_read_filter(vals[1])}
  end

  def valid_range=(val)
    # make sure value is a hash with lower, upper keys
    #CUSTOM_LOGGER.info "current type: #{self[:data_type]}"
    self[:valid_range] = val[:exclude] ? nil : "[#{time_input_filter(val[:lower])}, #{time_input_filter(val[:upper])}]"
  end

  def default_value
    time_read_filter(self[:default_value])
  end

  def default_value=(val)
    # assumes hash w/ value key and possible exclude key
    #CUSTOM_LOGGER.info "current type: #{self[:data_type]}"
    self[:default_value] = val[:exclude] ? nil : time_input_filter(val[:value])
  end

  ## make sure data_type and subtype display as symbols to allow comparisons
  # Dangerous??
  def data_type
   self[:data_type].nil? ? nil : self[:data_type].to_sym
  end

  def data_subtype
    self[:data_subtype].nil? ? nil : self[:data_subtype].to_sym
  end


private
  def time_input_filter(val)
    #CUSTOM_LOGGER.info "input, current type: #{data_type} \n #{val}"

    if data_type == :time_type
      Time.utc(val[:year], val[:month], val[:day], val[:hour], val[:minute], val[:second]).to_f
    else
      val
    end
  end

  def time_read_filter(val)
    #CUSTOM_LOGGER.info "read, current type: #{data_type} \n#{val}"
    if data_type == :time_type
      Time.zone.at(val.to_f)
    end
  end

end
