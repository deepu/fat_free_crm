# == Schema Information
# Schema version: 17
#
# Table name: contacts
#
#  id          :integer(4)      not null, primary key
#  uuid        :string(36)
#  user_id     :integer(4)
#  lead_id     :integer(4)
#  assigned_to :integer(4)
#  reports_to  :integer(4)
#  first_name  :string(64)      default(""), not null
#  last_name   :string(64)      default(""), not null
#  access      :string(8)       default("Private")
#  title       :string(64)
#  department  :string(64)
#  source      :string(32)
#  email       :string(64)
#  alt_email   :string(64)
#  phone       :string(32)
#  mobile      :string(32)
#  fax         :string(32)
#  blog        :string(128)
#  linkedin    :string(128)
#  facebook    :string(128)
#  twitter     :string(128)
#  address     :string(255)
#  born_on     :date
#  do_not_call :boolean(1)      not null
#  deleted_at  :datetime
#  created_at  :datetime
#  updated_at  :datetime
#

class Contact < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :lead
  belongs_to  :assignee, :class_name => "User", :foreign_key => :assigned_to
  has_one     :account_contact, :dependent => :destroy
  has_one     :account, :through => :account_contact
  has_many    :contact_opportunities, :dependent => :destroy
  has_many    :opportunities, :through => :contact_opportunities, :uniq => true, :order => "opportunities.id DESC"
  has_many    :tasks, :as => :asset, :dependent => :destroy, :order => 'created_at DESC'
  has_many    :activities, :as => :subject, :order => 'created_at DESC'

  simple_column_search :first_name, :last_name, :escape => lambda { |query| query.gsub(/[^\w\s\-]/, "").strip }

  uses_mysql_uuid
  uses_user_permissions
  acts_as_commentable
  acts_as_paranoid

  validates_presence_of :first_name, :message => "^Please specify first name."
  validates_presence_of :last_name, :message => "^Please specify last name."
  validate :users_for_shared_access

  SORT_BY = {
    "first name"   => "contacts.first_name ASC",
    "last name"    => "contacts.last_name ASC",
    "date created" => "contacts.created_at DESC",
    "date updated" => "contacts.updated_at DESC"
  }

  # Default values provided through class methods.
  #----------------------------------------------------------------------------
  def self.per_page ;  30                         ; end
  def self.outline  ;  "long"                     ; end
  def self.sort_by  ;  "contacts.created_at DESC" ; end
  def self.first_name_position ;  "before"        ; end

  #----------------------------------------------------------------------------
  def full_name(format = nil)
    if format.nil? || format == "before"
      "#{self.first_name} #{self.last_name}"
    else
      "#{self.last_name}, #{self.first_name}"
    end
  end
  alias :name :full_name

  # Backend handler for [Create New Contact] form (see contact/create).
  #----------------------------------------------------------------------------
  def save_with_account_and_permissions(params)
    account = Account.create_or_select_for(self, params[:account], params[:users])
    self.account_contact = AccountContact.new(:account => account, :contact => self) unless account.id.blank?
    self.opportunities << Opportunity.find(params[:opportunity]) unless params[:opportunity].blank?
    self.save_with_permissions(params[:users])
  end

  # Backend handler for [Update Contact] form (see contact/update).
  #----------------------------------------------------------------------------
  def update_with_account_and_permissions(params)
    account = Account.create_or_select_for(self, params[:account], params[:users])
    self.account_contact = AccountContact.new(:account => account, :contact => self) unless account.id.blank?
    self.update_with_permissions(params[:contact], params[:users])
  end

  # Class methods.
  #----------------------------------------------------------------------------
  def self.create_for(model, account, opportunity, params)
    attributes = {
      :user_id     => params[:account][:user_id],
      :assigned_to => params[:account][:assigned_to],
      :access      => params[:access]
    }
    %w(first_name last_name title source email alt_email phone mobile blog linkedin facebook twitter address do_not_call).each do |name|
      attributes[name] = model.send(name.intern)
    end
    contact = Contact.new(attributes)

    # Save the contact only if the account and the opportunity have no errors.
    if account.errors.empty? && opportunity.errors.empty?
      # Note: contact.account = account doesn't seem to work here.
      contact.account_contact = AccountContact.new(:account => account, :contact => contact) unless account.id.blank?
      contact.opportunities << opportunity unless opportunity.id.blank?
      if contact.access != "Lead" || model.nil?
        contact.save_with_permissions(params[:users])
      else
        contact.save_with_model_permissions(model)
      end
    end
    contact
  end

  private
  # Make sure at least one user has been selected if the contact is being shared.
  #----------------------------------------------------------------------------
  def users_for_shared_access
    errors.add(:access, "^Please specify users to share the contact with.") if self[:access] == "Shared" && !self.permissions.any?
  end

end
