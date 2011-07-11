class Event < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :subject_id, :study_id, :source_id, :name, :labtime_hr, :labtime_min, :labtime_sec, :labtime_year, :realtime, :notes

  belongs_to :source
  belongs_to :study
  belongs_to :subject
  has_and_belongs_to_many :event_tags, :join_table => "events_event_tags"
  has_many :data

  accepts_nested_attributes_for :data
  
  after_save :save_data
  
  
  # add demographic tags
  def add_demographic_tags
    add_tags(["demographic", "manual", "merged"])
  end
  
  # add form tags
  def add_form_tags
    add_tags(["demographic", "manual", "form"])
  end

  def add_tags(tag_list)
    tag_list.each do |tag|
      event_tags << EventTag.find_or_create_by_tag_name(tag)      
    end
  end
  
  ## Creators for different types of events ##
  # return an event object for holding subject demographic data
  def self.new_subject_demographics(subject)
    event = Event.new({:name => "demographics"})
    event.subject = subject
    event.add_demographic_tags
    event.add_data_by_event_type
    event.realtime = Time.now()
    event.source = Source.new({:user => Authorization.current_user.id, :source_type => "merged", 
                        :reference => "Merged Forms page for subject #{subject.subject_id}"
                       })  
    event
  end
  
  def self.new_form(form_name, subject_id)
    # maybe make this the accessor and creator?

    CUSTOM_LOGGER.info "Creating form #{form_name} for #{subject_id}"
    e = Event.where("name = ? AND subject_id = ?", form_name, subject_id).first
    CUSTOM_LOGGER.info e ? e.event_id : "no other such event found"
    
    if e.nil?
      event = Event.new(:name => form_name)
      event.subject_id = subject_id
      event.add_data_by_event_type
      event.add_form_tags
      event.source = Source.new({:user => Authorization.current_user.id, :source_type => "physical", 
                                  :reference => "File Room - folder for subject #{event.subject.subject_code} - #{event.name}"
                                 })
      return event      
    else
      return e
    end
    
  end
  
  def add_data_by_event_type
    # each event has data titles associated with it
    case name
      when "demographics"
        titles = ["admit date", "suite number", "date of birth", "gender", "ethnic category", "race" ]
        titles += ["height", "weight", "blood pressure systolic", "blood pressure diastolic", "heart rate"]
        titles += ["usual school or work bedtime (lower bound)", "usual school or work bedtime (upper bound)"]
        titles += ["usual day off or weekend bedtime (lower bound)", "usual day off or weekend bedtime (upper bound)"]
        titles += ["usual school or work waketime (lower bound)", "usual school or work waketime (upper bound)"]
        titles += ["usual day off or weekend waketime (lower bound)", "usual day off or weekend waketime (upper bound)"]
        titles += ["desired bedtime", "desired waketime", "naps per week", "nap time"]
        titles += ["owl lark score"]
      when "personal data form"
        titles = ["date of birth", "gender", "ethnic category", "race"]
      when "physical exam form"
        titles = ["blood pressure systolic", "blood pressure diastolic", "heart rate"]
      when "physician form"
        titles = ["height", "weight", "blood pressure systolic", "blood pressure diastolic", "heart rate"]
      when "subject information form"
        titles = ["date of birth", "gender", "height", "weight"]
        titles += ["usual school or work bedtime (lower bound)", "usual school or work bedtime (upper bound)"]
        titles += ["usual day off or weekend bedtime (lower bound)", "usual day off or weekend bedtime (upper bound)"]
        titles += ["usual school or work waketime (lower bound)", "usual school or work waketime (upper bound)"]
        titles += ["usual day off or weekend waketime (lower bound)", "usual day off or weekend waketime (upper bound)"]
        titles += ["desired bedtime", "desired waketime", "naps per week", "nap time"]
      when "owl lark form"
        titles = ["owl lark score"]
      when "other sources"
        titles = ["date of birth", "gender", "ethnic category", "race", "height", "weight"]
        titles += ["usual school or work bedtime (lower bound)", "usual school or work bedtime (upper bound)"]
        titles += ["usual day off or weekend bedtime (lower bound)", "usual day off or weekend bedtime (upper bound)"]
        titles += ["usual school or work waketime (lower bound)", "usual school or work waketime (upper bound)"]
        titles += ["usual day off or weekend waketime (lower bound)", "usual day off or weekend waketime (upper bound)"]
        titles += ["desired bedtime", "desired waketime", "naps per week", "nap time"]
    end
    titles.each { |title| data.build(:title => title) }
  end
  
  
  def add_update_data(params)
    # add or update applicable data fields to event
    params.each do |title, value|
      convert_units!(value)
      title_ns = title.tr('_', ' ')
      
      CUSTOM_LOGGER.info "Adding/updating data for #{subject.subject_code} #{name}: #{title} #{title_ns} #{value}"
      
      data_attributes = value.merge({ :title => title_ns }) 
      data_attributes[:missing] ||= 'f'

      if (datum = data.find_by_title(title_ns))
        CUSTOM_LOGGER.info "Updating existing #{title}"
        datum.update_attributes(data_attributes)
      else
        CUSTOM_LOGGER.info "Creating new #{title}"
        datum = data.build(data_attributes)
      end
        
      # make sure missing ==> no data stored
      if datum.missing
        datum.numeric = nil
        datum.char = nil
        datum.timepoint = nil
        datum.data_unit = nil
        datum.save
      end
      
      # create/update source information - put in data model
      if Source.create_source?(data_attributes[:source_attributes])
        CUSTOM_LOGGER.info "Updating/Creating Source Info"
        if datum.source
          CUSTOM_LOGGER.info "update current source"
          data_attributes[:source_attributes].merge({ :user => Authorization.current_user.id })
          datum.source.update_attributes(data_attributes[:source_attributes])
        else
          CUSTOM_LOGGER.info "create new source"
          s = Source.create(data_attributes[:source_attributes])
          s.user = Authorization.current_user.id
          datum.source = s
        end
        datum.save
      else
        if datum.source
          if datum.source.data.length <= 1
            ds = datum.source
            datum.source = nil
            datum.save            
            ds.destroy
          else
            datum.source = nil
          end
        end
      end
    end
  end
  
  private
  
  # convert to standard units - modifies value
  def convert_units!(value)
    # for now: lb ==> kg and ft/in ==> cm
    case value[:unit_name]
      when "ft"
        u = Unit(value[:numeric])
        u >>= "cm"
        value[:numeric] = u.abs
        value[:unit_name] = "cm"
      when "lb"
        u = Unit(value[:numeric] + " lb")
        u >>= "kg"
        value[:numeric] = u.abs
        value[:unit_name] = "kg"
    end
  end
  
  def save_data
    self.data.each {|d| d.save}
  end
end
