class TopicsController < ApplicationController
  
  before_filter :force_login, :except => [:index, :show, :unknown_request]
  before_filter :can_edit_topic, :only => [:edit, :update, :destroy]
  before_filter :check_privacy, :only => [:show]
  
  def index
    if logged_in?
      @topic_pages, @topics = paginate(:topics, :per_page => 20, :include => [:user, :last_poster], :order => 'last_post_at desc')
    else
      @topic_pages, @topics = paginate(:topics, :per_page => 20, :include => [:user, :last_poster], :order => 'last_post_at desc', :conditions => ["private = ?", false])
    end
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @topics.to_xml }
    end
  end

  def show
    @topic = Topic.find(params[:id])
    @posts = @topic.posts.find(:all)
    @forum = Forum.find_by_id(@topic.forum_id)
    @category = Category.find(@forum.category_id)
    @topic.hit!
    @page_title = @topic.title
    @posters = @posts.map(&:user) ; @posters.uniq!
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @topic.to_xml }
    end
  end

  def new
    @topic = Topic.new
    @topic.forum_id = params[:forum_id] 
  end

  def edit
    @topic = Topic.find(params[:id])
  end

  def create
    @topic = Topic.new(params[:topic])
    if @topic
      @topic.user_id = current_user.id
      @post = @topic.posts.build(params[:topic])
      @post.user_id = current_user.id
    end
    respond_to do |format|
      if @topic.save && @post.save
        format.html { redirect_to topic_url(@topic) }
        format.xml  { head :created, :location => topic_url(@topic) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @topic.errors.to_xml }
      end
    end
  end

  def update
    @topic = Topic.find(params[:id])
    respond_to do |format|
      if @topic.update_attributes(params[:topic])
        format.html { redirect_to topic_url(@topic) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @topic.errors.to_xml }
      end
    end
  end

  def destroy
    @topic = Topic.find(params[:id])
    @topic.destroy
    respond_to do |format|
      format.html { redirect_to topics_url }
      format.xml  { head :ok }
    end
  end
  
  def unknown_request
    if request.request_uri.include?('viewtopic.php')
      redirect_to topic_path(:id => params[:id])
    else
      redirect_to topics_path
    end
  end
  
  def can_edit_topic
    @topic = Topic.find(params[:id])
    redirect_to topic_path(@topic) and return false unless admin? || (current_user == @topic.user)
  end
  
  def check_privacy
    @topic = Topic.find(params[:id])
    redirect_to login_path if (!logged_in? && @topic.private)
  end
  
end
