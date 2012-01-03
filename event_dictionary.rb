class EventDictionary < ActiveRecord::Base
  # Table Properties
  set_table_name "event_dictionary"
  set_primary_key "record_id"
  set_sequence_name 'id_seq'

  ##
  # Callbacks
  before_save :delete_data_fields, :add_tags
  after_save :add_data_fields

  ##
  # Attributes
  attr_accessor :data_fields, :tag_names
  attr_accessible :name, :description, :data_fields, :event_tag_ids, :tag_names

  ##
  # Associations
  has_many :event_dictionary_data_fields, :foreign_key => "event_record_id"
  has_many :data_dictionary, :through => :event_dictionary_data_fields
  has_many :events_event_tags, :foreign_key => "record_id"
  has_many :event_tags, :through => :events_event_tags

  ##
  # Validations
  validates_presence_of :name, :description
  validates :name, :uniqueness => true,
                    :format =>  { :with => /\A\w+\z/, :message => "Only letters, numbers, or underscores allowed"},
                    :length => { :in => 2..255 }
  validates :description, :length => { minimum: 5 }


  ##
  # Scopes
  scope :has_tags, (lambda do |tags|
    # selects all records that have the given tag(s)
    tags = Array.wrap(tags)
    where(:record_id =>
      joins(:event_tags)
        .select("event_dictionary.record_id")
        .where(:event_tags=>{:tag_name=>tags})
        .group("event_dictionary.record_id")
        .having('count(event_dictionary.record_id) = ?', [tags.size]) # selects only those that match each tag
      )
  end)

  scope :has_data, (lambda do |data_titles|
    data_titles = Array.wrap(data_titles)
    where(:record_id => joins(:data_dictionary).select("event_dictionary.record_id").where(:data_dictionary => {:title => data_titles }).group("event_dictionary.record_id").having("count(event_dictionary.record_id) = ?", [data_titles.size]))
  end)

  ##
  # Methods
  #

  def delete_data_fields
     event_dictionary_data_fields.each {|df| df.destroy }
  end

  def add_data_fields
    #CUSTOM_LOGGER.info "DATA FIELDS: #{data_fields}"
    if data_fields
      data_fields.each do |field|
        if field["data_record_id"] != ""
          #CUSTOM_LOGGER.info "er: #{record_id} dr: #{field["data_record_id"]} f?: #{field["data_record_id"] == ""}"
          eddf = EventDictionaryDataField.new(:event_record_id => record_id, :data_record_id => field["data_record_id"], :required => false)# take out for now: field["required"])
          eddf.save
        end
      end
    end
  end

  def add_tags
    self.event_tags = []
    tag_names.split(', ').each do |tag_name|
      begin
        tag = EventTag.find_or_create_by_tag_name(tag_name.strip)
        CUSTOM_LOGGER.info "tag: #{tag.tag_name} valid?: #{tag.valid?} tags: #{self.event_tags}"
        self.event_tags << tag if tag.valid? # only save if creating valid tag
      rescue
      end
    end
    CUSTOM_LOGGER.info self.event_tags
  end

  def required_data_records
    event_dictionary_data_fields.where(:required => false).map { |x| x.data_dictionary }
  end

end