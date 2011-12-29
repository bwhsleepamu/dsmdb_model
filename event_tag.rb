class EventTag < ActiveRecord::Base
  set_primary_key self.name.underscore+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :tag_name, :description

  ##
  # Associations
  has_many :events_event_tags
  has_many :event_dictionary, :through => :events_event_tags

  ##
  # Scopes
  scope :search_by_name, lambda {|name|
    # allows searching by parts of tag name
    name = '%'+name+'%'
    where("lower(tag_name) like lower(?)", name)
  }

  scope :frequency, lambda { joins(:events_event_tags).select("event_tags.tag_name as tag, count(events_event_tags.event_tag_id) as freq").group("event_tags.tag_name") }

  ##
  # Validations
  validates_presence_of :tag_name
  validates :tag_name, :uniqueness => true,
                    :format =>  { :with => /\A\w+\z/, :message => "Only letters, numbers, or underscores allowed"},
                    :length => { :in => 2..255 }

  ##
  # Class Methods
  def self.frequency_hash(search)
    search_by_name(search).frequency.map{ |x| {:tag => x.tag, :freq => x.freq }}
  end

  def self.suggested_tag_names(number)
    EventTag.frequency_hash("").sort { |a, b| b[:freq] <=> a[:freq] }.map {|x| x[:tag]}.first(number)
  end

  def save
    # start transaction
    EventTag.transaction do
      CUSTOM_LOGGER.info "Started transaction"
      super
    end

  end

end
