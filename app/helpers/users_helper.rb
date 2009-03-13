module UsersHelper
  def avatar_for(user, size)
    if user.avatar.blank?
      image_tag "avatar_#{size}.png", :class => "avatar", :alt => user.login
    else
      image_tag url_for_file_column(user, :avatar, size), :class => "avatar", :alt => user.login
    end
  end
end