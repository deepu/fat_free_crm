require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
 
describe "/leads/promote.js.rjs" do
  include LeadsHelper

  before(:each) do
    login_and_assign
    @account = Factory(:account)
    assigns[:users] = [ @current_user ]
    assigns[:account] = @account
    assigns[:accounts] = [ @account ]
    assigns[:contact] = Factory(:contact)
    assigns[:opportunity] = Factory(:opportunity)
    assigns[:lead_status_total] = { :contacted => 1, :converted => 1, :new => 1, :rejected => 1, :other => 1, :all => 5 }
  end

  it "converted: should flip [Convert Lead] form when called from lead landing page" do
    request.env["HTTP_REFERER"] = "http://localhost/leads/123"
    assigns[:lead] = Factory(:lead, :id => 42, :status => "converted", :user => @current_user, :assignee => @current_user)

    render "leads/promote.js.rjs"
    response.should_not have_rjs("lead_42")
    response.should include_text('crm.flip_form("convert_lead"')
  end

  it "converted: should update sidebar when called from lead landing page" do
    request.env["HTTP_REFERER"] = "http://localhost/leads/123"
    assigns[:lead] = Factory(:lead, :id => 42, :status => "converted", :user => @current_user, :assignee => @current_user)

    render "leads/promote.js.rjs"
    response.should have_rjs("sidebar") do |rjs|
      with_tag("div[id=summary]")
      with_tag("div[id=recently]")
    end
    response.should include_text('$("summary").visualEffect("shake"')
  end

  it "converted: should update sidebar when called from leads index page" do
    request.env["HTTP_REFERER"] = "http://localhost/leads"
    assigns[:lead] = Factory(:lead, :id => 42, :status => "converted", :user => @current_user, :assignee => @current_user)

    render "leads/promote.js.rjs"
    response.should have_rjs("sidebar") do |rjs|
      with_tag("div[id=filters]")
      with_tag("div[id=recently]")
    end
    response.should include_text('$("filters").visualEffect("shake"')
  end

  it "converted: should update recently viewed items when called outside the leads (i.e. embedded)" do
    request.env["HTTP_REFERER"] = "http://localhost/campaigns/123"
    assigns[:lead] = Factory(:lead, :id => 42, :status => "converted", :user => @current_user, :assignee => @current_user)

    render "leads/promote.js.rjs"
    response.should have_rjs("recently") do |rjs|
      with_tag("div[class=caption]")
    end
  end

  it "converted: should replace [Convert Lead] with lead partial and highligh it when called outside lead landing page" do
    request.env["HTTP_REFERER"] = "http://localhost/leads"
    assigns[:lead] = Factory(:lead, :id => 42, :status => "converted", :user => @current_user, :assignee => @current_user)
  
    render "leads/promote.js.rjs"
    response.should have_rjs("lead_42") do |rjs|
      with_tag("li[id=lead_42]")
    end
    response.should include_text('$("lead_42").visualEffect("highlight"')
  end

  it "couldn't convert: should redraw the [Convert Lead] form and shake it" do
    assigns[:lead] = Factory(:lead, :id => 42, :status => "new", :user => @current_user, :assignee => @current_user)
  
    render "leads/promote.js.rjs"
    response.should have_rjs("lead_42") do |rjs|
      with_tag("form[class=edit_lead]")
    end
    response.should include_text('$("lead_42").visualEffect("shake"')
  end

  it "couldn't convert: should handle new or existing account and set up calendar field" do
    assigns[:lead] = Factory(:lead, :id => 42, :status => "new", :user => @current_user, :assignee => @current_user)
  
    render "leads/promote.js.rjs"
    response.should include_text("crm.create_or_select_account")
    response.should include_text('crm.date_select_popup("opportunity_closes_on")')
    response.should include_text('$("account_name").focus()')
  end

end