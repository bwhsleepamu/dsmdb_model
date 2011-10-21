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
    keys = params.keys.map { |x| x.to_sym}
    CUSTOM_LOGGER.info params.to_yaml
    ([:default_value, :valid_range, :length] & keys).each do |field|
      CUSTOM_LOGGER.info "Here's the field: #{field}"
      if params[field].key?(:exclude)
        CUSTOM_LOGGER.info "Excluded: #{field}"
        params[:field] = nil
      else
        case field.to_sym
          when :default_value
            params[field] = params[field][:value]
        end
      end


    end

    params
  end

  # Instance Methods
  def allowed_values
    #CUSTOM_LOGGER.info "WHAT COMES OUT: #{self[:allowed_values]}"
    self[:allowed_values].nil? ? nil : YAML::load(self[:allowed_values])
  end

  def allowed_values=(val)
    #CUSTOM_LOGGER.info "WHAT GOES IN??? #{val[:values]} #{val[:exclude]}"
    if val[:exclude] || val[:values].nil?
      self[:allowed_values] = nil
    else
      self[:allowed_values] = val[:values].to_yaml
    end
  end

  def length
    return {:min => nil, :max => nil} if self[:length].nil?

    # return hash with min, max keys
    vals = self[:length].scan(/\d+/)
    { :min => vals[0].to_i, :max => vals[1].to_i }
  end

  def length=(val)
    # make sure val is a hash with min, max keys
    self[:length] = val
  end

  def valid_range
    # return hash with lower, upper keys
    return {:lower => nil, :upper => nil} if self[:valid_range].nil?

    vals = self[:valid_range].scan(/[\s\d\\\/:\.]+/)
    vals.map! { |x| x.strip }
    {:lower => vals[0], :upper => vals[1]}
  end

  def valid_range=(val)
    # make sure value is a hash with lower, upper keys
    self[:valid_range] = "[#{val[:lower]}, #{val[:upper]}]"
  end
end
