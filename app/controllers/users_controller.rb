class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  #include AuthenticatedSystem
  
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge, :show, :shares, :participated_activities, :submitted_activities, :submitted_schools, :visited_schools]
  before_filter :login_required, :only => [:edit, :update, :suspend, :unsuspend, :destroy, :purge]

  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.register! if @user.valid?
    if @user.errors.empty?
      @user.activate!
      self.current_user = @user
      flash[:notice] = "注册完成, 补充一下你的个人信息吧"
      redirect_to "/setting"
      #render :action => "wait_activation"
    else
      render :action => 'new'
    end
  end


  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    #logger.info("CURRENT USER ACTIVE: #{self.current_user.active?}")
    #logger.info("LOGGED IN: #{logged_in?}")
    if logged_in? && !self.current_user.active?
      self.current_user.activate!
      flash[:notice] = "注册完成，补充一下你的个人信息吧"
      redirect_back_or_default("/setting")
    else
      flash[:notice] = "激活码不正确，请联系 feedback@1kg.org"
      redirect_back_or_default("/")
    end
    
  end
  
  def show
    
    get_user_record(@user)

    @shares = @user.shares.find(:all, :conditions => ["hidden=?", false], :order => "created_at desc", :limit => 3)
  end
  
  def shares
    
    get_user_record(@user)
    
    @shares = @user.shares.find(:all, :conditions => ["hidden=?", false], 
                                      :order => "created_at desc", 
                                      :select => "title, hits, comments_count, created_at, id")
  end
  
  
  def participated_activities
    @activities = @user.participated_activities.paginate(:page => params[:page] || 1, :order => "created_at desc", :per_page => 20)
  end
  
  def submitted_activities
    @activities = @user.submitted_activities.paginate(:page => params[:page] || 1, :order => "created_at desc", :per_page => 20)
  end
  
  def submitted_schools
    @schools = @user.submitted_schools.paginate(:page => params[:page] || 1, :order => "created_at desc", :per_page => 20)
  end
  
  def visited_schools
    @schools = @user.visited_schools.paginate(:page => params[:page] || 1, :order => "created_at desc", :per_page => 20)
  end
  
  
  
  def edit
    @page_title = "编辑个人信息"
    @user = current_user
    
    if params[:type] == "account"
      @type = "account"
      render :action => "setting_account"
      
    elsif params[:type] == "avatar"
      @type = "avatar"
      render :action => "setting_avatar"
      
    elsif params[:type] == "live"
      @type = "personal"
      @live_geo = @user.geo
      @current_geo = (params[:live].blank? ? @live_geo : Geo.find(params[:live]))
      if @current_geo
        @same_level_geos = @current_geo.siblings
        @next_level_geos = @current_geo.children
      else
        @same_level_geos = Geo.roots
        @next_level_geos = nil
      end      
      render :action => "setting_live"
      
    elsif params[:type] == 'profile'
      @type = "profile"
      @profile = @user.profile || Profile.new
      render :action => "setting_profile"
      
    else
      @type = "personal"
      render :action => "setting_personal"
    end
  end
  
  def update
    @user = current_user
    
    if params[:for] == 'login'
      @user.update_attributes!(params[:user])
      flash[:notice] = "用户名修改成功"
      redirect_to setting_url(:type => 'account')
    
    
      
    elsif params[:for] == 'password'
      @user.update_attributes!(params[:user])
      #self.current_user = @user
      flash[:notice] = "密码修改成功"
      redirect_to setting_url(:type => 'account')
    
    
      
    elsif params[:for] == 'avatar'
      # convert user's avatar to gif format, thanks for Robin Lu
      iconfile = params[:user][:avatar]
      unless iconfile.blank?
        # if user upload avatar, convert file format
        img = ::Magick::Image::from_blob(iconfile.read).first
        img.crop_resized!(72,72)
        filename = File.join(RAILS_ROOT + "/public/user/avatar/tmp", 'icon.gif')
        img.write(filename)
        iconfile = File.open(filename)
        params[:user][:avatar] = iconfile
      end
      @user.update_attributes!(params[:user])
      flash[:notice] = "头像修改成功"
      redirect_to setting_url(:type => "avatar")
    
    
    
    
    elsif params[:for] == 'move'
      @user.geo = nil
      @user.save!
      flash[:notice] = "请选择您现在的居住城市"
      redirect_to my_city_url
      
      
      
    elsif params[:for] == 'live'
      @geo = Geo.find(params[:geo])
      @user.geo = @geo unless @geo.blank?
      @user.save!
      flash[:notice] = "您已经入住#{@geo.name}"
      redirect_to my_city_url
    
    
    
    elsif params[:for] == 'profile'
      if @user.profile
        @user.profile.update_attributes!(params[:profile])
      else
        # 用户第一次填个人资料
        profile = Profile.new(params[:profile])
        @user.profile = profile
        @user.save!
      end
      flash[:notice] = "个人资料修改成功"
      redirect_to setting_url(:type => 'profile')
      
    end
  end

  def suspend
    @user.suspend! 
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end

  protected
  def find_user
    @user = User.find(params[:id])
  end
  
  def get_user_record(user)
    # user's published activities
    @activities = user.submitted_activities.find(:all, :limit => 10, :order => "created_at desc")
    
    #user's submitted schools
    @schools = user.submitted_schools.find(:all, :limit => 10, :order => "created_at desc")
    
    @neighbors = user.neighbors.find(:all, :order => "neighborhoods.created_at desc", 
                                           :limit => 16
                                           )
  end
  

end
