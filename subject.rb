class Subject < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :subject_code, :study_id, :notes, :new_irb_attributes, :deleted_irb_ids, :pl_id

  validates :subject_code, :presence => true, :uniqueness => true, :format => { :with => /\A\d+[A-Z]+[A-Z0-9]*\z/, :message => "Invalid subject code format"}

  # Associations
  belongs_to :study
  belongs_to :personnel, :foreign_key => "pl_id"
  has_many :events
  has_and_belongs_to_many :irbs


  # Callbacks
  after_update :save_irbs
  before_destroy :delete_irb_associations

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

  # Getters
  def demographics
    #events.where(:name => "demographics").first
    Event.where({:name => "demographics", :subject_id => subject_id}).first
  end

  # computed information:
  # TODO: SEARCH ON THIS INFO
  def age
    d = demographics
    if d
      admit_date = d.data.find_by_title("admit_date").value
      dob = d.data.find_by_title("date_of_birth").value

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
    end
    age || 'missing'
  end

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

end
