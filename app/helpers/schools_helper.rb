module SchoolsHelper
  def radio_choice(form, object)
    [[0,"无"], [1,"有"], [2, "未知"]].collect {|r| form.radio_button(object, r[0]) + r[1]}
  end
  
  def radio_value(value)
    result = %w(没有 有 未知)
    value.blank? ? "未知" : result[value]
  end
  
  def validate_for_human(school)
    if school.validated?
      if school.validator
        "#{school.validated_at.to_date}由#{link_to school.validator.login, user_url(school.validator)}验证"
      else
        "#{school.validated_at.to_date}通过验证"
      end
    else
      if school.validated_at.blank?
        "<span class=\"required\">学校信息未验证</span>"
      elsif school.validator
        "<span class=\"required\">#{school.validated_at.to_date}由#{link_to school.validator.login, user_url(school.validator)}取消验证</span>"
      elsif school.validated_at && !school.validator.blank?
        "<span class=\"required\">#{school.validated_at.to_date}取消验证</span>"
      end

    end
  end
  
  def edit_school_position_path(school)
    edit_school_path(school, :step => 'position')
  end
  
  def render_school_main_photo(school)
    html = ''
    if school.main_photo
      html += image_tag(school.main_photo.public_filename(:small))
    else
      html += image_tag(image_path('/images/default_school.jpg'), :width => "200")
    end
    html
  end
  
  
  def needs_check_box(form, tag, options, value)
    # 对秀秀和多背一公斤显示文本框模式
    if current_user.id == 31 || current_user.id == 1
      form.text_field tag, :size => 60
    else
      options.map do |option|
        included = value.nil? ? false : value.include?(option)
        check_box_tag(tag, option, included, :onchange => "update_needs('#{tag.to_s}')", :class => "#{tag}_needs") + 
        form.label(tag, option, {:class => 'checkbox_label'})
      end.join + form.hidden_field(tag, :id => "#{tag}_needs")
    end
  end
  
  def karma_star(karma)
    #要加上活跃度评星算法
    if karma == nil
      count = 0
    elsif karma < 20
      count = 0
    elsif karma < 40
      count = 1
    elsif karma < 80
      count = 2
    elsif karma < 160
      count = 3
    elsif karma < 320
      count = 4
    else
      count = 5
    end
    html = "<sapn title='活跃度:#{karma}'>" + '<img src="/images/star.png" class="stars"/>'*count + '<img src="/images/star_gary.png" class="stars"/>'*(5-count) + '</span>'
  end
  
  def link_to_needs(needs)
    unless needs.blank? 
      needs.split(' ').map do |need|
        link_to need, tag_path(:tag => need),:class => "need_tag"
      end.join(' ')
    else
      ""
    end
  end
  
  def needlist(school)
    return '' unless school.need
    list = [school.need.book,school.need.medicine,school.need.stationary,school.need.sport,school.need.cloth,school.need.accessory,school.need.course,school.need.teacher,school.need.other]
    list.map{|n| link_to_needs(n) }.join('')
  end
  
  def upload_script_for(id, container)
    javascript_tag(%(
      var swfu;
      jQuery(document).ready(function () {
        swfu = new SWFUpload({
          // Backend Settings
          upload_url: "upload.php",

          // File Upload Settings
          file_size_limit : "2 MB", // 2MB
          file_types : "*.*",
          file_types_description : "JPG Images|PNG Images and GIF Images",
          file_upload_limit : "0",

          // Event Handler Settings - these functions as defined in Handlers.js
          //  The handlers are not part of SWFUpload but are part of my website and control how
          //  my website reacts to the SWFUpload events.
          file_queue_error_handler : fileQueueError,
          file_dialog_complete_handler : fileDialogComplete,
          upload_progress_handler : uploadProgress,
          upload_error_handler : uploadError,
          upload_success_handler : uploadSuccess,
          upload_complete_handler : uploadComplete,

          // Button Settings
          button_image_url : "/images/buttonlink.gif",
          button_placeholder_id : "#{id}",
          button_width: 60,
          button_height: 20,
          button_text : '<a class="buttonlink" style="color:#FFF;">上传照片</a>',
          button_text_style : '.button { font-family: Helvetica, Arial, sans-serif; font-size: 12pt; } .buttonSmall { font-size: 10pt; }',
          button_text_top_padding: 3,
          button_text_left_padding: 5,
          button_window_mode: SWFUpload.WINDOW_MODE.TRANSPARENT,
          button_cursor: SWFUpload.CURSOR.HAND,

          // Flash Settings
          flash_url : "/swfs/swfupload.swf",

          custom_settings : {
            upload_target : "#{container}"
          },

          // Debug Settings
          debug: false
        });
      });
    ))
  end
  
  def upload_button(container)
    html = upload_script_for("upload", container)
    html += content_tag(:span, :id => "upload") do
      "上传照片"
    end
    html
  end
end