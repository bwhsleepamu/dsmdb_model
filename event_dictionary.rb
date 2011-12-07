class EventDictionary < ActiveRecord::Base
  # Table Properties
  set_table_name "event_dictionary"
  set_primary_key "record_id"
  set_sequence_name 'id_seq'

  # Callbacks
  before_save :delete_data_fields
  after_save :add_data_fields

  # Attributes
  attr_accessor :data_fields
  attr_accessible :name, :description, :data_fields

  # Associations
  has_many :event_dictionary_data_fields, :foreign_key => "event_record_id"
  has_many :data_dictionary, :through => :event_dictionary_data_fields
  has_and_belongs_to_many :event_tags, :join_table => "events_event_tags", :foreign_key => "record_id"

  # Validations
  validates_presence_of :name, :description
  validates :name, :uniqueness => true,
                    :format =>  { :with => /\A\w+\z/, :message => "Only letters, numbers, or underscores allowed"},
                    :length => { :in => 2..255 }
  validates :description, :length => { minimum: 5 }

  ##
  # Methods
  #

  def delete_data_fields
     event_dictionary_data_fields.each {|df| df.destroy }
  end

  def add_data_fields
    #CUSTOM_LOGGER.info "DATA FIELDS: #{data_fields}"
    data_fields.each do |field|
      if field["data_record_id"] != ""
        #CUSTOM_LOGGER.info "er: #{record_id} dr: #{field["data_record_id"]} f?: #{field["data_record_id"] == ""}"
        eddf = EventDictionaryDataField.new(:event_record_id => record_id, :data_record_id => field["data_record_id"], :required => false)# take out for now: field["required"])
        eddf.save
      end
    end
  end

  def add_tags(tag_list)
    tag_list.each do |tag|
      event_tags << EventTag.find_or_create_by_tag_name(tag)
    end
  end

  def required_data_records
    event_dictionary_data_fields.where(:required => false).map { |x| x.data_dictionary }
  end

end