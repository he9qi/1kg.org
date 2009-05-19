# == Schema Information
# Schema version: 20090430155946
#
# Table name: photos
#
#  id               :integer(4)      not null, primary key
#  parent_id        :integer(4)
#  content_type     :string(255)
#  filename         :string(255)
#  thumbnail        :string(255)
#  size             :integer(4)
#  width            :integer(4)
#  height           :integer(4)
#  user_id          :integer(4)
#  title            :string(255)     not null
#  description      :text
#  description_html :text
#  created_at       :datetime
#  updated_at       :datetime
#  deleted_at       :datetime
#  activity_id      :integer(4)
#  school_id        :integer(4)
#

class Photo < ActiveRecord::Base
  belongs_to :user
  belongs_to :school
  belongs_to :activity
  
  has_attachment :processor => :rmagick,
                 :content_type => :image,
                 :storage => :file_system,
                 :max_size => 2.megabytes,
                 :thumbnails => {
                   :square => "75x75!",
                   :thumb  => "120x80>",
                   :small  => "240x180>",
                   :medium => "565x420>"
                 }
  
  validates_as_attachment
  
  before_save :fill_title
  
  def self.recent
    find(:all, :conditions => "parent_id is NULL", :order => "updated_at desc", :limit => 8)
  end
  
  def previous(user)
    Photo.find(:first, :conditions => ["parent_id is NULL and id < ? and user_id = ?", self.id, user.id], :order => "id DESC")
  end
  
  def next(user)
    Photo.find(:first, :conditions => ["parent_id is NULL and id > ? and user_id = ?", self.id, user.id])
  end
  
  private
  def fill_title
    self.title = "未命名图片" if self.title.blank?
  end
  
end
