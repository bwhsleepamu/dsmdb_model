class Subject < ActiveRecord::Base
  ##
  # Table Settings
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'

  ##
  # Attributes
  attr_accessible :subject_code, :study_id, :notes, :new_irb_attributes, :deleted_irb_ids, :pl_id

  ##
  # Validations
  validates :subject_code, :presence => true, :uniqueness => true, :format => { :with => /\A\d+[A-Z]+[A-Z0-9]*\z/, :message => "Invalid subject code format"}
  #validates_associated :events
  #validates_presence_of :personnel, :irbs
  validates_with SubjectValidator

  ##
  # Associations
  belongs_to :study
  belongs_to :personnel, :foreign_key => "pl_id"
  has_many :events, :limit => 10
  has_and_belongs_to_many :irbs


  ##
  # Callbacks
  after_update :save_irbs
  before_destroy :delete_irb_associations
  after_initialize :init_default_events
  before_validation :add_demographics

  ##
  # Class Methods
  def self.subject_code_format
    /\A\d+[A-Z]+[A-Z0-9]*\z/
  end

  def self.search(search)
    if search
      where('subject_code LIKE ?', "%#{search}%")
    else
      scoped
    end
  end

  ##
  # Checks
  def raster?
    events.where(:name => "in_bed_start").length > 0
  end


  ##
  # Getters

  ## demographics
  def demographics(data_title = nil)
    event = events.where(:name => "subject_demographics").first || events.select{|e| e.name == "subject_demographics"}.first
    if event && data_title
      event.data.where(:title => data_title).first
    else
      event
    end
  end

  def demographics?(data_title = nil)
    if data_title
      demographic_datum = demographics(data_title)
      # true if data exists and is not missing
      (demographic_datum && !demographic_datum.missing)
    else
      !demographics.nil?
    end
  end

  def demographics_sources(title)
    # all event names with the given tags and data, except for the main subject_demographics event
    possible_names = (EventDictionary.has_tags(["subject_data", "demographics"]).has_data(title)).map(&:name)  - ["subject_demographics"]
    events.where(:name => possible_names)
  end


  ##
  # Computed Attributes

  # TODO: SEARCH ON THIS INFO
  def age
    # TODO: REFACTOR!! better ways of finding demographics and computing common things that have a failsafe for missing info!!!!!!!!!


    admit_date = demographics("admit_date").value if demographics("admit_date")
    dob = demographics("date_of_birth").value if demographics("date_of_birth")

    if dob && admit_date
      age = admit_date.year - dob.year

      # if admit date is before birthday, take one year away
      if admit_date.month < dob.month
        age -= 1
      elsif admit_date.month == dob.month
        if admit_date.day < dob.day
          age -= 1
        end
      end
    end

    age
  end


  ##
  # Setters
  def new_irb_attributes=(irb_attributes)
    # Either find existing Irb object or create new one, then add to study
    irb_attributes.each do |attr|
      unless (attr[:protocol_id].empty? || attr[:protocol_id].nil?)
        new_irb = Irb.find_or_create_by_protocol_id(attr[:protocol_id])
        irbs << new_irb unless irbs.include?(new_irb)
      end
    end
  end

  def deleted_irb_ids=(irb_ids)
    irb_ids = irb_ids.map(&:to_i)
    irbs_to_delete = irbs.find_all_by_irb_id(irb_ids)
    irbs.delete(irbs_to_delete)
  end

  # Helpers  
  def save_irbs
    irbs.each do |irb|
      irb.save(false)
    end
  end

  # make sure association table entries are deleted before the user is deleted.  
  # this enforces oracle foreign key constraints
  def delete_irb_associations
    self.irbs.delete(self.irbs)
  end

  ##
  # When a new subject is created, we might want to create a dummy demographics event based on the data dictionary
  # definitions for such an event (subject_demographics)


  private

  def init_default_events
    ##
    # Initialize required events that should exist for every subject.  Only do this when first creating subject

    # subject demographics

    if self.new_record?
      self.events << Event.scaffold("subject_demographics", self[:subject_id]) unless self.events.find_by_name("subject_demographics")
    end


  end
  def add_demographics
    events << Event.scaffold("subject_demographics", self[:subject_id]) unless (events.where(:name => "subject_demographics").first || events.select{|e| e.name == "subject_demographics"}.first)
  end

end
