require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CampaignsController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "campaigns", :action => "index").should == "/campaigns"
    end
  
    it "should map #new" do
      route_for(:controller => "campaigns", :action => "new").should == "/campaigns/new"
    end
  
    it "should map #show" do
      route_for(:controller => "campaigns", :action => "show", :id => 1).should == "/campaigns/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "campaigns", :action => "edit", :id => 1).should == "/campaigns/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "campaigns", :action => "update", :id => 1).should == "/campaigns/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "campaigns", :action => "destroy", :id => 1).should == "/campaigns/1"
    end

    it "should map #search" do
      route_for(:controller => "campaigns", :action => "search", :id => 1).should == "/campaigns/search/1"
    end

    it "should map #auto_complete" do
      route_for(:controller => "campaigns", :action => "auto_complete", :id => 1).should == "/campaigns/auto_complete/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/campaigns").should == {:controller => "campaigns", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/campaigns/new").should == {:controller => "campaigns", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/campaigns").should == {:controller => "campaigns", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/campaigns/1").should == {:controller => "campaigns", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/campaigns/1/edit").should == {:controller => "campaigns", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/campaigns/1").should == {:controller => "campaigns", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/campaigns/1").should == {:controller => "campaigns", :action => "destroy", :id => "1"}
    end

    it "should generate params for #search" do
      params_from(:get, "/campaigns/search/1").should == {:controller => "campaigns", :action => "search", :id => "1"}
    end

    it "should generate params for #auto_complete" do
      params_from(:post, "/campaigns/auto_complete/1").should == {:controller => "campaigns", :action => "auto_complete", :id => "1"}
    end
  end
end
