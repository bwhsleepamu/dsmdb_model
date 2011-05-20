class User < ActiveRecord::Base  
  has_many :authentications, :dependent => :delete_all
  has_and_belongs_to_many :roles
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :rememberable, :trackable, :validatable, :timeoutable, :registerable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name
  
  # Scopes
  scope :active, :conditions => { :active => true }
  
  before_destroy :delete_role_associations
  
  # User Methods
  
  # Overriding Devise built-in active? method
  def active_for_authentication?
    super and self.active and not self.deleted?
  end
  
  def apply_omniauth(omniauth)
    unless omniauth['user_info'].blank?
      self.email = omniauth['user_info']['email'] if email.blank?
      self.first_name = omniauth['user_info']['first_name'] if first_name.blank?
      self.last_name = omniauth['user_info']['last_name'] if last_name.blank?
    end
    authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end
  
  def password_required?
    (authentications.empty? || !password.blank?) && super
  end
  
  # Declaritive Authorization - maps roles to symbols
  def role_symbols
      roles.map do |role|
        role.title.underscore.to_sym
      end
  end
  
  private 
  
  # make sure association table entries are deleted before the user is deleted.  
  # this enforces oracle foreign key constraints
  def delete_role_associations
    self.roles.delete(self.roles)
  end
end
