# == Schema Information
#
# Table name: shares
#
#  id                       :integer(4)      not null, primary key
#  title                    :string(255)     not null
#  geo_id                   :integer(4)      not null
#  share_cover_file_name    :string(255)
#  share_cover_content_type :string(255)
#  share_cover_file_size    :string(255)
#  body_html                :text
#  activity_id              :integer(4)
#  school_id                :integer(4)
#  user_id                  :integer(4)      not null
#  hits                     :integer(4)      default(0), not null
#  comments_count           :integer(4)      default(0), not null
#  hidden                   :boolean(1)
#  created_at               :datetime
#  updated_at               :datetime
#  last_modified_at         :datetime
#  last_modified_by_id      :integer(4)
#  last_replied_at          :datetime
#  last_replied_by_id       :integer(4)
#  deleted_at               :datetime
#  clean_html               :text
#

class Share < ActiveRecord::Base
  include BodyFormat
  
  belongs_to :user,:counter_cache => true
  belongs_to :geo
  belongs_to :activity, :counter_cache => true
  belongs_to :school
  belongs_to :requirement
  belongs_to :execution
  has_many :comments, :as => 'commentable', :dependent => :destroy
  
  validates_presence_of :geo_id, :message => "请选择一个和你的分享有关的城市"
  validates_presence_of :title,  :message => "请起个题目"
  
  
  def validate
      if self.user.shares.find(:all,:limit=>2,:conditions => ["created_at > ?",1.minute.ago]).size > 1
        errors.add(:title,"发贴频率过快")
      end
  end  
  
  acts_as_voteable
  acts_as_taggable
  acts_as_paranoid
  
  before_save  :format_content
  after_create :initial_last_replied
  after_create :create_feed
  
  named_scope :recent_shares, :order => "last_replied_at desc, comments_count desc",
                              :limit => 8,
                              :include => [:user, :tags]
                              
  named_scope :with_activity, :order => "created_at desc, comments_count desc",
                              :conditions => "activity_id is not null",
                              :include => [:user]
                            
  named_scope :with_school, :order => "created_at desc, comments_count desc",
                              :conditions => "school_id is not null",
                              :include => [:user]
                            
  

  define_index do
    # fields
    indexes title
    indexes school.title, :as => :school_title
    indexes geo.name, :as => :city
    indexes clean_html, :as => :content
    
    has :updated_at
    has :created_at
  end
  
  def hit!
    self.class.increment_counter :hits, id
  end
  
  def moderated_by?(user)
    (! user.blank?) and (user_id == user.id or user.has_role?("roles.admin"))
  end
  
  def self.archives
    date_func = "extract(year from created_at) as year,extract(month from created_at) as month"
    
    counts = Share.find_by_sql(["select count(*) as count, #{date_func} from shares where created_at < ? and deleted_at is null group by year,month order by year asc,month asc",Time.now])
    
    sum = 0
    result = counts.map do |entry|
      sum += entry.count.to_i
      {
        :name => entry.year + "年" + entry.month + "月",
        :month => entry.month.to_i,
        :year => entry.year.to_i,
        :delta => entry.count,
        :sum => sum
      }
    end
    return result.reverse
  end
  
  def html
    self.clean_html ||= sanitize(self.body_html)
    self.save(false) if self.clean_html_changed?
    self.clean_html
  end

  def voted_by
    self.votes[0..2].map(&:user)
  end
  
  private
  def initial_last_replied
    self.update_attributes!(:last_replied_at => self.created_at, :last_replied_by_id => self.user_id)
  end
  
  def format_content
    self.clean_html = sanitize(self.body_html)
  end
  
  def create_feed
    self.school.feed_items.create(:content => %(#{self.user.login} 在#{self.created_at.to_date}写了一篇关于#{self.school.title}的分享：#{self.title}), :user_id => self.user.id, :category => 'share',
                :item_id => self.id, :item_type => 'Share') if self.school
  end
end
