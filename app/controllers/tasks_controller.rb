class TasksController < ApplicationController
  before_filter :require_user
  before_filter :update_sidebar, :only => :index
  before_filter :set_current_tab, :only => [ :index, :show ]

  # GET /tasks
  # GET /tasks.xml
  #----------------------------------------------------------------------------
  def index
    @view = params[:view] || "pending"
    @tasks = Task.find_all_grouped(@current_user, @view)

    respond_to do |format|
      format.html # index.html.haml
      # Hash keys must be strings... symbols generate "undefined method 'singularize' error"
      format.xml  { render :xml => @tasks.inject({}) { |tasks, (k,v)| tasks[k.to_s] = v; tasks } }
    end
  end

  # GET /tasks/1
  # GET /tasks/1.xml                                                       HTML
  #----------------------------------------------------------------------------
  def show
    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { @task = Task.tracked_by(@current_user).find(params[:id]);  render :xml => @task }
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml                                                     AJAX
  #----------------------------------------------------------------------------
  def new
    @view = params[:view] || "pending"
    @task = Task.new
    @users = User.except(@current_user).all
    @bucket = Setting.task_bucket[1..-1] << [ "On Specific Date...", :specific_time ]
    @category = Setting.invert(:task_category)
    if params[:related]
      model, id = params[:related].split("_")
      instance_variable_set("@asset", model.classify.constantize.my(@current_user).find(id))
    end

    respond_to do |format|
      format.js   # new.js.rjs
      format.xml  { render :xml => @task }
    end

  rescue ActiveRecord::RecordNotFound # Kicks in if related asset was not found.
    respond_to_related_not_found(model, :js) if model
  end

  # GET /tasks/1/edit                                                      AJAX
  #----------------------------------------------------------------------------
  def edit
    @view = params[:view] || "pending"
    @task = Task.tracked_by(@current_user).find(params[:id])
    @users = User.except(@current_user).all
    @bucket = Setting.task_bucket[1..-1] << [ "On Specific Date...", :specific_time ]
    @category = Setting.invert(:task_category)
    @asset = @task.asset if @task.asset_id?
    if params[:previous] =~ /(\d+)\z/
      @previous = Task.tracked_by(@current_user).find($1)
    end

  rescue ActiveRecord::RecordNotFound
    @previous ||= $1.to_i
    respond_to_not_found(:js) unless @task
  end

  # POST /tasks
  # POST /tasks.xml                                                        AJAX
  #----------------------------------------------------------------------------
  def create
    @task = Task.new(params[:task]) # NOTE: we don't display validation messages for tasks.
    @view = params[:view] || "pending"

    respond_to do |format|
      if @task.save
        update_sidebar if called_from_index_page?
        format.js   # create.js.rjs
        format.xml  { render :xml => @task, :status => :created, :location => @task }
      else
        format.js   # create.js.rjs
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml                                                       AJAX
  #----------------------------------------------------------------------------
  def update
    @view = params[:view] || "pending"
    @task = Task.tracked_by(@current_user).find(params[:id])
    @task_before_update = @task.clone

    if @task.due_at && (@task.due_at < Date.today.to_time)
      @task_before_update.bucket = "overdue"
    else
      @task_before_update.bucket = @task.computed_bucket
    end

    respond_to do |format|
      if @task.update_attributes(params[:task])
        @task.bucket = @task.computed_bucket
        if called_from_index_page?
          if Task.bucket_empty?(@task_before_update.bucket, @current_user, @view)
            @empty_bucket = @task_before_update.bucket
          end
          update_sidebar
        end
        format.js   # update.js.rjs
        format.xml  { head :ok }
      else
        format.js   # update.js.rjs
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml)
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml                                                    AJAX
  #----------------------------------------------------------------------------
  def destroy
    @view = params[:view] || "pending"
    @task = Task.tracked_by(@current_user).find(params[:id])
    @task.destroy if @task

    # Make sure bucket's div gets hidden if we're deleting last task in the bucket.
    if Task.bucket_empty?(params[:bucket], @current_user, @view)
      @empty_bucket = params[:bucket]
    end

    update_sidebar if called_from_index_page?
    respond_to do |format|
      format.js   # destroy.js.rjs
      format.xml  { head :ok }
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml)
  end

  # PUT /tasks/1/complete
  # PUT /leads/1/complete.xml                                              AJAX
  #----------------------------------------------------------------------------
  def complete
    @task = Task.tracked_by(@current_user).find(params[:id])
    @task.update_attributes(:completed_at => Time.now) if @task

    # Make sure bucket's div gets hidden if it's the last completed task in the bucket.
    if Task.bucket_empty?(params[:bucket], @current_user)
      @empty_bucket = params[:bucket]
    end

    update_sidebar unless params[:bucket].blank?
    respond_to do |format|
      format.js   # complete.js.rjs
      format.xml  { head :ok }
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml)
  end

  # Ajax request to filter out a list of tasks.                            AJAX
  #----------------------------------------------------------------------------
  def filter
    @view = params[:view] || "pending"

    update_session do |filters|
      if params[:checked] == "true"
        filters << params[:filter]
      else
        filters.delete(params[:filter])
      end
    end
  end

  private
  # Yields array of current filters and updates the session using new values.
  #----------------------------------------------------------------------------
  def update_session
    name = "filter_by_task_#{@view}"
    filters = (session[name].nil? ? [] : session[name].split(","))
    yield filters
    session[name] = filters.uniq.join(",")
  end

  # Collect data necessary to render filters sidebar.
  #----------------------------------------------------------------------------
  def update_sidebar
    @view = params[:view]
    @view = "pending" unless %w(pending assigned completed).include?(@view)
    @task_total = Task.totals(@current_user, @view)

    # Update filters session if we added, deleted, or completed a task.
    if @task
      update_session do |filters|
        if @empty_bucket  # deleted, completed, rescheduled, or reassigned and need to hide a bucket
          filters.delete(@empty_bucket)
        elsif !@task.deleted_at && !@task.completed_at # created new task
          filters << @task.computed_bucket
        end
      end
    end

    # Create default filters if filters session is empty.
    name = "filter_by_task_#{@view}"
    unless session[name]
      filters = @task_total.keys.select { |key| key != :all && @task_total[key] != 0 }.join(",")
      session[name] = filters unless filters.blank?
    end
  end

end
