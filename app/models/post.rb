class Post
  include Mongoid::Document
  before_save :set_date, if: Proc.new { |post| post.published_on_not_set? }

  field :title, type: String
  field :content, type: String
  field :published_on, type: Time

  validates :title, :content, presence: true

  has_many :comments
  belongs_to :user

  paginates_per 10

  def published_on_not_set?
    if published_on == nil
      true
    else
      false
    end
  end

  def set_date
    self.published_on = Time.now
  end

end